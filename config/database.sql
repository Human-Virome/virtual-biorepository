CREATE DATABASE hvp;
use hvp;

CREATE TABLE users (
  user_id        INTEGER AUTO_INCREMENT PRIMARY KEY,
  full_name      VARCHAR(100) NOT NULL DEFAULT '',
  affiliation    VARCHAR(100) NOT NULL DEFAULT '',
  email          VARCHAR(100) NOT NULL,
  password       CHAR(60)     NOT NULL,
  alt_password   CHAR(60)     NOT NULL DEFAULT '',
  last_login_utc DATETIME              DEFAULT NULL,
  added_by       INTEGER      NOT NULL,
  added_utc      DATETIME     NOT NULL DEFAULT (UTC_TIMESTAMP())
) ENGINE=InnoDB;

CREATE TABLE auth_tokens (
  auth_token_id    INTEGER AUTO_INCREMENT PRIMARY KEY,
  user_id          INTEGER   NOT NULL,
  auth_token_sha   CHAR(128) NOT NULL,
  valid_until_utc  DATETIME  NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users (user_id)
) ENGINE=InnoDB;

CREATE TABLE uid_suffixes (
  uid_suffix CHAR(6) NOT NULL PRIMARY KEY
) ENGINE=InnoDB;

# hvp:sbj-abcdef
CREATE TABLE subjects (
  subject_uid                   CHAR(14)     NOT NULL PRIMARY KEY,
  subject_name                  VARCHAR(255) NOT NULL DEFAULT '',
	subject_source                VARCHAR(255) NOT NULL DEFAULT '',
	subject_source_id             VARCHAR(255) NOT NULL DEFAULT '',
	alt_subject_id                VARCHAR(255) NOT NULL DEFAULT '',
	subject_source_catalog_number VARCHAR(255) NOT NULL DEFAULT '',
	subject_type                  VARCHAR(255) NOT NULL DEFAULT '',
	species                       VARCHAR(255) NOT NULL DEFAULT '',
	grant_number                  VARCHAR(255) NOT NULL DEFAULT '',
	grant_name                    VARCHAR(255) NOT NULL DEFAULT '',
	project_short_name            VARCHAR(255) NOT NULL DEFAULT '',
	cohort_id                     VARCHAR(255) NOT NULL DEFAULT '',
	access                        VARCHAR(255) NOT NULL DEFAULT '',
	subject_event_name            VARCHAR(255) NOT NULL DEFAULT '',
	subject_comments              VARCHAR(255) NOT NULL DEFAULT ''
) ENGINE=InnoDB;


INSERT INTO users (full_name, affiliation, email, password, added_by)
  VALUES ('Daniel Smith', 'BCM', 'dpsmith@bcm.edu', '$2a$12$Hfj7shdBenM6oJcSJm7CLeVac44mYfb3uAL9T2c9zTigXB1SBwOKO', 1);

CREATE UNIQUE INDEX users_idx1 ON users (email);
CREATE UNIQUE INDEX auth_tokens_idx1 ON auth_tokens (auth_token_sha);
ALTER TABLE users ADD CONSTRAINT users_fk1 FOREIGN KEY (added_by) REFERENCES users(user_id);


CREATE USER 'website'@'localhost';
GRANT SELECT, INSERT, UPDATE, DELETE ON hvp.* TO 'website'@'localhost';

FLUSH PRIVILEGES;
