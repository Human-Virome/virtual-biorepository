
# Global functions
unbox   <- jsonlite::unbox
hasName <- utils::hasName

UID_PREFIXES <- c(
  "boston_", "broad_park_", "caltech_", "cmmr_", "lbnl_", "mskcc_", "penn_", 
  "pnnl_", "stanford_", "suny_", "ucdavis_", "ucla_", "ucsf_", "uncch_", "utah_", 
  "v2c2_", "vast_", "wu_dantas_", "wu_wylie_", "yu_foxman_", "yu_gilbert_" )

MODE_SUFFIXES <- c(
  "oral", "topical", "injected", "intranasal", "inhalation", "sublingual", 
  "subdermal", "transdermal", "ophthalmic", "rectal", "vaginal" )

FREQ_SUFFIXES <- c("daily", "weekly", "occasionally", "prior_months", "prior_years")

#  `files.data_type` terms requiring sequencing/SRA metadata, vs. those that
#  are secondary files produced by an analysis.
SEQUENCE_DATA_TYPES <- c("scrubbed_sequence_reads", "unscrubbed_sequence_reads")
DERIVED_DATA_TYPES  <- c("alignment", "counts", "assembly", "analysis_metrics")

# SRA `filetype`s for the `files.file_format` EDAM terms that SRA accepts.
SRA_FILETYPES <- c(
  "EDAM:format_1930" = "fastq", "EDAM:format_1931" = "fastq",
  "EDAM:format_1932" = "fastq", "EDAM:format_1933" = "fastq",
  "EDAM:format_2572" = "bam",   "EDAM:format_3462" = "cram",
  "EDAM:format_3284" = "sff" )

# `libraries` fields that are "Required for sequence data."
SEQUENCING_FIELDS <- c(
  "library_strategy", "library_source", "library_selection",
  "paired_or_single", "sequencing_platform", "sequencing_instrument_model" )

UID_REGEX  <- paste0(   "(", paste0(UID_PREFIXES,  collapse = "|"), ")")
MODE_REGEX <- paste0("\\:(", paste0(MODE_SUFFIXES, collapse = "|"), ")")
FREQ_REGEX <- paste0("\\:(", paste0(FREQ_SUFFIXES, collapse = "|"), ")")

# Read the javascript definition of the data dictionaries.
DICT <- local({
  
  fp <- '../html/app/dictionary.js'
  if (!file.exists(fp)) fp <- 'html/app/dictionary.js'
  
  js <- readChar(con = fp, nchars = file.size(fp))
  js <- sub('const vbrDictionary = ', '', js)
  js <- sub('};', '}', js)
  
  dict <- jsonlite::parse_json(js)
  
  for (tbl in names(dict)) {
    for (field in names(dict[[tbl]])) {
      dict[[tbl]][[field]][['def']]      <- NULL
      dict[[tbl]][[field]][['urls']]     <- NULL
      dict[[tbl]][[field]][['examples']] <- NULL
    }
  }
  
  return (dict)
})

