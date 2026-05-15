CREATE DATABASE IF NOT EXISTS vbr;
use vbr;

CREATE TABLE IF NOT EXISTS permissions (
  oauth_email      VARCHAR(255) NOT NULL,
  cohort_id        VARCHAR(255) NOT NULL,
  permission       VARCHAR(255) NOT NULL,
  last_modified_by VARCHAR(255) NOT NULL,
  PRIMARY KEY (oauth_email, cohort_id),
  INDEX (cohort_id)
) ENGINE=InnoDB WITH SYSTEM VERSIONING;

CREATE TABLE IF NOT EXISTS uid_suffixes (
  uid_suffix CHAR(6) NOT NULL PRIMARY KEY
) ENGINE=InnoDB;

# hvp:ptt-abcdef
CREATE TABLE IF NOT EXISTS participants (
  uuid                           VARCHAR(50)  NOT NULL UNIQUE,
  participant_uid                VARCHAR(255) NOT NULL PRIMARY KEY,
  cohort_id                      VARCHAR(255) NOT NULL DEFAULT '',
  host_taxon                     TINYTEXT,
  race                           TINYTEXT,
  ethnicity                      TINYTEXT,
  sex_at_birth                   TINYTEXT,
  country_of_birth               TINYTEXT,
  country_of_childhood_residence TINYTEXT,
  gestational_age_at_birth       TINYTEXT,
  mode_of_birth_delivery         TINYTEXT,
  blood_type                     TINYTEXT,
  family_medical_history         TINYTEXT,
  last_modified_by               VARCHAR(255) NOT NULL,
  INDEX (cohort_id)
) ENGINE=InnoDB WITH SYSTEM VERSIONING;

# hvp:tpt-abcdef
CREATE TABLE IF NOT EXISTS events (
  uuid                                    VARCHAR(50)  NOT NULL UNIQUE,
  event_uid                               VARCHAR(255) NOT NULL PRIMARY KEY,
  participant_uid                         VARCHAR(255) NOT NULL,
  age                                     TINYTEXT,
  age_units                               TINYTEXT,
  age_range                               TINYTEXT,
  state_or_province_of_residence          TINYTEXT,
  vital_status                            TINYTEXT,
  weight                                  TINYTEXT,
  weight_units                            TINYTEXT,
  height                                  TINYTEXT,
  height_units                            TINYTEXT,
  number_of_household_members             TINYTEXT,
  animal_exposure                         TINYTEXT,
  exposure_animal_type                    TEXT,
  family_income                           TINYTEXT,
  occupation                              TINYTEXT,
  breastfed_status                        TINYTEXT,
  oral_health                             TINYTEXT,
  dental_exam                             TINYTEXT,
  systemic_comorbidities                  TEXT,
  mental_health_history                   TEXT,
  mental_health_at_sampling               TEXT,
  disabilities                            TEXT,
  prescription_medications                TEXT,
  antibiotics_or_antivirals               TEXT,
  otc_medications                         TEXT,
  supplements_or_vitamins_or_herbal       TEXT,
  lifetime_vaccinations                   TEXT,
  seasonal_vaccinations                   TEXT,
  alcohol_activity_collected              TINYTEXT,
  alcohol_consumption                     TINYTEXT,
  tobacco_use_collected                   TINYTEXT,
  cigarette_smoking                       TINYTEXT,
  former_pack_years                       TINYTEXT,
  current_pack_years                      TINYTEXT,
  other_tobacco_exposure                  TEXT,
  vaping_behavior                         TEXT,
  cannabis                                TEXT,
  recreational_or_illicit_drugs           TEXT,
  current_geography                       TINYTEXT,
  diet                                    TINYTEXT,
  diet_comment                            TEXT,
  physical_activity                       TINYTEXT,
  physical_activity_comment               TEXT,
  wellness_information_available          TINYTEXT,
  wellness_info_comment                   TEXT,
  social_determinants_of_health           TINYTEXT,
  soc_det_health_comment                  TEXT,
  acute_health_status_at_sampling         TINYTEXT,
  acute_health_status_at_sampling_comment TEXT,
  time_last_toothbrush                    TINYTEXT,
  last_modified_by                        VARCHAR(255) NOT NULL,
  INDEX (participant_uid)
) ENGINE=InnoDB WITH SYSTEM VERSIONING;

