


# Check for missing or extra fields.
# Ensure each required column is filled in.
validate_req_columns <- function (env) {
  
  errors <- c()
  
  # All the MariaDB table's column names
  sql    <- sprintf("DESC `%s`", env$tbl)
  desc   <- db_query(env$db, sql, 'ValReq1', simplify = FALSE)
  fields <- setdiff(desc[['Field']], c('hvp_id', 'user'))
  
  dict     <- DICT[[env$tbl]]
  required <- names(dict)[sapply(dict, `[[`, 'req') == "yes"]
    
  given   <- names(env$df)
  missing <- setdiff(required, given)
  invalid <- setdiff(given, fields)
  
  if (length(missing) > 0) {
    msg <- '%s: Required columns are missing: `%s`'
    msg <- sprintf(msg, env$tbl, paste(collapse = '`, `', missing))
    errors <- c(errors, msg)
  }
  if (length(invalid) > 0) {
    msg <- '%s: Unexpected columns are present: `%s`'
    msg <- sprintf(msg, env$tbl, paste(collapse = '`, `', invalid))
    errors <- c(errors, msg)
  }
  
  for (field in intersect(given, required)) {
    missing <- which(is.na(env$df[[field]])) + 1
    if (length(missing) > 0) {
      msg <- '%s: required `%s` values are missing on row(s) %s'
      msg <- sprintf(msg, env$tbl, field, paste(collapse = ', ', head(missing, 20)))
      errors <- c(errors, msg)
    }
  }
  
  # Add all the MariaDB columns to the data.frame
  for (add_col in setdiff(desc[['Field']], names(env$df)))
    env$df[[add_col]] <- NA_character_
  
  if (length(errors))
    stop(paste(errors, collapse = "\n"))
  invisible()  
}



# Converts
# From: "Dog [NCBI:txid9615]; Cat (Domestic) [NCBI:txid9685]"
# To:   "NCBI:txid9615;NCBI:txid9685"

reformat_ids <- function (env) {
  
  errors <- c()
  
  for (field in names(DICT[[env$tbl]])) {
    
    dict  <- DICT[[env$tbl]][[field]]
    fmt   <- unlist(dict[['fmt']])
    req   <- identical(dict[['req']], "yes")
    multi <- "multiple" %in% fmt
    if      ("uid"    %in% fmt) { prefixes <- UID_PREFIXES }
    else if ("prefix" %in% fmt) { prefixes <- unlist(dict[['prefix']]) }
    else                        { next }
    
    x <- env$df[[field]]
    
    # 1. Prefix and Regex Handling
    prefix_group  <- paste0("(", paste0(prefixes, collapse = "|"), ")")
    if      ("uid" %in% fmt)      { regex <- paste0(prefix_group, "[^;\\s]+")          }
    else if ("DB"  %in% prefixes) { regex <- paste0(prefix_group, "[a-zA-Z0-9_:\\-]+") }
    else                          { regex <- paste0(prefix_group, "[0-9]+")            }
    
    if ("mock" %in% fmt) { regex <- paste0("(mock|", regex ,")") }

    # 2. Identify empty records
    is_empty <- is.na(x)
    
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
    env$df[[field]][is_empty] <- NA
    
  }
  
  
  if (length(errors))
    stop(paste(errors, collapse = "\n"))
  invisible()  
}



validate_suffixes  <- function (env) {
  
  errors <- c()
  
  for (field in names(DICT[[env$tbl]])) {
    
    fmt  <- unlist(DICT[[env$tbl]][[field]][['fmt']])
    freq <- "freq" %in% fmt
    mode <- "mode" %in% fmt
    if (!(freq || mode)) next
    
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
    
  }
  
  if (length(errors))
    stop(paste(head(errors, n=20), collapse = "\n"))
  invisible()  
}



validate_cv  <- function (env) {
  
  errors <- c()
  
  for (field in names(DICT[[env$tbl]])) {
    
    cv <- unlist(DICT[[env$tbl]][[field]][['cv']])
    if (is.null(cv)) next
    
    invalid <- which(!(env$df[[field]] %in% c(cv, NA_character_)))
    
    if (length(invalid) > 0) {
      
      # 1. Normalize the Controlled Vocabulary: Make lowercase
      cv_norm <- stringi::stri_trans_tolower(cv)
      
      for (i in invalid) {
        user_val <- env$df[[field]][i]
        
        # 2. Normalize the user input identically
        val_norm <- stringi::stri_trans_tolower(stringi::stri_trans_general(user_val, "Latin-ASCII"))
        
        # 3. Wrap in Negative Lookarounds to prevent partial-word matching.
        # (?<!\\p{L}) ensures no letter precedes the match.
        # \\Q%s\\E    matches the inserted string literally.
        # (?!\\p{L})  ensures no letter follows the match.
        pattern <- sprintf("(?<!\\p{L})\\Q%s\\E(?!\\p{L})", val_norm)
        
        # 4. Detect matches in the normalized CV
        matches <- which(stringi::stri_detect_regex(cv_norm, pattern))
        
        # 5. If exactly one match is found, replace the environment value with the CORRECT case CV value
        if (length(matches) == 1) {
          env$df[[field]][i] <- cv[matches]
        }
      }
      
      # Re-evaluate invalid entries after the fuzzy matching attempt
      invalid <- which(!(env$df[[field]] %in% c(cv, NA_character_)))
      
      if (length(invalid) > 0) {
        bad_rows <- head(invalid)
        msg <- "%s:%d: `%s` doesn't match controlled vocabulary: \"%s\""
        msg <- sprintf(msg, env$tbl, bad_rows + 1, field, env$df[[field]][bad_rows])
        errors <- c(errors, msg)
      }
    }
  }
  
  
  if (length(errors))
    stop(paste(errors, collapse = "\n"))
  invisible()  
}



