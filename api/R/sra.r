
sra_refresh <- function (env) {
  
  sql <- "
    SELECT
      
      files.file_uid                  as file_path,
      files.file_format                     as file_format,
      
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
      LEFT JOIN sra        ON files.file_uid = sra.file_path
      LEFT JOIN libraries  USING (library_uid)
      LEFT JOIN biosamples ON biosamples.sample_name =libraries.sample_uid
      
    WHERE sra.file_path IS NULL
      AND files.data_type = 'scrubbed_sequence_reads'
      AND files.user = @user"
  
  sra <- db_query(env$db, sql, 'SraRefr1', simplify = FALSE)
  
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
  
  db_insert(env$db, 'sra', sra, 'ApiSra2')
  
  invisible()
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


