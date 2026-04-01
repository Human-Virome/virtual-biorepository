db_connect <- function (DATA_DIR) {
  
  db <- tryCatch(
    error = function (e) stop("Unable to connect to MySQL.\n", e$message),
    expr  = {
      DBI::dbConnect(
        drv    = RMariaDB::MariaDB(), 
        port   = 3306,
        user   = 'website',
        dbname = 'hvp' )
    })
  
  assert_dbi(db)
  return (db)
}


db_close <- function (db) {
  assert_dbi(db)
  tryCatch(
    error = function (e) stop("Unable to disconnect from MySQL.\n", e$message),
    expr  = DBI::dbDisconnect(db) )
}



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
        "In db_query (", err_code,"): \n", e$message, "\n", sql, "\n\n", 
        "Params = ", jsonlite::toJSON(params, auto_unbox = TRUE) ), 
    
    expr = local({
      
      
      sql  <- trimws(gsub("[\n\r\t\ ]+", " ", sql))
      verb <- toupper(strsplit(substr(sql, 1, 10), ' ', fixed = TRUE)[[1]][[1]])
      if (!verb %in% c("SELECT", "INSERT", "UPDATE", "DELETE", "BEGIN", "COMMIT"))
        stop("Invalid SQL verb: '", verb, "'.")
      
      
      #________________________________________________________
      # Run the query/statement
      #________________________________________________________
      result <- do.call(
        what = if (verb == "SELECT") DBI::dbGetQuery else DBI::dbExecute, 
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
      # Use column names to convert to boolean and POSIXct.
      #________________________________________________________
      for (k in colnames(result)) {
        if        (startsWith(k, "is_"))  { result[[k]] <- as.logical(result[[k]])
        } else if (startsWith(k, "has_")) { result[[k]] <- as.logical(result[[k]])
        } else if (endsWith(  k, "_utc")) { result[[k]] <- as.POSIXct(result[[k]], tz = "UTC") }
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
