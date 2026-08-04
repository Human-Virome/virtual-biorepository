
participants_before_insert <- function (env) {

  # Convert `animal_model` to `host_taxon`
  env$df[['host_taxon']] <- ifelse(
    test = is.na(env$df[['animal_model']]), 
    yes  = "NCBI:txid9606",                 # Default to Human
    no   = env$df[['animal_model']] )

  env$sql_ignored_fields <- c('animal_model', 'cohort_uids')
}


participants_after_insert <- function (env) {

  df <- env$df

  if (any(!is.na(df[['cohort_uids']]))) {

    cohort_sets      <- strsplit(df[['cohort_uids']], ';')
    cohort_uids      <- trimws(unlist(cohort_sets))
    participant_uids <- rep(df[['participant_uid']], sapply(cohort_sets, length))

    is_na            <- is.na(cohort_uids) | !nzchar(cohort_uids)
    cohort_uids      <- cohort_uids[!is_na]
    participant_uids <- participant_uids[!is_na]

    df <- data.frame(cohort_uid = unique(cohort_uids))
    db_insert(env$db, 'cohorts', df, 'PaAfIn1', ignore = TRUE)

    df <- data.frame(cohort_uid = cohort_uids, participant_uid = participant_uids)
    db_insert(env$db, 'cohort_participants', df, 'PaAfIn2')

  }

}

