
sra_refresh <- function (env) {
  
  sql <- "
    SELECT
      
      libraries.library_uid                 as library_name,
      libraries.sample_uid                  as sample_name,
      libraries.sequencing_instrument_model as instrument_model,
      libraries.library_strategy            as library_strategy,
      libraries.library_source              as library_source,
      libraries.library_selection           as library_selection,
      libraries.paired_or_single            as library_layout,
      libraries.library_processing_url      as library_construction_protocol,

      files.bioproject_id                   as BioProject,
      files.file_uniq_name                  as file_path,
      files.file_format                     as file_format,

      biosamples.biosample_accession        as BioSample

    FROM libraries
      LEFT JOIN sra        ON sra.library_name = libraries.library_uid
      LEFT JOIN files      ON files.library_uid = libraries.library_uid
      LEFT JOIN biosamples ON biosamples.sample_name = libraries.sample_uid

    WHERE sra.file_path IS NULL
      AND files.data_type = 'scrubbed_sequence_reads'
      AND files.user = @user"
  
  sra <- db_query(env$db, sql, 'SraRefr1', simplify = FALSE)
  
  if (nrow(sra) == 0) return (invisible())
  
  sra <- plyr::ddply(sra, 'library_name', function (x) {
    res <- x[1,,drop=FALSE]
    res[['file_path']] <- jsonlite::toJSON(x[['file_path']])
    return (res)
  })


  db_insert(env$db, 'sra', sra, 'ApiSra2')

  invisible()
}



# BioSample accessions are usually assigned after the files were ingested.
sra_sync_biosamples <- function (db) {

  sql <- "
    UPDATE sra
      JOIN biosamples ON biosamples.sample_name = sra.sample_name
    SET sra.BioSample = biosamples.biosample_accession
    WHERE sra.BioSample IS NULL
      AND biosamples.biosample_accession IS NOT NULL
      AND sra.user = @user"
  db_query(db, sql, 'SraSync1')

  invisible()
}



# Builds an SRA submission XML (one EXPERIMENT and RUN per library) for download.
api_sra_export <- function (db, hvp_ids) {

  hvp_ids <- unlist(hvp_ids)
  stopifnot(length(hvp_ids) > 0)

  sra_sync_biosamples(db)

  sql <- "
    SELECT
      sra.*,
      libraries.sequencing_platform as platform,
      libraries.technique           as technique
    FROM sra
      LEFT JOIN libraries ON libraries.library_uid = sra.library_name
    WHERE sra.user = @user"
  res <- db_query(db, sql, 'ApiSraEx1', simplify = FALSE)

  if (length(missing_hvp_ids <- setdiff(hvp_ids, res[['hvp_id']])))
    stop("`hvp_id`(s) missing from database: ", paste(collapse = ', ', missing_hvp_ids))

  res <- res[res[['hvp_id']] %in% hvp_ids, , drop = FALSE]
  res <- res[order(res[['library_name']]), , drop = FALSE]


  # One RUN per library holding all of its files, e.g. R1 and R2.
  runs <- local({
    file_names <- lapply(res[['file_path']], \(x) sort(unlist(jsonlite::parse_json(x))))
    runs <- data.frame(
      row      = rep(seq_len(nrow(res)), lengths(file_names)),
      filename = as.character(unlist(file_names)) )

    sql   <- "SELECT file_uniq_name, file_format, md5_checksum FROM files WHERE `user` = @user AND file_uniq_name IN (%s)"
    sql   <- sprintf(sql, paste(rep("?", nrow(runs)), collapse = ", "))
    files <- db_query(db, sql, 'ApiSraEx2', as.list(runs[['filename']]), simplify = FALSE)

    i <- match(runs[['filename']], files[['file_uniq_name']])
    runs[['file_format']] <- files[['file_format']][i]
    runs[['checksum']]    <- files[['md5_checksum']][i]
    runs[['filetype']]    <- unname(SRA_FILETYPES[runs[['file_format']]])
    runs
  })


  # CV terms like "OTHER: Host depletion" are submitted as SRA's OTHER/other,
  # with "library_selection: Host depletion" added to DESIGN_DESCRIPTION.
  design <- cbind(
    res[['technique']],
    ifelse(is.na(res[['library_construction_protocol']]), NA, paste("protocol:", res[['library_construction_protocol']])) )
  for (f in c('library_strategy', 'library_source', 'library_selection')) {
    is_other     <- grepl("^OTHER:", res[[f]])
    design       <- cbind(design, ifelse(is_other, paste0(f, ": ", trimws(sub("^OTHER:", "", res[[f]]))), NA))
    res[[f]][is_other] <- if (f == 'library_selection') "other" else "OTHER"
  }
  design <- apply(design, 1L, \(x) paste(na.omit(x), collapse = "; "))


  errors <- c()

  if (length(i <- which(is.na(res[['BioSample']])))) {
    msg    <- "Assign BioSample IDs before exporting these libraries: %s"
    errors <- c(errors, sprintf(msg, paste(res[['library_name']][i], collapse = ", ")))
  }

  required   <- c('BioProject', 'library_strategy', 'library_source', 'library_selection', 'library_layout', 'platform', 'instrument_model')
  is_missing <- is.na(as.matrix(res[, required, drop = FALSE]))
  for (i in head(which(rowSums(is_missing) > 0))) {
    msg    <- "%s: missing `%s`."
    errors <- c(errors, sprintf(msg, res[['library_name']][i], paste(required[is_missing[i, ]], collapse = "`, `")))
  }

  if (length(i <- head(which(is.na(runs[['filetype']]))))) {
    msg    <- "%s: SRA does not accept the file format of \"%s\" (%s)."
    errors <- c(errors, sprintf(msg, res[['library_name']][runs[['row']][i]], runs[['filename']][i], runs[['file_format']][i]))
  }

  if (length(errors))
    stop(paste(errors, collapse = "\n"))


  Submission <- xml2::xml_new_root("Submission", .version = "1.0", .encoding = "UTF-8")
  add        <- xml2::xml_add_child

  Description  <- add(Submission, "Description")
  Organization <- add(Description, "Organization", role = "owner", type = "consortium")
  add(Organization, "Name", "Human Virome Project")

  AddData <- add(add(Submission, "Action"), "AddData", target_db = "SRA")

  for (i in seq_len(nrow(res))) {

    x <- res[i, , drop = FALSE]

    # TITLE is left for NCBI to auto-generate.
    EXPERIMENT <- add(AddData, "EXPERIMENT", alias = x[['library_name']])
    add(EXPERIMENT, "STUDY_REF", accession = x[['BioProject']])

    DESIGN <- add(EXPERIMENT, "DESIGN")
    add(DESIGN, "DESIGN_DESCRIPTION", design[i])
    add(DESIGN, "SAMPLE_DESCRIPTOR", accession = x[['BioSample']])

    LIBRARY_DESCRIPTOR <- add(DESIGN, "LIBRARY_DESCRIPTOR")
    add(LIBRARY_DESCRIPTOR, "LIBRARY_NAME",      x[['library_name']])
    add(LIBRARY_DESCRIPTOR, "LIBRARY_STRATEGY",  x[['library_strategy']])
    add(LIBRARY_DESCRIPTOR, "LIBRARY_SOURCE",    x[['library_source']])
    add(LIBRARY_DESCRIPTOR, "LIBRARY_SELECTION", x[['library_selection']])
    add(add(LIBRARY_DESCRIPTOR, "LIBRARY_LAYOUT"), toupper(x[['library_layout']]))
    if (!is.na(x[['library_construction_protocol']]))
      add(LIBRARY_DESCRIPTOR, "LIBRARY_CONSTRUCTION_PROTOCOL", x[['library_construction_protocol']])

    PLATFORM <- add(EXPERIMENT, "PLATFORM")
    add(add(PLATFORM, x[['platform']]), "INSTRUMENT_MODEL", x[['instrument_model']])

    RUN   <- add(AddData, "RUN", alias = x[['library_name']], experiment_ref = x[['library_name']])
    FILES <- add(add(RUN, "DATA_BLOCK"), "FILES")
    for (j in which(runs[['row']] == i))
      add(FILES, "FILE",
        filename        = runs[['filename']][j],
        filetype        = runs[['filetype']][j],
        checksum_method = "MD5",
        checksum        = runs[['checksum']][j] )
  }

  return (list(download = list(
    filename = unbox(sprintf("SRA_submission_%s.xml", Sys.Date())),
    type     = unbox("application/xml"),
    content  = unbox(as.character(Submission)) )))
}



