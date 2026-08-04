CREATE DATABASE IF NOT EXISTS vbr;
use vbr;

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


# hvpoXXXXXX
CREATE TABLE IF NOT EXISTS protocols (
  protocol_uid         VARCHAR(255) NOT NULL UNIQUE,
  author               VARCHAR(255) NOT NULL,
  title                VARCHAR(255) NOT NULL,
  version              VARCHAR(255) NOT NULL,
  applications         VARCHAR(255) NOT NULL,
  access               VARCHAR(255) NOT NULL,
  summary              TEXT,
  url                  VARCHAR(255),
  collection_additive  VARCHAR(255),
  preprocess_growth    VARCHAR(255),
  preprocess_spike_in  VARCHAR(255),
  preprocess_substance VARCHAR(255),
  preprocess_isolation VARCHAR(255),
  library_taxonomy     VARCHAR(255),
  library_purpose      VARCHAR(255),
  sequencing_strategy  VARCHAR(255),
  sequencing_source    VARCHAR(255),
  sequencing_selection VARCHAR(255),
  sequencing_layout    VARCHAR(255),
  transit_temp_celsius FLOAT,
  storage_temp_celsius FLOAT,
  hvp_id               CHAR(10)     PRIMARY KEY,
  `user`               VARCHAR(255) NOT NULL,
  INDEX (`user`)
) ENGINE=InnoDB WITH SYSTEM VERSIONING;

# hvppXXXXXX
CREATE TABLE IF NOT EXISTS participants (
  participant_uid                VARCHAR(255) NOT NULL UNIQUE,
  access                         VARCHAR(255) NOT NULL,
  data_use_condition             VARCHAR(255) NOT NULL,
  data_use_specific_limit        VARCHAR(255),
  race                           VARCHAR(255) NOT NULL,
  ethnicity                      VARCHAR(255) NOT NULL,
  sex_at_birth                   VARCHAR(255) NOT NULL,
  country_of_birth               VARCHAR(255) NOT NULL,
  country_of_childhood_residence VARCHAR(255) NOT NULL,
  gestational_age_at_birth       FLOAT,
  mode_of_birth_delivery         VARCHAR(255),
  blood_type                     VARCHAR(255),
  family_medical_history         ENUM('yes','no'),
  host_taxon                     VARCHAR(255) NOT NULL,
  hvp_id                         CHAR(10)     PRIMARY KEY,
  `user`                         VARCHAR(255) NOT NULL,
  INDEX (`user`)
) ENGINE=InnoDB WITH SYSTEM VERSIONING;

# hvpcXXXXXX
CREATE TABLE IF NOT EXISTS cohorts (
  cohort_uid VARCHAR(255) NOT NULL UNIQUE,
  hvp_id     CHAR(10)     PRIMARY KEY,
  `user`     VARCHAR(255) NOT NULL,
  INDEX (`user`)
) ENGINE=InnoDB WITH SYSTEM VERSIONING;

# hvphXXXXXX
CREATE TABLE IF NOT EXISTS cohort_participants (
  cohort_uid      VARCHAR(255) NOT NULL,
  participant_uid VARCHAR(255) NOT NULL,
  hvp_id          CHAR(10)     PRIMARY KEY,
  `user`          VARCHAR(255) NOT NULL,
  UNIQUE (cohort_uid, participant_uid),
  INDEX (participant_uid),
  INDEX (`user`),
  FOREIGN KEY (cohort_uid)      REFERENCES cohorts(cohort_uid),
  FOREIGN KEY (participant_uid) REFERENCES participants(participant_uid)
) ENGINE=InnoDB WITH SYSTEM VERSIONING;

