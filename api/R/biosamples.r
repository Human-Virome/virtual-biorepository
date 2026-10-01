


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
  remote_xml_file   <- paste0("submit/Test/", submission_name, "/submission.xml")
  remote_ready_file <- paste0("submit/Test/", submission_name, "/submit.ready")
  
  # Write to a formatted XML file on disk
  xml2::write_xml(Submission, local_xml_file)
  file.create(local_ready_file)


  # Claim the samples before uploading, all in one transaction. A concurrent
  # request for the same samples (e.g. a double-click reaching both httpuv
  # workers) waits on these row locks, then finds them already claimed.
  # READ COMMITTED lets that waiting UPDATE see the other request's claim,
  # rather than failing with "Record has changed since last read". (The
  # connection only lives for this request.)
  db_query(db, "SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED", 'ApiBiAsIso')
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
        UPDATE biosamples b
          LEFT JOIN submissions s ON s.hvp_id = b.submission_hvp_id
        SET b.submission_hvp_id = ?, b.submission_error = NULL
        WHERE b.user = @user
          AND b.hvp_id IN (%s)
          AND b.biosample_accession IS NULL
          AND (b.submission_hvp_id IS NULL OR s.complete = 'yes')",
        paste(rep("?", nrow(res)), collapse = ", ") )
      claimed <- db_query(db, sql, 'ApiBiAs3', c(list(submission_hvp_id), as.list(res[['hvp_id']])))

      if (!isTRUE(claimed == nrow(res)))
        stop("Some of these samples were just submitted by another request. Refresh the page to see their status.")

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


biosamples_refresh <- function (env) {
  
  # Subsamples have a `parent_sample_uid` instead of an `event_uid`, so they
  # inherit the event of their parent (or grandparent). Composite samples with
  # multiple parents have no single event. Samples from multiple participants
  # have no single host subject, but keep `host` if their participants share a taxon.
  sql <- "
      SELECT
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
        participants.race                     as race,
        participants.ethnicity                as ethnicity,
        participants.sex_at_birth             as host_sex_at_birth,
        participants.family_medical_history   as medic_hist_perform,
        participants.mental_health_collected    as mental_health_collected,
        participants.medication_info_collected  as medication_info_collected,
        participants.alcohol_activity_collected as alcohol_activity_collected,
        participants.tobacco_use_collected      as tobacco_use_collected,
        participants.drug_use_collected         as drug_use_collected,

        events.event_uid                      as sampling_event_id,
        COALESCE(events.state_or_province_of_residence, 'not provided') as geo_loc_name,
        events.converted_age_years            as host_age,
        events.converted_height_cm            as host_height,
        events.converted_weight_kg            as host_tot_mass,
        events.bmi                            as host_body_mass_index,
        NULL                                  as pet_farm_animal,
        events.animal_exposure                as _animal_exposure,
        events.exposure_animal_type           as _exposure_animal_type,
        events.occupation                     as host_occupation,
        events.cigarette_smoking              as smoker,
        events.oral_health                    as oral_health_collected,
        events.dental_exam                    as dental_exam,
        events.current_geography              as current_geography,
        events.diet                           as diet_collected,
        events.wellness_information_available as wellness_collected,
        events.social_determinants_of_health  as social_det_collected,
        events.time_last_toothbrush           as time_last_toothbrush
        
      FROM samples
        LEFT JOIN biosamples             ON biosamples.sample_name = samples.sample_uid
        LEFT JOIN samples AS parent      ON parent.sample_uid      = samples.parent_sample_uid
        LEFT JOIN samples AS grandparent ON grandparent.sample_uid = parent.parent_sample_uid
        LEFT JOIN events                 ON events.event_uid       = COALESCE(samples.event_uid, parent.event_uid, grandparent.event_uid)
        LEFT JOIN participants           ON participants.participant_uid = samples.participant_uid

      WHERE biosamples.sample_name IS NULL 
        AND samples.user = @user"
  
  biosamples <- db_query(env$db, sql, 'ApiBio1', simplify = FALSE)

  # Samples with a user-provided BioSample accession only need a minimal
  # record, which prevents them from being submitted to NCBI by us.
  accession <- env$df[['biosample_id']][match(biosamples[['sample_name']], env$df[['sample_uid']])]
  if (any(has_acc <- !is.na(accession))) {
    minimal <- biosamples[has_acc, c('sample_name', 'host_subject_id', 'sampling_event_id'), drop = FALSE]
    minimal[['biosample_accession']] <- accession[has_acc]
    db_insert(env$db, 'biosamples', minimal, 'BioRefr2')
    biosamples <- biosamples[!has_acc, , drop = FALSE]
  }

  if (nrow(biosamples) > 0) {
    
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
    
    tmp        <- startsWith(names(biosamples), "_")
    biosamples <- biosamples[, !tmp, drop = FALSE]
    
    db_insert(env$db, 'biosamples', biosamples, 'BioRefr1')
  }
  
  invisible()
}



last_checked_at <- Sys.time()

# NCBI statuses after which a submission's report no longer changes.
FINAL_STATUSES <- c("processed-ok", "processed-error", "deleted", "failed")

