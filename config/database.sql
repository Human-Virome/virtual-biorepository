CREATE DATABASE IF NOT EXISTS vbr;
use vbr;

# DROP USER 'vbr'@'localhost';
CREATE USER 'vbr'@'localhost';
GRANT SELECT, INSERT, UPDATE, DELETE ON vbr.* TO 'vbr'@'localhost';
FLUSH PRIVILEGES;

# DROP DATABASE vbr;
CREATE DATABASE IF NOT EXISTS vbr;
use vbr;

# no_hvp_id
CREATE TABLE IF NOT EXISTS tokens (
  sha256      CHAR(64)     PRIMARY KEY,
  `user`      VARCHAR(255) NOT NULL,
  created     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  last_access TIMESTAMP
) ENGINE=InnoDB WITH SYSTEM VERSIONING;


# hvppXXXXXX
CREATE TABLE IF NOT EXISTS participants (
  participant_uid                VARCHAR(255) NOT NULL UNIQUE,
  cohort_uid                     VARCHAR(255) NOT NULL,
  taxon                          VARCHAR(255) NOT NULL,
  race                           VARCHAR(255),
  ethnicity                      VARCHAR(255),
  sex_at_birth                   VARCHAR(255),
  country_of_birth               VARCHAR(255),
  country_of_childhood_residence VARCHAR(255),
  gestational_age_at_birth       FLOAT,
  mode_of_birth_delivery         VARCHAR(255),
  blood_type                     VARCHAR(255),
  family_medical_history         ENUM('yes','no'),
  mental_health_collected        ENUM('yes','no'),
  medication_info_collected      ENUM('yes','no'),
  alcohol_activity_collected     ENUM('yes','no'),
  tobacco_use_collected          ENUM('yes','no'),
  drug_use_collected             ENUM('yes','no'),
  hvp_id                         CHAR(10)     PRIMARY KEY,
  `user`                         VARCHAR(255) NOT NULL,
  INDEX (`user`)
) ENGINE=InnoDB WITH SYSTEM VERSIONING;

# hvpeXXXXXX
CREATE TABLE IF NOT EXISTS participant_event_attributes (
  participant_uid                         VARCHAR(255) NOT NULL,
  event_uid                               VARCHAR(255) NOT NULL,
  age                                     FLOAT,
  age_units                               VARCHAR(255),
  converted_age_years                     FLOAT,
  age_range                               VARCHAR(255),
  state_or_province_of_residence          VARCHAR(255),
  current_geography                       VARCHAR(255),
  vital_status                            VARCHAR(255),
  weight                                  FLOAT,
  weight_units                            VARCHAR(255),
  converted_weight_kg                     FLOAT,
  height                                  FLOAT,
  height_units                            VARCHAR(255),
  converted_height_cm                     FLOAT,
  bmi                                     FLOAT,
  number_of_household_members             TINYINT UNSIGNED,
  animal_exposure                         VARCHAR(255),
  exposure_animal_type                    TEXT,
  family_income                           VARCHAR(255),
  occupation                              VARCHAR(255),
  breastfed_status                        VARCHAR(255),
  oral_health                             ENUM('yes','no'),
  dental_exam                             ENUM('yes','no'),
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
  alcohol_consumption                     VARCHAR(255),
  cigarette_smoking                       VARCHAR(255),
  former_pack_years                       FLOAT,
  current_pack_years                      FLOAT,
  other_tobacco_exposure                  VARCHAR(255),
  vaping_behavior                         VARCHAR(255),
  cannabis                                VARCHAR(255),
  recreational_or_illicit_drugs           TEXT,
  diet                                    ENUM('yes','no'),
  diet_comment                            TEXT,
  physical_activity                       VARCHAR(255),
  physical_activity_comment               TEXT,
  wellness_information_available          ENUM('yes','no'),
  wellness_info_comment                   TEXT,
  social_determinants_of_health           ENUM('yes','no'),
  soc_det_health_comment                  TEXT,
  acute_health_status_at_sampling         ENUM('yes','no'),
  acute_health_status_at_sampling_comment TEXT,
  time_last_toothbrush                    FLOAT,
  hvp_id                                  CHAR(10)     PRIMARY KEY,
  `user`                                  VARCHAR(255) NOT NULL,
  INDEX (`user`),
  INDEX (participant_uid),
  UNIQUE (participant_uid, event_uid),
  FOREIGN KEY (participant_uid) REFERENCES participants(participant_uid)
) ENGINE=InnoDB WITH SYSTEM VERSIONING;

