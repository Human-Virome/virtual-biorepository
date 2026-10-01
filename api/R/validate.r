


validate_table <- function (env) {

  errors <- c()

  dict        <- DICT[[env$tbl]]
  dict_fields <- names(dict)
  user_fields <- names(env$df)

  # Merge columns with duplicate names.
  if (any(duplicated(user_fields))) {
    dups <- unique(user_fields[duplicated(user_fields)])
    for (field in dups) {
      i <- which(names(env$df) == field)
      x <- apply(env$df[, i, drop = FALSE], 1L, \(y) paste(na.omit(y), collapse = ";"))
      env$df <- env$df[, -i, drop = FALSE]
      env$df[[field]] <- x
    }
    user_fields <- names(env$df)
  }

  # Reject columns that are not defined in the dictionary.
  if (length(rej <- setdiff(user_fields, dict_fields))) {
    msg <- '%s: Unexpected columns are present: `%s`'
    msg <- sprintf(msg, env$tbl, paste(rej, collapse = '`, `'))
    errors <- c(errors, msg)
  }

  # Add back any columns deleted by the user.
  for (field in setdiff(dict_fields, user_fields)) {
    nonblank        <- "non-blank" %in% dict[[field]][['fmt']]
    env$df[[field]] <- if (nonblank) "not collected" else NA_character_
  }

  # Whitespace-only cells (and merged duplicate columns with no values) are blank.
  for (field in dict_fields) {
    x <- trimws(env$df[[field]])
    x[!is.na(x) & !nzchar(x)] <- NA
    env$df[[field]] <- x
  }

  # "unavailable" satisfies the field's own `required`/`condition` check, but
  # is otherwise treated as blank and stored as NULL. The original positions
  # are remembered in `env$unavailable` for validate_required/condition.
  env$unavailable <- list()
  for (field in dict_fields) {
    if ("unavailable" %in% unlist(dict[[field]][['fmt']])) {
      is_unavailable <- env$df[[field]] %in% "unavailable"
      env$df[[field]][is_unavailable] <- NA
      env$unavailable[[field]] <- is_unavailable
    }
  }

  # Presence checks run first, so cross-field references see the values as
  # entered (except "unavailable") rather than as normalized below.
  for (field in dict_fields) {
    for (f in unlist(dict[[field]][['fmt']])) {
      errors <- c(errors, switch(f,
        'required'   = validate_required(env, field),
        'condition'  = validate_condition(env, field),
        'assert'     = validate_assert(env, field),
        NULL
      ))
    }
  }

  # Format checks, which may also normalize/convert values in env$df.
  for (field in dict_fields) {
    for (f in unlist(dict[[field]][['fmt']])) {
      errors <- c(errors, switch(f,
        'uid'        = validate_uid(env, field),
        'non-blank'  = validate_nonblank(env, field),
        'ontology'   = validate_ontology(env, field),
        'cv'         = validate_cv(env, field),
        'primary'    = validate_primary(env, field),
        'suffix'     = validate_suffix(env, field),
        'number'     = validate_number(env, field),
        'date'       = validate_date(env, field),
        'YYYY-MM-DD' = validate_yyyy_mm_dd(env, field),
        'YYYY-MM'    = validate_yyyy_mm(env, field),
        'md5'        = validate_md5(env, field),
        'json'       = validate_json(env, field),
        'url'        = validate_url(env, field),
        'file'       = validate_filename(env, field),
        'bioproject' = validate_bioproject(env, field),
        'biosample'  = validate_biosample(env, field),
        NULL
      ))
    }
  }

  if (length(errors))
    stop(paste(errors, collapse = "\n"))
  invisible()  
}



# TRUE where the user entered "unavailable" (since converted to NA).
is_unavailable <- function (env, field) {
  x <- env$unavailable[[field]]
  if (is.null(x)) rep(FALSE, nrow(env$df)) else x
}


# Fail loudly on dictionary typos instead of silently skipping a check.
dict_target <- function (env, field, target) {
  if (!hasName(env$df, target))
    stop(sprintf("Dictionary error: %s:%s references unknown field `%s`.", env$tbl, field, target))
  env$df[[target]]
}



