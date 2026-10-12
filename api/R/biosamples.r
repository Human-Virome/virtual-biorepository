


# Use package Metagenome.environmental.1.0
# https://submit.ncbi.nlm.nih.gov/biosample/template/?package-0=Metagenome.environmental.1.0&action=definition

api_biosamples_assign <- function (db, hvp_ids) {

  hvp_ids <- unlist(hvp_ids)
  stopifnot(length(hvp_ids) > 0)
  
  # release_date <- as.character(strptime(release_date, format="%Y-%m-%d"))
  # if (is.na(release_date) || length(release_date) != 1)
  #   stop("Invalid `release_date`.")
  
  sql <- "
    SELECT b.*, s.complete 
    FROM biosamples b
    LEFT JOIN submissions s ON b.submission_hvp_id = s.hvp_id
    WHERE b.user = @user"
  res <- db_query(db, sql, 'ApiBiAs1', simplify = FALSE)

  res <- res[res[['hvp_id']] %in% hvp_ids,,drop=FALSE]
  attrs <- setdiff(names(res), c('user', 'hvp_id', 'submission_hvp_id', 'submission_error', 'biosample_accession', 'sample_name', 'organism', 'complete'))
  
  
  # Confirm validity of all the provided `sample_name`s.
  if (length(missing_hvp_ids <- setdiff(hvp_ids, res[['hvp_id']])))
    stop("`hvp_id`(s) missing from database: ", paste(collapse = ', ', missing_hvp_ids))
  
  # Accessions may come from our own submissions or be provided by the user.
  is_pending_or_success <- !is.na(res[['biosample_accession']]) | (!is.na(res[['submission_hvp_id']]) & (is.na(res[['complete']]) | res[['complete']] == 'no'))
  if (length(already_submitted <- res[['sample_name']][is_pending_or_success]))
    stop("Samples already have a BioSample accession (or are pending): ", paste(collapse = ', ', already_submitted))
  
  
  # Create the root node
  Submission <- xml2::xml_new_root(
    '.value'                        = "Submission",
    '.version'                      = "1.0",
    '.encoding'                     = "utf-8",
    'schema_version'                = "2.0", 
    'xmlns:xsi'                     = "http://www.w3.org/2001/XMLSchema-instance",
    'xsi:noNamespaceSchemaLocation' = "https://raw.githubusercontent.com/ncbi/submission-schema/refs/heads/master/common/submission.xsd" )
  
  add <- xml2::xml_add_child
  
  desc <- add(Submission, "Description")
  # add(desc, "Hold", release_date = release_date)
  
  org <- add(desc, "Organization", role="owner", type="consortium")
  add(org, "Name", "Human Virome Project")
  
  for (i in seq_len(nrow(res))) {
    
    Action     <- add(Submission, "Action")
    AddData    <- add(Action, "AddData", target_db = "BioSample")
    Data       <- add(AddData, "Data", content_type = "XML")
    XmlContent <- add(Data, "XmlContent")
    BioSample  <- add(XmlContent, "BioSample", schema_version = "2.0")
    
    SampleId <- add(BioSample, "SampleId")
    add(SampleId, "SPUID", spuid_namespace = "HVPCC", res[i,'sample_name'])
    
    Descriptor   <- add(BioSample, "Descriptor")
    ExternalLink <- add(Descriptor, "ExternalLink", label = "Human Virome Project")
    add(ExternalLink, "URL", "https://human-virome.org/")
    
    Organism <- add(BioSample, "Organism")
    add(Organism, "OrganismName", res[i,'organism'])
    
    add(BioSample, "Package", "Metagenome.environmental.1.0")
    
    Attributes <- add(BioSample, "Attributes")
    for (f in attrs)
      if (!is.na(res[i,f]))
        add(Attributes, "Attribute", attribute_name = f, res[i,f])
    
    Identifier <- add(AddData, "Identifier")
    add(Identifier, "SPUID", spuid_namespace = "HVPCC", res[i,'sample_name'])
    
  }
  
  
  username <- db_query(db, "SELECT @user", 'ApiBiAs2', req1 = TRUE)
  username <- strsplit(username, '@', fixed = TRUE)[[1]][[1]]
  username <- gsub("[^a-zA-Z0-9._]+", "_", username)
  
  
  cat(as.character(Submission))
  
  local_xml_file    <- tempfile(); on.exit(unlink(local_xml_file), add = TRUE)
  local_ready_file  <- tempfile(); on.exit(unlink(local_ready_file), add = TRUE)
  submission_name   <- paste0(Sys.Date(), "-", stringi::stri_rand_strings(1,6))
  remote_xml_file   <- paste0(NCBI_SUBMIT_DIR, submission_name, "/submission.xml")
  remote_ready_file <- paste0(NCBI_SUBMIT_DIR, submission_name, "/submit.ready")
  
  # Write to a formatted XML file on disk
  xml2::write_xml(Submission, local_xml_file)
  file.create(local_ready_file)


  # Claim the samples before uploading, all in one transaction.
  DBI::dbBegin(db)
  tryCatch(
    error = function (e) {
      DBI::dbRollback(db)
      stop(e$message)
    },
    expr = {

      df <- data.frame(submission_name = submission_name, submission_xml = as.character(Submission))
      db_insert(db, 'submissions', df, 'ApiBiAsInsert')

      sql <- "SELECT hvp_id FROM submissions WHERE user = @user AND submission_name = ?"
      submission_hvp_id <- db_query(db, sql, 'ApiBiAsId', list(submission_name), req1 = TRUE)

      # Resubmitting a failed sample also clears its old error.
      sql <- sprintf("
        UPDATE biosamples
        SET submission_hvp_id = ?, submission_error = NULL
        WHERE user = @user AND hvp_id IN (%s)",
        paste(rep("?", nrow(res)), collapse = ", ") )
      db_query(db, sql, 'ApiBiAs3', c(list(submission_hvp_id), as.list(res[['hvp_id']])))

      sftp_conn <- sftpR::sftp_connect(
        hostname = "sftp-private.ncbi.nlm.nih.gov",
        user     = Sys.getenv("NCBI_SFTP_USERNAME"),
        password = Sys.getenv("NCBI_SFTP_PASSWORD") )

      sftpR::sftp_upload(sftp_conn, local_xml_file, remote_xml_file, .create_dir = TRUE)
      sftpR::sftp_upload(sftp_conn, local_ready_file, remote_ready_file,  .create_dir = TRUE)

      DBI::dbCommit(db)
    })

  return (list())
}


