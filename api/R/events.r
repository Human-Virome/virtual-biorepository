events_before_insert <- function (env) {

  errors <- c()

  env$df[['converted_age_years']] <- with(
    data = env$df,
    expr = data.table::fcase(
      age_units == 'days',   age / 365.25,
      age_units == 'weeks',  age / 52.18,
      age_units == 'months', age / 12,
      age_units == 'years',  age ))

  env$df[['converted_height_cm']] <- with(
    data = env$df,
    expr = data.table::fcase(
      height_units == 'meters',      height * 100,
      height_units == 'centimeters', height,
      height_units == 'feet',        height * 30.48,
      height_units == 'inches',      height * 2.54 ))

  env$df[['converted_weight_kg']] <- with(
    data = env$df,
    expr = data.table::fcase(
      weight_units == 'pounds',      weight * 0.453592,
      weight_units == 'kilograms',   weight,
      weight_units == 'ounces',      weight * 0.0283495 ))

  env$df[['bmi']] <- local({
    wt <- env$df[['converted_weight_kg']]
    ht <- env$df[['converted_height_cm']] / 100
    data.table::fifelse(ht > 0, wt / (ht * ht), NA_real_)
  })

  # Both `age` and `age_units` accept "unavailable", but a known age needs units.
  if (length(i <- head(which(!is.na(env$df[['age']]) & is.na(env$df[['age_units']]))))) {
    msg    <- "%s:%d: `age_units` cannot be \"unavailable\" when `age` is provided."
    errors <- c(errors, sprintf(msg, env$tbl, i + 1))
  }

  if (length(i <- head(which(env$df[['converted_age_years']] >= 90)))) {
    msg    <- "%s:%d: You must use `age_range` for ages >= 90 years. Set `age` to \"unavailable\" and `age_range` to \"90+\"."
    errors <- c(errors, sprintf(msg, env$tbl, i + 1))
  }


  if (length(errors))
    stop(paste(errors, collapse = "\n"))
  invisible()
}


# The first sample (if any) that refers to each event, and who uploaded it
# if that was another user. An event is identified by its `participant_uid`
# and `event_uid` together.
events_in_use <- function (db, events) {

  sql     <- "SELECT participant_uid, event_uid, sample_uid, %s AS owner FROM samples WHERE event_uid IS NOT NULL"
  samples <- db_query(db, sprintf(sql, OTHER_USER), 'EvInUse1', simplify = FALSE)

  i <- match(
    paste(events[['participant_uid']],  events[['event_uid']],  sep = "\t"),
    paste(samples[['participant_uid']], samples[['event_uid']], sep = "\t") )

  samples[i, c('sample_uid', 'owner'), drop = FALSE]
}


# Samples follow an event whose `event_uid` changed (rows `i` of `env$df`),
# but can't follow it to a different participant.
events_after_update <- function (env, i) {

  old     <- env$old[i, , drop = FALSE]
  new     <- env$df[i, , drop = FALSE]
  samples <- events_in_use(env$db, old)
  moved   <- old[['participant_uid']] != new[['participant_uid']]

  if (length(j <- head(which(moved & !is.na(samples[['sample_uid']]))))) {
    msg <- "%s:%d: `participant_uid` cannot change while this event is the `event_uid` of samples \"%s\"%s."
    stop(paste(sprintf(msg, env$tbl, i[j] + 1, samples[['sample_uid']][j], by_owner(samples[['owner']][j])), collapse = "\n"))
  }

  j <- which(!moved & old[['event_uid']] != new[['event_uid']])
  if (length(j)) {
    sql <- "UPDATE samples SET event_uid = ? WHERE participant_uid = ? AND event_uid = ?"
    db_query(env$db, sql, 'EvAfUp1', list(new[['event_uid']][j], old[['participant_uid']][j], old[['event_uid']][j]))
  }

  invisible()
}
