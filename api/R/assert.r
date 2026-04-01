
read_worksheet <- function (wb, sheet) {
  if (!sheet %in% openxlsx2::wb_get_sheet_names(wb)) return (NULL)
  df <- openxlsx2::wb_to_df(wb, sheet, skip_empty_rows = TRUE, skip_empty_cols = TRUE)
  if (nrow(df) == 0) return (NULL)
  return (df)
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