# hvpeXXXXXX
CREATE TABLE IF NOT EXISTS events (
  event_uid                               VARCHAR(255) NOT NULL UNIQUE,
  participant_uid                         VARCHAR(255) NOT NULL,
  `year_month`                            VARCHAR(255) NOT NULL,
  year_month_day                          VARCHAR(255),
  day_of_week                             VARCHAR(255),
  age                                     FLOAT,
  age_units                               VARCHAR(255),
  converted_age_years                     FLOAT,
  age_range                               VARCHAR(255),
  state_or_province_of_residence          VARCHAR(255) NOT NULL,
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
  alcohol_consumption                     VARCHAR(255),
  tobacco_use_collected                   ENUM('yes','no'),
  cigarette_smoking                       VARCHAR(255),
  former_pack_years                       FLOAT,
  current_pack_years                      FLOAT,
  other_tobacco_exposure                  VARCHAR(255),
  drug_use_collected                      ENUM('yes','no'),
  vaping_behavior                         VARCHAR(255),
  cannabis                                VARCHAR(255),
  recreational_or_illicit_drugs           TEXT,
  diet                                    ENUM('yes','no'),
  diet_comment                            TEXT,
  physical_activtiy_collected             ENUM('yes','no'),
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
  FOREIGN KEY (participant_uid) REFERENCES participants(participant_uid)
) ENGINE=InnoDB WITH SYSTEM VERSIONING;

# hvpsXXXXXX
CREATE TABLE IF NOT EXISTS samples (
  sample_uid              VARCHAR(255) NOT NULL UNIQUE,
  event_uid               VARCHAR(255) NOT NULL,
  collection_protocol_uid VARCHAR(255) NOT NULL,
  collection_method       VARCHAR(255) NOT NULL,
  anatomical_site         VARCHAR(255),
  body_product            VARCHAR(255),
  collection_device       VARCHAR(255),
  self_collection         ENUM('yes','no'),
  transit_hours           FLOAT,
  stool_type              VARCHAR(255),
  is_control_sample       VARCHAR(255),
  hvp_id                  CHAR(10)     PRIMARY KEY,
  `user`                  VARCHAR(255) NOT NULL,
  INDEX (event_uid),
  INDEX (`user`),
  FOREIGN KEY (event_uid)               REFERENCES events(event_uid),
  FOREIGN KEY (collection_protocol_uid) REFERENCES protocols(protocol_uid)
) ENGINE=InnoDB WITH SYSTEM VERSIONING;

# hvpnXXXXXX
CREATE TABLE IF NOT EXISTS sample_controls (
  experimental_sample_uid VARCHAR(255) NOT NULL,
  control_sample_uid      VARCHAR(255) NOT NULL,
  hvp_id                  CHAR(10)     PRIMARY KEY,
  `user`                  VARCHAR(255) NOT NULL,
  UNIQUE (experimental_sample, control_sample),
  INDEX (`user`),
  FOREIGN KEY (experimental_sample_uid) REFERENCES samples(sample_uid),
  FOREIGN KEY (control_sample_uid)      REFERENCES samples(sample_uid)
) ENGINE=InnoDB WITH SYSTEM VERSIONING;

# hvpmXXXXXX
CREATE TABLE IF NOT EXISTS composite_samples (
  composite_sample_uid VARCHAR(255) NOT NULL,
  component_sample_uid VARCHAR(255) NOT NULL,
  hvp_id               CHAR(10)     PRIMARY KEY,
  `user`               VARCHAR(255) NOT NULL,
  PRIMARY KEY (composite_sample_uid, component_sample_uid),
  INDEX (component_sample_uid),
  INDEX (`user`),
  FOREIGN KEY (composite_sample_uid) REFERENCES samples(sample_uid),
  FOREIGN KEY (component_sample_uid) REFERENCES samples(sample_uid)
) ENGINE=InnoDB WITH SYSTEM VERSIONING;