validate_required <- function (env, field) {
  
  errors <- c()

  x <- env$df[[field]]
  x <- trimws(gsub(";", "", x, fixed = TRUE))
  
  if (length(i <- head(which((is.na(x) | !nzchar(x)) & !is_unavailable(env, field))))) {
    msg    <- "%s:%s:%d: `%s` is required."
    if (hasName(env$unavailable, field))
      msg  <- "%s:%s:%d: `%s` is required. Use \"unavailable\" if the value is not known."
    msg    <- sprintf(msg, env$tbl, field, i + 1, field)
    errors <- c(errors, msg)
  }

  return(errors)  
}



validate_condition <- function (env, field) {

  errors <- c()

  # Conditions with only a description are enforced by `<tbl>_before_insert()`, if at all.
  conditions <- DICT[[env$tbl]][[field]][['condition']]
  checks     <- setdiff(names(conditions), "description")
  if (length(checks) == 0) return (errors)

  failing <- is.na(env$df[[field]]) & !is_unavailable(env, field)

  for (check in checks) {

    if (check == "when_true") {
      for (target in names(conditions[[check]])) {
        pattern <- conditions[[check]][[target]]
        failing <- failing & grepl(pattern, dict_target(env, field, target))
      }
    }
    else if (check == "when_false") {
      for (target in names(conditions[[check]])) {
        pattern <- conditions[[check]][[target]]
        failing <- failing & !grepl(pattern, dict_target(env, field, target))
      }
    }
    else if (check == "when_set") {
      for (target in unlist(conditions[[check]]))
        failing <- failing & !is.na(dict_target(env, field, target))
    }
    else if (check == "when_unset") {
      for (target in unlist(conditions[[check]]))
        failing <- failing & is.na(dict_target(env, field, target))
    }
    else {
      stop("Unknown condition check: ", check)
    }

  }

  return (condition_error(env, field, failing))
}



# Reports a failed `condition` using its dictionary description. Also used by
# `<tbl>_before_insert()` for conditions too complex for `when_*` checks.
condition_error <- function (env, field, failing) {

  if (!length(i <- head(which(failing)))) return (NULL)

  msg <- DICT[[env$tbl]][[field]][['condition']][['description']]
  sprintf("%s:%s:%d: %s", env$tbl, field, i + 1, msg)
}



validate_assert <- function (env, field) {

  errors <- c()

  asserts   <- DICT[[env$tbl]][[field]][['assert']]
  has_field <- !is.na(env$df[[field]])

  for (check in names(asserts)) {

    target     <- asserts[[check]]
    has_target <- !is.na(dict_target(env, field, target))

    if (check == "XOR") {
      if (length(i <- head(which(!xor(has_field, has_target))))) {
        msg    <- "%s:%d: Either `%s` or `%s` must be provided, but not both."
        errors <- c(errors, sprintf(msg, env$tbl, i + 1, field, target))
      }
    }
    else if (check == "NAND") {
      if (length(i <- head(which(has_field & has_target)))) {
        msg    <- "%s:%d: `%s` and `%s` cannot both be provided."
        errors <- c(errors, sprintf(msg, env$tbl, i + 1, field, target))
      }
    }
    else {
      stop("Unknown assert check: ", check)
    }
    
  }

  return(errors)  
}


