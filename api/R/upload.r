
api_metadata_upload <- function (auth_token, md_file_input, save) {
  
  stopifnot(isTRUE(save) || isFALSE(save))
  
  db <- db_connect()
  on.exit(db_close(db))
  
  user <- authenticate(db, auth_token)
  
  tryCatch(
    error = function (e) {
      db_query('ROLLBACK')
      list(issues = e$message)
    },
    expr  = {
      wb <- openxlsx2::wb_load(md_file_input$tmp_name)
      
      db_query('START TRANSACTION')
      
      projects_import_wb(db, user, wb)
      cohorts_import_wb(db, user, wb)
      subjects_import_wb(db, user, wb)
      samples_import_wb(db, user, wb)
      libraries_import_wb(db, user, wb)
      files_import_wb(db, user, wb)
      analyses_import_wb(db, user, wb)
      
      db_query(ifelse(save, 'COMMIT', 'ROLLBACK'))
      
      list()
    })
}
