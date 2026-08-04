


# Use package Metagenome.environmental.1.0
# https://submit.ncbi.nlm.nih.gov/biosample/template/?package-0=Metagenome.environmental.1.0&action=definition

api_biosamples_assign <- function (db, hvp_ids) {
  
  stopifnot(length(hvp_ids) > 0)
  
  # release_date <- as.character(strptime(release_date, format="%Y-%m-%d"))
  # if (is.na(release_date) || length(release_date) != 1)
  #   stop("Invalid `release_date`.")
  
  sql <- "
    SELECT b.*, s.complete 
    FROM biosamples b
    LEFT JOIN submissions s USING (submission_id)
    WHERE b.user = @user"
  res <- db_query(db, sql, 'ApiBiAs1', simplify = FALSE)
  
  res <- res[res[['hvp_id']] %in% hvp_ids,,drop=FALSE]
  attrs <- setdiff(names(res), c('user', 'submission_id', 'biosample_accession', 'sample_name', 'organism', 'complete'))
  
  
  # Confirm validity of all the provided `sample_name`s.
  if (length(missing_hvp_ids <- setdiff(hvp_ids, res[['hvp_id']])))
    stop("`hvp_id`(s) missing from database: ", paste(collapse = ', ', missing_hvp_ids))
  
  is_pending_or_success <- !is.na(res[['submission_id']]) & (is.na(res[['complete']]) | res[['complete']] == 'no' | !is.na(res[['biosample_accession']]))
  if (length(already_submitted <- res[['sample_name']][is_pending_or_success]))
    stop("Samples are already submitted to NCBI (or pending): ", paste(collapse = ', ', already_submitted))
  
  
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
  
  sftp_conn <- sftpR::sftp_connect(
    hostname = "sftp-private.ncbi.nlm.nih.gov",
    user     = Sys.getenv("NCBI_SFTP_USERNAME"),
    password = Sys.getenv("NCBI_SFTP_PASSWORD") )
  
  sftpR::sftp_upload(sftp_conn, local_xml_file, remote_xml_file, .create_dir = TRUE)
  sftpR::sftp_upload(sftp_conn, local_ready_file, remote_ready_file,  .create_dir = TRUE)
  
  
  sql <- "INSERT INTO submissions (submission_name, submission_xml, user) VALUES (?, ?, @user)"
  db_query(db, sql, 'ApiBiAsInsert', list(submission_name, as.character(Submission)))
  
  submission_id <- db_query(db, "SELECT LAST_INSERT_ID()", 'ApiBiAsId', req1 = TRUE)
  
  sql <- 'UPDATE biosamples SET submission_id = ? WHERE user = @user AND hvp_id = ?'
  db_query(db, sql, 'ApiBiAs2', list(rep(submission_id, nrow(res)), res[['hvp_id']]))
  
  return (list())
}


