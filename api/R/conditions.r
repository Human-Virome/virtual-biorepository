

condition_check_events <- function (env) {
  
  errors <- c()
  
  age         <- !is.na(env$df[['age']])
  age_units   <- !is.na(env$df[['age_units']])
  age_range   <- !is.na(env$df[['age_range']])
  has_animals <- unname(sapply(env$df[['animal_exposure']], identical, 'yes'))
  animal_list <- !is.na(env$df[['exposure_animal_type']])
  
  is_missing <- !(age | age_range)
  redundant  <- age & age_range
  age_ge_90  <- age & (as.numeric(age) >= 90) & (age_units == "years")
  
  if (any(is_missing)) {
    bad_rows <- head(which(is_missing))
    msg <- "%s:%d: either `age` or `age_range` must provided."
    msg <- sprintf(msg, env$tbl, bad_rows + 1)
    errors <- c(errors, msg)
  }
  
  if (any(redundant)) {
    bad_rows <- head(which(redundant))
    msg <- "%s:%d: provide either `age` or `age_range`, not both."
    msg <- sprintf(msg, env$tbl, bad_rows + 1)
    errors <- c(errors, msg)
  }
  
  if (any(age_ge_90)) {
    bad_rows <- head(which(age_ge_90))
    msg <- "%s:%d: use `age_range` instead of `age` when `age` >= 90 years."
    msg <- sprintf(msg, env$tbl, bad_rows + 1)
    errors <- c(errors, msg)
  }
  
  for (i in c('age', 'weight', 'height')) {
    
    value <- !is.na(env$df[[i]])
    units <- !is.na(env$df[[paste0(i, '_units')]])
    
    incomplete <- xor(value, units)
  
    if (any(incomplete)) {
      bad_rows <- head(which(incomplete))
      msg <- "%s:%d: `%s` and `%s_units` must always be given together."
      msg <- sprintf(msg, env$tbl, bad_rows + 1, i, i)
      errors <- c(errors, msg)
    }
    
  }
  
  
  missing_animals <- has_animals & !animal_list
  if (any(missing_animals)) {
    bad_rows <- head(which(missing_animals))
    msg <- "%s:%d: `exposure_animal_type` must be given when `animal_exposure` = yes."
    msg <- sprintf(msg, env$tbl, bad_rows + 1)
    errors <- c(errors, msg)
  }
  
  unexpected_animals <- animal_list & !has_animals
  if (any(unexpected_animals)) {
    bad_rows <- head(which(unexpected_animals))
    msg <- "%s:%d: `animal_exposure` must be \"yes\" when `exposure_animal_type` is given (%s)."
    msg <- sprintf(msg, env$tbl, bad_rows + 1, env$df[['exposure_animal_type']][bad_rows])
    errors <- c(errors, msg)
  }
  
  
  
  if (length(errors))
    stop(paste(errors, collapse = "\n"))
  invisible() 
}



condition_check_samples <- function (env) {
  
  errors <- c()
  
  anatomical_site       <- !is.na(env$df[['anatomical_site']])
  body_product          <- !is.na(env$df[['body_product']])
  is_control            <- env$df[['is_control_sample']] == "yes"
  negative_control_type <- !is.na(env$df[['negative_control_type']])
  postive_control_type  <- !is.na(env$df[['postive_control_type']])
  has_control_type      <- negative_control_type | postive_control_type
  
  no_product_or_site    <- !(anatomical_site | body_product)
  spurious_control_type <- !is_control & has_control_type
  missing_control_type  <- is_control & !has_control_type
  conflict_control_type <- negative_control_type & postive_control_type
  
  
  if (any(no_product_or_site)) {
    bad_rows <- head(which(no_product_or_site))
    msg <- "%s:%d: either `anatomical_site` or `body_product` must provided."
    msg <- sprintf(msg, env$tbl, bad_rows + 1)
    errors <- c(errors, msg)
  }
  
  if (any(spurious_control_type)) {
    bad_rows <- head(which(spurious_control_type))
    msg <- "%s:%d: `is_control_sample` should be \"yes\" when `negative_control_type` or `postive_control_type` is provided."
    msg <- sprintf(msg, env$tbl, bad_rows + 1)
    errors <- c(errors, msg)
  }
  
  if (any(missing_control_type)) {
    bad_rows <- head(which(missing_control_type))
    msg <- "%s:%d: `negative_control_type` or `postive_control_type` is required when `is_control_sample` = \"yes\"."
    msg <- sprintf(msg, env$tbl, bad_rows + 1)
    errors <- c(errors, msg)
  }
  
  if (any(conflict_control_type)) {
    bad_rows <- head(which(conflict_control_type))
    msg <- "%s:%d: provide either `negative_control_type` or `postive_control_type`, not both."
    msg <- sprintf(msg, env$tbl, bad_rows + 1)
    errors <- c(errors, msg)
  }
  
  
  if (length(errors))
    stop(paste(errors, collapse = "\n"))
  invisible() 
}



