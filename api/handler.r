
# Initialize the global database connection pool. 
POOL <- pool::dbPool(
  drv      = RMariaDB::MariaDB(),
  dbname   = "hvp",
  host     = "localhost", 
  port     = 3306,
  user     = "hvp_local", 
  password = "",
  minSize  = 1, 
  maxSize  = 3 )


# Load all logic and endpoint functions.
invisible(sapply(list.files("R", pattern = "\\.r$", full.names = TRUE), source))


# Initialize the empty Plumber router.
pr <- plumber::pr()

pr <- plumber::pr_get(pr, '/req', handler = function (req) { req })


# Dynamically mount routes to functions starting with "api_".
for (fn in ls(pattern = "^api_")) {
  path <- sub('api_', '/api/', fn, fixed = TRUE)
  pr   <- plumber::pr_post(pr, path, handler = get(fn))
}
remove(list = intersect(ls(), c('fn', 'path')))


# Handle `stop()` by returning the error message.
pr <- plumber::pr_set_error(pr, fun = function (req, res, err) {
  res$status <- 200
  list(error = err$message)
})


# Clean up resources on exit.
pr <- plumber::pr_hook(pr, "exit", function () {
  pool::poolClose(POOL)
})


# Start the API.
plumber::pr_run(pr)
