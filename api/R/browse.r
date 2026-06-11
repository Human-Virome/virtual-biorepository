

browse_allowlist <- c(
  'participants', 'events', 'samples', 'libraries',
  'analyses', 'files', 'biosamples', 'sra' )

api_browse <- function (db, table, page, size, sort, filter) {
  
  if (!isTRUE(table %in% browse_allowlist))
    stop("Invalid table name.")
  
  if (identical(table, 'biosamples'))
    biosamples_status_check(db)
  
  sql <- sprintf("SELECT * FROM `%s` WHERE `user` = @user", table)
  res <- db_query(db, final_sql, ec("ApiBrws"), simplify = FALSE)
  
  res$user   <- NULL
  res$hvp_id <- NULL
  
  return(list(data = res))
}