# Whether a BioSample record can still change. "provided" ones hold just the
# user's own accession, and "submitted" ones are with NCBI (pending or
# accessioned). See `submission_status` in api_browse_biosamples().
BIOSAMPLE_STATE <- "
  CASE
    WHEN biosamples.submission_hvp_id IS NULL
      THEN IF(biosamples.biosample_accession IS NULL, 'editable', 'provided')
    WHEN biosamples.biosample_accession IS NOT NULL
      THEN 'submitted'
    WHEN biosamples.submission_error IS NULL AND submissions.complete = 'no'
      THEN 'submitted'
    ELSE 'editable'
  END"


# Adds BioSample records for the user's samples that don't have one yet.
biosamples_refresh <- function (env) {

  biosamples <- biosamples_derive(env$db, "biosamples.sample_name IS NULL AND samples.user = @user")

  # Samples with a user-provided BioSample accession only need a minimal
  # record, which prevents them from being submitted to NCBI by us.
  accession <- env$df[['biosample_id']][match(biosamples[['sample_name']], env$df[['sample_uid']])]
  if (any(has_acc <- !is.na(accession))) {
    minimal <- biosamples[has_acc, c('sample_name', 'host_subject_id', 'sampling_event_id'), drop = FALSE]
    minimal[['biosample_accession']] <- accession[has_acc]
    db_insert(env$db, 'biosamples', minimal, 'BioRefr2')
    biosamples <- biosamples[!has_acc, , drop = FALSE]
  }

  if (nrow(biosamples) > 0)
    db_insert(env$db, 'biosamples', biosamples_format(biosamples), 'BioRefr1')

  invisible()
}


