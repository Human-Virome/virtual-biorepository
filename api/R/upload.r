
api_metadata_upload <- function (db, file, save) {
  
  # Data is a csv, tsv, etc
  if (is.null(readxl::excel_format(file))) {
    
    df <- data.table::fread(
      file             = file,
      header           = TRUE,
      na.strings       = "",
      colClasses       = "character",
      strip.white      = TRUE,
      blank.lines.skip = TRUE,
      data.table       = FALSE )
    
    if      (hasName(df, 'host_taxon'))           { tbl <- 'participants' }
    else if (hasName(df, 'age_units'))            { tbl <- 'events' }
    else if (hasName(df, 'sampling_protocol'))    { tbl <- 'samples'      }
    else if (hasName(df, 'library_type'))         { tbl <- 'libraries'    }
    else if (hasName(df, 'file_format'))          { tbl <- 'files'        }
    else if (hasName(df, 'analysis_description')) { tbl <- 'analyses'     }
    else    { stop('Required headers are missing.') }
    
    if (nrow(df) == 0) stop('No data records were found in the uploaded file.')
    
    env <- as.environment(precheck(df, tbl))
    
    tryCatch(
      error = function (e) {
        db_query(db, 'ROLLBACK')
        stop(e$message)
      },
      expr  = {
        db_query(db, 'START TRANSACTION')
        do.call(paste0('import_', tbl), list(db, env))
        db_query(db, ifelse(identical(save, "true"), 'COMMIT', 'ROLLBACK'))
      })
  }
  
  # Data is an Excel file (xls or xlsx)
  else {
    
    excel_sheets <- setdiff(readxl::excel_sheets(file), 'cv')
    valid_sheets <- c('participants', 'events', 'samples', 'libraries', 'files', 'analyses')
    
    if (length(invalid_sheets <- setdiff(excel_sheets, valid_sheets)))
      stop('Unrecognized Excel worksheet(s): ', paste(collapse = ", ", invalid_sheets))
    
    tryCatch(
      error = function (e) {
        db_query(db, 'ROLLBACK')
        stop(e$message)
      },
      expr  = {
        db_query(db, 'START TRANSACTION')
        
        recs <- 0
        for (tbl in excel_sheets) {
          
          df <- readxl::read_excel(
            path         = file,
            sheet        = tbl,
            col_types    = "text",
            .name_repair = "minimal" )
          
          if (nrow(df) == 0) next
          recs <- recs + nrow(df)
          
          env <- as.environment(precheck(df, tbl))
          do.call(paste0('import_', tbl), list(db, env))
        }
        if (recs == 0) stop('No data records were found in the uploaded file.')
        
        db_query(db, ifelse(identical(save, "true"), 'COMMIT', 'ROLLBACK'))
      })
  }
  
  list()
}


# Read the javascript definition of the data dictionaries.
DICT_ALL <- list()
DICT_REQ <- list()
DICT_FMT <- list()
DICT_SEP <- list()
DICT_OPT <- list()
local({
  fp <- '../html/app/dictionary.js'
  js <- readChar(con = fp, nchars = file.size(fp))
  js <- sub('const vbrDictionary = ', '', js)
  js <- sub('};', '}', js)
  js <- jsonlite::parse_json(js)
  for (dict in names(js)) {
    defs   <- js[[dict]]
    fields <- unname(sapply(defs, `[[`, 'field'))
    is_req <- sapply(defs, `[[`, 'req') == "yes"
    DICT_ALL[[dict]] <<- fields
    DICT_REQ[[dict]] <<- fields[is_req]
    DICT_FMT[[dict]] <<- unname(sapply(defs, `[[`, 'fmt'))
    DICT_FMT[[dict]] <<- unname(sapply(defs, `[[`, 'fmt'))
  }
  invisible()
})



# Simple validations performed the same for all tables.
precheck <- function (df, tbl) {
  
  
  # Combine duplicate columns.
  fields <- names(df)
  if (any(duplicated(fields))) {
    merged <- df[,!duplicated(fields),drop=FALSE]
    for (field in fields) {
      indices <- which(fields == field)
      if (length(indices) > 1) {
        cols <- as.list(df[,indices,drop=FALSE])
        merged[[field]] <- do.call(paste, c(cols, sep = '; '))
      }
    }
    df <- merged
  }
  
  
  # Check for missing or extra fields.
  fields  <- names(df)
  missing <- setdiff(DICT_REQ[[tbl]], fields)
  invalid <- setdiff(fields, DICT_ALL[[tbl]])
  if (length(missing) > 0) {
    msg <- '%s: Required columns are missing: %s'
    msg <- sprintf(msg, tbl, paste(collapse = ', ', missing))
    stop(msg)
  }
  if (length(invalid) > 0) {
    msg <- '%s: Unexpected columns are present: "%s"'
    msg <- sprintf(msg, tbl, paste(collapse = '", "', invalid))
    stop(msg)
  }
  
  
  # Ensure each required column is filled in.
  for (field in DICT_REQ[[tbl]]) {
    missing <- which(!nzchar(trimws(df[[field]]))) + 1
    if (length(missing) > 0) {
      msg <- '%s: required "%s" values are missing on row(s) %s'
      msg <- sprintf(msg, tbl, field, paste(collapse = '`, `', head(missing, 20)))
      stop(msg)
    }
  }
  
  return (df)
}


