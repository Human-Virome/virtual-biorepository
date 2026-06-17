CREATE DATABASE IF NOT EXISTS vbr;
use vbr;

CREATE USER 'vbr'@'localhost';
GRANT SELECT, INSERT, UPDATE, DELETE ON vbr.* TO 'vbr'@'localhost';
FLUSH PRIVILEGES;

# DROP DATABASE vbr;
CREATE DATABASE IF NOT EXISTS vbr;
use vbr;

# hvp:p-abcdef
CREATE TABLE IF NOT EXISTS participants (
  hvp_id                         VARCHAR(50)  NOT NULL UNIQUE,
  participant_uid                VARCHAR(255) NOT NULL PRIMARY KEY,
  cohort_uid                     TEXT,
  host_taxon                     TINYTEXT,
  race                           TINYTEXT,
  ethnicity                      TINYTEXT,
  sex_at_birth                   TINYTEXT,
  country_of_birth               TINYTEXT,
  country_of_childhood_residence TINYTEXT,
  gestational_age_at_birth       FLOAT UNSIGNED,
  mode_of_birth_delivery         TINYTEXT,
  blood_type                     TINYTEXT,
  family_medical_history         ENUM('yes','no'),
  `user`                         VARCHAR(255) NOT NULL,
  INDEX (`user`)
) ENGINE=InnoDB WITH SYSTEM VERSIONING;

# hvp:e-abcdef
CREATE TABLE IF NOT EXISTS events (
  hvp_id                                  VARCHAR(50)  NOT NULL UNIQUE,
  event_uid                               VARCHAR(255) NOT NULL PRIMARY KEY,
  participant_uid                         VARCHAR(255) NOT NULL,
  age                                     FLOAT UNSIGNED,
  age_units                               TINYTEXT,
  converted_age_years                     FLOAT UNSIGNED,
  age_range                               TINYTEXT,
  state_or_province_of_residence          TINYTEXT,
  current_geography                       TINYTEXT,
  vital_status                            TINYTEXT,
  weight                                  FLOAT UNSIGNED,
  weight_units                            TINYTEXT,
  converted_weight_kg                     FLOAT UNSIGNED,
  height                                  FLOAT UNSIGNED,
  height_units                            TINYTEXT,
  converted_height_cm                     FLOAT UNSIGNED,
  bmi                                     FLOAT UNSIGNED,
  number_of_household_members             INT UNSIGNED,
  animal_exposure                         TINYTEXT,
  exposure_animal_type                    TEXT,
  family_income                           TINYTEXT,
  occupation                              TINYTEXT,
  breastfed_status                        TINYTEXT,
  oral_health                             ENUM('yes','no'),
  dental_exam                             ENUM('yes','no'),
  systemic_comorbidities                  TEXT,
  mental_health_collected                 ENUM('yes','no'),
  mental_health_history                   TEXT,
  mental_health_at_sampling               TEXT,
  disabilities                            TEXT,
  medication_info_collected               ENUM('yes','no'),
  prescription_medications                TEXT,
  antibiotics_or_antivirals               TEXT,
  otc_medications                         TEXT,
  supplements_or_vitamins_or_herbal       TEXT,
  lifetime_vaccinations                   TEXT,
  seasonal_vaccinations                   TEXT,
  alcohol_activity_collected              ENUM('yes','no'),
  alcohol_consumption                     TINYTEXT,
  tobacco_use_collected                   ENUM('yes','no'),
  cigarette_smoking                       TINYTEXT,
  former_pack_years                       FLOAT UNSIGNED,
  current_pack_years                      FLOAT UNSIGNED,
  other_tobacco_exposure                  TINYTEXT,
  drug_use_collected                      ENUM('yes','no'),
  vaping_behavior                         TINYTEXT,
  cannabis                                TINYTEXT,
  recreational_or_illicit_drugs           TEXT,
  diet                                    ENUM('yes','no'),
  diet_comment                            TEXT,
  physical_activtiy_collected             ENUM('yes','no'),
  physical_activity                       TINYTEXT,
  physical_activity_comment               TEXT,
  wellness_information_available          ENUM('yes','no'),
  wellness_info_comment                   TEXT,
  social_determinants_of_health           ENUM('yes','no'),
  soc_det_health_comment                  TEXT,
  acute_health_status_at_sampling         ENUM('yes','no'),
  acute_health_status_at_sampling_comment TEXT,
  time_last_toothbrush                    FLOAT UNSIGNED,
  `user`                                  VARCHAR(255) NOT NULL,
  INDEX (`user`),
  FOREIGN KEY (participant_uid) REFERENCES participants(participant_uid)
) ENGINE=InnoDB WITH SYSTEM VERSIONING;

