
profiles_after_insert <- function (env) {

  df <- env$df

  if (any(!is.na(df[['control_profile_uids']]))) {

    control_sets <- strsplit(df[['control_profile_uids']], ';')
    control_uids <- trimws(unlist(control_sets))
    profile_uids <- rep(df[['profile_uid']], sapply(control_sets, length))

    is_na        <- is.na(control_uids) | !nzchar(control_uids)
    control_uids <- control_uids[!is_na]
    profile_uids <- profile_uids[!is_na]

    df <- data.frame(experimental_profile_uid = profile_uids, control_profile_uid = control_uids)
    db_insert(env$db, 'control_profiles', df, 'PrAfIn1')

  }

}