biosamples_status_check <- function (db) {

  # Throttle scraping NCBI's FTP server
  if (difftime(Sys.time(), last_checked_at, units = "secs") < 10) return (invisible())
  last_checked_at <<- Sys.time()
  
  
  # Process all submissions regardless of the active user (poor-man's cron job)
  sql <- "SELECT submission_name FROM `submissions` WHERE complete = 'no'"
  pending_submissions <- db_query(db, sql, 'BioStChk1', simplify = FALSE)
  
  if (nrow(pending_submissions) == 0) return (invisible())
  
  sftp_conn <- sftpR::sftp_connect(
    hostname = "sftp-private.ncbi.nlm.nih.gov", 
    user     = Sys.getenv("NCBI_SFTP_USERNAME"),
    password = Sys.getenv("NCBI_SFTP_PASSWORD") )
  
  # character(0), not c(): `[[<-` on NULL would build a list, which RMariaDB rejects.
  accession_updates <- character(0)
  error_updates     <- character(0)
  
  for (submission_name in pending_submissions$submission_name) {
    local({
      
      # NCBI adds report.1.xml, report.2.xml, ... as processing progresses.
      # There are none until NCBI picks up the submission.
      remote_dir <- paste0("submit/Test/", submission_name, "/")
      listing    <- tryCatch(sftpR::sftp_list(sftp_conn, remote_dir, .verbose = FALSE), error = function(e) NULL)
      reports    <- grep("^report(\\.[0-9]+)?\\.xml$", listing[['name']], value = TRUE)
      if (length(reports) == 0) return()

      report_n    <- suppressWarnings(as.integer(sub("^report\\.?([0-9]*)\\.xml$", "\\1", reports)))
      remote_file <- paste0(remote_dir, reports[order(report_n, na.last = FALSE)][length(reports)])
      local_file  <- tempfile(fileext = ".xml")
      on.exit(unlink(local_file))

      dl_res <- tryCatch({
        sftpR::sftp_download(sftp_conn, remote_file, local_file)
        TRUE
      }, error = function(e) FALSE)

      if (!dl_res) return()

      SubmissionStatus <- xml2::read_xml(local_file)
      Actions          <- xml2::xml_find_all(SubmissionStatus, ".//Action")

      # Keep polling until NCBI reports a final status (e.g. not "processing").
      status     <- tolower(xml2::xml_attr(SubmissionStatus, 'status'))
      complete   <- if (is.na(status) || status %in% FINAL_STATUSES) 'yes' else 'no'
      report_xml <- as.character(SubmissionStatus)

      # Skip unchanged reports; every UPDATE adds a system-versioned history row.
      sql <- "
        UPDATE submissions
        SET report_xml = ?, report_timestamp = CURRENT_TIMESTAMP, complete = ?
        WHERE submission_name = ? AND NOT (report_xml <=> ?)"
      changed <- db_query(db, sql, 'BioStChk_Sub', list(report_xml, complete, submission_name, report_xml))
      if (changed == 0) return()

      for (i in seq_along(Actions)) {

        Action <- Actions[[i]]
        Object <- xml2::xml_find_first(Action, ".//Object")

        accession   <- xml2::xml_attr(Object, 'accession')
        sample_name <- xml2::xml_attr(Object, 'spuid')

        if (!is.na(sample_name)) {
          if (isTRUE(!is.na(accession) & startsWith(accession, "SAMN"))) {
            accession_updates[[sample_name]] <<- accession
          }
          else if (tolower(xml2::xml_attr(Action, 'status')) %in% FINAL_STATUSES) {
            messages <- xml2::xml_text(xml2::xml_find_all(Action, ".//Message"))
            if (length(messages) == 0) messages <- paste("NCBI status:", xml2::xml_attr(Action, 'status'))
            error_updates[[sample_name]] <<- paste(messages, collapse = "; ")
          }
        }
      }

    })
  }
  
  if (length(accession_updates) > 0) {
    sql <- "UPDATE biosamples SET biosample_accession = ? WHERE sample_name = ?"
    db_query(db, sql, 'BioStChk3', list(unname(accession_updates), names(accession_updates)))
  }
  
  if (length(error_updates) > 0) {
    sql <- "UPDATE biosamples SET submission_error = ? WHERE sample_name = ?"
    db_query(db, sql, 'BioStChk4', list(unname(error_updates), names(error_updates)))
  }
  
  invisible()
}



txid_to_name <- function (txids) {
  
  map <- c(
    `NCBI:txid1070528` = "viral metagenome", 
    `NCBI:txid9606`    = "Homo sapiens",
    `NCBI:txid10090`   = "Mus musculus" )
  
  if (sum(!is.na(txids)) > 0 && !all(txids %in% c(names(map), NA))) {
    query_ids  <- sub('NCBI:txid', '', unique(txids[!is.na(txids)]), fixed = TRUE)
    search_res <- tryCatch(
      expr    = rentrez::entrez_summary(db = "taxonomy", id = query_ids, always_return_list = TRUE), 
      error   = \(e) stop('Error looking up NCBI taxa ID.\n', e$message), 
      warning = \(w) stop('Error looking up NCBI taxa ID.\n', w$message) )
    map <- setNames(
      object = rentrez::extract_from_esummary(search_res, "scientificname"), 
      nm     = paste0('NCBI:txid', rentrez::extract_from_esummary(search_res, "taxid")) )
  }
  
  unname(map[txids])
}

