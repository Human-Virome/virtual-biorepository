
samples_before_insert <- function (env) {
  env$sql_ignored_fields <- c('control_sample_uids',	'composite_parent_uids')
}


samples_after_insert <- function (env) {

  df <- env$df

  if (any(!is.na(df[['control_sample_uids']]))) {

    control_sets <- strsplit(df[['control_sample_uids']], ';')
    control_uids <- trimws(unlist(control_sets))
    sample_uids  <- rep(df[['sample_uid']], sapply(control_sets, length))

    is_na        <- is.na(control_uids) | !nzchar(control_uids)
    control_uids <- control_uids[!is_na]
    sample_uids  <- sample_uids[!is_na]

    df <- data.frame(experimental_sample_uid = sample_uids, control_sample_uid = control_uids)
    db_insert(env$db, 'control_samples', df, 'SaAfIn1')

  }

  if (any(!is.na(df[['composite_parent_uids']]))) {

    composite_sets <- strsplit(df[['composite_parent_uids']], ';')
    composite_uids <- trimws(unlist(composite_sets))
    sample_uids    <- rep(df[['sample_uid']], sapply(composite_sets, length))

    is_na          <- is.na(composite_uids) | !nzchar(composite_uids)
    composite_uids <- composite_uids[!is_na]
    sample_uids    <- sample_uids[!is_na]

    df <- data.frame(composite_sample_uid = composite_uids, component_sample_uid = sample_uids)
    db_insert(env$db, 'composite_samples', df, 'SaAfIn2')

  }


  biosamples_refresh(env)

}

