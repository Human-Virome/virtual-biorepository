

browse_db_table <- function (db, table) {
  
  sql <- paste0(
    "SELECT *, ROW_START as `last_modified`",
    " FROM `", table, "`",
    " WHERE `user` = @user",
    " ORDER BY `last_modified` DESC" )
  res <- db_query(db, sql, "BrwsDb1", simplify = FALSE)
  
  res$user <- NULL
  
  return(list(data = res))
}

api_browse_participants <- function (db) { browse_db_table(db, 'participants') }
api_browse_events       <- function (db) { browse_db_table(db, 'events')       }
api_browse_samples      <- function (db) { browse_db_table(db, 'samples')      }
api_browse_libraries    <- function (db) { browse_db_table(db, 'libraries')    }
api_browse_analyses     <- function (db) { browse_db_table(db, 'analyses')     }
api_browse_files        <- function (db) { browse_db_table(db, 'files')        }
api_browse_sra          <- function (db) {
  biosamples_status_check(db)
  sra_sync_biosamples(db)
  browse_db_table(db, 'sra')
}
api_browse_biosamples   <- function (db) {
  biosamples_status_check(db)
  res <- browse_db_table(db, 'biosamples')

  # Each row shows the progress of the NCBI submission it is part of. Only
  # "not submitted" and "failed" rows can be submitted (again).
  sql <- "SELECT `hvp_id`, `complete`, `report_xml` FROM `submissions` WHERE `user` = @user"
  sub <- db_query(db, sql, "BrwsBio1", simplify = FALSE)

  # E.g. "queued" or "processing", or "submitted" until NCBI's first report.
  sub_status <- vapply(sub$report_xml, function (x) {
    if (is.na(x)) return ("submitted")
    tolower(xml2::xml_attr(xml2::read_xml(x), "status"))
  }, character(1), USE.NAMES = FALSE)

  # A pending "processed-error" submission has samples still processing.
  sub_status[sub_status == "processed-error"] <- "processing"

  df <- res$data
  i  <- match(df$submission_hvp_id, sub$hvp_id)
  df$submission_status <- data.table::fcase(
    !is.na(df$biosample_accession) & is.na(i), "provided",
    !is.na(df$biosample_accession),            "accessioned",
    is.na(i),                                  "not submitted",
    !is.na(df$submission_error),               "failed",
    sub$complete[i] == "yes",                  "failed",
    default = sub_status[i] )

  # Next to `sample_name`, which the grid pins.
  res$data <- df[, unique(c('hvp_id', 'sample_name', 'submission_status', names(df))), drop = FALSE]

  return (res)
}
