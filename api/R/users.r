
# returns row from `users` as a list
authenticate <- function (db, auth_token) {
  
  assert_dbi(db)
  assert_string(auth_token, 100, 100)

  auth_token_sha <- as.character(openssl::sha512(auth_token))
  
  sql <- 'DELETE FROM auth_tokens WHERE valid_until_utc < UTC_TIMESTAMP'
  db_query(db, sql, 'Auth1')

  sql <- 'UPDATE auth_tokens'
  sql <- paste(sql, 'SET valid_until_utc = DATE_ADD(UTC_TIMESTAMP, INTERVAL 30 DAY)')
  sql <- paste(sql, 'WHERE auth_token_sha = ?')
  db_query(db, sql, 'Auth2', list(auth_token_sha))

  sql <- 'SELECT * FROM auth_tokens WHERE auth_token_sha = ?'
  res <- db_query(db, sql, 'Auth3', list(auth_token_sha))

  if (is.null(res)) stop('Session expired. Please log in again.')

  sql <- 'SELECT * FROM users WHERE user_id = ?'
  res <- db_query(db, sql, 'Auth4', list(res$user_id))

  return (res)
}


api_add_users <- function (auth_token, emails) {

  db <- db_connect()
  on.exit(db_close(db))

  user <- authenticate(db, auth_token)
  
  emails <- strsplit(emails, '\n', fixed = TRUE)[[1]]
  emails <- emails[nzchar(emails)]
  
  # Maximum emails per second that AWS allows us to send
  max_rate    <- as.numeric(Sys.getenv('SMTP_MAX_RATE', unset = '10'))
  emails_sent <- 0
  
  results <- lapply(emails, function (email) {
    
    tryCatch(
      error = function (e) e$message,
      expr  = {
        
        email    <- trimws(assert_string(email, 5, 100))
        if (!grepl('.+@.+\\..+', email)) stop('not an email address')

        sql <- 'SELECT * FROM users WHERE email = ?'
        res <- db_query(db, sql, 'CAcct1', list(trimws(tolower(email))))
        if (!is.null(res)) stop('account already exists')

        password <- random_string(20)
        sql      <- 'INSERT INTO users (email, password) VALUES (?, ?)'
        db_query(db, sql, 'CAcct2', list(tolower(email), bcrypt::hashpw(password) ))

        inviter <- ifelse(
          test = nzchar(user$full_name),
          yes  = sprintf('%s (%s)', user$full_name, user$email),
          no   = user$email )
        
        emails_sent <<- emails_sent + 1
        if (emails_sent %% max_rate == 0) Sys.sleep(1)
        
        send_email(
          to      = email, 
          subject = "Welcome to HVP's Virtual Biorepository!",
          message = sprintf(
            fmt = paste(
              sep = "<br><br>", 
              "%s has created an account for you at <https://hvp.jplab.net>.",
              "This website facilitates uploading metadata for the Human Virome Project, and exporting metadata formatted for SRA submissions.",
              "You can log in with the following credentials:",
              "Email Address: %s",
              "Password: %s" ), inviter, email, password ))
        
        'email sent'
      }
    )

  })
  
  message <- paste0(collapse = '\n', emails, ": ", unlist(results))

  return (list(message = message))
}


api_my_acct <- function (auth_token, full_name, affiliation) {

  assert_string(full_name,   3,   100)
  assert_string(affiliation, 3,   100)

  db <- db_connect()
  on.exit(db_close(db))

  user <- authenticate(db, auth_token)

  sql <- 'UPDATE users SET full_name = ?, affiliation = ? WHERE user_id = ?'
  db_query(db, sql, 'UAcct1', list(full_name, affiliation, user$user_id))
  
  return (list(
    full_name   = full_name,
    affiliation = affiliation,
    username    = if_empty(full_name, user[['email']]) ))
}


api_forgot_pw <- function (email) {

  assert_string(email, 3, 100)

  db <- db_connect()
  on.exit(db_close(db))

  sql <- 'SELECT * FROM users WHERE email = ?'
  res <- db_query(db, sql, 'RPass1', list(trimws(tolower(email))))

  if (is.null(res))
    stop('Email address not registered.')

  alt_password <- random_string(20)
  sql <- 'UPDATE users SET alt_password = ? WHERE user_id = ?'
  db_query(db, sql, 'RPass2', list(bcrypt::hashpw(alt_password), res$user_id))

  send_email(
    to      = res$email, 
    subject = "Password Reset",
    message = sprintf(paste(
      sep = "<br><br>", 
      "You can now log in with this alternate password: %s",
      "Once you log in using the alternate password, your old password will no longer work.",
      "<span style='font-size:11px; font-style:italic'>",
      "If you are not trying to reset your password, this email can be safely ignored.",
      "</span>"), alt_password ))
  
  
  message <- 'Check your email for your new password.'
  
  return (list(message = message))
}