validate_numbers <- function (env) {
  
  errors <- c()
  
  for (field in names(DICT[[env$tbl]])) {
    
    fmt <- unlist(DICT[[env$tbl]][[field]][['fmt']])
    if (!any(c('number', 'integer') %in% fmt)) next
    
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
    
    if ('non-negative' %in% fmt) {
      is_neg <- which(x_num < 0 & is.finite(x_num))
      
      if (length(is_neg) > 0) {
        bad_rows <- head(is_neg)
        msg <- "%s:%d: `%s` cannot be negative: \"%s\""
        msg <- sprintf(msg, env$tbl, bad_rows + 1, field, x[bad_rows])
        errors <- c(errors, msg)
      }
    }
    
    env$df[[field]] <- x_num
  }
  
  if (length(errors))
    stop(paste(errors, collapse = "\n"))
  invisible()  
}



validate_dates <- function (env) {
  
  errors <- c()
  
  for (field in names(DICT[[env$tbl]])) {
    
    fmt <- unlist(DICT[[env$tbl]][[field]][['fmt']])
    ymd <- intersect(c('YYYY-MM', 'YYYY-MM-DD'), fmt)
    if (length(ymd) == 0) next
    
    x <- env$df[[field]]
    
    if (identical(ymd, 'YYYY-MM'))
      x[!is.na(x)] <- paste0(x[!is.na(x)], "-01")
    
    x_date   <- strptime(x, format="%Y-%m-%d")
    not_date <- which(!is.na(x) & is.na(x_date))
    
    if (length(not_date) > 0) {
      bad_rows <- head(not_date)
      msg <- "%s:%d: `%s` is not a valid %s date: \"%s\""
      msg <- sprintf(msg, env$tbl, bad_rows + 1, field, ymd, x[bad_rows])
      errors <- c(errors, msg)
    }
    
  }
  
  if (length(errors))
    stop(paste(errors, collapse = "\n"))
  invisible()  
}



validate_urls  <- function (env) {
  
  errors <- c()
  
  for (field in names(DICT[[env$tbl]])) {
    
    fmt <- unlist(DICT[[env$tbl]][[field]][['fmt']])
    if (!('url' %in% fmt)) next
    
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
    
  }
  
  if (length(errors))
    stop(paste(errors, collapse = "\n"))
  invisible()  
}



validate_md5  <- function (env) {
  
  errors <- c()
  
  for (field in names(DICT[[env$tbl]])) {
    
    fmt <- unlist(DICT[[env$tbl]][[field]][['fmt']])
    if (!('md5' %in% fmt)) next
    
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
    
  }
  
  if (length(errors))
    stop(paste(errors, collapse = "\n"))
  invisible()  
}



validate_keys <- function (env) {
  
  errors <- c()
  
  for (field in names(DICT[[env$tbl]])) {
    
    fmt <- unlist(DICT[[env$tbl]][[field]][['fmt']])
    if (!('primary' %in% fmt)) next
    
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
    
  }
  
  if (length(errors))
    stop(paste(errors, collapse = "\n"))
  invisible()  
}



validate_refs <- function (env) {
  
  errors <- c()
  
  for (field in names(DICT[[env$tbl]])) {
    
    fmt <- unlist(DICT[[env$tbl]][[field]][['fmt']])
    if (!('ref' %in% fmt)) next
    
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
    
  }
  
  if (length(errors))
    stop(paste(errors, collapse = "\n"))
  invisible()  
}



validate_file_names <- function (env) {
  
  errors <- c()
  
  if (hasName(env$df, 'file_uniq_name')) {
    
    # Regex pattern definition:
    # ^               = Start of the string
    # [a-zA-Z0-9_.-]+ = One or more safe characters (alphanumeric, underscores, hyphens, dots)
    #                 = (This implicitly blocks paths like "/" or "\", spaces, and special characters)
    # \\.             = A literal dot separating the name from the extension
    # [a-zA-Z0-9]+    = One or more alphanumeric characters for the final extension
    # $               = End of the string
    pattern <- "^[a-zA-Z0-9_.-]+\\.[a-zA-Z0-9]+$"
    
    invalid <- !grepl(pattern, env$df[['file_uniq_name']])
    if (any(invalid)) {
      bad_rows <- head(which(invalid))
      msg <- "%s:%d: invalid `file_uniq_name` \"%s\"."
      msg <- sprintf(msg, env$tbl, bad_rows + 1, env$df[['file_uniq_name']][bad_rows])
      errors <- c(errors, msg)
    }
    
  }
  
  if (length(errors))
    stop(paste(errors, collapse = "\n"))
  invisible()
}



validate_bioproject_ids <- function (env) {
  
  errors <- c()
  
  if (hasName(env$df, 'bioproject_id')) {
    
    unique_ids <- unique(env$df[['bioproject_id']])
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
      
      not_found <- !(env$df[['bioproject_id']] %in% valid_ids)
      if (any(not_found)) {
        bad_rows <- head(which(not_found))
        msg <- "%s:%d: cannot find `bioproject_id` \"%s\" in NCBI."
        msg <- sprintf(msg, env$tbl, bad_rows + 1, env$df[['bioproject_id']][bad_rows])
        errors <- c(errors, msg)
      }
      
    }
  }
  
  if (length(errors))
    stop(paste(errors, collapse = "\n"))
  invisible()
}



