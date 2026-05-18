
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
    
    env <- as.environment(df)
    remove('df')
    
    tryCatch(
      error = function (e) {
        db_query(db, 'ROLLBACK')
        stop(e$message)
      },
      expr  = {
        db_query(db, 'START TRANSACTION')
        ingest_table(db, env, tbl)
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
        
        recs <- 0
        
        # Control the order in which they're processed
        for (tbl in intersect(valid_sheets, excel_sheets)) {
          
          df <- readxl::read_excel(
            path         = file,
            sheet        = tbl,
            col_types    = "text",
            .name_repair = "minimal" )
          
          if (nrow(df) == 0) next
          recs <- recs + nrow(df)
          
          env <- as.environment(df)
          remove('df')
          
          ingest_table(db, env, tbl)
        }
        if (recs == 0) stop('No data records were found in the uploaded file.')
        
        db_query(db, ifelse(identical(save, "true"), 'COMMIT', 'ROLLBACK'))
      })
  }
  
  list()
}



ingest_table <- function (db, env, tbl) {
  
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
  
  insert_rows(db, env, tbl)
  
}