# hvplXXXXXX
CREATE TABLE IF NOT EXISTS profiles (
  profile_uid               VARCHAR(255) NOT NULL UNIQUE,
  sample_uid                VARCHAR(255) NOT NULL,
  ncbi_bioproject_id        CHAR(12),
  sample_storage_days       FLOAT,
  preprocess_protocol_uid   VARCHAR(255),
  preprocess_lab            VARCHAR(255),
  preprocess_uid            VARCHAR(255),
  extraction_protocol_uid   VARCHAR(255),
  extraction_lab            VARCHAR(255),
  extraction_uid            VARCHAR(255),
  library_prep_protocol_uid VARCHAR(255) NOT NULL,
  library_prep_lab          VARCHAR(255) NOT NULL,
  library_prep_uid          VARCHAR(255),
  multiplex_pool_uid        VARCHAR(255),
  aliquot_uid               VARCHAR(255),
  assay_protocol_uid        VARCHAR(255) NOT NULL,
  assay_lab                 VARCHAR(255) NOT NULL,
  assay_platform            VARCHAR(255),
  assay_uid                 VARCHAR(255),
  postprocess_protocol_uid  VARCHAR(255),
  postprocess_lab           VARCHAR(255),
  postprocess_uid           VARCHAR(255),
  is_control_profile        VARCHAR(255),
  hvp_id                    CHAR(10)     PRIMARY KEY,
  `user`                    VARCHAR(255) NOT NULL,
  INDEX (sample_uid),
  INDEX (ncbi_bioproject_id),
  INDEX (preprocess_protocol_uid),
  INDEX (preprocess_uid),
  INDEX (extraction_protocol_uid),
  INDEX (extraction_uid),
  INDEX (library_prep_protocol_uid),
  INDEX (library_prep_uid),
  INDEX (assay_protocol_uid),
  INDEX (assay_uid),
  INDEX (postprocess_protocol_uid),
  INDEX (postprocess_uid),
  INDEX (`user`),
  FOREIGN KEY (sample_uid)                REFERENCES samples(sample_uid),
  FOREIGN KEY (preprocess_protocol_uid)   REFERENCES protocols(protocol_uid),
  FOREIGN KEY (extraction_protocol_uid)   REFERENCES protocols(protocol_uid),
  FOREIGN KEY (library_prep_protocol_uid) REFERENCES protocols(protocol_uid),
  FOREIGN KEY (assay_protocol_uid)        REFERENCES protocols(protocol_uid),
  FOREIGN KEY (postprocess_protocol_uid)  REFERENCES protocols(protocol_uid)
) ENGINE=InnoDB WITH SYSTEM VERSIONING;

# hvptXXXXXX
CREATE TABLE IF NOT EXISTS profile_controls (
  experimental_profile_uid VARCHAR(255) NOT NULL,
  control_profile_uid      VARCHAR(255) NOT NULL,
  hvp_id                   CHAR(10)     PRIMARY KEY,
  `user`                   VARCHAR(255) NOT NULL,
  UNIQUE (experimental_profile_uid, control_profile_uid),
  INDEX (`user`),
  FOREIGN KEY (experimental_profile_uid) REFERENCES profiles(profile_uid),
  FOREIGN KEY (control_profile_uid)      REFERENCES profiles(profile_uid)
) ENGINE=InnoDB WITH SYSTEM VERSIONING;

# hvpaXXXXXX
CREATE TABLE IF NOT EXISTS analyses (
  analysis_uid          VARCHAR(255) NOT NULL UNIQUE,
  analysis_protocol_uid VARCHAR(255) NOT NULL,
  workspace             VARCHAR(255),
  arguments             TEXT,
  settings              JSON,
  hvp_id                CHAR(10)     PRIMARY KEY,
  `user`                VARCHAR(255) NOT NULL,
  INDEX (`user`),
  FOREIGN KEY (analysis_protocol_uid) REFERENCES protocols(protocol_uid)
) ENGINE=InnoDB WITH SYSTEM VERSIONING;

