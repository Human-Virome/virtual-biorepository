

browse_db_table <- function (db, table) {
  
  sql <- sprintf("SELECT * FROM `%s` WHERE `user` = @user", table)
  res <- db_query(db, final_sql, ec("ApiBrws"), simplify = FALSE)
  
  res$user   <- NULL
  res$hvp_id <- NULL
  
  return(list(data = res))
}

api_browse_participants <- function (db) { browse_db_table(db, 'participants') }
api_browse_events       <- function (db) { browse_db_table(db, 'events')       }
api_browse_samples      <- function (db) { browse_db_table(db, 'samples')      }
api_browse_analyses     <- function (db) { browse_db_table(db, 'analyses')     }
api_browse_files        <- function (db) { browse_db_table(db, 'files')        }
api_browse_sra          <- function (db) { browse_db_table(db, 'sra')          }
api_browse_biosamples   <- function (db) {
  biosamples_status_check(db)
  browse_db_table(db, 'biosamples')
}
