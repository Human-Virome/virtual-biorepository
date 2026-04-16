

participants_import_wb <- function (db, user, wb) {
  
  tryCatch(
    error = function (e) {
      msg <- 'Unable to process the `%s` worksheet.\n%s'
      stop(sprintf(msg, 'participants', e$message))
    },
    expr = {
      
      df <- read_worksheet(wb, 'participants')
      if (is.null(df)) return (NULL)
      
      assert_colnames(
        present  = colnames(df),
        required = c(
          'participant_uid', 'cohort_id', 'host_taxon', 'race', 'ethnicity', 
          'sex_at_birth', 'country_of_birth', 'country_of_childhood_residence' ),
        optional = c(
          'gestational_age_at_birth', 'mode_of_birth_delivery', 'blood_type', 
          'family_medical_history' ))
      
      assert_ids_do_not_exist(db, 'participants', 'participant_uid', df$participant_uid)
      
      
  })
  
  invisible()
}


participants_export_wb <- function (db, user, wb) {
  
  invisible()
}