condition_check_libraries <- function (env) {
  
  errors <- c()
  
  is_control                  <- sapply(env$df[['is_control_library']], identical, "yes")
  library_pos_cont_type       <- !is.na(env$df[['library_pos_cont_type']])
  library_neg_cont_type       <- !is.na(env$df[['library_neg_cont_type']])
  paired_or_single            <- !is.na(env$df[['paired_or_single']])
  sequencing_platform         <- !is.na(env$df[['sequencing_platform']])
  sequencing_instrument_model <- !is.na(env$df[['sequencing_instrument_model']])
  
  is_partial_seq <- paired_or_single + sequencing_platform + sequencing_instrument_model
  is_partial_seq <- (is_partial_seq > 0) & (is_partial_seq < 3)
  
  has_control_type      <- library_neg_cont_type | library_pos_cont_type
  spurious_control_type <- !is_control & has_control_type
  missing_control_type  <- is_control & !has_control_type
  conflict_control_type <- library_neg_cont_type & library_pos_cont_type
  
  
  if (any(is_partial_seq)) {
    bad_rows <- head(which(is_partial_seq))
    msg <- "%s:%d: expected all or none of: `paired_or_single`, `sequencing_platform`, `sequencing_instrument_model`."
    msg <- sprintf(msg, env$tbl, bad_rows + 1)
    errors <- c(errors, msg)
  }
  
  if (any(spurious_control_type)) {
    bad_rows <- head(which(spurious_control_type))
    msg <- "%s:%d: `is_control_library` should be \"yes\" when `library_neg_cont_type` or `library_pos_cont_type` is provided."
    msg <- sprintf(msg, env$tbl, bad_rows + 1)
    errors <- c(errors, msg)
  }
  
  if (any(missing_control_type)) {
    bad_rows <- head(which(missing_control_type))
    msg <- "%s:%d: `library_neg_cont_type` or `library_pos_cont_type` is required when `is_control_sample` = \"yes\"."
    msg <- sprintf(msg, env$tbl, bad_rows + 1)
    errors <- c(errors, msg)
  }
  
  if (any(conflict_control_type)) {
    bad_rows <- head(which(conflict_control_type))
    msg <- "%s:%d: provide either `library_neg_cont_type` or `library_pos_cont_type`, not both."
    msg <- sprintf(msg, env$tbl, bad_rows + 1)
    errors <- c(errors, msg)
  }
  
  
  if (length(errors))
    stop(paste(errors, collapse = "\n"))
  invisible() 
}



condition_check_files <- function (env) {
  
  errors <- c()
  
  disease_research <- sapply(env$df[['data_use_condition']], identical, "DUO:0000007")
  which_disease    <- !is.na(env$df[['data_use_specific_limit']])
  invalid_source   <- !xor(is.na(env$df[['library_uid']]), is.na(env$df[['analysis_uid']]))
  incomplete_ana   <- xor(is.na(env$df[['analysis_uid']]), is.na(env$df[['file_derived_from']]))
  
  missing_limit  <- disease_research & !which_disease
  spurious_limit <- !disease_research & which_disease
  
  
  if (any(spurious_limit)) {
    bad_rows <- head(which(spurious_limit))
    msg <- "%s:%d: `data_use_condition` should be \"DUO:0000007\" (disease specific research) when `data_use_specific_limit` is provided."
    msg <- sprintf(msg, env$tbl, bad_rows + 1)
    errors <- c(errors, msg)
  }
  
  if (any(missing_limit)) {
    bad_rows <- head(which(missing_limit))
    msg <- "%s:%d: `data_use_specific_limit` is required when `data_use_condition` = \"DUO:0000007\" (disease specific research)."
    msg <- sprintf(msg, env$tbl, bad_rows + 1)
    errors <- c(errors, msg)
  }
  
  if (any(invalid_source)) {
    bad_rows <- head(which(invalid_source))
    msg <- "%s:%d: Either `library_uid` or `analysis_uid` must be provided (but not both)."
    msg <- sprintf(msg, env$tbl, bad_rows + 1)
    errors <- c(errors, msg)
  }
  
  if (any(incomplete_ana)) {
    bad_rows <- head(which(incomplete_ana))
    msg <- "%s:%d: `analysis_uid` and `file_derived_from` must be filled in together or not at all."
    msg <- sprintf(msg, env$tbl, bad_rows + 1)
    errors <- c(errors, msg)
  }
}




