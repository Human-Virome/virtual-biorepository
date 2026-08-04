


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
      x <- gsub(";+", ";", apply(env$df[, i, drop = FALSE], 1L, paste, collapse = ";"))
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

  for (field in dict_fields) {
    for (f in unlist(dict[[field]][['fmt']])) {
      errors <- c(errors, switch(f,
        'required'   = validate_required(env, field),
        'condition'  = validate_condition(env, field),
        'assert'     = validate_assert(env, field),
        'uid'        = validate_identifier(env, field),
        'ontology'   = validate_identifier(env, field),
        'cv'         = validate_cv(env, field),
        'primary'    = validate_primary(env, field),
        'ref'        = validate_ref(env, field),
        'protocol'   = validate_protocol(env, field),
        'suffix'     = validate_suffix(env, field),
        'number'     = validate_number(env, field),
        'date'       = validate_date(env, field),
        'md5'        = validate_md5(env, field),
        'json'       = validate_json(env, field),
        'url'        = validate_url(env, field),
        'file'       = validate_file(env, field),
        'non-blank'  = validate_nonblank(env, field),
        'bioproject' = validate_bioproject(env, field),
        NULL
      ))
    }
  }

  if (length(errors))
    stop(paste(errors, collapse = "\n"))
  invisible()  
}



validate_required <- function (env, field) {
  
  errors <- c()

  is_na <- is.na(env$df[[field]])
  if (!any(is_na)) {
    bad_rows <- head(which(is_na))
    msg      <- "%s:%d: `%s` is required."
    msg      <- sprintf(msg, env$tbl, bad_rows + 1, field)
    errors   <- c(errors, msg)
  }

  return(errors)  
}



validate_condition <- function (env, field) {

  errors <- c()

  conditions <- DICT[[env$tbl]][[field]][['condition']]
  if (length(conditions) == 1) return (errors)

  failing <- is.na(env$df[[field]])

  for (check in setdiff(names(conditions), "description")) {

    if (check == "when_true") {
      target  <- names(conditions[[check]])
      pattern <- unname(conditions[[check]])
      failing <- failing & grepl(pattern, env$df[[target]])
    }
    else if (check == "when_false") {
      target  <- names(conditions[[check]])
      pattern <- unname(conditions[[check]])
      failing <- failing & !grepl(pattern, env$df[[target]])
    }
    else if (check == "when_set") {
      target  <- unname(conditions[[check]])
      failing <- failing & !is.na(env$df[[target]])
    }
    else if (check == "when_unset") {
      target  <- unname(conditions[[check]])
      failing <- failing & is.na(env$df[[target]])
    }
    else {
      stop("Unknown condition check: ", check)
    }
    
  }

  if (any(failing)) {
    bad_rows <- head(which(failing))
    msg      <- "%s:%d: %s"
    msg      <- sprintf(msg, env$tbl, bad_rows + 1, conditions[['description']])
    errors   <- c(errors, msg)
  }


  return(errors)  
}



