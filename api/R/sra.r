
sra_refresh <- function (db) {
  
  sql <- "
    SELECT
      
      file.file_uniq_name                   as file_path,
      file.file_format                      as file_format,
      
      biosamples.biosample_accession        as BioSample,
      
      libraries.bioproject_id               as BioProject,
      libraries.sample_uid                  as sample_name,
      libraries.library_uid                 as library_name,
      libraries.library_processing_url      as library_construction_protocol,
      libraries.technique                   as technique,
      NULL                                  as library_strategy,
      NULL                                  as library_source,
      NULL                                  as library_selection,
      libraries.paired_or_single            as library_layout,
      libraries.sequencing_instrument_model as instrument_model,
      libraries.user                        as user
      
    FROM files
      LEFT JOIN sra        ON file.file_uniq_name = sra.file_path
      LEFT JOIN libraries  USING (library_uid)
      LEFT JOIN biosamples ON libraries.sample_uid =libraries.sample_uid
      
    WHERE sra.file_path IS NULL
      AND file.data_type = 'scrubbed_sequence_reads'
      AND file.user = @user"
  
  sra <- db_query(db, sql, 'SraRefr1', simplify = FALSE)
  
  if (nrow(sra) == 0) return (invisible())
  
  
  # WGS:           Whole Genome Sequencing
  # RNA-Seq:       Direct sequencing of RNA transcriptomes
  # AMPLICON:      Sequencing of targeted PCR amplicons (e.g., 16S rRNA)
  # Bisulfite-Seq: Bisulfite Sequencing for methylation profiling
  
  sra[['library_strategy']] <- with(
    data = sra, 
    expr = data.table::fcase(
      technique == 'OBI:0002768', "WGS",           # whole virome sequencing assay
      technique == 'OBI:0000748', "Bisulfite-Seq", # bisulfite sequencing assay
      technique == 'OBI:0002117', "WGS"            # whole genome sequencing assay
    ))
  
  
  # METAGENOMIC:        Extracted directly from an environmental sample (mixed microbial community) without culturing.
  # METATRANSCRIPTOMIC: RNA extracted directly from an environmental sample.
  
  sra[['library_source']] <- with(
    data = sra, 
    expr = data.table::fcase(
      technique == 'OBI:0002768', "METAGENOMIC", # whole virome sequencing assay
      technique == 'OBI:0000748', "METAGENOMIC", # bisulfite sequencing assay
      technique == 'OBI:0002117', "METAGENOMIC"  # whole genome sequencing assay
    ))
  
  
  # RANDOM:     Sheared or mechanically fragmented DNA (e.g., standard whole-genome shotgun).
  # PCR:        Amplified library (typically using primers).
  # RANDOM PCR: Randomly sheared DNA followed by PCR amplification.
  # RT-PCR:     Reverse transcriptase PCR (commonly for cDNA).
  # MF:         Methyl-filtered.
  # ChIP:       Chromatin immunoprecipitation.
  # ChIP-seq:   Direct sequencing of ChIP products.
  # MBD:        Methyl-CpG binding domain.
  # MeDIP:      Methylated DNA immunoprecipitation.
  
  sra[['library_selection']] <- with(
    data = sra, 
    expr = data.table::fcase(
      technique == 'OBI:0002768', "RANDOM", # whole virome sequencing assay
      technique == 'OBI:0000748', "RANDOM", # bisulfite sequencing assay
      technique == 'OBI:0002117', "RANDOM"  # whole genome sequencing assay
    ))
  
  
  errors <- c()
  
  for (f in c('library_strategy', 'library_source', 'library_selection')) {
    unmapped <- is.na(sra[[f]])
    if (any(unmapped)) {
      bad_rows <- head(which(unmapped))
      msg <- "%s:%d: no `%s` mapping for `technique` \"%s\"."
      msg <- sprintf(msg, env$tbl, bad_rows + 1, f, df[['technique']][bad_rows])
      errors <- c(errors, msg)
    }
  }
  
  
  if (length(errors))
    stop(paste(errors, collapse = "\n"))
  
  sra[['technique']] <- NULL
  
  db_append(db, 'sra', sra, 'ApiSra2')
  
  invisible()
}


# DataType: generic-data, sra-run-fastq, sra-run-bam, and sra-run-cram