# The BioSample record of each sample matching the SQL `where` condition, as
# derived from the sample and its participant and event. `_source` and
# `_hvp_id` identify the sample and its existing BioSample record, if any.
biosamples_derive <- function (db, where) {
  
  # Subsamples have a `parent_sample_uid` instead of an `event_uid`, so they
  # inherit the event of their parent (or grandparent). Composite samples with
  # multiple parents have no single event. Samples from multiple participants
  # have no single host subject, but keep `host` if their participants share a taxon.
  # An `event_uid` is only unique per participant, so events join on both.
  sql <- "
      SELECT
        samples.hvp_id                        as _source,
        biosamples.hvp_id                     as _hvp_id,
        %s                                    as _state,
        IF(samples.user = @user, NULL, samples.user) as _owner,
        samples.sample_uid                    as sample_name,
        participants.participant_uid          as host_subject_id,
        samples.anatomical_site               as host_tissue_sampled,
        samples.body_product                  as host_body_product,
        samples.collection_method             as collection_method,
        samples.collection_device             as samp_collect_device,
        samples.collection_date               as collection_date,
        samples.collection_month_year         as _collection_month_year,
        samples.negative_control_type         as neg_cont_type,
        samples.positive_control_type         as pos_cont_type,
        samples.sample_taxonomy               as organism,

        COALESCE(participants.taxon, (
          SELECT MIN(p.taxon) FROM participants AS p
          WHERE LOCATE(CONCAT(';', p.participant_uid, ';'), CONCAT(';', samples.participant_uid, ';')) > 0
          HAVING COUNT(DISTINCT p.taxon) = 1 )) as host,
        participants.race                       as race,
        participants.ethnicity                  as ethnicity,
        participants.sex_at_birth               as host_sex_at_birth,
        participants.family_medical_history     as medic_hist_perform,
        participants.mental_health_collected    as mental_health_collected,
        participants.medication_info_collected  as medication_info_collected,
        participants.alcohol_activity_collected as alcohol_activity_collected,
        participants.tobacco_use_collected      as tobacco_use_collected,
        participants.drug_use_collected         as drug_use_collected,

        participant_event_attributes.event_uid                      as sampling_event_id,
        COALESCE(participant_event_attributes.state_or_province_of_residence, 'not provided') as geo_loc_name,
        participant_event_attributes.converted_age_years            as host_age,
        participant_event_attributes.converted_height_cm            as host_height,
        participant_event_attributes.converted_weight_kg            as host_tot_mass,
        participant_event_attributes.bmi                            as host_body_mass_index,
        NULL                                                        as pet_farm_animal,
        participant_event_attributes.animal_exposure                as _animal_exposure,
        participant_event_attributes.exposure_animal_type           as _exposure_animal_type,
        participant_event_attributes.occupation                     as host_occupation,
        participant_event_attributes.cigarette_smoking              as smoker,
        participant_event_attributes.oral_health                    as oral_health_collected,
        participant_event_attributes.dental_exam                    as dental_exam,
        participant_event_attributes.current_geography              as current_geography,
        participant_event_attributes.diet                           as diet_collected,
        participant_event_attributes.wellness_information_available as wellness_collected,
        participant_event_attributes.social_determinants_of_health  as social_det_collected,
        participant_event_attributes.time_last_toothbrush           as time_last_toothbrush
        
      FROM samples
        LEFT JOIN biosamples                   ON biosamples.sample_name = samples.sample_uid
        LEFT JOIN submissions                  ON submissions.hvp_id     = biosamples.submission_hvp_id
        LEFT JOIN samples AS parent            ON parent.sample_uid      = samples.parent_sample_uid
        LEFT JOIN samples AS grandparent       ON grandparent.sample_uid = parent.parent_sample_uid
        LEFT JOIN participant_event_attributes ON participant_event_attributes.event_uid       = COALESCE(samples.event_uid, parent.event_uid, grandparent.event_uid)
                                              AND participant_event_attributes.participant_uid = samples.participant_uid
        LEFT JOIN participants           ON participants.participant_uid = samples.participant_uid

      WHERE %s"

  db_query(db, sprintf(sql, BIOSAMPLE_STATE, where), 'ApiBio1', simplify = FALSE)
}