# <?xml version="1.0" encoding="UTF-8"?>
# <Submission>
#   <Description>
#     <Comment>Batch SRA submission for Cohort A - WGS and 16S</Comment>
#     <Organization role="center" type="institute">
#       <Name>My Multi-Center Consortium</Name>
#     </Organization>
#   </Description>
#   
#   <!-- ACTION 1: Add SRA Experiments and Runs -->
#   <Action>
#     <AddData target_db="SRA">
#       <!-- EXPERIMENT 1: 16S Data -->
#       <EXPERIMENT alias="Exp_Sample001_16S">
#         <TITLE>16S rRNA sequencing of Sample 001</TITLE>
#         <STUDY_REF accession="PRJNA123456"/> <!-- Cohort BioProject -->
#         <DESIGN>
#           <DESIGN_DESCRIPTION>V3-V4 16S rRNA amplification</DESIGN_DESCRIPTION>
#           <SAMPLE_DESCRIPTOR accession="SAMN11111111"/> <!-- Existing BioSample -->
#           <LIBRARY_DESCRIPTOR>
#             <LIBRARY_NAME>Lib_001_16S</LIBRARY_NAME>
#             <LIBRARY_STRATEGY>AMPLICON</LIBRARY_STRATEGY>
#             <LIBRARY_SOURCE>METAGENOMIC</LIBRARY_SOURCE>
#             <LIBRARY_SELECTION>PCR</LIBRARY_SELECTION>
#             <LIBRARY_LAYOUT>
#               <PAIRED/>
#             </LIBRARY_LAYOUT>
#           </LIBRARY_DESCRIPTOR>
#         </DESIGN>
#         <PLATFORM>
#           <ILLUMINA>
#             <INSTRUMENT_MODEL>Illumina MiSeq</INSTRUMENT_MODEL>
#           </ILLUMINA>
#         </PLATFORM>
#       </EXPERIMENT>
# 
#       <!-- RUN 1: Linking FASTQ Files to Experiment 1 -->
#       <RUN alias="Run_Sample001_16S" experiment_ref="Exp_Sample001_16S">
#         <DATA_BLOCK>
#           <FILES>
#             <FILE filename="Sample001_16S_R1.fastq.gz" filetype="fastq" checksum_method="MD5" checksum="c032..."/>
#             <FILE filename="Sample001_16S_R2.fastq.gz" filetype="fastq" checksum_method="MD5" checksum="d841..."/>
#           </FILES>
#         </DATA_BLOCK>
#       </RUN>
#     </AddData>
#   </Action>
# </Submission>



# DataType: generic-data, sra-run-fastq, sra-run-bam, and sra-run-cram


