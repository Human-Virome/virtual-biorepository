

assert_ids_do_exist <- function (db, tbl, col, ids) {
  sql     <- sprintf("SELECT `%s` FROM `%s`", col, tbl)
  missing <- setdiff(ids[nzchar(ids)], db_query(db, sql, 'Asrt1'))
  if (length(missing) > 0) {
    msg <- '\n\tThe following ID(s) must first be added to the %s table:\n\t %s'
    msg <- sprintf(msg, tbl, paste(collapse = ', ', missing))
    stop(msg)
  }
}

assert_ids_do_not_exist <- function (db, tbl, col, ids) {
  sql     <- sprintf("SELECT `%s` FROM `%s`", col, tbl)
  present <- intersect(ids[nzchar(ids)], db_query(db, sql, 'Asrt2'))
  if (length(present) > 0) {
    msg <- 'The following ID(s) already exist: %s'
    msg <- sprintf(msg, paste(collapse = '`, `', present))
    stop(msg)
  }
}
