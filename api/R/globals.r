
# Global functions
unbox   <- jsonlite::unbox
hasName <- utils::hasName

UID_PREFIXES <- c(
  "boston_", "broad_park_", "caltech_", "lbnl_", "mskcc_", "penn_", "pnnl_", 
  "stanford_", "suny_", "ucdavis_", "ucla_", "ucsf_", "uncch_", "utah_", 
  "v2c2_", "vast_", "wu_dantas_", "wu_wylie_", "yu_foxman_", "yu_gilbert_" )

MODE_SUFFIXES <- c(
  "oral", "topical", "injected", "intranasal", "inhalation", "sublingual", 
  "subdermal", "transdermal", "ophthalmic", "rectal", "vaginal" )

FREQ_SUFFIXES <- c("daily", "weekly", "occasionally", "prior_months", "prior_years")

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

