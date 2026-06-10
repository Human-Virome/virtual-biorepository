

browse_allowlist <- c(
  'participants', 'events', 'samples', 'libraries',
  'analyses', 'files', 'biosamples', 'sra' )

api_browse <- function (db, table, page, size, sort, filter) {
  
  if (!isTRUE(table %in% browse_allowlist))
    stop("Invalid table name.")
  
  if (identical(table, 'biosamples'))
    biosamples_status_check(db)
  
  db_page(db, 'ApiBrow1', table, page, size, sort, filter)
}