validate_uid <- function (env, field) {
  
  errors <- c()
  x      <- env$df[[field]]
  dict   <- DICT[[env$tbl]][[field]]
  fmt    <- unlist(dict[['fmt']])
  multi  <- "multiple" %in% fmt
  is_ref <- isTRUE("ref" %in% fmt)

  uid_sets <- strsplit(x, ';')
  all_uids <- trimws(unlist(uid_sets))
  uid_rows <- rep(seq_along(x), sapply(uid_sets, length))

  is_na    <- is.na(all_uids) | !nzchar(all_uids)
  all_uids <- all_uids[!is_na]
  uid_rows <- uid_rows[!is_na]

  if (!isTRUE(multi)) {
    if (length(i <- head(which(sapply(uid_sets, length) > 1)))) {
      msg    <- "%s:%s:%d: multiple UIDs are not allowed: \"%s\""
      msg    <- sprintf(msg, env$tbl, field, i + 1, x[i])
      errors <- c(errors, msg)
    }
  }

  special <- c()
  if (is_ref && field %in% c('participant_uid', 'event_uid')) { special <- c('composite$', 'mock$') }
  pattern <- paste0("^(", paste0(c(special, UID_PREFIXES), collapse = "|"), ")")

  if (length(i <- head(which(!grepl(pattern, all_uids))))) {
      msg    <- "%s:%s:%d: UID must begin with a center prefix: \"%s\""
      msg    <- sprintf(msg, env$tbl, field, uid_rows[i] + 1, all_uids[i])
      errors <- c(errors, msg)
  }

  if (is_ref) {
    ref_table <- names(dict[['ref']])
    ref_field <- unname(dict[['ref']])[[1]]

    sql     <- sprintf('SELECT `%s` FROM `%s`', ref_field, ref_table)
    current <- db_query(env$db, sql, 'ValUid')
    
    if (identical(ref_table, env$tbl))
      current <- c(current, env$df[[ref_field]])
    
    if (length(i <- head(which(!(all_uids %in% current))))) {
      msg <- "%s:%s:%d: \"%s\" is not defined by the %s table."
      msg <- sprintf(msg, env$tbl, field, uid_rows[i] + 1, all_uids[i], ref_table)
      errors <- c(errors, msg)
    }
  }

  env$df[[field]] <- unname(sapply(uid_sets, function (x) {
    x <- trimws(x)
    if (all(is.na(x) | nchar(x) == 0)) return (NA_character_)
    paste(x, collapse = ";")
  }))

  return(errors)  
}



# Allows optional multi-value fields (e.g. Rx Meds) to
# differentiate between "not collected" and "none reported".
validate_nonblank <- function (env, field) {
  
  errors <- c()
  
  # Importer has already converted all blanks ("") to NA.
  x <- env$df[[field]]

  # Handle sentinel values. Required for optional multi-value columns.
  if (any(is.na(x))) {
    bad_rows <- head(which(is.na(x)))
    msg <- "%s:%d: blank values are ambigous in `%s`. Please use \"none reported\" or \"not collected\"."
    msg <- sprintf(msg, env$tbl, bad_rows + 1, field)
    errors <- c(errors, msg)
  }

  # Recode sentinel values.
  x[x == "not collected"] <- NA
  x[x == "none reported"] <- ""
  env$df[[field]] <- x
  
  return(errors)  
}


