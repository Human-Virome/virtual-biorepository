
api_validate_file <- function (db, file) { ingest_file(db, file, commit = FALSE) }
api_commit_file   <- function (db, file) { ingest_file(db, file, commit = TRUE)  }


ingest_file <- function (db, file, commit) {
  
  tryCatch(
    expr = {
      DBI::dbBegin(db)
      
      is_xls <- !is.null(readxl::excel_format(file))
      
      if (is_xls) { ingest_excel_file(db, file) }
      else        { ingest_delim_file(db, file) }
      
      if (commit) { DBI::dbCommit(db)   }
      else        { DBI::dbRollback(db) }
    },
    error = function (e) {
      DBI::dbRollback(db)
      #stop(e$message)
      stop(as.character(e))
    })
  
  # No errors to report
  return (list())
}


# Data is an Excel file (xls or xlsx)
ingest_excel_file <- function (db, file) {
  
  received_sheets <- setdiff(readxl::excel_sheets(file), 'cv')
  expected_sheets <- c('participants', 'events', 'samples', 'libraries', 'analyses', 'files')
  
  valid_sheets   <- intersect(expected_sheets, received_sheets)
  invalid_sheets <- setdiff(received_sheets, expected_sheets)
  
  if (length(invalid_sheets) > 0)
    stop('Unrecognized Excel worksheet(s): ', paste(collapse = ", ", invalid_sheets))
  
  env <- list2env(list(db = db))
  found_records <- FALSE
  
  for (tbl in valid_sheets) {
    
    env$tbl <- tbl
    env$df  <- readxl::read_excel(
      path         = file,
      sheet        = tbl,
      col_types    = "text",
      .name_repair = "minimal" )
    
    if (nrow(env$df) == 0) next
    found_records <- TRUE
    
    ingest_table(env)
  }
  
  if (!found_records)
    stop('No data records were found in the uploaded file.')
  
  invisible()
}


# Uploaded file is a csv, tsv, etc
ingest_delim_file <- function (db, file) {
  
  env <- list2env(list(db = db))
  
  env$df <- data.table::fread(
    file             = file,
    header           = TRUE,
    na.strings       = "",
    colClasses       = "character",
    strip.white      = TRUE,
    blank.lines.skip = TRUE,
    data.table       = FALSE )
  
  if (nrow(env$df) == 0)
    stop('No data records were found in the uploaded file.')
  
  env$tbl <- {
    if      (hasName(env$df, 'host_taxon'))               { 'participants' }
    else if (any(hasName(env$df, c('age', 'age_range')))) { 'events'       }
    else if (hasName(env$df, 'sample_type'))              { 'samples'      }
    else if (hasName(env$df, 'library_type'))             { 'libraries'    }
    else if (hasName(env$df, 'analysis_description'))     { 'analyses'     }
    else if (hasName(env$df, 'file_format'))              { 'files'        }
    else { stop('Required headers are missing.') }
  }
  
  ingest_table(env)
  
  invisible()
}



ingest_table <- function (env) {
  
  n_rows <- nrow(env$df)
  if (n_rows == 0) return (invisible())
  
  validate_req_columns(env)
  reformat_ids(env)
  validate_suffixes(env)
  validate_cv(env)
  validate_numbers(env)
  validate_dates(env)
  validate_urls(env)
  validate_md5(env)
  validate_keys(env)
  validate_refs(env)
  validate_file_names(env)
  validate_bioproject_ids(env)
  
  switch(
    EXPR = env$tbl,
    'events'    = condition_check_events(env),
    'samples'   = condition_check_samples(env),
    'libraries' = condition_check_libraries(env),
    'files'     = condition_check_files(env) )
  
  switch(
    EXPR = env$tbl,
    'events'    = derive_cols_events(env),
    'libraries' = derive_cols_libraries(env) )
  
  env$df[['hvp_id']] <- create_hvp_ids(env)
  env$df[['user']]   <- attr(env$db, 'user')
  
  db_append(env$db, env$tbl, env$df, 'InTbl1')
  
  switch(
    EXPR = env$tbl,
    'samples' = biosamples_refresh(env$db),
    'files'   = sra_refresh(env$db) )
  
  invisible()
}



