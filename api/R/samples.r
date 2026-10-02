
samples_before_insert <- function (env) {

  errors <- c()
  df     <- env$df

  is_control <- df[['is_control_sample']] %in% "yes"

  # Control samples need a control type.
  failing <- is_control & is.na(df[['negative_control_type']]) & is.na(df[['positive_control_type']])
  errors  <- c(errors, condition_error(env, 'negative_control_type', failing))

  # Only experimental samples link to their controls.
  if (length(i <- head(which(is_control & !is.na(df[['control_sample_uid']]))))) {
    msg    <- "%s:%d: `control_sample_uid` must be blank when `is_control_sample` is \"yes\"."
    errors <- c(errors, sprintf(msg, env$tbl, i + 1))
  }

  # `collection_date` must fall within `collection_month_year` (blank only when "unavailable").
  ym  <- substr(df[['collection_date']], 1, 7)
  cmy <- data.table::fcoalesce(df[['collection_month_year']], "unavailable")
  if (length(i <- head(which(ym != cmy)))) {
    msg    <- "%s:%d: `collection_date` \"%s\" does not match `collection_month_year` \"%s\"."
    errors <- c(errors, sprintf(msg, env$tbl, i + 1, df[['collection_date']][i], cmy[i]))
  }

  # Fill in or check `collection_day_of_week` when `collection_date` is known.
  days <- c("Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday")
  dow  <- days[as.POSIXlt(as.Date(df[['collection_date']], format = "%Y-%m-%d"))$wday + 1]
  if (length(i <- head(which(dow != df[['collection_day_of_week']])))) {
    msg    <- "%s:%d: `collection_day_of_week` \"%s\" does not match `collection_date` \"%s\" (a %s)."
    errors <- c(errors, sprintf(msg, env$tbl, i + 1, df[['collection_day_of_week']][i], df[['collection_date']][i], dow[i]))
  }
  env$df[['collection_day_of_week']] <- data.table::fcoalesce(df[['collection_day_of_week']], dow)

  # `participant_uid` must agree with the participant recorded for `event_uid`.
  has_event <- !is.na(df[['event_uid']])
  if (any(has_event)) {
    sql    <- "SELECT event_uid, participant_uid FROM events"
    events <- db_query(env$db, sql, 'SaBfIn1', simplify = FALSE)
    linked <- events[['participant_uid']][match(df[['event_uid']], events[['event_uid']])]
    if (length(i <- head(which(has_event & linked != df[['participant_uid']])))) {
      msg    <- "%s:%d: `participant_uid` \"%s\" does not match the participant of event \"%s\" (\"%s\")."
      errors <- c(errors, sprintf(msg, env$tbl, i + 1, df[['participant_uid']][i], df[['event_uid']][i], linked[i]))
    }
  }

  # `event_uid` must match the event of each parent sample (which may itself
  # be inherited from a grandparent). Parents may be in this upload.
  has_parent <- has_event & !is.na(df[['parent_sample_uid']])
  if (any(has_parent)) {
    cols    <- c('sample_uid', 'event_uid', 'parent_sample_uid')
    sql     <- "SELECT sample_uid, event_uid, parent_sample_uid FROM samples"
    lineage <- rbind(db_query(env$db, sql, 'SaBfIn2', simplify = FALSE), as.data.frame(df[, cols]))

    event_of <- function (uid, depth = 0) {
      i <- match(uid, lineage[['sample_uid']])
      if (!is.na(lineage[['event_uid']][i]) || depth > 10) return (lineage[['event_uid']][i])
      parent <- lineage[['parent_sample_uid']][i]
      if (is.na(parent) || grepl(";", parent, fixed = TRUE)) return (NA_character_)
      event_of(parent, depth + 1)
    }

    msg   <- "%s:%d: `event_uid` \"%s\" does not match the event of parent sample \"%s\" (\"%s\")."
    found <- c()
    for (i in which(has_parent)) {
      parents <- strsplit(df[['parent_sample_uid']][i], ";", fixed = TRUE)[[1]]
      events  <- vapply(parents, event_of, character(1))
      if (length(j <- which(events != df[['event_uid']][i])))
        found <- c(found, sprintf(msg, env$tbl, i + 1, df[['event_uid']][i], parents[j[1]], events[j[1]]))
    }
    errors <- c(errors, head(found))
  }


  if (length(errors))
    stop(paste(errors, collapse = "\n"))
  invisible()
}


samples_after_insert <- function (env) {

  biosamples_refresh(env)

}