# hvp:s-abcdef
CREATE TABLE IF NOT EXISTS samples (
  hvp_id                   VARCHAR(50)  NOT NULL UNIQUE,
  sample_uid               VARCHAR(255) NOT NULL PRIMARY KEY,
  biosample_id             VARCHAR(50),
  participant_uid          VARCHAR(255) NOT NULL,
  event_uid                VARCHAR(255) NOT NULL,
  collection_lab           TINYTEXT,
  sample_type              TINYTEXT,
  sample_subtype           TINYTEXT,
  parent_sample_uid        TEXT,
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
  control_sample_uid       TEXT,
  sample_processing        TINYTEXT,
  sample_transit_temp      FLOAT,
  sample_transit_duration  FLOAT UNSIGNED,
  stool_type               TINYTEXT,
  self_collection          ENUM('yes','no'),
  is_control_sample        ENUM('yes','no'),
  negative_control_type    TINYTEXT,
  postive_control_type     TINYTEXT,
  `user`                   VARCHAR(255) NOT NULL,
  INDEX (`user`),
  FOREIGN KEY (event_uid)       REFERENCES events(event_uid),
  FOREIGN KEY (participant_uid) REFERENCES participants(participant_uid)
) ENGINE=InnoDB WITH SYSTEM VERSIONING;

# hvp:l-abcdef
CREATE TABLE IF NOT EXISTS libraries (
  hvp_id                      VARCHAR(50)  NOT NULL UNIQUE,
  library_uid                 VARCHAR(255) NOT NULL PRIMARY KEY,
  sample_uid                  VARCHAR(255) NOT NULL,
  library_type                TINYTEXT,
  is_library_aliquot          ENUM('yes','no'),
  parent_library_uid          TEXT,
  extraction_lab              TINYTEXT,
  library_prep_lab            TINYTEXT,
  sequencing_lab              TINYTEXT,
  technique                   TINYTEXT,
  subspecimen_type            TINYTEXT,
  library_processing_url      TINYTEXT,
  samp_store_dur              FLOAT UNSIGNED,
  control_library_uid         TEXT,
  is_control_library          ENUM('yes','no'),
  library_pos_cont_type       TINYTEXT,
  library_neg_cont_type       TINYTEXT,
  paired_or_single            TINYTEXT,
  sequencing_platform         TINYTEXT,
  sequencing_instrument_model TINYTEXT,
  `user`                      VARCHAR(255) NOT NULL,
  INDEX (`user`),
  FOREIGN KEY (sample_uid) REFERENCES samples(sample_uid)
) ENGINE=InnoDB WITH SYSTEM VERSIONING;

# hvp:a-abcdef
CREATE TABLE IF NOT EXISTS analyses (
  hvp_id                 VARCHAR(50)  NOT NULL UNIQUE,
  analysis_uid           VARCHAR(255) NOT NULL PRIMARY KEY,
  analysis_description   TEXT,
  pipeline_name          TINYTEXT,
  pipeline_description   TEXT,
  pipeline_version       TINYTEXT,
  sop_url                TINYTEXT,
  community_workspace    TINYTEXT,
  pipeline_container_url TINYTEXT,
  `user`                 VARCHAR(255) NOT NULL,
  INDEX (`user`)
) ENGINE=InnoDB WITH SYSTEM VERSIONING;

# hvp:f-abcdef
CREATE TABLE IF NOT EXISTS files (
  hvp_id                  VARCHAR(50)  NOT NULL UNIQUE,
  file_uniq_name          VARCHAR(255) NOT NULL PRIMARY KEY,
  library_uid             VARCHAR(255),
  bioproject_id           TINYTEXT,
  data_type               TINYTEXT,
  file_format             TINYTEXT,
  md5_checksum            TINYTEXT,
  file_derived_from       TEXT,
  analysis_uid            VARCHAR(255),
  access                  TINYTEXT,
  data_use_condition      TINYTEXT,
  data_use_specific_limit TINYTEXT,
  `user`                  VARCHAR(255) NOT NULL,
  INDEX (`user`),
  FOREIGN KEY (library_uid)  REFERENCES libraries(library_uid),
  FOREIGN KEY (analysis_uid) REFERENCES analyses(analysis_uid)
) ENGINE=InnoDB WITH SYSTEM VERSIONING;