# Converts biosamples_derive()'s values into the ones submitted to NCBI.
biosamples_format <- function (biosamples) {

  # Standardized (converted_*) values, e.g. "42.5 years".
  with_units <- function (x, units) {
    data.table::fifelse(is.na(x), 'not collected', paste(signif(x, 4), units))
  }
  biosamples[['host_age']]      <- with_units(biosamples[['host_age']],      'years')
  biosamples[['host_height']]   <- with_units(biosamples[['host_height']],   'cm')
  biosamples[['host_tot_mass']] <- with_units(biosamples[['host_tot_mass']], 'kg')

  biosamples[['smoker']] <- data.table::fcase(
    is.na(biosamples[['smoker']]),                                     'not collected',
    biosamples[['smoker']] == "non-smoker (<100 cigarettes lifetime)", 'no',
    default = 'yes' )

  # E.g. "yes;domestic;Canis lupus familiaris"
  biosamples[['pet_farm_animal']] <- local({
    exposure <- biosamples[['_animal_exposure']]
    animal   <- txid_to_name(biosamples[['_exposure_animal_type']])
    yes      <- apply(cbind('yes', exposure, animal), 1L, \(x) paste(na.omit(x), collapse = ';'))
    data.table::fcase(
      exposure %in% 'none',            'no',
      is.na(exposure) & is.na(animal), 'not collected',
      default = yes )
  })

  biosamples[['collection_date']] <- data.table::fcoalesce(
    biosamples[['collection_date']],
    biosamples[['_collection_month_year']],
    'not provided' )

  biosamples[['host']]     <- txid_to_name(biosamples[['host']])
  biosamples[['organism']] <- txid_to_name(biosamples[['organism']])

  tmp <- startsWith(names(biosamples), "_")
  biosamples[, !tmp, drop = FALSE]
}


# Brings BioSample records in line with changes made to the samples,
# participants, and events they're derived from. `before` is what
# biosamples_derive() returned, for existing records, before those changes.
biosamples_sync <- function (env, before) {

  if (nrow(before) == 0) return (invisible())

  after <- biosamples_derive(env$db, "TRUE")
  i     <- match(before[['_source']], after[['_source']])
  k     <- which(!is.na(i) & rows_differ(before, after[i, , drop = FALSE]))
  if (length(k) == 0) return (invisible())

  state  <- before[['_state']][k]
  hvp_id <- before[['_hvp_id']][k]
  owner  <- before[['_owner']][k]
  old    <- biosamples_format(before[k, , drop = FALSE])
  new    <- biosamples_format(after[i[k], , drop = FALSE])

  # Values that NCBI already has (or is processing) can no longer change.
  errors <- c()
  blank  <- function (x) ifelse(is.na(x), "", as.character(x))
  for (field in names(new)) {
    j      <- which(state == 'submitted' & rows_differ(old[field], new[field]))
    msg    <- "%s: Sample \"%s\"%s was submitted to NCBI, so its BioSample attribute `%s` cannot change from \"%s\" to \"%s\"."
    errors <- c(errors, sprintf(msg, env$tbl, old[['sample_name']][j], by_owner(owner[j]), field, blank(old[[field]][j]), blank(new[[field]][j])))
  }
  if (length(errors))
    stop(paste(head(errors), collapse = "\n"))

  j <- which(state == 'editable' & rows_differ(old, new))
  if (length(j))
    db_update(env$db, 'biosamples', new[j, , drop = FALSE], list(hvp_id = hvp_id[j]), 'BioSync1')

  # Records with a user-provided accession stay minimal.
  keys <- c('sample_name', 'host_subject_id', 'sampling_event_id')
  j    <- which(state == 'provided' & rows_differ(old[keys], new[keys]))
  if (length(j))
    db_update(env$db, 'biosamples', new[j, keys, drop = FALSE], list(hvp_id = hvp_id[j]), 'BioSync2')

  invisible()
}


# A `biosample_id` given to an existing sample replaces its BioSample record
# with a minimal one. A blank `biosample_id` leaves the record as it is.
biosamples_provide <- function (env) {

  sql <- "
    SELECT biosamples.sample_name, biosamples.biosample_accession, %s AS state
    FROM biosamples
      LEFT JOIN submissions ON submissions.hvp_id = biosamples.submission_hvp_id"
  current <- db_query(env$db, sprintf(sql, BIOSAMPLE_STATE), 'BioProv1', simplify = FALSE)

  accession <- env$df[['biosample_id']]
  i         <- match(env$df[['sample_uid']], current[['sample_name']])
  is_new    <- !is.na(accession) & !is.na(i) & !(accession == current[['biosample_accession']][i]) %in% TRUE
  if (!any(is_new)) return (invisible())

  if (length(j <- head(which(is_new & current[['state']][i] == 'submitted')))) {
    msg <- "%s:%d: `biosample_id` cannot be changed; sample \"%s\" was submitted to NCBI."
    stop(paste(sprintf(msg, env$tbl, j + 1, env$df[['sample_uid']][j]), collapse = "\n"))
  }

  # biosamples_refresh() adds the new record, and sra_sync_biosamples()
  # points the sample's SRA records at it.
  uids <- env$df[['sample_uid']][is_new]
  db_query(env$db, "UPDATE sra SET BioSample = NULL WHERE sample_name = ? AND BioSample IS NOT NULL", 'BioProv2', list(uids))
  db_query(env$db, "DELETE FROM biosamples WHERE sample_name = ?", 'BioProv3', list(uids))
  
  invisible()
}