api_token_login <- function (auth_token) {

  db <- db_connect()
  on.exit(db_close(db))

  tryCatch(
    error = function (e) list(auth_token = ''),
    expr  = {
      user <- authenticate(db, auth_token)
      list(
        full_name   = user[['full_name']],
        affiliation = user[['affiliation']], 
        username    = if_empty(user[['full_name']], user[['email']]) ) })
}


api_log_in <- function (email, password) {

  assert_string(email,    3, 100)
  assert_string(password, 3, 100)

  db <- db_connect()
  on.exit(db_close(db))

  sql  <- 'SELECT * FROM users WHERE email = ?'
  user <- db_query(db, sql, 'LIn1', list(trimws(tolower(email))))

  if (is.null(user))
    stop('Email address not registered.')


  # user is switching to a newly emailed password
  if (nzchar(user$alt_password) && bcrypt::checkpw(password, user$alt_password)) {

    sql <- 'UPDATE users SET password=alt_password WHERE user_id = ?'
    db_query(db, sql, 'LIn2', list(user$user_id))
    user$password <- user$alt_password
  
    sql <- 'UPDATE users SET alt_password="" WHERE user_id = ?'
    db_query(db, sql, 'LIn3', list(user$user_id))
    user$alt_password <- ''
  }


  if (!bcrypt::checkpw(password, user$password))
    stop('Incorrect password.')
  
  
  # user remembered their old password
  if (!nzchar(user$alt_password)) {
    sql <- 'UPDATE users SET alt_password="" WHERE user_id = ?'
    db_query(db, sql, 'LIn4', list(user$user_id))
  }

  # create a new auth_token
  auth_token     <- random_string(100)
  auth_token_sha <- as.character(openssl::sha512(auth_token))
  sql <- 'INSERT INTO auth_tokens (user_id, auth_token_sha, valid_until_utc)'
  sql <- paste(sql, 'VALUES (?, ?, DATE_ADD(UTC_TIMESTAMP, INTERVAL 30 DAY))')
  db_query(db, sql, 'LIn5', list(user$user_id, auth_token_sha))

  # update last login time
  sql <- 'UPDATE users SET last_login_utc=UTC_TIMESTAMP where user_id=?'
  db_query(db, sql, 'LIn6', list(user$user_id))

  return (list(
    auth_token  = auth_token,
    full_name   = user[['full_name']],
    affiliation = user[['affiliation']], 
    username    = if_empty(user[['full_name']], user[['email']]) ))
}


api_log_out <- function (auth_token) {

  assert_string(auth_token, 100, 100)

  db <- db_connect()
  on.exit(db_close(db))
  
  auth_token_sha <- as.character(openssl::sha512(auth_token))
  
  sql <- 'DELETE FROM auth_tokens WHERE auth_token_sha = ?'
  db_query(db, sql, 'LOut1', list(auth_token_sha))
  
  return (list(auth_token = ''))
}



assert_string <- function (str, min_len, max_len) {
  if (!is.character(str))   stop(substitute(str), ' must be a string')
  if (length(str) != 1)     stop(substitute(str), ' must be a string')
  if (is.na(str))           stop(substitute(str), ' must be a string')
  if (nchar(str) < min_len) stop(substitute(str), ' must be at least ', min_len, ' characters long')
  if (nchar(str) > max_len) stop(substitute(str), ' must be at most ',  max_len, ' characters long')
  invisible(str)
}


assert_dbi <- function (db) {
  if (!inherits(db, "DBIConnection"))
    stop('MySQL connection is class <', paste(collapse='/', class(db)), '>, not DBIConnection.')
  if (!DBI::dbIsValid(db)) stop('MySQL connection is not valid.')
  invisible(db)
}

random_string <- function (len) {
  paste(collapse = '', sample(c(LETTERS, letters, 0:9), len, replace = TRUE))
}

if_empty <- function (val, alt) {
  if (is.null(val))     return (alt)
  if (length(val) == 0) return (alt)
  if (nchar(val) == 0)  return (alt)
  return (val)
}