# Converts
# From: "Dog [NCBI:txid9615]; Cat (Domestic) [NCBI:txid9685]"
# To:   "NCBI:txid9615;NCBI:txid9685"
validate_ontology <- function (env, field) {
  
  errors   <- c()
  x        <- env$df[[field]]
  dict     <- DICT[[env$tbl]][[field]]
  prefixes <- unlist(dict[['ontology']])
  multi    <- "multiple" %in% unlist(dict[['fmt']])

  regex <- paste0("\\b(", paste0(prefixes, "[0-9]+", collapse = "|"), ")")
  regex <- sub("DB[0-9]", "DB[a-zA-Z0-9_:\\-]", regex, fixed = TRUE)

  # 2. Identify missing records
  is_na    <- is.na(x)
  is_blank <- !is_na & x == ""
  is_empty <- is_na | is_blank

  x[is_blank] <- NA
  
  # 3. Process strings based on `multi` parameter
  if (!isTRUE(multi)) {
    # -- MULTI = FALSE LOGIC --
    
    # Semicolons are strictly forbidden
    has_semi <- stringi::stri_detect_fixed(x, ";")
    if (any(has_semi, na.rm = TRUE)) {
      bad_rows <- head(which(has_semi))
      msg <- "%s:%d: semicolons in `%s` are not allowed: \"%s\""
      msg <- sprintf(msg, env$tbl, bad_rows + 1, field, x[bad_rows])
      errors <- c(errors, msg)
    }
    
    # Extract matches for the entire string
    matches   <- stringi::stri_extract_all_regex(x, regex)
    n_matches <- sapply(matches, function(m) sum(!is.na(m)))
    
    # Validations:
    # Missing if required+empty, OR if non-empty and lacks exactly 1 match
    is_missing  <- !is_empty & n_matches == 0
    is_too_many <- !is_empty & n_matches > 1
    
    # Flatten single results
    result_list <- lapply(matches, function(m) m[1])
    
  } else {
    # -- MULTI = TRUE LOGIC --
    
    # Split by semicolon into lists of substrings
    splits <- stringi::stri_split_fixed(x, ";")
    
    # Extract matches for each individual substring
    sub_matches <- lapply(splits, function(s) {
      stringi::stri_extract_all_regex(s, regex)
    })
    
    # Count valid matches per substring
    sub_counts <- lapply(sub_matches, function(row_matches) {
      sapply(row_matches, function(m) sum(!is.na(m)))
    })
    
    # Validations per substring constraints:
    is_missing <- sapply(seq_along(sub_counts), function(i) {
      if (is_empty[i]) return(FALSE)
      any(sub_counts[[i]] == 0) # Fails if ANY substring has 0 matches
    })
    
    is_too_many <- sapply(seq_along(sub_counts), function(i) {
      if (is_empty[i]) return(FALSE)
      any(sub_counts[[i]] > 1)  # Fails if ANY substring has >1 matches
    })
    
    # Rejoin the first valid match from each substring with a semicolon
    result_list <- lapply(sub_matches, function(row_matches) {
      extracted <- sapply(row_matches, function(m) m[1])
      stringi::stri_join(extracted[!is.na(extracted)], collapse = ";")
    })
  }
  
  # 4. Error Reporting 
  # (Note: +1 assumes 1-based indexing for spreadsheet/header rows)
  if (length(i <- head(which(is_missing)))) {
    msg    <- "%s:%s:%d: missing or invalid ontology ID: \"%s\""
    msg    <- sprintf(msg, env$tbl, field, i + 1, x[i])
    errors <- c(errors, msg)
  }
  
  if (length(i <- head(which(is_too_many)))) {
    msg    <- "%s:%s:%d: multiple ontology IDs are not allowed: \"%s\""
    msg    <- sprintf(msg, env$tbl, field, i + 1, x[i])
    errors <- c(errors, msg)
  }
  
  # 5. Finalize and Assign
  env$df[[field]] <- unlist(result_list)
  env$df[[field]][is_blank] <- ""
  env$df[[field]][is_na]    <- NA
  
  return(errors)  
}



validate_primary <- function (env, field) {
  
  errors <- c()
  
  x <- env$df[[field]]
  
  sql     <- sprintf('SELECT `%s` FROM `%s`', field, env$tbl)
  current <- db_query(env$db, sql, 'ValPri')
  
  if (length(i <- head(which(x %in% current)))) {
    msg    <- "%s:%s:%d: UID already exists in database: \"%s\""
    msg    <- sprintf(msg, env$tbl, field, i + 1, x[i])
    errors <- c(errors, msg)
  }
  
  if (length(i <- head(which(duplicated(x) & !is.na(x))))) {
    msg    <- "%s:%s:%d: UID is defined more than once: \"%s\""
    msg    <- sprintf(msg, env$tbl, field, i + 1, x[i])
    errors <- c(errors, msg)
  }
  
  return(errors)   
}



validate_suffix  <- function (env, field) {
  
  errors <- c()

  fmt  <- unlist(DICT[[env$tbl]][[field]][['fmt']])
  freq <- "freq" %in% fmt
  mode <- "mode" %in% fmt
  
  x <- env$df[[field]]
  
  for (i in which(!is.na(x))) {
    invisible(sapply(strsplit(x[[i]], ";", fixed = TRUE)[[1]], \(str) {
      s <- str
      if (freq) s <- sub(FREQ_REGEX, '', s)
      if (mode) s <- sub(MODE_REGEX, '', s)
      valid <- isTRUE(grepl('^DB(X_[^:]+|\\d+)$', s))
      valid <- valid && startsWith(str, s)
      if (!valid) {
        msg <- "%s:%d: invalid `%s` identifier/suffix: \"%s\""
        msg <- sprintf(msg, env$tbl, i + 1, field, str)
        errors <<- c(errors, msg)
      }
    }))
  }
  
  return(errors)  
}



