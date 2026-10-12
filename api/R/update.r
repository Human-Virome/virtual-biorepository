
# Uploaded rows with an `hvp_id` change an existing record instead of adding
# a new one. The row's values replace all of the record's values, or the
# record is deleted when the rest of the row is blank.


# Checks that each `hvp_id` is a record of the logged-in user. Sets rows to
# delete aside in `env$deletes`, leaving `env$df` with the rows to add or
# update, `env$hvp_id` and `env$old` with the `hvp_id` and stored record of
# each (NA for new records), and `env$row` with their spreadsheet rows.
hvp_ids_before_validate <- function (env) {

  errors <- c()
  df     <- env$df

  hvp_id <- rep(NA_character_, nrow(df))
  if (hasName(df, 'hvp_id')) {
    hvp_id <- tolower(trimws(df[['hvp_id']]))
    hvp_id[!nzchar(hvp_id)] <- NA
    df <- df[, names(df) != 'hvp_id', drop = FALSE]
  }

  sql    <- sprintf("SELECT * FROM `%s` WHERE `user` = @user", env$tbl)
  stored <- db_query(env$db, sql, 'HvpIds1', simplify = FALSE)
  i      <- match(hvp_id, stored[['hvp_id']])

  if (length(j <- head(which(!is.na(hvp_id) & is.na(i))))) {
    msg    <- "%s:hvp_id:%d: \"%s\" does not match any of your %s records."
    errors <- c(errors, sprintf(msg, env$tbl, j + 1, hvp_id[j], env$tbl))
  }

  if (length(j <- head(which(duplicated(hvp_id) & !is.na(hvp_id))))) {
    msg    <- "%s:hvp_id:%d: \"%s\" is listed more than once."
    errors <- c(errors, sprintf(msg, env$tbl, j + 1, hvp_id[j]))
  }

  # Other users' samples rely on the "mock" participant.
  if (env$tbl == 'participants') {
    if (length(j <- head(which(stored[['participant_uid']][i] == 'mock')))) {
      msg    <- "%s:hvp_id:%d: The \"mock\" participant cannot be changed or deleted."
      errors <- c(errors, sprintf(msg, env$tbl, j + 1))
    }
  }

  if (length(errors))
    stop(paste(errors, collapse = "\n"))

  cells     <- as.matrix(df)
  is_blank  <- rowSums(!is.na(cells) & nzchar(trimws(cells))) == 0
  is_delete <- !is.na(hvp_id) & is_blank

  if (any(is_delete))
    env$deletes[[env$tbl]] <- cbind(row = which(is_delete) + 1L, stored[i[is_delete], , drop = FALSE])

  env$df     <- df[!is_delete, , drop = FALSE]
  env$row    <- which(!is_delete) + 1L
  env$hvp_id <- hvp_id[!is_delete]
  env$old    <- stored[i[!is_delete], , drop = FALSE]

  invisible()
}


# The stored value of `field` for each row in `env$df`. NA for new records.
old_value <- function (env, field) {
  if (is.null(env$old)) return (rep(NA_character_, nrow(env$df)))
  env$old[[field]]
}


# TRUE for each row in `env$df` whose `field` is unchanged from what's stored.
is_stored <- function (env, field) {
  (env$df[[field]] == old_value(env, field)) %in% TRUE
}


# Validators number rows by their position in `env$df`, which no longer
# matches the spreadsheet once rows to delete are set aside. Corrects the
# row numbers in their error messages, e.g. "samples:sample_uid:12: ...".
relabel_rows <- function (env, msg) {

  if (identical(env$row, seq_along(env$row) + 1L)) return (msg)

  lines <- strsplit(msg, "\n", fixed = TRUE)[[1]]
  regex <- sprintf("^(%s:(?:[a-z0-9_]+:)?)([0-9]+)(: .*)$", env$tbl)
  parts <- stringi::stri_match_first_regex(lines, regex)
  i     <- as.integer(parts[, 3]) - 1L
  i[!i %in% seq_along(env$row)] <- NA

  j        <- which(!is.na(i))
  lines[j] <- paste0(parts[j, 2], env$row[i[j]], parts[j, 4])

  paste(lines, collapse = "\n")
}


