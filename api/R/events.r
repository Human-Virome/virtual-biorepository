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
