

subjects_import_wb <- function (db, user, wb) {
  
  if (!is.null(df <- read_worksheet(wb, 'subject'))) {
    
    df$subject_id <- lookup_subject_ids(db, df)
    
    assert_df_names(wb, 'subject',
      c('subject_name', 'subject_source', 'subject_source_id', 'alt_subject_id', 
        'subject_source_catalog_number', 'subject_type', 'species', 
        'grant_number', 'grant_name', 'project_short_name', 'cohort_id', 
        'access', 'subject_event_name', 'subject_comments' ))
  }
  
  
  
  
  if (!is.null(df <- read_worksheet(wb, 'subject_attributes'))) {
    df$subject_ids <- lookup_subject_ids(db, df)
  }
  
  if (!'subject_attributes' %in% sheet_names) return (NULL)
  df <- openxlsx2::wb_to_df(wb, 'subject_attributes', skip_empty_rows = TRUE, skip_empty_cols = TRUE)
  assert_worksheet_headers(wb, 'subject_attributes',
    c('subject_name', 'attribute_name', 'attribute_value', 'unit', 
    'metadata_access', 'event_name', 'event_type', 'event_date', 'event_info' ))
  
  invisible()
}


subjects_export_wb <- function (db, user, wb) {
  
  invisible()
}


lookup_subject_ids <- function (db, df) {
  assert_req_columns(df, 'subject', c('subject_name', 'project_short_name'))
  
  sql <- 'SELECT subject_id, subject_name, project_short_name FROM subjects'
  tbl <- db_query(db, sql, 'LSId1')
}

