


# Use package Metagenome.environmental.1.0
# https://submit.ncbi.nlm.nih.gov/biosample/template/?package-0=Metagenome.environmental.1.0&action=definition

api_biosamples_assign <- function (db, hvp_ids) {
  
  stopifnot(length(hvp_ids) > 0)
  
  # release_date <- as.character(strptime(release_date, format="%Y-%m-%d"))
  # if (is.na(release_date) || length(release_date) != 1)
  #   stop("Invalid `release_date`.")
  
  sql <- "SELECT * FROM biosamples WHERE user = @user"
  res <- db_query(db, sql, 'ApiBiAs1', simplify = FALSE)
  
  res <- res[res[['hvp_id']] %in% hvp_ids,,drop=FALSE]
  attrs <- setdiff(names(res), c('user', 'ncbi_status', 'biosample_accession', 'sample_name', 'organism'))
  
  
  # Confirm validity of all the provided `sample_name`s.
  if (length(missing_hvp_ids <- setdiff(hvp_ids, res[['hvp_id']])))
    stop("`hvp_id`(s) missing from database: ", paste(collapse = ', ', missing_hvp_ids))
  if (length(already_submitted <- res[['sample_name']][res[['ncbi_status']] != "not submitted"]))
    stop("Samples are already submitted to NCBI: ", paste(collapse = ', ', already_submitted))
  
  
  # Create the root node
  Submission <- xml2::xml_new_root("Submission")
  
  add <- xml2::xml_add_child
  
  desc <- add(Submission, "Description")
  # add(desc, "Hold", release_date = release_date)
  
  org <- add(desc, "Organization", role="owner", type="consortium")
  add(org, "Name", "Human Virome Project")
  
  Action <- add(Submission, "Action")
  
  for (i in seq_len(nrow(res))) {
    
    AddData    <- add(Action, "AddData", target_db = "BioSample")
    
    Data       <- add(AddData, "Data", content_type = "XML")
    XmlContent <- add(Data, "XmlContent")
    BioSample  <- add(XmlContent, "BioSample", schema_version = "2.0")
    
    SampleId   <- add(BioSample, "SampleId")
    add(SampleId, "SPUID", spuid_namespace = "HVPCC", res[i,'sample_name'])
    
    Descriptor   <- add(BioSample, "Descriptor")
    ExternalLink <- add(Descriptor, "ExternalLink", label = "Human Virome Project")
    add(ExternalLink, "URL", "https://human-virome.org/")
    
    Organism <- add(BioSample, "Organism")
    add(Organism, "OrganismName", res[i,'organism'])
    
    BioProject <- add(BioSample, "BioProject")
    add(BioProject, "PrimaryId", db = "BioProject", "PRJNA1336838") # Umbrella Project
    
    add(BioSample, "Package", "Metagenome.environmental.1.0")
    
    Attributes <- add(BioSample, "Attributes")
    for (f in attrs)
      if (!is.na(res[i,f]))
        add(Attributes, "Attribute", attribute_name = f, res[i,f])
    
  }
  
  
  cat(as.character(Submission))
  
  local_file  <- tempfile(); on.exit(unlink(local_file), add = TRUE)
  empty_file  <- tempfile(); on.exit(unlink(empty_file), add = TRUE)
  remote_file <- paste0(basename(local_file), "/submission.xml")
  ready_file  <- paste0(basename(local_file), "/submit.ready")
  
  # Write to a formatted XML file on disk
  xml2::write_xml(Submission, local_file)
  file.create(empty_file)
  
  sftp_conn <- sftpR::sftp_connect(
    hostname = "sftp-private.ncbi.nlm.nih.gov",
    path     = "Test",
    user     = Sys.getenv("NCBI_SFTP_USERNAME"),
    password = Sys.getenv("NCBI_SFTP_PASSWORD") )
  
  sftpR::sftp_upload(sftp_conn, local_file, remote_file, .create_dir = TRUE)
  #sftpR::sftp_upload(sftp_conn, empty_file, ready_file,  .create_dir = TRUE)
  
  
  sql <- 'UPDATE biosamples SET ncbi_status = "pending" WHERE user = @user AND hvp_id = ?'
  db_query(db, sql, 'ApiBiAs2', list(res[['hvp_id']]))
  
  invisible()
}


biosamples_refresh <- function (db) {
  
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
  
  biosamples <- db_query(db, sql, 'ApiBio1', simplify = FALSE)
  
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
    
    db_append(db, 'biosamples', biosamples, 'BioRefr1')
  }
  
  invisible()
}



last_checked_at <- Sys.time()

biosamples_status_check <- function (db) {
  
  # Throttle scraping NCBI's FTP server
  if (as.numeric(Sys.time() - last_checked_at) < 10) return (invisible())
  last_checked_at <<- Sys.time()
  
  
  sql <- paste(
    "SELECT COUNT(*) FROM `biosamples`",
    "  WHERE user = @user",
    "  AND ncbi_status IS NOT NULL",
    "  AND biosample_accession IS NULL" )
  
  pending <- db_query(db, sql, 'BioStChk1')
  if (pending == 0) return (invisible())
  
  
  sftp_conn <- sftpR::sftp_connect(
    hostname = "sftp-private.ncbi.nlm.nih.gov", 
    user     = Sys.getenv("NCBI_SFTP_USERNAME"),
    password = Sys.getenv("NCBI_SFTP_PASSWORD") )
  
  files <- sftpR::sftp_list(sftp_conn, .recursive = TRUE)
  files <- subset(files, type == 'file' & name == 'report.xml')$url
  
  
  status_updates     <- c()
  accession_updates  <- c()
  delete_remote_dirs <- c()
  
  for (remote_file in files) {
    local({
      
      local_file <- tempfile(fileext = ".xml")
      on.exit(unlink(local_file))
      
      sftp_download(sftp_conn, remote_file, local_file)
      
      SubmissionStatus <- xml2::read_xml(local_file)
      Responses        <- xml2::xml_find_all(SubmissionStatus, ".//Response")
      
      file_status <- xml2::xml_attr(SubmissionStatus, 'status')
      if (identical(file_status, 'processed-ok'))
        delete_remote_dirs <- c(delete_remote_dirs, basename(remote_file))
      
      for (i in seq_along(Responses)) {
        
        Response <- Responses[[i]]
        Object   <- xml2::xml_find_first(Response, ".//Object")
        
        status      <- xml2::xml_attr(Response, 'status')
        accession   <- xml2::xml_attr(Object, 'accession')
        sample_name <- xml2::xml_attr(Object, 'spuid')
        
        if (!is.na(sample_name)) {
          if (!is.na(status))    status_updates[[sample_name]]    <<- status
          if (!is.na(accession)) accession_updates[[sample_name]] <<- accession
        }
      }
      
    })
  }
  
  if (length(status_updates) > 0) {
    sql <- "UPDATE biosamples SET ncbi_status = ? WHERE sample_name = ?"
    db_query(db, sql, 'BioStChk2', list(unname(status_updates), names(status_updates)))
  }
  
  if (length(accession_updates) > 0) {
    sql <- "UPDATE biosamples SET biosample_accession = ? WHERE sample_name = ?"
    db_query(db, sql, 'BioStChk3', list(unname(accession_updates), names(accession_updates)))
  }
  
  for (remote_url in delete_remote_dirs) {
    sftp_delete(sftp_conn, remote_url, .recursive = TRUE)
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

