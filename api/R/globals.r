
# Global functions
unbox <- jsonlite::unbox

stri_extract_all <- stringi::stri_extract_all
stri_flatten     <- stringi::stri_flatten
stri_join_list   <- stringi::stri_join_list



# Converts
# From: "Dog [NCBI:txid9615]; Cat (Domestic) [NCBI:txid9685]"
# To:   "NCBI:txid9615; NCBI:txid9685"

format_ids <- function (env, field, regex, req = TRUE, multi = TRUE) {
  
  if (!hasName(env, field)) stop(field, ' is missing.')
  
  matches <- stri_extract_all(str = env[[field]], regex = regex)
  n       <- sapply(matches, function (x) sum(!is.na(x)))
  
  if (isTRUE(req) && length(missing <- which(n == 0) + 1)) {
    msg <- "Missing or invalid %s identifier on row(s) %s"
    stop(sprintf(msg, field, stri_flatten(head(missing, 20), ", ")))
  }
  if (!isTRUE(multi) && length(toomany <- which(n > 1) + 1)) {
    msg <- "Multiple %s identifiers on row(s) %s"
    stop(sprintf(msg, field, stri_flatten(head(toomany, 20), ", ")))
  }
  
  result <- stri_join_list(matches, ';')
  result[is.na(result)] <- ""
  
  env[[field]] <- result
  
  invisible(NULL)
}



match_cv <- function (env, field, cv) {
  
  if (!hasName(env, field)) stop(field, ' is missing.')
  
  invalid <- which(!(env[[field]] %in% cv))
  
  if (length(invalid) > 0) {
    
    # 1. Normalize the Controlled Vocabulary: Make lowercase
    cv_norm <- stri_trans_tolower(cv)
    
    for (i in invalid) {
      user_val <- env[[field]][i]
      
      # 2. Normalize the user input identically
      val_norm <- stri_trans_tolower(stri_trans_general(user_val, "Latin-ASCII"))
      
      # 3. Escape any regex characters in the user string (e.g., if they typed a parenthesis)
      val_escaped <- stri_escape_regex(val_norm)
      
      # 4. Wrap in Negative Lookarounds to prevent partial-word matching.
      # (?<!\\p{L}) ensures no letter precedes the match.
      # (?!\\p{L})  ensures no letter follows the match.
      pattern <- sprintf("(?<!\\p{L})%s(?!\\p{L})", val_escaped)
      
      # 5. Detect matches in the normalized CV
      matches <- which(stri_detect_regex(cv_norm, pattern))
      
      # 6. If exactly one match is found, replace the environment value with the CORRECT case CV value
      if (length(matches) == 1) {
        env[[field]][i] <- cv[matches]
      }
    }
    
    # Re-evaluate invalid entries after the fuzzy patching attempt
    invalid <- which(!(env[[field]] %in% cv))
    
    if (length(invalid) > 0) {
      msg <- "%s doesn't match controlled vocabulary on row(s) %s"
      stop(sprintf(msg, field, stri_flatten(head(invalid + 1, 20), ", ")))
    }
  }
  
  
  invisible(NULL)
}