# hvpiXXXXXX
CREATE TABLE IF NOT EXISTS analysis_inputs (
  analysis_uid       VARCHAR(255) NOT NULL,
  input_profile_uid  VARCHAR(255),
  input_analysis_uid VARCHAR(255),
  hvp_id             CHAR(10)     PRIMARY KEY,
  `user`             VARCHAR(255) NOT NULL,
  INDEX       (analysis_uid),
  UNIQUE      (input_profile_uid,  analysis_uid),
  UNIQUE      (input_analysis_uid, analysis_uid),
  INDEX       (user),
  FOREIGN KEY (analysis_uid)       REFERENCES analyses(analysis_uid),
  FOREIGN KEY (input_profile_uid)  REFERENCES profiles(profile_uid),
  FOREIGN KEY (input_analysis_uid) REFERENCES analyses(analysis_uid)
) ENGINE=InnoDB WITH SYSTEM VERSIONING;

# hvpfXXXXXX
CREATE TABLE IF NOT EXISTS files (
  profile_uid  VARCHAR(255),
  analysis_uid VARCHAR(255),
  filename     VARCHAR(255) NOT NULL,
  data_type    VARCHAR(255) NOT NULL,
  file_format  VARCHAR(255) NOT NULL,
  md5_checksum CHAR(32)     NOT NULL,
  hvp_id       CHAR(10)     PRIMARY KEY,
  `user`       VARCHAR(255) NOT NULL,
  UNIQUE (profile_uid,  filename),
  UNIQUE (analysis_uid, filename),
  INDEX (`user`),
  FOREIGN KEY (profile_uid)  REFERENCES profiles(profile_uid),
  FOREIGN KEY (analysis_uid) REFERENCES analyses(analysis_uid)
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
  host_subject_id             VARCHAR(255) NOT NULL,
  sampling_event_id           VARCHAR(255) NOT NULL,
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
  physical_activtiy_collected ENUM('yes','no'),
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
  FOREIGN KEY (host_subject_id)   REFERENCES participants(participant_uid),
  FOREIGN KEY (sampling_event_id) REFERENCES events(event_uid)
) ENGINE=InnoDB WITH SYSTEM VERSIONING;

# hvprXXXXXX
CREATE TABLE IF NOT EXISTS sra (
  profile_uid                   VARCHAR(255) UNIQUE,
  file_path                     JSON,
  sample_name                   VARCHAR(255) NOT NULL,
  BioSample                     VARCHAR(20),
  BioProject                    VARCHAR(20),
  file_format                   VARCHAR(255),
  library_name                  VARCHAR(255),
  library_strategy              VARCHAR(255),
  library_source                VARCHAR(255),
  library_selection             VARCHAR(255),
  library_layout                VARCHAR(255),
  library_construction_protocol VARCHAR(255),
  instrument_model              VARCHAR(255),
  hvp_id                        CHAR(10) PRIMARY KEY,
  `user`                        VARCHAR(255) NOT NULL,
  INDEX (`user`),
  FOREIGN KEY (profile_uid)  REFERENCES profiles(profile_uid),
  FOREIGN KEY (sample_name)  REFERENCES samples(sample_uid),
  FOREIGN KEY (library_name) REFERENCES profiles(library_id),
  FOREIGN KEY (BioSample)    REFERENCES biosamples(biosample_accession)
) ENGINE=InnoDB WITH SYSTEM VERSIONING;



INSERT INTO `participants`
  (hvp_id, participant_uid, access, data_use_condition, user)
  VALUES
    ('hvpp00MOCK', 'mock',      'open', 'DUO:0000004', 'Daniel.Smith@bcm.edu'),
    ('hvpp00COMP', 'composite', 'open', 'DUO:0000004', 'Daniel.Smith@bcm.edu');

INSERT INTO `events`
  (hvp_id, event_uid, participant_uid, year_month, user)
  VALUES
    ('hvpe00MOCK', 'mock',      'mock',      '2026-08', 'Daniel.Smith@bcm.edu'),
    ('hvpe00COMP', 'composite', 'composite', '2026-08', 'Daniel.Smith@bcm.edu');
