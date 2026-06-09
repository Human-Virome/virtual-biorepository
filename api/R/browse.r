

api_browse <- function (db, table, page, size, sort, filter, refresh) {
  
  stopifnot(isTRUE(table %in% c(names(DICT), c('biosamples', 'sra'))))
  
  if (identical(refresh, 'true'))
    switch(
      EXPR = table,
      'biosamples' = biosamples_status_check(db) )
  
  db_page(db, 'ApiBrow1', table, page, size, sort, filter)
}