# The rows in `env$df` that have an `hvp_id` and differ from what's stored.
# The rest are skipped, since every UPDATE adds a system-versioned history row.
# Only the dictionary's fields are compared; the others are derived from them.
changed_rows <- function (env) {

  is_changed <- rep(FALSE, nrow(env$df))

  for (field in intersect(names(DICT[[env$tbl]]), db_fields(env$db, env$tbl))) {
    new <- env$df[[field]]
    old <- env$old[[field]]
    is_changed <- is_changed | !((is.na(new) & is.na(old)) | (new == old) %in% TRUE)
  }

  which(is_changed & !is.na(env$hvp_id))
}


# Overwrites the stored record of rows `i` in `env$df`. A changed UID is
# also changed wherever other records refer to it.
update_records <- function (env, i) {

  db      <- env$db
  primary <- dict_primary(env$tbl)
  renamed <- integer(0)
  if (!is.null(primary))
    renamed <- i[which(env$old[[primary]][i] != env$df[[primary]][i])]

  # Foreign keys can't be checked until both sides of them are updated.
  if (length(renamed)) {
    db_query(db, "SET FOREIGN_KEY_CHECKS = 0", 'UpdRec1')
    on.exit(db_query(db, "SET FOREIGN_KEY_CHECKS = 1", 'UpdRec2'), add = TRUE)
  }

  db_update(db, env$tbl, env$df[i, , drop = FALSE], list(hvp_id = env$hvp_id[i]), 'UpdRec3')

  if (length(renamed))
    refs_replace(db, env$tbl, env$old[[primary]][renamed], env$df[[primary]][renamed])

  if (env$tbl == 'participant_event_attributes')
    events_after_update(env, i)

  invisible()
}


# Deletes the records set aside by hvp_ids_before_validate(). Runs after the
# rest of the upload and children-first, so that a record can be deleted
# along with the records that refer to it.
delete_records <- function (env) {

  db <- env$db

  for (tbl in rev(intersect(names(DICT), names(env$deletes)))) {

    env$tbl <- tbl
    del     <- env$deletes[[tbl]]
    errors  <- c()
    before  <- derived_snapshot(db)
    primary <- dict_primary(tbl)

    if (tbl == 'participant_event_attributes') {
      samples <- events_in_use(db, del)
      if (length(i <- head(which(!is.na(samples[['sample_uid']]))))) {
        msg    <- "%s:%d: \"%s\" cannot be deleted while it is the `event_uid` of samples \"%s\"%s."
        errors <- c(errors, sprintf(msg, tbl, del[['row']][i], del[['event_uid']][i], samples[['sample_uid']][i], by_owner(samples[['owner']][i])))
      }
    }

    if (tbl == 'samples') {
      state <- before$biosamples[['_state']][match(del[['hvp_id']], before$biosamples[['_source']])]
      if (length(i <- head(which(state == 'submitted')))) {
        msg    <- "%s:%d: \"%s\" cannot be deleted; it was submitted to NCBI."
        errors <- c(errors, sprintf(msg, tbl, del[['row']][i], del[['sample_uid']][i]))
      }
    }

    # Removes the deleted UIDs from the user's own optional lists of UIDs.
    # Their other references must be changed or deleted first, and a record
    # that another user's records refer to can't be deleted at all.
    blocked <- if (!is.null(primary)) refs_replace(db, tbl, del[[primary]], NA_character_, skip = del[['hvp_id']])
    if (length(i <- head(seq_len(NROW(blocked))))) {
      msg    <- "%s:%d: \"%s\" cannot be deleted while it is the `%s` of %s \"%s\"%s."
      row    <- del[['row']][match(blocked[['uid']][i], del[[primary]])]
      errors <- c(errors, sprintf(msg, tbl, row, blocked[['uid']][i], blocked[['field']][i], blocked[['tbl']][i], blocked[['label']][i], by_owner(blocked[['owner']][i])))
    }

    if (length(errors))
      stop(paste(errors, collapse = "\n"))

    # Derived records go with the record they describe.
    if (tbl == 'samples')   db_query(db, "DELETE FROM biosamples WHERE sample_name = ?", 'DelRec1', list(del[['sample_uid']]))
    if (tbl == 'libraries') db_query(db, "DELETE FROM sra WHERE library_name = ?",       'DelRec2', list(del[['library_uid']]))

    sql <- sprintf("DELETE FROM `%s` WHERE `hvp_id` = ?", tbl)
    db_query(db, sql, 'DelRec3', list(del[['hvp_id']]))

    derived_sync(env, before)
  }

  invisible()
}


