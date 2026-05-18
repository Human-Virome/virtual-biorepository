
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
    else if (hasName(df, 'age_units'))            { tbl <- 'events'       }
    else if (hasName(df, 'sampling_protocol'))    { tbl <- 'samples'      }
    else if (hasName(df, 'library_type'))         { tbl <- 'libraries'    }
    else if (hasName(df, 'file_format'))          { tbl <- 'files'        }
    else if (hasName(df, 'analysis_description')) { tbl <- 'analyses'     }
    else    { stop('Required headers are missing.') }
    
    if (nrow(df) == 0) stop('No data records were found in the uploaded file.')
    
    tryCatch(
      error = function (e) {
        db_query(db, 'ROLLBACK')
        stop(e$message)
      },
      expr  = {
        db_query(db, 'START TRANSACTION')
        ingest_table(db, df, tbl)
        db_query(db, ifelse(identical(save, "true"), 'COMMIT', 'ROLLBACK'))
      })
  }
  
  # Data is an Excel file (xls or xlsx)
  else {
    
    excel_sheets <- setdiff(readxl::excel_sheets(file), 'cv')
    valid_sheets <- c('participants', 'events', 'samples', 'libraries', 'analyses', 'files')
    
    if (length(invalid_sheets <- setdiff(excel_sheets, valid_sheets)))
      stop('Unrecognized Excel worksheet(s): ', paste(collapse = ", ", invalid_sheets))
    
    tryCatch(
      error = function (e) {
        db_query(db, 'ROLLBACK')
        stop(e$message)
      },
      expr  = {
        db_query(db, 'START TRANSACTION')
        
        total_rows <- 0
        
        # Control the order in which they're processed
        for (tbl in intersect(valid_sheets, excel_sheets)) {
          
          df <- readxl::read_excel(
            path         = file,
            sheet        = tbl,
            col_types    = "text",
            .name_repair = "minimal" )
          
          ingest_table(db, df, tbl)
          total_rows <- total_rows + nrow(df)
        }
        if (total_rows == 0) stop('No data records were found in the uploaded file.')
        
        db_query(db, ifelse(identical(save, "true"), 'COMMIT', 'ROLLBACK'))
      })
  }
  
  list()
}



ingest_table <- function (db, df, tbl) {
  
  n_rows <- nrow(df)
  if (n_rows == 0) return (invisible())
  
  env <- as.environment(df)
  attr(env, 'n_rows') <- n_rows
  
  validate_req_columns(env, tbl)
  reformat_ids(env, tbl)
  validate_prefixes(env, tbl)
  validate_suffixes(env, tbl)
  validate_cv(env, tbl)
  validate_numbers(env, tbl)
  validate_dates(env, tbl)
  validate_urls(env, tbl)
  validate_keys(db, env, tbl)
  validate_refs(db, env, tbl)
  validate_conditions(db, env, tbl)
  
  switch(
    EXPR = tbl,
    'events'       = condition_check_events(db, env, tbl),
    'samples'      = condition_check_samples(db, env, tbl),
    'libraries'    = condition_check_libraries(db, env, tbl),
    'files'        = condition_check_files(db, env, tbl) )
  
  df <- as.data.frame(as.list(env))
  
  df[['hvp_id']]      <- create_hvp_ids(db, tbl, n = n_rows)
  df[['oauth_email']] <- attr(db, 'oauth_email')
  
  DBI::dbWriteTable(db, tbl, df, append = TRUE)
  
  return (invisible())
}



create_hvp_ids <- function (db, tbl, n) {
  
  stopifnot(is.character(tbl), isTRUE(nzchar(tbl)))
  stopifnot(is.numeric(n), isTRUE(n %% 1 == 0))
  
  if (n < 1) return (character(0))
  
  prefix <- switch(
    EXPR = tbl,
    'participants' = "hvp:p-",
    'events'       = "hvp:e-",
    'samples'      = "hvp:s-",
    'libraries'    = "hvp:l-",
    'analyses'     = "hvp:a-",
    'files'        = "hvp:f-",
    stop('No table to prefix mapping for table ', tbl) )
  
  # Generate 5 extra IDs in case of collisions.
  new_ids <- stringi::stri_rand_strings(n + 5, 8)
  new_ids <- paste0(prefix, new_ids)
  
  # Avoid colliding with existing IDs.
  current <- db_query(db, sprintf('SELECT hvp_id FROM `%s`', tbl), 'CrHvId')
  new_ids <- setdiff(new_ids, current)[seq_len(n)]
  
  # Too many collisions (highly unlikely).
  stopifnot(!anyNA(new_ids))
  
  return (new_ids)
}