# hvpsXXXXXX
CREATE TABLE IF NOT EXISTS samples (
  sample_uid              VARCHAR(255) NOT NULL UNIQUE,
  participant_uid         TEXT,
  event_uid               VARCHAR(255),
  lab                     VARCHAR(255) NOT NULL,
  sample_type             VARCHAR(255) NOT NULL,
  sample_subtype          VARCHAR(255),
  parent_sample_uid       TEXT,
  sampling_protocol       TEXT,
  sample_taxonomy         VARCHAR(255) NOT NULL,
  anatomical_site         VARCHAR(255),
  body_product            VARCHAR(255),
  collection_method       VARCHAR(255),
  collection_device       VARCHAR(255),
  collection_month_year   VARCHAR(255),
  collection_date         VARCHAR(255),
  collection_day_of_week  VARCHAR(255),
  sample_storage          VARCHAR(255),
  sample_additive         VARCHAR(255),
  control_sample_uid      TEXT,
  sample_transit_temp     FLOAT,
  sample_transit_duration FLOAT,
  storage_temp_celsius    FLOAT,
  stool_type              VARCHAR(255),
  self_collection         ENUM('yes','no'),
  is_control_sample       ENUM('yes','no') NOT NULL,
  negative_control_type   VARCHAR(255),
  positive_control_type   VARCHAR(255),
  hvp_id                  CHAR(10)     PRIMARY KEY,
  `user`                  VARCHAR(255) NOT NULL,
  INDEX (`user`),
  INDEX (event_uid)
) ENGINE=InnoDB WITH SYSTEM VERSIONING;

# hvplXXXXXX
CREATE TABLE IF NOT EXISTS libraries (
  library_uid                 VARCHAR(255) NOT NULL UNIQUE,
  sample_uid                  VARCHAR(255) NOT NULL,
  library_prep_lab            VARCHAR(255) NOT NULL,
  library_aliquot             ENUM('yes','no') NOT NULL,
  parent_library_uid          TEXT,
  technique                   VARCHAR(255) NOT NULL,
  subspecimen_type            VARCHAR(255),
  library_processing_url      TEXT,
  samp_store_dur              FLOAT,
  control_library_uid         TEXT,
  is_control_library          ENUM('yes','no') NOT NULL,
  library_pos_cont_type       VARCHAR(255),
  library_neg_cont_type       VARCHAR(255),
  library_strategy            VARCHAR(255),
  library_source              VARCHAR(255),
  library_selection           VARCHAR(255),
  paired_or_single            VARCHAR(255),
  sequencing_platform         VARCHAR(255),
  sequencing_instrument_model VARCHAR(255),
  hvp_id                      CHAR(10)     PRIMARY KEY,
  `user`                      VARCHAR(255) NOT NULL,
  INDEX (`user`),
  INDEX (sample_uid),
  FOREIGN KEY (sample_uid) REFERENCES samples(sample_uid)
) ENGINE=InnoDB WITH SYSTEM VERSIONING;

# hvpaXXXXXX
CREATE TABLE IF NOT EXISTS analyses (
  analysis_uid           VARCHAR(255) NOT NULL UNIQUE,
  analysis_description   TEXT         NOT NULL,
  pipeline_name          VARCHAR(255),
  pipeline_description   TEXT,
  pipeline_version       VARCHAR(255),
  sop_url                TEXT,
  community_workspace    VARCHAR(255),
  pipeline_container_url TEXT,
  hvp_id                 CHAR(10)     PRIMARY KEY,
  `user`                 VARCHAR(255) NOT NULL,
  INDEX (`user`)
) ENGINE=InnoDB WITH SYSTEM VERSIONING;

# hvpfXXXXXX
CREATE TABLE IF NOT EXISTS files (
  file_uniq_name          VARCHAR(255) NOT NULL UNIQUE,
  library_uid             VARCHAR(255),
  library_aliquot_uid     VARCHAR(255),
  bioproject_id           VARCHAR(255),
  data_type               VARCHAR(255) NOT NULL,
  file_format             VARCHAR(255) NOT NULL,
  md5_checksum            CHAR(32)     NOT NULL,
  file_derived_from       TEXT,
  analysis_uid            VARCHAR(255),
  access                  VARCHAR(255) NOT NULL,
  data_use_condition      VARCHAR(255) NOT NULL,
  data_use_specific_limit VARCHAR(255),
  hvp_id                  CHAR(10)     PRIMARY KEY,
  `user`                  VARCHAR(255) NOT NULL,
  INDEX (`user`),
  INDEX (library_uid),
  INDEX (library_aliquot_uid),
  INDEX (analysis_uid),
  FOREIGN KEY (library_uid)          REFERENCES libraries(library_uid),
  FOREIGN KEY (library_aliquot_uid)  REFERENCES libraries(library_uid),
  FOREIGN KEY (analysis_uid)         REFERENCES analyses(analysis_uid)
) ENGINE=InnoDB WITH SYSTEM VERSIONING;


