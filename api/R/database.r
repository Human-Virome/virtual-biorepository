
#______________________________________________________________________________
#' Wrapper around DBI's dbGetQuery and dbExecute.
#' 
#' @param db  DBI connection object.
#' @param sql  A single SQL statement to run.
#' @param err_code  A unique error code to emit if an error occurs.
#' @param params  A list of values for the statement's \code{?} placeholders.
#' @param simplify  Return single values or named arrays instead of data frames 
#'        whenever possible. (Default: TRUE)
#' @param req1  Generate an error unless the SELECT query matches exactly one row.
#'
#' @return A data.frame of the SELECT result, potentially simplified if 
#'         \code{simplify=TRUE}. For an INSERT, the new rowid. For SQL statements
#'         other than SELECT/INSERT, the value returned by \code{dbExecute()}.
db_query <- function (db, sql, err_code, params = NULL, simplify = TRUE, req1 = FALSE) {
  
  tryCatch(
    
    error = function (e)
      stop(
        "In db_query (", err_code, "): \n", e$message, "\n", sql, "\n\n", 
        "Params = ", jsonlite::toJSON(params, auto_unbox = TRUE) ), 
    
    expr = local({
      
      sql  <- trimws(gsub("[\n\r\t\ ]+", " ", sql))
      verb <- toupper(strsplit(substr(sql, 1, 10), ' ', fixed = TRUE)[[1]][[1]])
      if (!verb %in% c("SELECT", "INSERT", "UPDATE", "DELETE", "SET", "SHOW"))
        stop("Invalid SQL verb: '", verb, "'.")
      
      
      #________________________________________________________
      # Run the query/statement
      #________________________________________________________
      params <- if (length(params)) unname(params) else NULL
      result <- do.call(
        what = if (verb %in% c("SELECT", "SHOW")) DBI::dbGetQuery else DBI::dbExecute, 
        args = list(conn = db, statement = sql, params = params) )
      
      
      #________________________________________________________
      # For INSERT statements, the result is the new row_id
      #________________________________________________________
      if (verb == "INSERT")
        result <- tryCatch(
          error = function (e) stop("LAST_INSERT_ID():\n", e$message),
          expr  = DBI::dbGetQuery(db, "SELECT LAST_INSERT_ID()")[1,1]  )
      
      
      #________________________________________________________
      # Only concerned with SELECT output from here on down.
      #________________________________________________________
      if (verb != "SELECT") return (result)
      
      
      #________________________________________________________
      # Enforce req1 - Need exactly one result row.
      #________________________________________________________
      if (isTRUE(req1)) {
        if (nrow(result) == 0) stop("req1 - No matching rows found.")
        if (nrow(result) >= 2) stop("req1 - Too many results found.")
      }
      
      
      #________________________________________________________
      # Try to simplify the data.frame.
      #________________________________________________________
      if (isTRUE(simplify) && is.data.frame(result)) {
        if (nrow(result) == 0) return (NULL)
        if (ncol(result) == 1) return (result[[1]])
        if (nrow(result) == 1) return (as.list(result))
      }
      
      return (result)
      
    }))
}



# Append data frame's rows to mariadb table
db_append <- function (db, tbl, df, err_code) {
  columns      <- paste0("`", names(df), "`", collapse = ", ")
  placeholders <- paste0(rep("?", ncol(df)),  collapse = ", ")
  sql <- sprintf("INSERT INTO `%s` (%s) VALUES (%s)", tbl, columns, placeholders)
  db_query(db, sql, err_code, params = unname(as.list(df)))
}



# Format data for tabulator paging
db_page <- function (db, err_code, table, page, size, sort, filter, where = NULL) {
  
  page <- as.integer(page)
  size <- as.integer(size)
  stopifnot(
    isTRUE(page > 0),
    isTRUE(size > 0) )
  
  ec <- function (x) sprintf('%s -> %s', err_code, x)
  
  # Fetch valid columns for the requested table
  cols   <- db_query(db, sprintf("SHOW COLUMNS FROM `%s`", table), ec("DbPage1"), simplify = FALSE)
  fields <- setdiff(cols$Field, "user")
  
  sapply(sort, function (x) {
    stopifnot(
      isTRUE(x$field %in% fields),
      isTRUE(x$dir   %in% c("asc", "desc")) )})
  
  sapply(filter, function (x) {
    stopifnot(
      isTRUE(x$field %in% fields),
      isTRUE(x$type  %in% c("=", "!=", "<", ">", "<=", ">=", "like")) )})
  
  
  # Build WHERE Clause and Parameters
  where_clauses <- c("`user`=@user", where)
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
  total_rows <- db_query(db, count_sql, ec("DbPage2"), params)
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
  result_df <- db_query(db, final_sql, ec("DbPage3"), params, simplify = FALSE)
  
  # Clean up internal columns
  result_df$user <- NULL
  
  return (list(last_page = jsonlite::unbox(last_page), data = result_df))
}