# The dictionary field holding a table's own UID. NULL for events, which
# are identified by their `participant_uid` and `event_uid` together.
dict_primary <- function (tbl) {
  for (field in names(DICT[[tbl]]))
    if ("primary" %in% unlist(DICT[[tbl]][[field]][['fmt']]))
      return (field)
  return (NULL)
}


# Replaces `old` UIDs with `new` ones in every dictionary field that refers
# to `tbl`'s UID, whoever uploaded the record, or removes them when `new` is
# NA. A UID is never removed from another user's record, nor is a required
# (or conditionally required) field left blank; those cases are returned
# instead. `skip` holds `hvp_id`s of `tbl` records to leave alone.
refs_replace <- function (db, tbl, old, new, skip = NULL) {

  blocked <- NULL
  primary <- dict_primary(tbl)
  new     <- rep_len(new, length(old))

  for (ref_tbl in names(DICT)) {
    for (field in names(DICT[[ref_tbl]])) {

      dict <- DICT[[ref_tbl]][[field]]
      fmt  <- unlist(dict[['fmt']])
      if (!identical(dict[['ref']][[tbl]], primary)) next

      label <- c(dict_primary(ref_tbl), 'event_uid')[[1]]
      sql   <- "SELECT `hvp_id`, `%s` AS `uids`, `%s` AS `label`, %s AS `owner` FROM `%s` WHERE `%s` IS NOT NULL"
      rows  <- db_query(db, sprintf(sql, field, label, OTHER_USER, ref_tbl, field), 'RefRep1', simplify = FALSE)
      rows  <- rows[!(ref_tbl == tbl & rows[['hvp_id']] %in% skip), , drop = FALSE]

      # Multi-value fields hold a ";"-delimited list of UIDs.
      lists <- strsplit(rows[['uids']], ";", fixed = TRUE)
      i     <- which(vapply(lists, \(uids) any(uids %in% old), logical(1)))
      rows  <- rows[i, , drop = FALSE]

      rows[['uid']]  <- vapply(lists[i], \(uids) intersect(uids, old)[[1]], character(1))
      rows[['uids']] <- vapply(lists[i], FUN.VALUE = character(1), function (uids) {
        uids <- ifelse(uids %in% old, new[match(uids, old)], uids)
        uids <- uids[!is.na(uids)]
        if (length(uids) == 0) NA_character_ else paste(uids, collapse = ";")
      })

      is_removed <- is.na(new[match(rows[['uid']], old)])
      is_blank   <- is.na(rows[['uids']]) & any(c("required", "condition") %in% fmt)
      is_blocked <- is_blank | (is_removed & !is.na(rows[['owner']]))
      if (any(is_blocked))
        blocked <- rbind(blocked, cbind(rows[is_blocked, c('uid', 'label', 'owner'), drop = FALSE], tbl = ref_tbl, field = field))

      rows <- rows[!is_blocked, , drop = FALSE]
      if (nrow(rows) > 0)
        db_update(db, ref_tbl, setNames(rows['uids'], field), list(hvp_id = rows[['hvp_id']]), 'RefRep2')
    }
  }

  return (blocked)
}


# SQL for who uploaded a record, when it wasn't the logged-in user.
OTHER_USER <- "IF(`user` = @user, NULL, `user`)"

# Says whose record stands in the way, when it isn't one of the user's own.
by_owner <- function (owner) {
  ifelse(is.na(owner), "", sprintf(" (uploaded by %s)", owner))
}


# TRUE for each row in which data frames `a` and `b` differ. Ignores the
# `_`-prefixed columns that identify a derived record.
rows_differ <- function (a, b) {

  differ <- rep(FALSE, nrow(a))
  for (field in setdiff(names(a), c('_source', '_hvp_id', '_state'))) {
    is_same <- (is.na(a[[field]]) & is.na(b[[field]])) | (a[[field]] == b[[field]]) %in% TRUE
    differ  <- differ | !is_same
  }

  return (differ)
}


# The `biosamples` and `sra` tables are derived from the other tables.
# Comparing what they'd hold before and after a change shows which of their
# records the change affects.
derived_snapshot <- function (db) {
  list(
    biosamples = biosamples_derive(db, "biosamples.sample_name IS NOT NULL"),
    sra        = sra_derive(db, "sra.library_name IS NOT NULL") )
}

derived_sync <- function (env, before) {

  # SRA records take their accession from the BioSample records.
  biosamples_sync(env, before$biosamples)
  sra_sync(env, before$sra)

  invisible()
}