# hvp:sam-abcdef
CREATE TABLE IF NOT EXISTS samples (
  uuid                     VARCHAR(50)  NOT NULL UNIQUE,
  biosample_id             VARCHAR(50)  NOT NULL DEFAULT '',
  sample_uid               VARCHAR(255) NOT NULL PRIMARY KEY,
  participant_uid          VARCHAR(255) NOT NULL DEFAULT '',
  event_uid                VARCHAR(255) NOT NULL DEFAULT '',
  lab                      TINYTEXT,
  sample_type              TINYTEXT,
  sample_subtype           TINYTEXT,
  parent_sample_id         TEXT,
  sampling_protocol        TINYTEXT,
  sample_taxonomy          TINYTEXT,
  anatomical_site          TINYTEXT,
  body_product             TINYTEXT,
  collection_method        TINYTEXT,
  sample_collection_device TINYTEXT,
  collection_month_year    TINYTEXT,
  collection_date          TINYTEXT,
  collection_day_of_week   TINYTEXT,
  sample_storage           TINYTEXT,
  sample_additive          TINYTEXT,
  control_sample_id        TINYTEXT,
  sample_processing        TINYTEXT,
  sample_transit_temp      TINYTEXT,
  sample_transit_duration  TINYTEXT,
  stool_type               TINYTEXT,
  self_collection          TINYTEXT,
  is_control_sample        TINYTEXT,
  negative_control_type    TINYTEXT,
  postive_control_type     TINYTEXT,
  last_modified_by         VARCHAR(255) NOT NULL,
  INDEX (participant_uid),
  INDEX (event_uid)
) ENGINE=InnoDB WITH SYSTEM VERSIONING;

# hvp:lib-abcdef
CREATE TABLE IF NOT EXISTS libraries (
  uuid                        VARCHAR(50) NOT NULL UNIQUE,
  library_uid                 VARCHAR(255) NOT NULL PRIMARY KEY,
  bioproject_id               TINYTEXT,
  library_type                TINYTEXT,
  library_aliquot             TINYTEXT,
  parent_library_uids         TEXT,
  technique                   TINYTEXT,
  subspecimen_type            TINYTEXT,
  library_processing_url      TINYTEXT,
  samp_store_dur              TINYTEXT,
  control_library_uid         TEXT,
  is_control_library          TINYTEXT,
  library_pos_cont_type       TINYTEXT,
  library_neg_cont_type       TINYTEXT,
  paired_or_single            TINYTEXT,
  sequencing_platform         TINYTEXT,
  sequencing_instrument_model TINYTEXT,
  last_modified_by            VARCHAR(255) NOT NULL,
  INDEX (library_uid)
) ENGINE=InnoDB WITH SYSTEM VERSIONING;

# hvp:fil-abcdef
CREATE TABLE IF NOT EXISTS files (
  uuid                        VARCHAR(50)  NOT NULL UNIQUE,
  file_uniq_name              VARCHAR(255) NOT NULL PRIMARY KEY,
  library_uid                 VARCHAR(255),
  library_aliqout_uid         TINYTEXT,
  bioproject_id               TINYTEXT,
  data_type                   TINYTEXT,
  file_format                 TINYTEXT,
  md5_checksum                TINYTEXT,
  file_derived_from           TEXT,
  analysis_uid                VARCHAR(255),
  access                      TINYTEXT,
  data_use_condition          TINYTEXT,
  data_use_specific_limit     TINYTEXT,
  last_modified_by            VARCHAR(255) NOT NULL,
  INDEX (library_uid)
) ENGINE=InnoDB WITH SYSTEM VERSIONING;

