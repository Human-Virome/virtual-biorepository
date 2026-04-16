
read_worksheet <- function (wb, sheet) {
  
  if (!sheet %in% openxlsx2::wb_get_sheet_names(wb)) return (NULL)
  df <- openxlsx2::wb_to_df(wb, sheet, skip_empty_rows = TRUE, skip_empty_cols = TRUE)
  if (nrow(df) == 0) return (NULL)
  
  # Normalize the column headers
  nms <- colnames(df)
  nms <- tolower(gsub(' ', '_', trimws(nms)))
  colnames(df) <- nms
  
  # Remove leading/trailing whitespace
  for (i in seq_len(ncol(df)))
    if (is.character(df[[i]]))
      df[[i]] <- trimws(df[[i]])
  
  # Combine duplicate columns
  if (any(duplicated(nms))) {
    merged <- df[,!duplicated(nms),drop=FALSE]
    for (nm in nms) {
      indices <- which(nms == nm)
      if (length(indices) > 1) {
        cols <- as.list(df[,indices,drop=FALSE])
        merged[[nm]] <- do.call(paste, c(cols, sep = '; '))
      }
    }
    df <- merged
  }
  
  return (df)
}


assert_ids_do_exist <- function (db, tbl, col, ids) {
  sql     <- sprintf("SELECT `%s` FROM `%s`", col, tbl)
  missing <- setdiff(ids[nzchar(ids)], db_query(db, sql, 'Asrt1'))
  if (length(missing) > 0) {
    msg <- 'The following IDs must first be added to `%s`: %s'
    msg <- sprintf(msg, tbl, paste(collapse = '`, `', missing))
    stop(msg)
  }
}

assert_ids_do_not_exist <- function (db, tbl, col, ids) {
  sql     <- sprintf("SELECT `%s` FROM `%s`", col, tbl)
  present <- intersect(ids[nzchar(ids)], db_query(db, sql, 'Asrt2'))
  if (length(present) > 0) {
    msg <- 'The following IDs already exist in `%s`: %s'
    msg <- sprintf(msg, tbl, paste(collapse = '`, `', present))
    stop(msg)
  }
}

assert_colnames <- function (present, required, optional) {
  missing <- setdiff(required, present)
  invalid <- setdiff(present, c(required, optional))
  if (length(missing) > 0) {
    msg <- 'Required columns are missing: `%s`'
    msg <- sprintf(msg, paste(collapse = '`, `', missing))
    stop(msg)
  }
  if (length(invalid) > 0) {
    msg <- 'Unexpected columns are present: `%s`'
    msg <- sprintf(msg, paste(collapse = '`, `', invalid))
    stop(msg)
  }
}


assert_columns <- function (df, sheet, nms) {
  missing <- setdiff(nms, colnames(df))
  if (length(missing) > 0) {
    msg <- 'Columns are missing from the `%s` worksheet: `%s`'
    msg <- sprintf(msg, sheet, paste(collapse = '`, `', missing))
    stop(msg)
  }
}


assert_req_columns <- function (df, sheet, nms) {
  assert_columns(df, sheet, nms)
  for (nm in nms) {
    missing <- which(!nzchar(trimws(df[[nm]]))) + 1
    if (length(missing) > 0) {
      msg <- paste(
        'On the `%s` worksheet, column `%s` is required.\n',
        'Values are missing for `%s` on rows %s.')
      msg <- sprintf(msg, sheet, nm, nm, paste(collapse = '`, `', head(missing, 20)))
      stop(msg)
    }
  }
}