# Use package Metagenome.environmental.1.0
# https://submit.ncbi.nlm.nih.gov/biosample/template/?package-0=Metagenome.environmental.1.0&action=definition
CREATE TABLE IF NOT EXISTS biosamples (
  hvp_id                      VARCHAR(50)  NOT NULL UNIQUE,
  sample_name                 VARCHAR(50)  NOT NULL PRIMARY KEY,
  ncbi_status                 TINYTEXT     DEFAULT ('not submitted'),
  biosample_accession         VARCHAR(50)  UNIQUE,
  host_subject_id             VARCHAR(50)  NOT NULL,
  sampling_event_id           VARCHAR(50)  NOT NULL,
  organism                    TINYTEXT,
  host_tissue_sampled         TINYTEXT,
  host_body_product           TINYTEXT,
  collection_method           TINYTEXT,
  samp_collect_device         TINYTEXT,
  collection_date             TINYTEXT,
  neg_cont_type               TINYTEXT,
  pos_cont_type               TINYTEXT,
  host                        TINYTEXT,
  host_age                    TINYTEXT,
  race                        TINYTEXT,
  ethnicity                   TINYTEXT,
  host_sex_at_birth           TINYTEXT,
  medic_hist_perform          TINYTEXT,
  geo_loc_name                TINYTEXT,
  host_height                 TINYTEXT,
  host_tot_mass               TINYTEXT,
  host_body_mass_index        FLOAT UNSIGNED,
  pet_farm_animal             TINYTEXT,
  host_occupation             TINYTEXT,
  smoker                      TINYTEXT,
  oral_health_collected       ENUM('yes','no'),
  dental_exam                 ENUM('yes','no'),
  mental_health_collected     ENUM('yes','no'),
  medication_info_collected   ENUM('yes','no'),
  alcohol_activity_collected  ENUM('yes','no'),
  tobacco_use_collected       ENUM('yes','no'),
  drug_use_collected          ENUM('yes','no'),
  current_geography           TINYTEXT,
  diet_collected              ENUM('yes','no'),
  physical_activtiy_collected ENUM('yes','no'),
  wellness_collected          ENUM('yes','no'),
  social_det_collected        ENUM('yes','no'),
  time_last_toothbrush        FLOAT UNSIGNED,
  lat_lon                     TINYTEXT NOT NULL DEFAULT ('not collected'),
  `user`                      VARCHAR(255) NOT NULL,
  INDEX (`user`),
  FOREIGN KEY (sample_name)       REFERENCES samples(sample_uid),
  FOREIGN KEY (host_subject_id)   REFERENCES participants(participant_uid),
  FOREIGN KEY (sampling_event_id) REFERENCES events(event_uid)
) ENGINE=InnoDB WITH SYSTEM VERSIONING;

CREATE TABLE IF NOT EXISTS sra (
  hvp_id                        VARCHAR(50)  NOT NULL UNIQUE,
  file_path                     VARCHAR(255) NOT NULL PRIMARY KEY,
  sample_name                   VARCHAR(50)  NOT NULL,
  BioSample                     VARCHAR(50),
  BioProject                    TINYTEXT,
  file_format                   TINYTEXT,
  library_name                  VARCHAR(255),
  library_strategy              TINYTEXT,
  library_source                TINYTEXT,
  library_selection             TINYTEXT,
  library_layout                TINYTEXT,
  library_construction_protocol TINYTEXT,
  instrument_model              TINYTEXT,
  `user`                        VARCHAR(255) NOT NULL,
  INDEX (`user`),
  FOREIGN KEY (file_path)    REFERENCES files(file_uniq_name),
  FOREIGN KEY (sample_name)  REFERENCES samples(sample_uid),
  FOREIGN KEY (library_name) REFERENCES libraries(library_uid),
  FOREIGN KEY (BioSample)    REFERENCES biosamples(biosample_accession)
) ENGINE=InnoDB WITH SYSTEM VERSIONING;


INSERT INTO `participants` (`hvp_id`, `user`, `participant_uid`)              VALUES ('hvp:p-mock', 'VBR', 'mock');
INSERT INTO `events`       (`hvp_id`, `user`, `participant_uid`, `event_uid`) VALUES ('hvp:e-mock', 'VBR', 'mock', 'mock');

