
api_validate_file <- function (db, file) { ingest_file(db, file, commit = FALSE) }
api_commit_file   <- function (db, file) { ingest_file(db, file, commit = TRUE)  }


ingest_file <- function (db, file, commit) {
  
  env <- list2env(list(db = db, deletes = list(), changes = list()))
  
  tryCatch(
    expr = {
      DBI::dbBegin(db)
      
      is_xls <- !is.na(readxl::excel_format(file))
      
      if (is_xls) { ingest_excel_file(env, file) }
      else        { ingest_delim_file(env, file) }
      
      delete_records(env)
      
      if (commit) { DBI::dbCommit(db)   }
      else        { DBI::dbRollback(db) }
    },
    error = function (e) {
      DBI::dbRollback(db)
      stop(e$message)
      #stop(as.character(e))
    })
  
  # No errors to report. Tell the user what the file adds, updates, and deletes.
  changes <- do.call(rbind, env$changes)
  return (list(changes = data.frame(table = rownames(changes), changes, row.names = NULL)))
}


# Data is an Excel file (xls or xlsx)
ingest_excel_file <- function (env, file) {
  
  received_sheets <- setdiff(readxl::excel_sheets(file), 'cv')
  expected_sheets <- names(DICT)
  
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
ingest_delim_file <- function (env, file) {
  
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
    if      (hasName(env$df, 'taxon'))                    { 'participants'                 }
    else if (any(hasName(env$df, c('age', 'age_range')))) { 'participant_event_attributes' }
    else if (hasName(env$df, 'sample_type'))              { 'samples'                      }
    else if (hasName(env$df, 'library_prep_lab'))         { 'libraries'                    }
    else if (hasName(env$df, 'analysis_description'))     { 'analyses'                     }
    else if (hasName(env$df, 'md5_checksum'))             { 'files'                        }
    else if (hasName(env$df, 'hvp_id'))                   { hvp_id_table(env$df[['hvp_id']]) }
    else { stop('Required headers are missing.') }
  }
  
  ingest_table(env)
  
  invisible()
}



# The table that `hvp_id`s belong to, going by their prefix. For files with
# no other headers, i.e. that only list records to delete.
hvp_id_table <- function (hvp_ids) {
  
  prefix <- substr(tolower(trimws(hvp_ids[!is.na(hvp_ids)][1])), 1, 4)
  tbl    <- names(HVP_PREFIXES)[match(prefix, HVP_PREFIXES)]
  
  if (!tbl %in% names(DICT))
    stop('Required headers are missing.')
  
  return (tbl)
}



ingest_table <- function (env) {
  
  n_rows <- nrow(env$df)
  if (n_rows == 0) return (invisible())
  
  # Rows with an `hvp_id` update an existing record, or delete it.
  hvp_ids_before_validate(env)
  
  is_new  <- is.na(env$hvp_id)
  changed <- integer(0)
  
  if (nrow(env$df) > 0) tryCatch(
    error = function (e) stop(relabel_rows(env, e$message)),
    expr  = {
      
      validate_table(env)
      
      # Derived fields and checks too complex for the dictionary.
      switch(
        EXPR = env$tbl,
        'participant_event_attributes' = events_before_insert(env),
        'samples'                      = samples_before_insert(env),
        'libraries'                    = libraries_before_insert(env),
        'files'                        = files_before_insert(env) )
      
      # Records derived from the updated ones are brought in line with them,
      # as is the SRA record of a library that gets more files.
      changed <- changed_rows(env)
      derived <- length(changed) > 0 || (env$tbl == 'files' && any(is_new))
      if (derived)
        before <- derived_snapshot(env$db)
      
      if (any(is_new))
        db_insert(env$db, env$tbl, env$df[is_new, , drop = FALSE], 'InTbl1')
      
      if (length(changed) > 0)
        update_records(env, changed)
      
      if (derived)
        derived_sync(env, before)
      
      switch(
        EXPR = env$tbl,
        'samples'      = samples_after_insert(env),
        'files'        = files_after_insert(env) )
    })
  
  env$changes[[env$tbl]] <- c(
    added   = sum(is_new),
    updated = length(changed),
    deleted = NROW(env$deletes[[env$tbl]]) )
  
  invisible()
}