validate_assert <- function (env, field) {

  errors <- c()

  asserts   <- DICT[[env$tbl]][[field]][['assert']]
  has_field <- !is.na(env$df[[field]])

  for (check in names(asserts)) {

    target     <- asserts[[check]]
    has_target <- !is.na(env$df[[target]])

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



# Converts
# From: "Dog [NCBI:txid9615]; Cat (Domestic) [NCBI:txid9685]"
# To:   "NCBI:txid9615;NCBI:txid9685"
validate_identifier <- function (env, field) {
  
  errors <- c()
  
  dict  <- DICT[[env$tbl]][[field]]
  fmt   <- unlist(dict[['fmt']])
  req   <- "required" %in% fmt
  multi <- "multiple" %in% fmt

  if ("ontology" %in% fmt) { prefixes <- unlist(dict[['ontology']]) }
  else                     { prefixes <- UID_PREFIXES               } 
  
  x <- env$df[[field]]
  
  # 1. Prefix and Regex Handling
  prefix_group  <- paste0("(", paste0(prefixes, collapse = "|"), ")")
  if      ("uid" %in% fmt)      { regex <- paste0(prefix_group, "[^;\\s]+")          }
  else if ("DB"  %in% prefixes) { regex <- paste0(prefix_group, "[a-zA-Z0-9_:\\-]+") }
  else                          { regex <- paste0(prefix_group, "[0-9]+")            }

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
    is_missing  <- (req & is_empty) | (!is_empty & n_matches == 0)
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
      if (is_empty[i]) return(isTRUE(req))
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
  if (any(is_missing)) {
    bad_rows <- head(which(is_missing))
    msg <- "%s:%d: missing or invalid `%s` identifier: \"%s\""
    msg <- sprintf(msg, env$tbl, bad_rows + 1, field, x[bad_rows])
    errors <- c(errors, msg)
  }
  
  if (any(is_too_many)) {
    bad_rows <- head(which(is_too_many))
    msg <- "%s:%d: multiple `%s` identifiers: \"%s\""
    msg <- sprintf(msg, env$tbl, bad_rows + 1, field, x[bad_rows])
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
  
  current   <- db_query(env$db, sprintf('SELECT `%s` FROM `%s`', field, env$tbl), 'ValKey')
  conflicts <- which(x %in% current)
  duplicate <- which(duplicated(x) & !is.na(x))
  
  if (length(conflicts) > 0) {
    bad_rows <- head(conflicts)
    msg <- "%s:%d: `%s` already exists in database: %s"
    msg <- sprintf(msg, env$tbl, bad_rows + 1, field, x[bad_rows])
    errors <- c(errors, msg)
  }
  
  if (length(duplicate) > 0) {
    bad_rows <- head(duplicate)
    msg <- "%s:%d: `%s` appears more than once: %s"
    msg <- sprintf(msg, env$tbl, bad_rows + 1, field, x[bad_rows])
    errors <- c(errors, msg)
  }
  
  return(errors)   
}



validate_ref <- function (env, field) {
  
  errors <- c()
  
  x <- env$df[[field]]
  
  ref_table <- names(DICT[[env$tbl]][[field]][['ref']])[[1]]
  ref_field <- DICT[[env$tbl]][[field]][['ref']][[ref_table]]
  current   <- db_query(env$db, sprintf('SELECT `%s` FROM `%s`', ref_field, ref_table), 'ValRef')
  
  if (identical(ref_table, env$tbl))
    current <- c(current, env$df[[ref_field]])
  
  for (i in which(!is.na(x))) {
    
    ids <- strsplit(x[[i]], ';', fixed = TRUE)[[1]]
    is_missing <- which(!(ids %in% current))
    
    if (length(is_missing) > 0) {
      bad_ids <- head(is_missing)
      msg <- "%s:%d: `%s` does not exist: \"%s\""
      msg <- sprintf(msg, env$tbl, i, field, ids[bad_ids])
      errors <- c(errors, msg)
    }
  }
  
  return(errors)  
}



validate_protocol <- function (env, field) {
  
  errors <- c()

  if (is.null(env$protocols)) {
    env$protocols <- local({
      sql <- "SELECT `protocol_uid`, `applications` FROM `protocols`"
      res <- db_query(env$db, sql, 'ValPro')
      
      application_sets <- strsplit(res[['applications']], ';')
      applications     <- unlist(application_sets)
      protocol_uids    <- rep(df[['protocol_uid']], sapply(application_sets, length))

      protocols <- sapply(
        X        = unique(applications), 
        simplify = FALSE, 
        FUN      = function (application) {
          protocol_uids[applications == application]
      })

      return (protocols)
    })
  }
  
  application <- DICT[[env$tbl]][[field]][['protocol']]
  protocols   <- c(env$protocols[[application]], NA)
  
  x <- env$df[[field]]
  
  if (length(i <- which(!(x %in% protocols)))) {
    i      <- i[head(which(!duplicated(x[i])))]
    a      <- ifelse(substr(application, 1, 1) %in% c('a', 'e'), 'an', 'a')
    msg    <- "%s:%s:%d: \"%s\" is not %s %s protocol"
    msg    <- sprintf(msg, env$tbl, field, i + 1, x[i], a, application)
    errors <- c(errors, msg)
  }
  
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
    env$df[[field]] <- gsub("[\\s;]+", ";", env$df[[field]])
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



validate_date <- function (env, field) {
  
  errors <- c()
  
  x <- env$df[[field]]
  
  is_ymd_fmt <- (!is.na(x) | grepl("^[0-9]{4}\\-[0-9]{2}(|\\-[0-9]{2})$", x))
  if (any(!is_ymd_fmt)) {
    bad_rows <- head(which(!is_ymd_fmt))
    msg <- "%s:%d: `%s` has invalid date format: \"%s\""
    msg <- sprintf(msg, env$tbl, bad_rows + 1, field, x[bad_rows])
    errors <- c(errors, msg)
  }
  
  x_full  <- ifelse(nchar(x) == 7, paste0(x, "-01"), x)
  x_full  <- strptime(x_full, format="%Y-%m-%d")
  is_date <- is.na(x) | !is.na(x_full)
  
  if (any(!is_date)) {
    bad_rows <- head(which(!is_date))
    msg <- "%s:%d: `%s` is not a real %s date: \"%s\""
    msg <- sprintf(msg, env$tbl, bad_rows + 1, field, ymd, x[bad_rows])
    errors <- c(errors, msg)
  }

  max_date <- Sys.Date()
  min_date <- max_date - 100*365.25 # 100 years
  oob_dates <- x_full > max_date | x_full < min_date
  if (any(oob_dates)) {
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
  if (length(urls) == 0) next
  
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
    
    not_found <- !(x %in% valid_ids)
    if (any(not_found)) {
      bad_rows <- head(which(not_found))
      msg <- "%s:%d: cannot find `bioproject_id` \"%s\" in NCBI."
      msg <- sprintf(msg, env$tbl, bad_rows + 1, x[bad_rows])
      errors <- c(errors, msg)
    }
    
  }
  
  return(errors)  
}