# NCBI action statuses after which an action's report no longer changes.
FINAL_STATUSES <- c("processed-ok", "processed-error", "deleted", "failed")


# Reads an NCBI report.<N>.xml into the submission's status and, for each
# Action (one per BioSample), its SPUID, status, accession, and error.
ncbi_report_parse <- function (report_xml) {

  SubmissionStatus <- xml2::read_xml(report_xml)
  Actions          <- xml2::xml_find_all(SubmissionStatus, "Action")

  # Error messages, or all messages when none are errors.
  messages <- function (Messages) {
    is_error <- startsWith(xml2::xml_attr(Messages, "severity"), "error") %in% TRUE
    if (any(is_error)) Messages <- Messages[is_error]
    if (length(Messages) == 0) return (NA_character_)
    paste(trimws(xml2::xml_text(Messages)), collapse = "; ")
  }

  status        <- tolower(xml2::xml_attr(SubmissionStatus, "status"))
  message       <- messages(xml2::xml_find_all(SubmissionStatus, "Message"))
  action_status <- tolower(xml2::xml_attr(Actions, "status"))
  accession     <- xml2::xml_attr(xml2::xml_find_first(Actions, ".//Object[@accession]"), "accession")

  # Failed actions may lack an Object, but their action_id is
  # "<submission_id>-<spuid>", with the SPUID lowercased.
  spuid <- data.table::fcoalesce(
    xml2::xml_attr(xml2::xml_find_first(Actions, ".//Object[@spuid]"), "spuid"),
    sub("^SUB[0-9]+-", "", xml2::xml_attr(Actions, "action_id")) )

  # A finished action without an accession failed, perhaps for a reason
  # given only for the whole submission.
  error <- vapply(seq_along(Actions), function (i) {
    if (!action_status[[i]] %in% FINAL_STATUSES || !is.na(accession[[i]])) return (NA_character_)
    data.table::fcoalesce(
      messages(xml2::xml_find_all(Actions[[i]], ".//Message")),
      message,
      paste("NCBI status:", action_status[[i]]) )
  }, character(1))

  list(
    status   = status,

    # The submission is "processed-error" as soon as one action fails, even
    # while others are still processing.
    complete = status %in% c("failed", "deleted") ||
               (length(Actions) > 0 && all(action_status %in% FINAL_STATUSES)),

    message  = message,
    actions  = data.frame(spuid, status = action_status, accession, error) )
}



last_checked_at <- Sys.time()

# Records the BioSample accessions or errors in NCBI's reports for every
# pending submission, regardless of user (poor-man's cron job).
biosamples_status_check <- function (db) {

  # Throttle scraping NCBI's FTP server
  if (difftime(Sys.time(), last_checked_at, units = "secs") < 10) return (invisible())
  last_checked_at <<- Sys.time()

  sql     <- "SELECT hvp_id, submission_name FROM `submissions` WHERE complete = 'no'"
  pending <- db_query(db, sql, 'BioStChk1', simplify = FALSE)

  if (nrow(pending) == 0) return (invisible())

  # Not sftpR: it drops the trailing "/" from folder URLs, and NCBI's server
  # refuses to open a folder as a file.
  h <- curl::new_handle(
    userpwd        = paste0(Sys.getenv("NCBI_SFTP_USERNAME"), ":", Sys.getenv("NCBI_SFTP_PASSWORD")),
    ssh_auth_types = 2L,     # password
    dirlistonly    = TRUE,   # folder listings are just file names
    timeout        = 30L )

  # One unreadable report shouldn't hold up the rest.
  for (i in seq_len(nrow(pending)))
    tryCatch(
      error = function (e) message("Submission ", pending$submission_name[[i]], ": ", conditionMessage(e)),
      expr  = biosamples_status_update(db, h, pending$hvp_id[[i]], pending$submission_name[[i]]) )

  invisible()
}


