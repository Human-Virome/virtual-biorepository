
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
      if (!verb %in% c("SELECT", "INSERT", "UPDATE", "DELETE", "SET", "SHOW", "DESC"))
        stop("Invalid SQL verb: '", verb, "'.")
      
      
      #________________________________________________________
      # Run the query/statement
      #________________________________________________________
      params <- if (length(params)) unname(params) else NULL
      result <- do.call(
        what = if (verb %in% c("SELECT", "SHOW", "DESC")) DBI::dbGetQuery else DBI::dbExecute, 
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
  
  prefix <- switch(
    EXPR = tbl,
    'participants' = "hvp:p-",
    'events'       = "hvp:e-",
    'samples'      = "hvp:s-",
    'libraries'    = "hvp:l-",
    'analyses'     = "hvp:a-",
    'files'        = "hvp:f-",
    'biosamples'   = "hvp:b-",
    'sra'          = "hvp:r-",
    stop('bad table name') )
  
  # Generate 5 extra IDs in case of collisions.
  n <- nrow(df)
  new_ids <- stringi::stri_rand_strings(n + 5, 8)
  new_ids <- paste0(prefix, new_ids)
  
  # Avoid colliding with existing IDs.
  current <- db_query(db, sprintf('SELECT hvp_id FROM `%s`', tbl), 'CrHvId')
  new_ids <- setdiff(new_ids, current)[seq_len(n)]
  stopifnot(!anyNA(new_ids)) # Too many collisions (highly unlikely).
  
  df[['hvp_id']] <- new_ids
  df[['user']]   <- NULL
  
  colnames     <- paste0("`", names(df), "`", collapse = ", ")
  placeholders <- paste0(rep("?", ncol(df)),  collapse = ", ")
  fmt <- "INSERT INTO `%s` (%s, `user`) VALUES (%s, @user)"
  sql <- sprintf(fmt, tbl, colnames, placeholders)
  
  db_query(db, sql, err_code, params = unname(as.list(df)))
}



# Format data for AG Grid paging
db_page <- function (db, err_code, table, page, size, sort, filter, where = NULL) {
  
  page <- as.integer(page)
  size <- as.integer(size)
  stopifnot(
    isTRUE(page > 0),
    isTRUE(size > 0) )
  
  ec <- function (x) sprintf('%s -> %s', err_code, x)
  
  where     <- c("`user`=@user", where)
  order_sql <- ""
  params    <- list()
  
  # Only query db table structure when needed
  if (length(sort) > 0 || isTRUE(nzchar(trimws(filter)))) {
    
    # Fetch column information
    sql        <- sprintf("SHOW COLUMNS FROM `%s`", table)
    tbl_struct <- db_query(db, sql, ec("DbPage1"))
    
    # Assemble the ORDER BY clause
    if (length(sort) > 0) {
      
      stopifnot(
        isTRUE(all(names(sort)  %in% tbl_struct[['Field']])),
        isTRUE(all(unname(sort) %in% c("asc", "desc"))) )
      
      order_sql <- sprintf("`%s` %s", names(sort), unname(sort))
      order_sql <- paste(order_sql, collapse = ", ")
      order_sql <- paste("ORDER BY", order_sql)
    }
    
    # Add to the WHERE clause
    if (isTRUE(nzchar(trimws(filter)))) {
      
      fields <- tbl_struct[grep("varchar|text", tolower(tbl_struct$Type)), 'Field']
      fields <- setdiff(fields, 'user')
      
      if (length(fields) > 0) {
        like_exprs <- sprintf("`%s` LIKE ?", fields)
        where      <- c(where, sprintf("(%s)", paste(like_exprs, collapse = " OR ")))
        
        where_params <- rep(paste0("%", trimws(filter), "%"), length(fields))
        params       <- c(params, as.list(where_params))
      }
    }
  }
  
  # Assemble the WHERE and LIMIT BY clauses
  where_sql <- paste("WHERE", paste(where, collapse = " AND "))
  limit_sql <- sprintf("LIMIT %d OFFSET %d", size, (page - 1L) * size)
  
  # Calculate Total Pages (last_page) for frontend pagination matching
  count_sql  <- sprintf("SELECT COUNT(*) FROM `%s` %s", table, where_sql)
  total_rows <- db_query(db, count_sql, ec("DbPage2"), params)
  
  # Execute Final Paginated Query
  final_sql <- paste(sprintf("SELECT * FROM `%s`", table), where_sql, order_sql, limit_sql)
  result_df <- db_query(db, final_sql, ec("DbPage3"), params, simplify = FALSE)
  
  # Strip system columns before sending data down to client asset
  result_df$user   <- NULL
  result_df$hvp_id <- NULL
  
  return (list(
    total_rows = jsonlite::unbox(total_rows), 
    data       = result_df ))
}