validate_cv  <- function (env, field) {
  
  errors <- c()
    
  fmt <- unlist(DICT[[env$tbl]][[field]][['fmt']])
  cv  <- unlist(DICT[[env$tbl]][[field]][['cv']])
  cv  <- c(cv, NA_character_)
  
  if ('multiple' %in% fmt) {

    # Treat user input as semicolon-delimited values
    env$df[[field]] <- gsub("\\s*;\\s*", ";", env$df[[field]])
    is_valid <- sapply(env$df[[field]], function(x) {
      all(unlist(strsplit(x, split = ";", fixed = TRUE)) %in% cv)
    })
    invalid <- which(!is_valid)
    
  } else {
    # Standard exact match for single values
    invalid <- which(!(env$df[[field]] %in% cv))
  }
  
  if (length(invalid) > 0) {
    bad_rows <- head(invalid)
    msg <- "%s:%d: `%s` doesn't match controlled vocabulary: \"%s\""
    msg <- sprintf(msg, env$tbl, bad_rows + 1, field, env$df[[field]][bad_rows])
    errors <- c(errors, msg)
  }
  
  return(errors)  
}



validate_number <- function (env, field) {
  
  errors <- c()
  
  fmt <- unlist(DICT[[env$tbl]][[field]][['fmt']])
  
  x <- env$df[[field]]
  
  x_num   <- suppressWarnings(as.numeric(x))
  not_num <- which(!is.na(x) & !is.finite(x_num))
  
  if (length(not_num) > 0) {
    bad_rows <- head(not_num)
    msg <- "%s:%d: `%s` is not a number: \"%s\""
    msg <- sprintf(msg, env$tbl, bad_rows + 1, field, x[bad_rows])
    errors <- c(errors, msg)
  }
  
  if ('integer' %in% fmt) {
    is_frac <- which(x_num %% 1 > 0 & is.finite(x_num))
    
    if (length(is_frac) > 0) {
      bad_rows <- head(is_frac)
      msg <- "%s:%d: `%s` is not a whole number: \"%s\""
      msg <- sprintf(msg, env$tbl, bad_rows + 1, field, x[bad_rows])
      errors <- c(errors, msg)
    }
  }
  
  range_vals <- unlist(DICT[[env$tbl]][[field]][['range']])
  if (!is.null(range_vals) && length(range_vals) == 2) {
    min_val <- range_vals[1]
    max_val <- range_vals[2]
    
    out_of_range <- which((x_num < min_val | x_num > max_val) & is.finite(x_num))
    
    if (length(out_of_range) > 0) {
      bad_rows <- head(out_of_range)
      msg <- "%s:%d: `%s` is outside the allowed range [%s, %s]: \"%s\""
      msg <- sprintf(msg, env$tbl, bad_rows + 1, field, min_val, max_val, x[bad_rows])
      errors <- c(errors, msg)
    }
  }
  
  env$df[[field]] <- x_num
  
  return(errors)   
}



validate_yyyy_mm <- function (env, field) {
  
  x <- env$df[[field]]
  
  is_fmt <- (is.na(x) | grepl("^[0-9]{4}\\-[0-9]{2}$", x))
  if (any(!is_fmt)) {
    bad_rows <- head(which(!is_fmt))
    msg    <- "%s:%d: `%s` has invalid YYYY-MM date format: \"%s\""
    errors <- sprintf(msg, env$tbl, bad_rows + 1, field, x[bad_rows])
  }
  else {
    errors <- validate_date(env, field)
  }
  
  return(errors)   
}



validate_yyyy_mm_dd <- function (env, field) {
  
  x <- env$df[[field]]
  
  is_fmt <- (is.na(x) | grepl("^[0-9]{4}\\-[0-9]{2}\\-[0-9]{2}$", x))
  if (any(!is_fmt)) {
    bad_rows <- head(which(!is_fmt))
    msg    <- "%s:%d: `%s` has invalid YYYY-MM-DD date format: \"%s\""
    errors <- sprintf(msg, env$tbl, bad_rows + 1, field, x[bad_rows])
  }
  else {
    errors <- validate_date(env, field)
  }
  
  return(errors)   
}



