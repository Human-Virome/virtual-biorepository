
# Downloads of a user's stored records, in the form that records are
# uploaded in. Each has its `hvp_id`, so that uploading an edited download
# updates the stored records.


# The selected records of one table, or all of its records when none are
# selected, as an Excel workbook with just that table's worksheet.
api_export_table <- function (db, table, hvp_ids) {

  stopifnot(isTRUE(table %in% names(DICT)))
  hvp_ids <- unlist(hvp_ids)

  df <- export_records(db, table)

  if (length(hvp_ids) > 0) {

    if (length(missing_hvp_ids <- setdiff(hvp_ids, df[['hvp_id']])))
      stop("`hvp_id`(s) missing from database: ", paste(collapse = ', ', missing_hvp_ids))

    df <- df[df[['hvp_id']] %in% hvp_ids, , drop = FALSE]
  }

  export_download(setNames(list(df), table), sprintf("vbr_%s_%s.xlsx", table, Sys.Date()))
}


# All of the user's records, as an Excel workbook like the upload template.
api_export_all <- function (db) {

  data <- sapply(names(DICT), simplify = FALSE, function (tbl) export_records(db, tbl))

  export_download(data, sprintf("vbr_metadata_%s.xlsx", Sys.Date()))
}


# An Excel workbook of the given tables' records, for the browser to save.
export_download <- function (data, filename) {

  file <- tempfile(fileext = ".xlsx"); on.exit(unlink(file), add = TRUE)
  export_excel(data, file)

  return (list(download = list(
    filename = unbox(filename),
    type     = unbox("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"),
    base64   = unbox(jsonlite::base64_enc(readBin(file, "raw", n = file.size(file)))) )))
}


# The user's records in a table, with the dictionary's fields plus `hvp_id`.
# Values are text, written as validate_table() expects to read them.
export_records <- function (db, tbl) {

  sql <- sprintf("SELECT * FROM `%s` WHERE `user` = @user ORDER BY 1, 2", tbl)
  df  <- db_query(db, sql, 'ExpRec1', simplify = FALSE)

  if (tbl == 'samples') {

    # A `biosample_id` is kept as its sample's BioSample record.
    sql      <- "SELECT sample_name, biosample_accession FROM biosamples WHERE submission_hvp_id IS NULL"
    provided <- db_query(db, sql, 'ExpRec2', simplify = FALSE)
    df[['biosample_id']] <- provided[['biosample_accession']][match(df[['sample_uid']], provided[['sample_name']])]

    # The day of the week is filled in from a known `collection_date`. Left
    # blank, it still will be after the user changes that date.
    df[['collection_day_of_week']][!is.na(df[['collection_date']])] <- NA
  }

  res <- list()
  for (field in names(DICT[[tbl]])) {

    fmt <- unlist(DICT[[tbl]][[field]][['fmt']])
    x   <- df[[field]]

    if (is.double(x)) x <- float_text(x)
    x <- as.character(x)

    # Blank values that were uploaded as one of these terms.
    if ("non-blank" %in% fmt) {
      x[x %in% ""] <- "none reported"
      x[is.na(x)]  <- "not collected"
    }
    if ("unavailable" %in% fmt)
      x[is.na(x)] <- "unavailable"

    res[[field]] <- x
  }
  res[['hvp_id']] <- df[['hvp_id']]

  as.data.frame(res, check.names = FALSE)
}


# The shortest decimal numbers that mariadb stores as the given FLOATs,
# e.g. "36.6" for 36.5999984741211.
float_text <- function (x) {

  res <- x
  for (digits in 9:6) {
    rounded <- signif(x, digits)
    is_same <- (as_float(rounded) == x) %in% TRUE
    res[is_same] <- rounded[is_same]
  }

  ifelse(is.na(res), NA_character_, formatC(res, digits = 15, format = "fg"))
}
