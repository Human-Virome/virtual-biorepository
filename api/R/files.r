
files_before_insert <- function (env) {

  errors <- c()
  df     <- env$df

  # Conditions whose description depends on the kind of file (`data_type`).
  required_for <- function (field, data_types) {
    failing <- df[['data_type']] %in% data_types & is.na(df[[field]])
    if (!length(i <- head(which(failing)))) return (NULL)
    msg <- "%s:%s:%d: `%s` is required when `data_type` is \"%s\"."
    sprintf(msg, env$tbl, field, i + 1, field, df[['data_type']][i])
  }

  errors <- c(errors,
    required_for('library_uid',       SEQUENCE_DATA_TYPES),
    required_for('bioproject_id',     SEQUENCE_DATA_TYPES),
    required_for('file_derived_from', DERIVED_DATA_TYPES),
    required_for('analysis_uid',      DERIVED_DATA_TYPES) )

  # Sequence data needs the library's sequencing details for SRA.
  is_seq <- df[['data_type']] %in% SEQUENCE_DATA_TYPES & !is.na(df[['library_uid']])
  if (any(is_seq)) {
    uids <- unique(df[['library_uid']][is_seq])
    sql  <- "SELECT library_uid, %s FROM libraries WHERE library_uid IN (%s)"
    sql  <- sprintf(sql, paste0("`", SEQUENCING_FIELDS, "`", collapse = ", "), paste(rep("?", length(uids)), collapse = ", "))
    libs <- db_query(env$db, sql, 'FiBfIn1', as.list(uids), simplify = FALSE)

    incomplete <- libs[['library_uid']][rowSums(is.na(libs[, SEQUENCING_FIELDS, drop = FALSE])) > 0]
    if (length(i <- head(which(is_seq & df[['library_uid']] %in% incomplete)))) {
      msg    <- "%s:%d: Library \"%s\" is missing sequencing details (`%s`) required for sequence data."
      errors <- c(errors, sprintf(msg, env$tbl, i + 1, df[['library_uid']][i], paste(SEQUENCING_FIELDS, collapse = "`, `")))
    }
  }


  if (length(errors))
    stop(paste(errors, collapse = "\n"))
  invisible()
}


files_after_insert <- function (env) {
  sra_refresh(env)
}
