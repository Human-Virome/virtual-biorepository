
api_validate_file <- function (db, file) { ingest_file(db, file, commit = FALSE) }
api_commit_file   <- function (db, file) { ingest_file(db, file, commit = TRUE)  }


ingest_file <- function (db, file, commit) {
  
  tryCatch(
    expr = {
      DBI::dbBegin(db)
      
      is_xls <- isTRUE(nzchar(readxl::excel_format(file)))
      
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
  expected_sheets <- names(DICT)
  
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
    if      (hasName(env$df, 'host_taxon'))                                      { 'participants'        }
    else if (any(hasName(env$df, c('age', 'age_range'))))                        { 'events'              }
    else if (hasName(env$df, 'collection_protocol_uid'))                         { 'samples'             }
    else if (hasName(env$df, 'assay_protocol_uid'))                              { 'profiles'            }
    else if (hasName(env$df, 'analysis_protocol_uid'))                           { 'analyses'            }
    else if (any(hasName(env$df, c('input_profile_uid', 'input_analysis_uid')))) { 'analysis_inputs'     }
    else if (hasName(env$df, 'filename'))                                        { 'files'               }
    else if (hasName(env$df, 'application'))                                     { 'protocols'           }
    else if (all(hasName(env$df, c('cohort_uid','participant_uid'))))            { 'cohort_participants' }
    else if (all(names(env$df) %in% c('cohort_uid', 'title')))                   { 'cohorts'             }
    else if (hasName(env$df, 'experimental_sample'))                             { 'sample_controls'     }
    else if (hasName(env$df, 'experimental_profile'))                            { 'profile_controls'    }
    else if (hasName(env$df, 'composite_sample'))                                { 'composite_samples'   }
    else { stop('Required headers are missing.') }
  }
  
  ingest_table(env)
  
  invisible()
}



ingest_table <- function (env) {
  
  n_rows <- nrow(env$df)
  if (n_rows == 0) return (invisible())
  
  validate_table(env)
  
  switch(
    EXPR = env$tbl,
    'participants' = participants_before_insert(env),
    'events'       = events_before_insert(env),
    'samples'      = samples_before_insert(env),
    'profiles'     = profiles_before_insert(env) )
  
  db_insert(env$db, env$tbl, env$df, 'InTbl1')
  
  switch(
    EXPR = env$tbl,
    'participants' = participants_after_insert(env),
    'samples'      = samples_after_insert(env),
    'profiles'     = profiles_after_insert(env),
    'files'        = files_after_insert(env) )
  
  invisible()
}



