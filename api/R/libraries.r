
libraries_before_insert <- function (env) {

  errors <- c()
  df     <- env$df

  is_control <- df[['is_control_library']] %in% "yes"

  # Control libraries need a control type.
  failing <- is_control & is.na(df[['library_pos_cont_type']]) & is.na(df[['library_neg_cont_type']])
  errors  <- c(errors, condition_error(env, 'library_pos_cont_type', failing))

  # Only experimental libraries link to their controls.
  if (length(i <- head(which(is_control & !is.na(df[['control_library_uid']]))))) {
    msg    <- "%s:%d: `control_library_uid` must be blank when `is_control_library` is \"yes\"."
    errors <- c(errors, sprintf(msg, env$tbl, i + 1))
  }

  # Sequencing fields are "Required for sequence data", so all-or-none.
  is_set <- !is.na(as.matrix(df[, SEQUENCING_FIELDS, drop = FALSE]))
  if (length(i <- head(which(rowSums(is_set) %in% seq_len(length(SEQUENCING_FIELDS) - 1))))) {
    missing <- apply(!is_set[i, , drop = FALSE], 1L, \(x) paste(SEQUENCING_FIELDS[x], collapse = "`, `"))
    msg     <- "%s:%d: Sequenced libraries must also provide `%s`."
    errors  <- c(errors, sprintf(msg, env$tbl, i + 1, missing))
  }

  # A library being updated can't drop them while it has sequence data files.
  uids <- old_value(env, 'library_uid')
  if (any(dropped <- rowSums(is_set) == 0 & !is.na(uids))) {
    sql    <- "SELECT DISTINCT library_uid FROM files WHERE data_type IN (%s)"
    sql    <- sprintf(sql, paste(rep("?", length(SEQUENCE_DATA_TYPES)), collapse = ", "))
    in_use <- db_query(env$db, sql, 'LiBfIn1', as.list(SEQUENCE_DATA_TYPES))
    if (length(i <- head(which(dropped & uids %in% in_use)))) {
      msg    <- "%s:%d: Library \"%s\" has sequence data files, so its sequencing details (`%s`) are required."
      errors <- c(errors, sprintf(msg, env$tbl, i + 1, uids[i], paste(SEQUENCING_FIELDS, collapse = "`, `")))
    }
  }


  if (length(errors))
    stop(paste(errors, collapse = "\n"))
  invisible()
}
