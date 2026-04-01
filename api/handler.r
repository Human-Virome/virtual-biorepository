
resp <- tryCatch(
  error = function (e) { list(error = e$message) },
  expr  = {

    # action should be the unprefixed function name
    handler_args <- c(GET, POST, FILES)
    action       <- handler_args[['action']]
    action       <- assert_string(action, 3, 20)
    stopifnot(grepl('^[a-z_]+$', action))

    # Find the api_* function and its incoming args.
    action_function <- get(paste0('api_', action))
    action_params   <- formalArgs(action_function)
    action_args     <- handler_args[action_params]

    if (length(missing_args <- setdiff(action_params, names(action_args))) > 0)
      stop(action, ' is missing argument(s): ', paste(collapse = ', ', missing_args))

    # Call the api_* function.
    do.call(action_function, action_args)
  }
)

setContentType("application/json")
cat(jsonlite::toJSON(resp, auto_unbox = TRUE, null = "null"))
OK
