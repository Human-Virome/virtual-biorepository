
# Load all logic and endpoint functions.
invisible(sapply(list.files("R", pattern = "\\.r$", full.names = TRUE), source))


# Define the httpuv application router
app <- list(
  call = function(req) {
    
    response <- tryCatch(
      # error = function (e) { return (list(error = unbox(as.character(e)))) },
      error = function (e) { return (list(error = unbox(e$message))) },
      expr  = local({
      
        # Sanity checks
        stopifnot(identical(req$REQUEST_METHOD, "POST"))
        stopifnot(startsWith(req$PATH_INFO, "/api/"))
        stopifnot(isTRUE(nzchar(req$HTTP_X_OAUTH_EMAIL)))
        
        args <- list()
        
        # Check if Nginx handed us a file path
        if (isTRUE(nzchar(req$HTTP_X_FILE_PATH))) {
          
          # Parse the URL's query string
          if (isTRUE(nzchar(req$QUERY_STRING)))
            args <- webutils::parse_query(req$QUERY_STRING)
          
          args$file <- req$HTTP_X_FILE_PATH
        }
        else {
          # Standard JSON/Form parsing for other API endpoints
          body <- req$rook.input$read()
          if (length(body))
            args <- webutils::parse_http(body, req$CONTENT_TYPE, simplifyVector = FALSE)
        }
        
        # Convert URL path to function name (e.g., /api/login -> api_login)
        api_fn <- req$PATH_INFO
        api_fn <-  sub("/", "",  api_fn, fixed = TRUE)
        api_fn <- gsub("/", "_", api_fn, fixed = TRUE)
        stopifnot(startsWith(api_fn, "api_"))
        stopifnot(exists(api_fn, mode = "function"))
        api_fun <- get(api_fn)
        
        # Connect to MariaDB
        if (hasName(formals(api_fun), 'db')) {
          
          args$db <- DBI::dbConnect(RMariaDB::MariaDB(), dbname = "vbr", port = 3306, user = "vbr")
          on.exit(DBI::dbDisconnect(args$db), add = TRUE)
          stopifnot(DBI::dbIsValid(args$db))
          
          attr(args$db, 'user') <- req$HTTP_X_OAUTH_EMAIL
          db_query(args$db, 'SET @user = ?;', 'SetEmail', list(req$HTTP_X_OAUTH_EMAIL))
        }
        
        # Confirm api function arguments
        exp <- paste(collapse = ",", sort(names(formals(api_fun))))
        rcv <- paste(collapse = ",", sort(names(args)))
        if (!identical(exp, rcv))
          stop(sprintf("%s expects (%s) but received (%s).", api_fn, exp, rcv))
        
        # Execute the dynamically resolved function
        response <- do.call(api_fun, args)
        
        stopifnot(is.list(response))
        return (response)
    }))
    
    gc(verbose = FALSE)
    
    # Construct list object expected by httpuv.
    list(
      status  = 200L,
      headers = list("Content-Type" = "application/json"),
      body    = jsonlite::toJSON(response, null = "null", na = "null") )
  }
)

# Start the API
port <- as.integer(Sys.getenv('HTTPUV_PORT', '8080'))
cat("Starting httpuv server on http://127.0.0.1:", port, sep = '')
httpuv::runServer(host = "127.0.0.1", port = port, app = app)
