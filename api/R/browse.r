

api_browse <- function (db, table, page, size, sort, filter) {
  
  page <- as.integer(page)
  size <- as.integer(size)
  
  # Hard-coded list of tables the user can see.
  tables <- c(names(DICT), c('biosamples', 'sra'))
  
  stopifnot(
    isTRUE(page > 0),
    isTRUE(size > 0),
    isTRUE(table %in% tables) )
  
  # Fetch valid columns for the requested table
  cols   <- db_query(db, sprintf("SHOW COLUMNS FROM `%s`", table), "BrwsCol", simplify = FALSE)
  fields <- setdiff(cols$Field, "oauth_email")
  
  sapply(sort, function (x) {
    stopifnot(
      isTRUE(x$field %in% fields),
      isTRUE(x$dir   %in% c("asc", "desc")) )})
  
  sapply(filter, function (x) {
    stopifnot(
      isTRUE(x$field %in% fields),
      isTRUE(x$type  %in% c("=", "!=", "<", ">", "<=", ">=", "like")) )})
  
  
  # Build WHERE Clause and Parameters
  where_clauses <- c("`oauth_email`=@oauth_email")
  params <- list()
  
  for (f in filter) {
    where_clauses <- c(where_clauses, sprintf("`%s` LIKE ?", f$field))
    
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
  total_rows <- db_query(db, count_sql, "BrwsTtl", params)
  last_page  <- max(1L, as.integer(ceiling(total_rows / size)))
  
  # Build ORDER BY Clause
  order_sql <- ""
  if (length(sort) > 0) {
    order_clauses <- sapply(sort, function(s) sprintf("`%s` %s", s$field, s$dir))
    order_sql     <- paste("ORDER BY", paste(order_clauses, collapse = ", "))
  }
  
  # Build LIMIT/OFFSET Clause
  limit_sql <- sprintf("LIMIT %d OFFSET %d", size, (page - 1L) * size)
  
  # Execute Final Query
  final_sql <- paste(sprintf("SELECT * FROM `%s`", table), where_sql, order_sql, limit_sql)
  result_df <- db_query(db, final_sql, "BrwsReq", params, simplify = FALSE)
  
  # Clean up internal columns
  result_df$hvp_id      <- NULL
  result_df$oauth_email <- NULL
  
  list(last_page = jsonlite::unbox(last_page), data = result_df)
}