validate_date <- function (env, field) {
  
  errors <- c()
  
  x <- env$df[[field]]
  
  is_fmt <- (is.na(x) | grepl("^[0-9]{4}\\-[0-9]{2}(|\\-[0-9]{2})$", x))
  if (any(!is_fmt)) {
    bad_rows <- head(which(!is_fmt))
    msg <- "%s:%d: `%s` has invalid date format: \"%s\""
    msg <- sprintf(msg, env$tbl, bad_rows + 1, field, x[bad_rows])
    errors <- c(errors, msg)
  }
  
  x_full  <- ifelse(nchar(x) == 7, paste0(x, "-01"), x)
  x_full  <- as.Date(x_full, format="%Y-%m-%d")
  is_date <- is.na(x) | !is.na(x_full)
  
  if (any(!is_date)) {
    bad_rows <- head(which(!is_date))
    msg <- "%s:%d: `%s` is not a real date: \"%s\""
    msg <- sprintf(msg, env$tbl, bad_rows + 1, field, x[bad_rows])
    errors <- c(errors, msg)
  }

  max_date <- Sys.Date()
  min_date <- max_date - 100*365.25 # 100 years
  oob_dates <- x_full > max_date | x_full < min_date
  if (any(oob_dates, na.rm = TRUE)) {
    bad_rows <- head(which(oob_dates))
    msg <- "%s:%d: `%s` is outside the allowed range [%s, %s]: \"%s\""
    msg <- sprintf(msg, env$tbl, bad_rows + 1, field, min_date, max_date, x[bad_rows])
    errors <- c(errors, msg)
  }
  
  return(errors)  
}



validate_url  <- function (env, field) {
  
  errors <- c()
  
  x <- env$df[[field]]
  
  # Basic Syntax Check (must start with http:// or https://)
  is_a_url   <- grepl("^https?://", tolower(x))
  bad_syntax <- which(!is.na(x) & !is_a_url)
  
  if (length(bad_syntax) > 0) {
    bad_rows <- head(bad_syntax)
    msg <- "%s:%d: `%s` is not a URL: \"%s\""
    msg <- sprintf(msg, env$tbl, bad_rows + 1, field, x[bad_rows])
    errors <- c(errors, msg)
  }
  
  urls <- unique(x[is_a_url])
  if (length(urls) > 0) {
    
    reqs <- crul::Async$new(urls = urls)
    unreachable <- which(!sapply(reqs$get(), function(res) {
      res$success() && res$status_code >= 200 && res$status_code < 400
    }))
    
    if (length(unreachable) > 0) {
      bad_rows <- head(which(is_a_url & (x %in% urls[unreachable])))
      msg <- "%s:%d: `%s` is not reachable: %s"
      msg <- sprintf(msg, env$tbl, bad_rows + 1, field, x[bad_rows])
      errors <- c(errors, msg)
    }
  }
  
  return(errors)  
}



validate_md5  <- function (env, field) {
  
  errors <- c()
  
  x <- env$df[[field]]
  
  # Basic Syntax Check (must start with http:// or https://)
  is_md5     <- grepl("^[a-f0-9]{32}$", tolower(x))
  bad_syntax <- which(!is.na(x) & !is_md5)
  
  if (length(bad_syntax) > 0) {
    bad_rows <- head(bad_syntax)
    msg <- "%s:%d: `%s` is not a MD5 checksum: \"%s\""
    msg <- sprintf(msg, env$tbl, bad_rows + 1, field, x[bad_rows])
    errors <- c(errors, msg)
  }
  
  return(errors)  
}



validate_json  <- function (env, field) {
  
  errors <- c()
  
  x <- env$df[[field]]
  
  is_json <- is.na(x) | sapply(x, jsonlite::validate)
  if (any(!is_json)) {
    bad_rows <- head(which(!is_json))
    msg <- "%s:%d: `%s` is not valid JSON: \"%s\""
    msg <- sprintf(msg, env$tbl, bad_rows + 1, field, x[bad_rows])
    errors <- c(errors, msg)
  }
  
  return(errors)  
}



