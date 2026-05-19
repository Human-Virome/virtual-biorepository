
api_validate_file <- function (db, file) { ingest_file(db, file, commit = FALSE) }
api_commit_file   <- function (db, file) { ingest_file(db, file, commit = TRUE)  }


ingest_file <- function (db, file, commit) {
  
  tryCatch(
    expr = {
      db_query(db, 'START TRANSACTION', 'InFile1')
      
      is_xls <- !is.null(readxl::excel_format(file))
      
      if (is_xls) { ingest_excel_file(db, file) }
      else        { ingest_delim_file(db, file) }
      
      if (commit) { db_query(db, 'COMMIT',   'InFile2') }
      else        { db_query(db, 'ROLLBACK', 'InFile3') }
    },
    error = function (e) {
      db_query(db, 'ROLLBACK', 'InFile4')
      stop(e$message)
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
  validate_keys(env)
  validate_refs(env)
  
  switch(
    EXPR = tbl,
    'events'    = condition_check_events(env),
    'samples'   = condition_check_samples(env),
    'libraries' = condition_check_libraries(env),
    'files'     = condition_check_files(env) )
  
  env$df[['hvp_id']]      <- create_hvp_ids(env)
  env$df[['oauth_email']] <- attr(env$db, 'oauth_email')
  
  DBI::dbWriteTable(
    conn   = env$db, 
    name   = env$tbl, 
    value  = env$df, 
    append = TRUE )
  
  invisible()
}



create_hvp_ids <- function (env) {
  
  prefix <- switch(
    EXPR = env$tbl,
    'participants' = "hvp:p-",
    'events'       = "hvp:e-",
    'samples'      = "hvp:s-",
    'libraries'    = "hvp:l-",
    'analyses'     = "hvp:a-",
    'files'        = "hvp:f-",
    stop('bad table name') )
  
  # Generate 5 extra IDs in case of collisions.
  n <- nrow(env$df)
  new_ids <- stringi::stri_rand_strings(n + 5, 8)
  new_ids <- paste0(prefix, new_ids)
  
  # Avoid colliding with existing IDs.
  current <- db_query(env$db, sprintf('SELECT hvp_id FROM `%s`', env$tbl), 'CrHvId')
  new_ids <- setdiff(new_ids, current)[seq_len(n)]
  
  # Too many collisions (highly unlikely).
  stopifnot(!anyNA(new_ids))
  
  return (new_ids)
}



