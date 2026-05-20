

api_browse <- function (db, table, page, size, sorters, filters) {
  
  page <- as.integer(page)
  size <- as.integer(size)
  
  stopifnot(
    isTRUE(page > 0),
    isTRUE(size > 0),
    isTRUE(table %in% names(DICT)) )
  
  fields <- names(DICT[[table]])
  
  sapply(sorters, function (x) {
    stopifnot(
      isTRUE(x$field %in% fields),
      isTRUE(x$dir   %in% c("asc", "desc")) )})
  
  sapply(filters, function (x) {
    stopifnot(
      isTRUE(x$field %in% fields),
      isTRUE(x$type  %in% c("=", "!=", "<", ">", "<=", ">=", "like")) )})
  
  
  # Build WHERE Clause and Parameters
  where_clauses <- c("`oauth_email`=@oauth_email")
  params <- list()
  
  for (f in filters) {
    where_clauses <- c(where_clauses, sprintf("`%s` %s ?", f$field, f$type))
    
    # Tabulator sends raw strings for 'like' searches; MySQL requires wildcards
    if (f$type == "like") {
      params <- append(params, paste0("%", f$value, "%"))
    } else {
      params <- append(params, f$value)
    }
  }
  
  where_sql <- paste("WHERE", paste(where_clauses, collapse = " AND "))
  
  # Calculate Total Pages (last_page) required by Tabulator
  count_sql  <- sprintf("SELECT COUNT(*) FROM `%s` %s", table, where_sql)
  total_rows <- db_query(db, count_sql, "Brws1")
  last_page  <- max(1L, as.integer(ceiling(total_rows / size)))
  
  # Build ORDER BY Clause
  order_sql <- ""
  if (length(sorters) > 0) {
    order_clauses <- sapply(sorters, function(s) sprintf("`%s` %s", s$field, s$dir))
    order_sql     <- paste("ORDER BY", paste(order_clauses, collapse = ", "))
  }
  
  # Build LIMIT/OFFSET Clause
  limit_sql <- sprintf("LIMIT %d OFFSET %d", size, (page - 1L) * size)
  
  # Execute Final Query
  final_sql <- paste(sprintf("SELECT * FROM `%s`", table), where_sql, order_sql, limit_sql)
  result_df <- db_query(db, final_sql, "Brws2", params, simplify = FALSE)
  
  # Clean up internal columns
  result_df$hvp_id      <- NULL
  result_df$oauth_email <- NULL
  
  list(last_page = jsonlite::unbox(last_page), data = result_df)
}