biosamples_refresh <- function (env) {
  
  sql <- "
      SELECT
        samples.hvp_id                        as hvp_id,
        samples.user                          as user,
        samples.sample_uid                    as sample_name,
        samples.sample_taxonomy               as organism,
        samples.anatomical_site               as host_tissue_sampled,
        samples.body_product                  as host_body_product,
        samples.collection_method             as collection_method,
        samples.sample_collection_device      as samp_collect_device,
        samples.collection_date               as collection_date,
        samples.collection_month_year         as _collection_month_year,
        samples.negative_control_type         as neg_cont_type,
        samples.postive_control_type          as pos_cont_type,
        
        participants.participant_uid          as host_subject_id,
        participants.host_taxon               as host,
        participants.race                     as race,
        participants.ethnicity                as ethnicity,
        participants.sex_at_birth             as host_sex_at_birth,
        participants.family_medical_history   as medic_hist_perform,
        
        events.event_uid                      as sampling_event_id,
        events.state_or_province_of_residence as geo_loc_name,
        events.age                            as host_age,
        events.age_units                      as _age_units,
        events.height                         as host_height,
        events.height_units                   as _height_units,
        events.weight                         as host_tot_mass,
        events.weight_units                   as _weight_units,
        events.bmi                            as host_body_mass_index,
        NULL                                  as pet_farm_animal,
        events.animal_exposure                as _animal_exposure,
        events.exposure_animal_type           as _exposure_animal_type,
        events.occupation                     as host_occupation,
        events.cigarette_smoking              as smoker,
        events.oral_health                    as oral_health_collected,
        events.dental_exam                    as dental_exam,
        events.mental_health_collected        as mental_health_collected,
        events.medication_info_collected      as medication_info_collected,
        events.alcohol_activity_collected     as alcohol_activity_collected,
        events.tobacco_use_collected          as tobacco_use_collected,
        events.drug_use_collected             as drug_use_collected,
        events.current_geography              as current_geography,
        events.diet                           as diet_collected,
        events.physical_activtiy_collected    as physical_activtiy_collected,
        events.wellness_information_available as wellness_collected,
        events.social_determinants_of_health  as social_det_collected,
        events.time_last_toothbrush           as time_last_toothbrush
        
      FROM samples
        LEFT JOIN biosamples   ON samples.sample_uid = biosamples.sample_name
        LEFT JOIN participants USING (participant_uid)
        LEFT JOIN events       USING (event_uid)
        
      WHERE biosamples.sample_name IS NULL 
        AND samples.user = @user"
  
  biosamples <- db_query(env$db, sql, 'ApiBio1', simplify = FALSE)
  
  if (nrow(biosamples) > 0) {
    
    biosamples[['host_age']] <- data.table::fifelse(
      test = is.na(biosamples[['host_age']]), 
      yes  = 'not collected', 
      no   = paste(biosamples[['host_age']], biosamples[['_age_units']]) )
    
    biosamples[['host_height']] <- data.table::fifelse(
      test = is.na(biosamples[['host_height']]), 
      yes  = 'not collected', 
      no   = paste(biosamples[['host_height']], biosamples[['_height_units']]) )
    
    biosamples[['host_tot_mass']] <- data.table::fifelse(
      test = is.na(biosamples[['host_tot_mass']]), 
      yes  = 'not collected', 
      no   = paste(biosamples[['host_tot_mass']], biosamples[['_weight_units']]) )
    
    biosamples[['smoker']] <- data.table::fifelse(
      test = is.na(biosamples[['smoker']]), 
      no   = 'not collected', 
      yes  = data.table::fifelse(
        test = identical(biosamples[['smoker']], "non-smoker (<100 cigarettes lifetime)"), 
        no   = 'no', 
        yes  = 'yes' ))
    
    biosamples[['pet_farm_animal']] <- data.table::fifelse(
      test = is.na(biosamples[['_animal_exposure']]), 
      no   = 'not collected', 
      yes  = data.table::fifelse(
        test = is.na(biosamples[['_exposure_animal_type']]), 
        no   = paste0('yes;', biosamples[['_animal_exposure']]), 
        yes  = 'no' ))
    
    biosamples[['collection_date']] <- data.table::fifelse(
      test = is.na(biosamples[['collection_date']]), 
      yes  = biosamples[['_collection_month_year']], 
      no   = biosamples[['collection_date']] )
    
    biosamples[['host']]     <- txid_to_name(biosamples[['host']])
    biosamples[['organism']] <- txid_to_name(biosamples[['organism']])
    
    tmp        <- startsWith(names(biosamples), "_")
    biosamples <- biosamples[, !tmp, drop = FALSE]
    
    db_insert(env$db, 'biosamples', biosamples, 'BioRefr1')
  }
  
  invisible()
}



last_checked_at <- Sys.time()

biosamples_status_check <- function (db) {
  
  # Throttle scraping NCBI's FTP server
  if (as.numeric(Sys.time() - last_checked_at) < 10) return (invisible())
  last_checked_at <<- Sys.time()
  
  
  # Process all submissions regardless of the active user (poor-man's cron job)
  sql <- "SELECT submission_name FROM `submissions` WHERE complete = 'no'"
  pending_submissions <- db_query(db, sql, 'BioStChk1', simplify = FALSE)
  
  if (nrow(pending_submissions) == 0) return (invisible())
  
  sftp_conn <- sftpR::sftp_connect(
    hostname = "sftp-private.ncbi.nlm.nih.gov", 
    user     = Sys.getenv("NCBI_SFTP_USERNAME"),
    password = Sys.getenv("NCBI_SFTP_PASSWORD") )
  
  accession_updates <- c()
  error_updates <- c()
  
  for (submission_name in pending_submissions$submission_name) {
    local({
      
      remote_file <- paste0("submit/Test/", submission_name, "/report.xml")
      local_file <- tempfile(fileext = ".xml")
      on.exit(unlink(local_file))
      
      # Try downloading the file, it might not exist yet if NCBI hasn't processed it
      dl_res <- tryCatch({
        sftpR::sftp_download(sftp_conn, remote_file, local_file)
        TRUE
      }, error = function(e) FALSE)
      
      if (!dl_res) return()
      
      SubmissionStatus <- xml2::read_xml(local_file)
      Responses        <- xml2::xml_find_all(SubmissionStatus, ".//Response")
      
      file_status <- xml2::xml_attr(SubmissionStatus, 'status')
      
      sql <- "UPDATE submissions SET report_xml = ?, report_timestamp = CURRENT_TIMESTAMP, complete = 'yes' WHERE submission_name = ?"
      report_xml_content <- as.character(SubmissionStatus)
      db_query(db, sql, 'BioStChk_Sub', list(report_xml_content, submission_name))
      
      for (i in seq_along(Responses)) {
        
        Response <- Responses[[i]]
        Object   <- xml2::xml_find_first(Response, ".//Object")
        
        accession   <- xml2::xml_attr(Object, 'accession')
        sample_name <- xml2::xml_attr(Object, 'spuid')
        
        if (!is.na(sample_name)) {
          if (isTRUE(!is.na(accession) & startsWith(accession, "SAMN"))) {
            accession_updates[[sample_name]] <<- accession
          }
          else {
            messages <- xml2::xml_find_all(Response, ".//Message")
            if (length(messages) > 0) {
              error_updates[[sample_name]] <<- paste(xml2::xml_text(messages), collapse = "; ")
            }
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

