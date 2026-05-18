

condition_check_events <- function (db, env, tbl) {
  
  recs <- length(env[[ls(env)[[1]]]])
  
  for (field in c('age', 'age_units', 'age_range'))
    if (!hasName(env, field))
      env[[field]] <- character(recs)
  
  age       <- nzchar(env[['age']])
  age_units <- nzchar(env[['age_units']])
  age_range <- nzchar(env[['age_range']])
  
  is_missing <- !(age | age_range)
  redundant  <- age & age_range
  incomplete <- xor(age, age_units)
  
  if (any(is_missing)) {
    bad_rows <- head(which(is_missing))
    msg <- "%s:%d: either `age` or `age_range` must provided."
    msg <- sprintf(msg, tbl, bad_rows + 1)
    errors <- c(errors, msg)
  }
  
  if (any(incomplete)) {
    bad_rows <- head(which(incomplete))
    msg <- "%s:%d: `age` and `age_units` must always be given together."
    msg <- sprintf(msg, tbl, bad_rows + 1)
    errors <- c(errors, msg)
  }
  
  if (any(redundant)) {
    bad_rows <- head(which(redundant))
    msg <- "%s:%d: provide either `age` or `age_range`, not both."
    msg <- sprintf(msg, tbl, bad_rows + 1)
    errors <- c(errors, msg)
  }
  
  
  if (length(errors))
    stop(paste(errors, collapse = "\n"))
  invisible() 
}



condition_check_samples <- function (db, env, tbl) {
  
  recs <- length(env[[ls(env)[[1]]]])
  
  for (field in c('anatomical_site', 'body_product', 'negative_control_type', 'postive_control_type'))
    if (!hasName(env, field))
      env[[field]] <- character(recs)
  
  anatomical_site       <- nzchar(env[['anatomical_site']])
  body_product          <- nzchar(env[['body_product']])
  is_control            <- env[['is_control_sample']] == "yes"
  negative_control_type <- nzchar(env[['negative_control_type']])
  postive_control_type  <- nzchar(env[['postive_control_type']])
  has_control_type      <- negative_control_type | postive_control_type
  
  no_product_or_site    <- anatomical_site | body_product
  spurious_control_type <- !is_control & has_control_type
  missing_control_type  <- is_control & !has_control_type
  conflict_control_type <- negative_control_type & postive_control_type
  
  
  if (any(no_product_or_site)) {
    bad_rows <- head(which(no_product_or_site))
    msg <- "%s:%d: either `anatomical_site` or `body_product` must provided."
    msg <- sprintf(msg, tbl, bad_rows + 1)
    errors <- c(errors, msg)
  }
  
  if (any(spurious_control_type)) {
    bad_rows <- head(which(spurious_control_type))
    msg <- "%s:%d: `is_control_sample` should be \"yes\" when `negative_control_type` or `postive_control_type` is provided."
    msg <- sprintf(msg, tbl, bad_rows + 1)
    errors <- c(errors, msg)
  }
  
  if (any(missing_control_type)) {
    bad_rows <- head(which(missing_control_type))
    msg <- "%s:%d: `negative_control_type` or `postive_control_type` is required when `is_control_sample` = \"yes\"."
    msg <- sprintf(msg, tbl, bad_rows + 1)
    errors <- c(errors, msg)
  }
  
  if (any(conflict_control_type)) {
    bad_rows <- head(which(conflict_control_type))
    msg <- "%s:%d: provide either `negative_control_type` or `postive_control_type`, not both."
    msg <- sprintf(msg, tbl, bad_rows + 1)
    errors <- c(errors, msg)
  }
  
  
  if (length(errors))
    stop(paste(errors, collapse = "\n"))
  invisible() 
}



condition_check_libraries <- function (db, env, tbl) {
  
  recs <- length(env[[ls(env)[[1]]]])
  
  for (field in c('is_control_library', 'library_pos_cont_type', 'library_neg_cont_type', 'paired_or_single', 'sequencing_platform', 'sequencing_instrument_model'))
    if (!hasName(env, field))
      env[[field]] <- character(recs)
  
  
  is_control                  <- env[['is_control_library']] == "yes"
  library_pos_cont_type       <- nzchar(env[['library_pos_cont_type']])
  library_neg_cont_type       <- nzchar(env[['library_neg_cont_type']])
  paired_or_single            <- nzchar(env[['paired_or_single']])
  sequencing_platform         <- nzchar(env[['sequencing_platform']])
  sequencing_instrument_model <- nzchar(env[['sequencing_instrument_model']])
  
  is_partial_seq <- paired_or_single + sequencing_platform + sequencing_instrument_model
  is_partial_seq <- (is_partial_seq > 0) & (is_partial_seq < 3)
  
  has_control_type      <- library_neg_cont_type | library_pos_cont_type
  spurious_control_type <- !is_control & has_control_type
  missing_control_type  <- is_control & !has_control_type
  conflict_control_type <- library_neg_cont_type & library_pos_cont_type
  
  
  if (any(is_partial_seq)) {
    bad_rows <- head(which(is_partial_seq))
    msg <- "%s:%d: expected all or none of: `paired_or_single`, `sequencing_platform`, `sequencing_instrument_model`."
    msg <- sprintf(msg, tbl, bad_rows + 1)
    errors <- c(errors, msg)
  }
  
  if (any(spurious_control_type)) {
    bad_rows <- head(which(spurious_control_type))
    msg <- "%s:%d: `is_control_library` should be \"yes\" when `library_neg_cont_type` or `library_pos_cont_type` is provided."
    msg <- sprintf(msg, tbl, bad_rows + 1)
    errors <- c(errors, msg)
  }
  
  if (any(missing_control_type)) {
    bad_rows <- head(which(missing_control_type))
    msg <- "%s:%d: `library_neg_cont_type` or `library_pos_cont_type` is required when `is_control_sample` = \"yes\"."
    msg <- sprintf(msg, tbl, bad_rows + 1)
    errors <- c(errors, msg)
  }
  
  if (any(conflict_control_type)) {
    bad_rows <- head(which(conflict_control_type))
    msg <- "%s:%d: provide either `library_neg_cont_type` or `library_pos_cont_type`, not both."
    msg <- sprintf(msg, tbl, bad_rows + 1)
    errors <- c(errors, msg)
  }
  
  
  if (length(errors))
    stop(paste(errors, collapse = "\n"))
  invisible() 
}



condition_check_files <- function (db, env, tbl) {
  
  recs <- length(env[[ls(env)[[1]]]])
  
  for (field in c('data_use_condition', 'data_use_specific_limit'))
    if (!hasName(env, field))
      env[[field]] <- character(recs)
  
  data_use_condition      <- env[['data_use_condition']] == "DUO:0000007"
  data_use_specific_limit <- nzchar(env[['data_use_specific_limit']])
  
  missing_limit  <- data_use_condition & !data_use_specific_limit
  spurious_limit <- !data_use_condition & data_use_specific_limit
  
  
  if (any(spurious_limit)) {
    bad_rows <- head(which(spurious_limit))
    msg <- "%s:%d: `data_use_condition` should be \"DUO:0000007\" (disease specific research) when `data_use_specific_limit` is provided."
    msg <- sprintf(msg, tbl, bad_rows + 1)
    errors <- c(errors, msg)
  }
  
  if (any(missing_control_type)) {
    bad_rows <- head(which(missing_control_type))
    msg <- "%s:%d: `data_use_specific_limit` is required when `data_use_condition` = \"DUO:0000007\" (disease specific research)."
    msg <- sprintf(msg, tbl, bad_rows + 1)
    errors <- c(errors, msg)
  }
}




