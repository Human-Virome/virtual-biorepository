
sra_refresh <- function (env) {
  
  sql <- "
    SELECT
      
      profiles.profile_uid           as profile_uid,
      profiles.bioproject_id         as BioProject,
      profiles.sample_uid            as sample_name,
      profiles.assay_platform        as instrument_model,
      profiles.library_prep_uid      as library_name,
      profiles.user                  as user,

      protocols.sequencing_strategy  as library_strategy,
      protocols.sequencing_source    as library_source,
      protocols.sequencing_selection as library_selection,
      protocols.sequencing_layout    as library_layout,
      protocols.url                  as library_construction_protocol,

      biosamples.biosample_accession as BioSample,
      files.filename                 as file_path,
      files.file_format              as file_format
      
    FROM profiles
      LEFT JOIN sra        USING (profile_uid)
      LEFT JOIN files      USING (profile_uid)
      LEFT JOIN biosamples ON biosamples.sample_name = profiles.sample_uid
      
    WHERE sra.file_path IS NULL
      AND files.data_type = 'scrubbed_sequence_reads'
      AND files.user = @user"
  
  sra <- db_query(env$db, sql, 'SraRefr1', simplify = FALSE)
  
  if (nrow(sra) == 0) return (invisible())
  
  sra <- plyr::ddply(sra, setdiff(names(sra), 'file_path'), function (x) {
    data.frame(file_path = jsonlite::toJSON(x[['file_path']]))
  })


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