validate_filename <- function (env, field) {
  
  errors <- c()
  
  x <- env$df[[field]]
  
  # Regex pattern definition:
  # ^               = Start of the string
  # [a-zA-Z0-9_.-]+ = One or more safe characters (alphanumeric, underscores, hyphens, dots)
  #                 = (This implicitly blocks paths like "/" or "\", spaces, and special characters)
  # \\.             = A literal dot separating the name from the extension
  # [a-zA-Z0-9]+    = One or more alphanumeric characters for the final extension
  # $               = End of the string
  pattern <- "^[a-zA-Z0-9_.-]+\\.[a-zA-Z0-9]+$"
  
  invalid <- !grepl(pattern, x)
  if (any(invalid)) {
    bad_rows <- head(which(invalid))
    msg <- "%s:%d: invalid `filename` \"%s\"."
    msg <- sprintf(msg, env$tbl, bad_rows + 1, x[bad_rows])
    errors <- c(errors, msg)
  }
  
  return(errors)  
}



validate_bioproject <- function (env, field) {
  
  x <- env$df[[field]]
  errors <- c()
    
  unique_ids <- unique(x)
  unique_ids <- unique_ids[!is.na(unique_ids)]
  
  if (length(unique_ids) > 0) {
    
    search_res <- rentrez::entrez_search(
      db     = "bioproject", 
      term   = paste0(unique_ids, "[Project Accession]", collapse = " OR "),
      retmax = length(unique_ids) )
    
    summaries <- list()
    if (length(search_res$ids) > 0)
      summaries <- rentrez::entrez_summary(
        db = "bioproject",
        id = search_res$ids,
        always_return_list = TRUE )
    
    valid_ids <- sapply(summaries, `[[`, 'project_acc')
    
    not_found <- !is.na(x) & !(x %in% valid_ids)
    if (any(not_found)) {
      bad_rows <- head(which(not_found))
      msg <- "%s:%d: cannot find `%s` \"%s\" in NCBI."
      msg <- sprintf(msg, env$tbl, bad_rows + 1, field, x[bad_rows])
      errors <- c(errors, msg)
    }
    
  }
  
  return(errors)  
}



validate_biosample <- function (env, field) {
  
  x <- env$df[[field]]
  errors <- c()
  
  if (length(i <- head(which(duplicated(x) & !is.na(x))))) {
    msg <- "%s:%d: `%s` is used by more than one sample: \"%s\""
    msg <- sprintf(msg, env$tbl, i + 1, field, x[i])
    errors <- c(errors, msg)
  }
  
  sql     <- 'SELECT `biosample_accession` FROM `biosamples`'
  current <- db_query(env$db, sql, 'ValBioS')
  
  if (length(i <- head(which(x %in% current & !is.na(x))))) {
    msg <- "%s:%d: `%s` is already assigned to another sample: \"%s\""
    msg <- sprintf(msg, env$tbl, i + 1, field, x[i])
    errors <- c(errors, msg)
  }
  
  unique_ids <- unique(x[!is.na(x)])
  valid_ids  <- c()
  
  # Query NCBI in batches to keep the request URLs short.
  for (ids in split(unique_ids, ceiling(seq_along(unique_ids) / 100))) {
    
    search_res <- rentrez::entrez_search(
      db     = "biosample", 
      term   = paste0(ids, "[accn]", collapse = " OR "),
      retmax = length(ids) )
    
    if (length(search_res$ids) > 0) {
      summaries <- rentrez::entrez_summary(
        db = "biosample",
        id = search_res$ids,
        always_return_list = TRUE )
      valid_ids <- c(valid_ids, sapply(summaries, `[[`, 'accession'))
    }
  }
  
  if (length(i <- head(which(!is.na(x) & !(x %in% valid_ids))))) {
    msg <- "%s:%d: cannot find `%s` \"%s\" in NCBI."
    msg <- sprintf(msg, env$tbl, i + 1, field, x[i])
    errors <- c(errors, msg)
  }
  
  return(errors)  
}