# hvp:ana-abcdef
CREATE TABLE IF NOT EXISTS analyses (
  uuid                   VARCHAR(50)  NOT NULL UNIQUE,
  analysis_uid           VARCHAR(255) NOT NULL PRIMARY KEY,
  analysis_description   TEXT,
  pipeline_name          TINYTEXT,
  pipeline_description   TEXT,
  pipeline_version       TINYTEXT,
  sop_url                TINYTEXT,
  community_workspace    TINYTEXT,
  pipeline_container_url TINYTEXT,
  last_modified_by       VARCHAR(255) NOT NULL
) ENGINE=InnoDB WITH SYSTEM VERSIONING;


CREATE TABLE IF NOT EXISTS biosamples (
  sample_uid                  VARCHAR(50) NOT NULL PRIMARY KEY,
  request_date                TIMESTAMP   DEFAULT NULL,
  export_date                 TIMESTAMP   DEFAULT NULL,
  biosample_id                VARCHAR(50) UNIQUE,
  sample_name                 TINYTEXT,
  organism                    TINYTEXT,
  host_tissue_sampled         TINYTEXT,
  host_body_product           TINYTEXT,
  collection_method           TINYTEXT,
  samp_collect_device         TINYTEXT,
  collection_date             TINYTEXT,
  neg_cont_type               TINYTEXT,
  pos_cont_type               TINYTEXT,
  lat_lon                     TINYTEXT DEFAULT ('not collected'),
  env_broad_scale             TINYTEXT DEFAULT ('not collected'),
  host_subject_id             TINYTEXT,
  host                        TINYTEXT,
  host_age                    TINYTEXT,
  race                        TINYTEXT,
  ethnicity                   TINYTEXT,
  host_sex_at_birth           TINYTEXT,
  host_height                 TINYTEXT,
  host_body_mass_index        TINYTEXT,
  pet_farm_animal             TINYTEXT,
  host_occupation             TINYTEXT,
  oral_health_collected       TINYTEXT,
  dental_exam                 TINYTEXT,
  medic_hist_perform          TINYTEXT,
  mental_health_collected     TINYTEXT,
  medication_info_collected   TINYTEXT,
  alcohol_activity_collected  TINYTEXT,
  tobacco_use_collected       TINYTEXT,
  drug_use_collected          TINYTEXT,
  current_geography           TINYTEXT,
  diet_collected              TINYTEXT,
  physical_activtiy_collected TINYTEXT,
  wellness_collected          TINYTEXT,
  social_det_collected        TINYTEXT,
  time_last_toothbrush        TINYTEXT,
  last_modified_by            VARCHAR(255) NOT NULL
) ENGINE=InnoDB WITH SYSTEM VERSIONING;

CREATE TABLE IF NOT EXISTS sra (
  library_uid          VARCHAR(255) NOT NULL PRIMARY KEY,
  export_date          TIMESTAMP    DEFAULT NULL,
  biosample_id         VARCHAR(50)  UNIQUE,
  bioproject_accession TINYTEXT,    
  title                TINYTEXT,         
  library_strategy     TINYTEXT,                    
  library_source       TINYTEXT,                  
  library_selection    TINYTEXT,                     
  library_layout       TINYTEXT,                  
  platform             TINYTEXT,            
  instrument_model     TINYTEXT,                    
  Biosample_accession  TINYTEXT,                       
  last_modified_by     VARCHAR(255) NOT NULL
) ENGINE=InnoDB WITH SYSTEM VERSIONING;


CREATE USER 'vbr'@'localhost';
GRANT SELECT, INSERT, UPDATE, DELETE ON vbr.* TO 'vbr'@'localhost';

FLUSH PRIVILEGES;
