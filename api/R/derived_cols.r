
derive_cols_events <- function (env) {
  
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
    wt / (ht * ht)
  })
  
  env$df[['mental_health_collected']] <- local({
    hist <- !is.na(env$df[['mental_health_history']])
    samp <- !is.na(env$df[['mental_health_at_sampling']])
    data.table::fifelse(hist | samp, "yes", "no")
  })
  
  env$df[['medication_info_collected']] <- local({
    is_na <- is.na(env$df[['prescription_medications']])
    data.table::fifelse(is_na, "no", "yes")
  })
  
  env$df[['alcohol_activity_collected']] <- local({
    is_na <- !is.na(env$df[['alcohol_consumption']])
    data.table::fifelse(is_na, "no", "yes")
  })
  
  env$df[['tobacco_use_collected']] <- local({
    smoke <- !is.na(env$df[['cigarette_smoking']])
    other <- !is.na(env$df[['other_tobacco_exposure']])
    data.table::fifelse(smoke | other, "yes", "no")
  })
  
  env$df[['drug_use_collected']] <- local({
    vape <- !is.na(env$df[['vaping_behavior']])
    weed <- !is.na(env$df[['cannabis']])
    hard <- !is.na(env$df[['recreational_or_illicit_drugs']])
    data.table::fifelse(vape | weed | hard, "yes", "no")
  })
  
  env$df[['physical_activtiy_collected']] <- local({
    is_na <- is.na(env$df[['physical_activity']])
    is_no <- sapply(env$df[['physical_activity']], identical, "yes")
    data.table::fifelse(is_na | is_no, "no", "yes")
  })
  
  invisible()
}


derive_cols_libraries <- function (env) {
  
  invisible() 
}
