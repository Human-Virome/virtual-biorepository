
# returns row from `users` as a list
authenticate <- function (db, req) {
  
  oauth_email <- req$HTTP_X_FORWARDED_EMAIL
  oauth_uid   <- req$HTTP_X_FORWARDED_UID
  
  # If the headers are missing return an error
  if (!isTRUE(nzchar(email)) || !isTRUE(nzchar(uid)))
    stop("Unauthenticated session")
  
  
  sql <- 'SELECT * FROM users WHERE oauth_uid = ?'
  res <- db_query(db, sql, 'Auth1', list(oauth_uid))
  
  
  # First time logging into the Virtual Biorepository.
  if (is.null(res)) {
    
    sql <- 'INSERT INTO users (oauth_uid, oauth_email) VALUES (?, ?)'
    db_query(db, sql, 'Auth2', list(oauth_uid, oauth_email))
    
    sql <- 'SELECT * FROM users WHERE oauth_uid = ?'
    res <- db_query(db, sql, 'Auth3', list(oauth_uid))
  }
  
  # Logging in with a different email address than before.
  else if (!identical(tolower(res$oauth_email), tolower(oauth_email))) {
    
    sql <- 'UPDATE users SET oauth_email=? WHERE user_id=?'
    db_query(db, sql, 'Auth4', list(oauth_email, res$user_id))
    
    res$oauth_email <- oauth_email
  }
  
  sql <- 'UPDATE users SET last_login_utc=CURRENT_TIMESTAMP WHERE user_id=?'
  db_query(db, sql, 'Auth4', list(oauth_email, res$user_id))
  
  return (res)
}


api_whoami <- function (req) {
  
  db   <- pool::localCheckout(POOL)
  user <- authenticate(db, req)
  
  return (user)
}