# hvpuXXXXXX
CREATE TABLE IF NOT EXISTS submissions (
  submission_name      VARCHAR(255),
  submission_xml       LONGTEXT,
  report_xml           LONGTEXT,
  submission_timestamp TIMESTAMP        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  report_timestamp     TIMESTAMP,
  complete             ENUM('yes','no') NOT NULL DEFAULT 'no',
  hvp_id               CHAR(10)         PRIMARY KEY,
  `user`               VARCHAR(255)     NOT NULL,
  INDEX (`user`)
) ENGINE=InnoDB WITH SYSTEM VERSIONING;

# Use package Metagenome.environmental.1.0
# https://submit.ncbi.nlm.nih.gov/biosample/template/?package-0=Metagenome.environmental.1.0&action=definition
# hvpbXXXXXX
CREATE TABLE IF NOT EXISTS biosamples (
  sample_name                 VARCHAR(255) UNIQUE,
  submission_hvp_id           CHAR(10),
  biosample_accession         VARCHAR(20) UNIQUE,
  submission_error            TEXT,
  host_subject_id             VARCHAR(255),
  sampling_event_id           VARCHAR(255),
  organism                    VARCHAR(255),
  host_tissue_sampled         VARCHAR(255),
  host_body_product           VARCHAR(255),
  collection_method           VARCHAR(255),
  samp_collect_device         VARCHAR(255),
  collection_date             VARCHAR(255),
  neg_cont_type               VARCHAR(255),
  pos_cont_type               VARCHAR(255),
  host                        VARCHAR(255),
  host_age                    VARCHAR(255),
  race                        VARCHAR(255),
  ethnicity                   VARCHAR(255),
  host_sex_at_birth           VARCHAR(255),
  medic_hist_perform          VARCHAR(255),
  host_height                 VARCHAR(255),
  host_tot_mass               VARCHAR(255),
  host_body_mass_index        FLOAT,
  pet_farm_animal             VARCHAR(255),
  host_occupation             VARCHAR(255),
  smoker                      VARCHAR(255),
  oral_health_collected       ENUM('yes','no'),
  dental_exam                 ENUM('yes','no'),
  mental_health_collected     ENUM('yes','no'),
  medication_info_collected   ENUM('yes','no'),
  alcohol_activity_collected  ENUM('yes','no'),
  tobacco_use_collected       ENUM('yes','no'),
  drug_use_collected          ENUM('yes','no'),
  current_geography           VARCHAR(255),
  diet_collected              ENUM('yes','no'),
  wellness_collected          ENUM('yes','no'),
  social_det_collected        ENUM('yes','no'),
  time_last_toothbrush        FLOAT,
  geo_loc_name                VARCHAR(255) NOT NULL DEFAULT ('not provided'),
  lat_lon                     VARCHAR(255) NOT NULL DEFAULT ('not collected'),
  hvp_id                      CHAR(10)     PRIMARY KEY,
  `user`                      VARCHAR(255) NOT NULL,
  INDEX (biosample_accession),
  INDEX (`user`),
  FOREIGN KEY (sample_name)       REFERENCES samples(sample_uid),
  FOREIGN KEY (submission_hvp_id) REFERENCES submissions(hvp_id),
  FOREIGN KEY (host_subject_id)   REFERENCES participants(participant_uid)
) ENGINE=InnoDB WITH SYSTEM VERSIONING;

# hvprXXXXXX
CREATE TABLE IF NOT EXISTS sra (
  library_name                  VARCHAR(255) UNIQUE,
  file_path                     JSON,
  sample_name                   VARCHAR(255) NOT NULL,
  BioSample                     VARCHAR(20),
  BioProject                    VARCHAR(20),
  file_format                   VARCHAR(255),
  library_strategy              VARCHAR(255),
  library_source                VARCHAR(255),
  library_selection             VARCHAR(255),
  library_layout                VARCHAR(255),
  library_construction_protocol TEXT,
  instrument_model              VARCHAR(255),
  hvp_id                        CHAR(10) PRIMARY KEY,
  `user`                        VARCHAR(255) NOT NULL,
  INDEX (`user`),
  FOREIGN KEY (library_name) REFERENCES libraries(library_uid),
  FOREIGN KEY (sample_name)  REFERENCES samples(sample_uid),
  FOREIGN KEY (BioSample)    REFERENCES biosamples(biosample_accession)
) ENGINE=InnoDB WITH SYSTEM VERSIONING;

      
INSERT INTO `participants`
  (hvp_id, participant_uid, cohort_uid, taxon, `user`)
  VALUES
    ('hvpp00MOCK', 'mock', 'mock', 'NCBI:txid9606', 'Daniel.Smith@bcm.edu');
