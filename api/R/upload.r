
api_metadata_upload <- function (db, file, save) {
  
  # Data is a csv, tsv, etc
  if (is.null(readxl::excel_format(file))) {
    
    data <- data.table::fread(
      file             = file,
      header           = TRUE,
      na.strings       = "",
      colClasses       = "character",
      strip.white      = TRUE,
      blank.lines.skip = TRUE,
      data.table       = FALSE )
    
    if      (hasName(data, 'age_units'))            { ws <- 'participants' }
    else if (hasName(data, 'sampling_protocol'))    { ws <- 'samples'      }
    else if (hasName(data, 'library_type'))         { ws <- 'libraries'    }
    else if (hasName(data, 'file_format'))          { ws <- 'files'        }
    else if (hasName(data, 'analysis_description')) { ws <- 'analyses'     }
    else    { stop('Required headers are missing.') }
    
    tryCatch(
      error = function (e) {
        db_query(db, 'ROLLBACK')
        stop(e$message)
      },
      expr  = {
        db_query(db, 'START TRANSACTION')
        do.call(paste0('import_', ws), list(db, data))
        db_query(db, ifelse(identical(save, "true"), 'COMMIT', 'ROLLBACK'))
      })
  }
  
  # Data is an Excel file (xls or xlsx)
  else {
    
    excel_sheets <- setdiff(readxl::excel_sheets(file), 'cv')
    valid_sheets <- c('participants', 'samples', 'libraries', 'files', 'analyses')
    
    if (length(invalid_sheets <- setdiff(excel_sheets, valid_sheets)))
      stop('Unrecognized Excel worksheet(s): ', paste(collapse = ", ", invalid_sheets))
    
    tryCatch(
      error = function (e) {
        db_query(db, 'ROLLBACK')
        stop(e$message)
      },
      expr  = {
        db_query(db, 'START TRANSACTION')
        
        for (ws in excel_sheets) {
          
          data <- readxl::read_excel(
            path         = file,
            sheet        = ws,
            col_types    = "text",
            .name_repair = "minimal" )
          
          do.call(paste0('import_', ws), list(db, data))
        }
        
        db_query(db, ifelse(identical(save, "true"), 'COMMIT', 'ROLLBACK'))
      })
  }
  
  list()
}