biosamples_status_update <- function (db, h, submission_hvp_id, submission_name) {

  # NCBI adds report.1.xml, report.2.xml, ... as processing progresses.
  # There are none until NCBI picks up the submission.
  remote_dir <- paste0("sftp://sftp-private.ncbi.nlm.nih.gov/", NCBI_SUBMIT_DIR, submission_name, "/")
  listing    <- rawToChar(curl::curl_fetch_memory(remote_dir, handle = h)$content)
  reports    <- grep("^report(\\.[0-9]+)?\\.xml$", strsplit(listing, "\r?\n")[[1]], value = TRUE)
  if (length(reports) == 0) return (invisible())

  # report.xml is a link to the latest numbered report.
  report_n   <- suppressWarnings(as.integer(sub("^report\\.?([0-9]*)\\.xml$", "\\1", reports)))
  latest     <- reports[order(report_n, na.last = FALSE)][length(reports)]
  report_xml <- curl::curl_fetch_memory(paste0(remote_dir, latest), handle = h)$content
  report_xml <- as.character(xml2::read_xml(report_xml))
  report     <- ncbi_report_parse(report_xml)

  # Match case-insensitively, since SPUIDs from action IDs are lowercased.
  sql       <- "SELECT sample_name FROM biosamples WHERE submission_hvp_id = ?"
  samples   <- db_query(db, sql, 'BioStChk2', list(submission_hvp_id), simplify = FALSE)[['sample_name']]
  j         <- match(tolower(samples), tolower(report$actions$spuid))
  accession <- report$actions$accession[j]
  error     <- report$actions$error[j]

  # Once complete, every sample has either an accession or an error.
  if (report$complete)
    error[is.na(accession) & is.na(error)] <- data.table::fcoalesce(report$message, paste("NCBI status:", report$status))

  # The report and the samples it describes are recorded together, so an
  # unchanged report means there's nothing new.
  DBI::dbWithTransaction(db, {

    # Skip unchanged reports; every UPDATE adds a system-versioned history row.
    sql <- "
      UPDATE submissions
      SET report_xml = ?, report_timestamp = CURRENT_TIMESTAMP, complete = ?
      WHERE hvp_id = ? AND NOT (report_xml <=> ?)"
    complete <- if (report$complete) 'yes' else 'no'
    changed  <- db_query(db, sql, 'BioStChk3', list(report_xml, complete, submission_hvp_id, report_xml))

    k <- which(!is.na(accession) | !is.na(error))
    if (changed > 0 && length(k) > 0) {
      sql <- "
        UPDATE biosamples SET biosample_accession = ?, submission_error = ?
        WHERE sample_name = ? AND submission_hvp_id = ?"
      db_query(db, sql, 'BioStChk4', list(accession[k], error[k], samples[k], rep(submission_hvp_id, length(k))))
    }
  })

  invisible()
}



txid_to_name <- function (txids) {
  
  map <- c(
    `NCBI:txid1070528` = "viral metagenome", 
    `NCBI:txid9606`    = "Homo sapiens",
    `NCBI:txid10090`   = "Mus musculus" )
  
  # Multi-valued fields are semicolon-delimited, e.g. "NCBI:txid9615;NCBI:txid9685"
  splits  <- strsplit(txids, ";", fixed = TRUE)
  all_ids <- unique(unlist(splits))
  all_ids <- all_ids[!is.na(all_ids) & nzchar(all_ids)]

  if (!all(all_ids %in% names(map))) {
    query_ids  <- sub('NCBI:txid', '', setdiff(all_ids, names(map)), fixed = TRUE)
    search_res <- tryCatch(
      expr    = rentrez::entrez_summary(db = "taxonomy", id = query_ids, always_return_list = TRUE),
      error   = \(e) stop('Error looking up NCBI taxa ID.\n', e$message),
      warning = \(w) stop('Error looking up NCBI taxa ID.\n', w$message) )
    map <- c(map, setNames(
      object = rentrez::extract_from_esummary(search_res, "scientificname"),
      nm     = paste0('NCBI:txid', rentrez::extract_from_esummary(search_res, "taxid")) ))
  }

  vapply(splits, FUN.VALUE = character(1), \(x) {
    x <- x[!is.na(x) & nzchar(x)]
    if (length(x) == 0) NA_character_ else paste(map[x], collapse = ';')
  })
}

