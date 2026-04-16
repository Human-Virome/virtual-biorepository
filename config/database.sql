CREATE DATABASE IF NOT EXISTS hvp;
use hvp;

CREATE TABLE IF NOT EXISTS users (
  user_id           INTEGER AUTO_INCREMENT PRIMARY KEY,
  full_name         VARCHAR(100) NOT NULL DEFAULT '',
  affiliation       VARCHAR(100) NOT NULL DEFAULT '',
  email             VARCHAR(100) NOT NULL UNIQUE,
  password          TINYTEXT     NOT NULL,
  alt_password      TINYTEXT     NOT NULL DEFAULT '',
  last_login_utc    DATETIME              DEFAULT NULL,
  added_by          INTEGER      NOT NULL,
  added_utc         DATETIME     NOT NULL DEFAULT (UTC_TIMESTAMP())
) ENGINE=InnoDB WITH SYSTEM VERSIONING;

CREATE TABLE IF NOT EXISTS auth_tokens (
  auth_token_sha   CHAR(128) NOT NULL PRIMARY KEY,
  user_id          INTEGER   NOT NULL,
  valid_until_utc  DATETIME  NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users (user_id)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS uid_suffixes (
  uid_suffix CHAR(6) NOT NULL PRIMARY KEY
) ENGINE=InnoDB;

# hvp:ptt-abcdef
CREATE TABLE IF NOT EXISTS participants (
  uuid                           VARCHAR(50) NOT NULL UNIQUE,
  last_modified_by               INTEGER     NOT NULL,
  participant_uid                VARCHAR(50) NOT NULL PRIMARY KEY,
  cohort_id                      VARCHAR(50) NOT NULL DEFAULT '',
  host_taxon                     TINYTEXT    NOT NULL DEFAULT (''),
  race                           TINYTEXT    NOT NULL DEFAULT (''),
  ethnicity                      TINYTEXT    NOT NULL DEFAULT (''),
  sex_at_birth                   TINYTEXT    NOT NULL DEFAULT (''),
  country_of_birth               TINYTEXT    NOT NULL DEFAULT (''),
  country_of_childhood_residence TINYTEXT    NOT NULL DEFAULT (''),
  gestational_age_at_birth       TINYTEXT    NOT NULL DEFAULT (''),
  mode_of_birth_delivery         TINYTEXT    NOT NULL DEFAULT (''),
  blood_type                     TINYTEXT    NOT NULL DEFAULT (''),
  family_medical_history         TINYTEXT    NOT NULL DEFAULT (''),
  FOREIGN KEY (last_modified_by) REFERENCES users (user_id)
) ENGINE=InnoDB WITH SYSTEM VERSIONING;

# hvp:tpt-abcdef
CREATE TABLE IF NOT EXISTS timepoints (
  uuid                                    VARCHAR(50) NOT NULL UNIQUE,
  last_modified_by                        INTEGER     NOT NULL,
  participant_uid                         VARCHAR(50) NOT NULL PRIMARY KEY,
  timepoint_uid                           VARCHAR(50) NOT NULL DEFAULT '',
  age                                     TINYTEXT    NOT NULL DEFAULT (''),
  age_units                               TINYTEXT    NOT NULL DEFAULT (''),
  age_range                               TINYTEXT    NOT NULL DEFAULT (''),
  state_or_province_of_residence          TINYTEXT    NOT NULL DEFAULT (''),
  vital_status                            TINYTEXT    NOT NULL DEFAULT (''),
  weight                                  TINYTEXT    NOT NULL DEFAULT (''),
  weight_units                            TINYTEXT    NOT NULL DEFAULT (''),
  height                                  TINYTEXT    NOT NULL DEFAULT (''),
  height_units                            TINYTEXT    NOT NULL DEFAULT (''),
  bmi                                     TINYTEXT    NOT NULL DEFAULT (''),
  number_of_household_members             TINYTEXT    NOT NULL DEFAULT (''),
  animal_exposure                         TINYTEXT    NOT NULL DEFAULT (''),
  exposure_animal_type                    TEXT        NOT NULL DEFAULT (''),
  family_income                           TINYTEXT    NOT NULL DEFAULT (''),
  occupation                              TINYTEXT    NOT NULL DEFAULT (''),
  breastfed_status                        TINYTEXT    NOT NULL DEFAULT (''),
  oral_health                             TINYTEXT    NOT NULL DEFAULT (''),
  dental_exam                             TINYTEXT    NOT NULL DEFAULT (''),
  systemic_comorbidities                  TEXT        NOT NULL DEFAULT (''),
  mental_health_history                   TEXT        NOT NULL DEFAULT (''),
  mental_health_at_sampling               TEXT        NOT NULL DEFAULT (''),
  disabilities                            TEXT        NOT NULL DEFAULT (''),
  prescription_medications                TEXT        NOT NULL DEFAULT (''),
  mode_of_administration                  TINYTEXT    NOT NULL DEFAULT (''),
  systemic_antibiotic_or_antiviral_use    TEXT        NOT NULL DEFAULT (''),
  topical_antibiotic_or_antiviral_use     TEXT        NOT NULL DEFAULT (''),
  otc_medications                         TEXT        NOT NULL DEFAULT (''),
  supplements_or_vitamins_or_herbal       TEXT        NOT NULL DEFAULT (''),
  lifetime_vaccinations                   TEXT        NOT NULL DEFAULT (''),
  seasonal_vaccinations                   TEXT        NOT NULL DEFAULT (''),
  alcohol_consumption                     TINYTEXT    NOT NULL DEFAULT (''),
  cigarette_smoking                       TINYTEXT    NOT NULL DEFAULT (''),
  former_pack_years                       TINYTEXT    NOT NULL DEFAULT (''),
  current_pack_years                      TINYTEXT    NOT NULL DEFAULT (''),
  other_tobacco_exposure                  TEXT        NOT NULL DEFAULT (''),
  vaping_behavior                         TEXT        NOT NULL DEFAULT (''),
  cannabis                                TEXT        NOT NULL DEFAULT (''),
  recreational_or_illicit_drugs           TEXT        NOT NULL DEFAULT (''),
  current_geography                       TINYTEXT    NOT NULL DEFAULT (''),
  diet                                    TINYTEXT    NOT NULL DEFAULT (''),
  diet_comment                            TEXT        NOT NULL DEFAULT (''),
  physical_activity                       TINYTEXT    NOT NULL DEFAULT (''),
  physical_activity_comment               TEXT        NOT NULL DEFAULT (''),
  wellness_information_available          TINYTEXT    NOT NULL DEFAULT (''),
  wellness_info_comment                   TEXT        NOT NULL DEFAULT (''),
  social_determinants_of_health           TINYTEXT    NOT NULL DEFAULT (''),
  soc_det_health_comment                  TEXT        NOT NULL DEFAULT (''),
  acute_health_status_at_sampling         TINYTEXT    NOT NULL DEFAULT (''),
  acute_health_status_at_sampling_comment TEXT        NOT NULL DEFAULT (''),
  time_last_toothbrush                    TINYTEXT    NOT NULL DEFAULT (''),
  FOREIGN KEY (last_modified_by) REFERENCES users (user_id)
) ENGINE=InnoDB WITH SYSTEM VERSIONING;

# hvp:sam-abcdef
CREATE TABLE IF NOT EXISTS samples (
  uuid                     VARCHAR(50) NOT NULL UNIQUE,
  last_modified_by         INTEGER     NOT NULL,
  sample_uid               VARCHAR(50) NOT NULL PRIMARY KEY,
  timepoint_uid            VARCHAR(50) NOT NULL DEFAULT '',
  lab                      TINYTEXT    NOT NULL DEFAULT (''),
  sample_type              TINYTEXT    NOT NULL DEFAULT (''),
  sample_subtype           TINYTEXT    NOT NULL DEFAULT (''),
  parent_sample_id         TEXT        NOT NULL DEFAULT (''),
  sampling_protocol        TINYTEXT    NOT NULL DEFAULT (''),
  sample_taxonomy          TINYTEXT    NOT NULL DEFAULT (''),
  anatomical_site          TINYTEXT    NOT NULL DEFAULT (''),
  body_product             TINYTEXT    NOT NULL DEFAULT (''),
  collection_method        TINYTEXT    NOT NULL DEFAULT (''),
  sample_collection_device TINYTEXT    NOT NULL DEFAULT (''),
  collection_month_year    TINYTEXT    NOT NULL DEFAULT (''),
  collection_date          TINYTEXT    NOT NULL DEFAULT (''),
  collection_day_of_week   TINYTEXT    NOT NULL DEFAULT (''),
  sample_storage           TINYTEXT    NOT NULL DEFAULT (''),
  sample_additive          TINYTEXT    NOT NULL DEFAULT (''),
  control_sample_id        TINYTEXT    NOT NULL DEFAULT (''),
  sample_processing        TINYTEXT    NOT NULL DEFAULT (''),
  sample_transit_temp      TINYTEXT    NOT NULL DEFAULT (''),
  sample_transit_duration  TINYTEXT    NOT NULL DEFAULT (''),
  stool_type               TINYTEXT    NOT NULL DEFAULT (''),
  self_collection          TINYTEXT    NOT NULL DEFAULT (''),
  is_control_sample        TINYTEXT    NOT NULL DEFAULT (''),
  negative_control_type    TINYTEXT    NOT NULL DEFAULT (''),
  postive_control_type     TINYTEXT    NOT NULL DEFAULT (''),
  FOREIGN KEY (last_modified_by) REFERENCES users (user_id)
) ENGINE=InnoDB WITH SYSTEM VERSIONING;


INSERT INTO users (full_name, affiliation, email, password, added_by)
  VALUES ('Daniel Smith', 'BCM', 'dpsmith@bcm.edu', '$7$C6..../....XzwK5ceDoM1kjl341TPT6UzbP8wCyjWtXxRJHoUyv8B$ktk/WHrp8irF7pIS3BOS.R.vrSeDRK5y2wJ.pIrDio.', 1);

ALTER TABLE users ADD CONSTRAINT users_fk1 FOREIGN KEY (added_by) REFERENCES users(user_id);


CREATE USER 'hvp_local'@'localhost';
GRANT SELECT, INSERT, UPDATE, DELETE ON hvp.* TO 'hvp_local'@'localhost';

FLUSH PRIVILEGES;
