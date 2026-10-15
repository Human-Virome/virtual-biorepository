# Human Virome Project Virtual Biorepository (VBR)

**https://metadata.human-virome.org**

The Virtual Biorepository (VBR) is the Human Virome Project's (HVP) central
metadata service. Each HVP center deposits metadata about its study
participants, samples, sequencing libraries, analyses, and data files on the
site. The VBR checks every record against one shared HVP data dictionary.
It then turns the accepted records into submissions for the National Center
for Biotechnology Information (NCBI): it registers samples with NCBI
BioSample, and it builds the files needed to deposit sequencing reads in the
Sequence Read Archive (SRA).

In short, the VBR gives the consortium:

- **One metadata standard** for all centers, enforced when data is uploaded
  rather than reconciled afterwards.
- **Instant, specific feedback** that tells depositors exactly which cell of
  which row breaks which rule.
- **Automated NCBI submission.** BioSample accessions are requested, tracked,
  and recorded without depositors filling in NCBI's forms by hand, and SRA
  submission files are generated from the same records.
- **A durable, auditable record** of every change made to the consortium's
  metadata.


## Contents

- [Data Model](#data-model)
- [Depositor Workflow](#depositor-workflow)
- [Validation](#validation)
- [NCBI BioSample Registration](#ncbi-biosample-registration)
- [SRA Submission Files](#sra-submission-files)
- [Security and Data Integrity](#security-and-data-integrity)
- [Architecture](#architecture)
- [Server Setup](#server-setup)


## Data Model

HVP metadata is organized into six linked tables. Each table matches one stage
of the path from a person to a data file:

| Table                          | Describes                                                    | Fields |
|--------------------------------|--------------------------------------------------------------|-------:|
| `participants`                 | Study participants (human or animal hosts) and their cohorts | 17     |
| `participant_event_attributes` | A participant's clinical, lifestyle, and exposure data at a point in time (a visit or "event") | 49 |
| `samples`                      | Specimens collected from participants, including subsamples, composite samples, and controls | 28 |
| `libraries`                    | Extraction and sequencing library preparation, and sequencing details | 19 |
| `analyses`                     | Bioinformatic pipelines and their versions, SOPs, and containers | 8 |
| `files`                        | Sequence reads and derived data files, with checksums and data-use conditions | 12 |

Records point to their parents by unique identifier (UID). A sample names its
participant and event, a library names its sample, and a file names its
library or analysis. The VBR also maintains two tables that it derives from
the six above:

- **`biosamples`**: each sample's record in NCBI BioSample format, ready to
  submit.
- **`sra`**: each sequenced library's record in SRA format, ready to export.

The HVP data dictionary (`html/app/dictionary.js`) defines all 133 fields:
their meaning, examples, allowed values, ontologies, and validation rules.
That one definition drives the field documentation on the website, the Excel
template that depositors fill in, and the server's validation. Because all
three come from the same source, they cannot disagree.

Every record also receives a permanent HVP identifier, for example
`hvps8k2m1q` for a sample. Its prefix names the table (`hvpp` participants,
`hvpe` events, `hvps` samples, `hvpl` libraries, `hvpa` analyses, `hvpf`
files), and an identifier is never reused, even after its record is deleted.


## Depositor Workflow

Depositors sign in with their institutional credentials through Globus and
work on two pages.

**Upload**

1. **Download the template.** The Excel workbook has one worksheet per table.
   Each column header shows the field's definition when selected. Fields with
   a controlled vocabulary have drop-down lists, and numeric fields reject
   values outside their allowed range. Many mistakes are therefore caught
   while the spreadsheet is still being filled in.
2. **Consult the dictionary.** An interactive reference lists every field
   with its definition, the conditions under which it is required, its format
   rules, allowed values, UID format, links to the relevant ontologies, and
   examples.
3. **Validate.** The depositor uploads the completed workbook, or a CSV/TSV
   file of a single table. The VBR checks it without saving anything and
   either lists every problem found or summarizes what the upload would do:
   how many records it would add, update, and delete in each table.
4. **Commit.** Once the file validates, the depositor commits it. The whole
   file is saved in one database transaction, so it is either stored
   completely or not at all.

**Browse**

- View, sort, filter, and page through one's own records in every table.
- Download any table, or all of them as a single workbook. A downloaded
  workbook can be edited and uploaded again: rows carrying an HVP identifier
  update the existing record, and rows left blank apart from the identifier
  delete it. Renaming a UID updates every record that refers to it.
- Select samples and **Assign BioSample IDs**
  (see [NCBI BioSample Registration](#ncbi-biosample-registration)).
- Select libraries and **Export for SRA**
  (see [SRA Submission Files](#sra-submission-files)).


## Validation

Every upload passes through several layers of checks before anything is
stored. All of the errors in a file are reported together, not just the
first one. Each error names its table, field, and spreadsheet row, for
example:

```
samples:collection_date:14: `collection_date` is not a real date: "2025-02-30"
```

### Field format rules

The data dictionary gives each field one or more of about twenty rule types.

| Rule                     | What is checked |
|--------------------------|-----------------|
| Required                 | The field must have a value. |
| Conditionally required   | The field is required only when other fields have certain values. For example, a control type is required for control samples, and sequencing details are required for sequence data. |
| Mutually exclusive       | Only one of two related fields may be given (either-or / not-both). |
| "unavailable"            | For sensitive or hard-to-obtain fields, an explicit `unavailable` satisfies the requirement. This keeps "not known" separate from "forgotten". |
| Controlled vocabulary    | Values must come from a fixed list, for example race, sex at birth, country, sample type, or sequencing platform. |
| Multiple values          | Fields that permit lists accept semicolon-separated values, each of which is checked individually. |
| Ontology terms           | Values must contain a valid term ID from the named ontologies: NCBI Taxonomy, UBERON, Cell Ontology, Disease Ontology, SNOMED CT, NCI Thesaurus, Symptom Ontology, EDAM, Data Use Ontology, CDC CVX vaccine codes, or DrugBank. Human-readable labels such as `Dog [NCBI:txid9615]` are accepted and reduced to the ID. |
| Medication suffixes      | Drug entries may add a route of administration and frequency, for example `DB00945:oral:daily`, and these are checked against fixed lists. |
| Numbers                  | Values must be numeric, whole numbers where required, and within the allowed range. |
| Dates                    | Values must be in `YYYY-MM-DD` or `YYYY-MM` format, be real calendar dates, and fall within the past 100 years. |
| Text                     | Values must not exceed the maximum length. |
| File attributes          | File names must be safe, MD5 checksums must be well formed, and JSON must be valid. |
| URLs                     | Protocol and container links must be well formed, and the VBR checks that they are reachable. |

### Identifier rules

- **Center prefixes.** Every UID must begin with a registered HVP center
  prefix, for example `vast_`, `penn_`, or `wu_wylie_`. This keeps
  identifiers unique across the consortium without central coordination.
- **Uniqueness.** A new UID may not already exist in the database or appear
  twice in the same upload.
- **Referential integrity.** Every reference to another record, such as a
  sample's participant or a file's library, must resolve to a record that
  already exists or is defined in the same upload.
- **Cross-center safety.** When a UID is renamed, the change follows into
  every record that refers to it, including records owned by other centers.
  A record that another center's data depends on cannot be deleted, and the
  error names the account that uploaded the dependent data.

### Checks against NCBI

- **BioProject accessions** (for example `PRJNA…`) are looked up live in
  NCBI's BioProject database.
- **Existing BioSample accessions** (`SAMN…`, `SAMEA…`, `SAMD…`) that a
  center supplies for samples it has already registered are looked up in
  NCBI's BioSample database, and each may be assigned to only one sample.

### Scientific and cross-field rules

Some rules span several fields or tables and are written as code:

- **Unit harmonization.** Ages, heights, and weights may be entered in any
  supported unit. They are converted to years, centimeters, and kilograms,
  and BMI is calculated from them.
- **De-identification.** Ages of 90 years or more must be reported as the
  age range "90+", following HIPAA de-identification rules.
- **Date consistency.** A collection date must fall within the month given
  for collection. The day of the week is filled in from the date, or checked
  against it.
- **Event lineage.** A sample's event must belong to its participant, and a
  subsample must share the event of its parent (or grandparent) sample.
- **Controls.** Control samples and control libraries must state their
  control type, and only experimental records may link to controls.
- **Sequencing readiness.** Sequence-read files require a library and a
  BioProject. Their library must have complete sequencing details (strategy,
  source, selection, layout, platform, and instrument). Derived files, such as
  alignments, assemblies, and counts, must name the analysis and source data
  they came from.


## NCBI BioSample Registration

Before reads can be deposited in SRA, each sample needs an NCBI BioSample
accession. The VBR produces these accessions from the metadata that centers
have already uploaded. No separate data entry is needed.

1. **Automatic record creation.** When a sample is uploaded, the VBR builds
   its BioSample record by combining the sample with its participant and
   collection event. Values are translated to NCBI's attribute names and
   conventions: taxonomy IDs become scientific names through the NCBI
   Taxonomy service, measurements are expressed in standard units, smoking
   history becomes a yes/no answer, animal exposure becomes NCBI's
   `pet_farm_animal` attribute, and so on. Later corrections to the sample,
   participant, or event automatically flow into the BioSample record.
2. **One-click submission.** In the `biosamples` table, the depositor
   selects samples and clicks **Assign BioSample IDs**. The VBR generates an
   NCBI submission XML document under the Human Virome Project consortium,
   with each sample identified by its HVP UID. It uploads the document to
   NCBI's secure submission portal over SFTP.
3. **Status tracking.** The VBR reads the processing reports that NCBI
   posts and shows each sample's progress (submitted, queued, processing,
   processed). When NCBI issues an accession, it is stored with the sample.
   If NCBI rejects a sample, NCBI's error message is shown next to it, and
   the sample can be corrected and submitted again.
4. **Downstream linkage.** New accessions are inserted automatically into
   the SRA records of the sample's libraries.

Once a sample has been sent to NCBI, the VBR refuses any upload that would
change or delete the information NCBI holds, so the VBR and NCBI cannot
drift apart. Centers that registered samples with NCBI themselves can supply
those accessions instead. The VBR verifies them and never submits those
samples a second time.


## SRA Submission Files

The VBR derives one SRA record for each sequenced library from the library's
preparation and sequencing details, its scrubbed (host-removed) read files,
its BioProject, and its sample's BioSample accession. In the `sra` table, the
depositor selects libraries and clicks **Export for SRA**. This downloads an
NCBI SRA submission XML file with one EXPERIMENT and RUN per library. Each
RUN lists its read files with file types and MD5 checksums, ready to submit
together with the files.

Before generating the file, the export confirms that every library has a
BioSample accession, a BioProject, complete sequencing details, and files in
a format that SRA accepts. Any library that falls short is listed with its
problem.


## Security and Data Integrity

- **Institutional sign-in.** Users sign in with their home institution's
  credentials through Globus. No passwords are stored by the VBR. Every
  request is authenticated before it reaches the application.
- **Data ownership.** Each record belongs to the account that uploaded it.
  Depositors browse, edit, and delete only their own records.
- **Complete audit history.** All tables use MariaDB system versioning. Every
  insert, update, and delete is retained with a timestamp, so any record can
  be traced through its history or restored as of a past date.
- **All-or-nothing uploads.** Each upload is a single database transaction,
  and uploads that write data are processed one at a time. Concurrent
  activity can therefore never leave the database partially updated.
- **Hardened server.** All traffic is HTTPS only, with upload size limits and
  automatic blocking of abusive clients (fail2ban). Credentials for NCBI live
  in protected server configuration, not in the code.


## Architecture

| Layer          | Technology |
|----------------|------------|
| Hosting        | AWS Lightsail, Debian 13 |
| Web server     | nginx (TLS via Let's Encrypt) |
| Authentication | oauth2-proxy with Globus Auth (OpenID Connect) |
| Application    | R, served by `httpuv` (`api/`) |
| Database       | MariaDB with system-versioned tables (`config/database.sql`) |
| Front end      | HTML/JavaScript with AG Grid (`html/`) |
| NCBI services  | E-utilities (record lookups) and the NCBI submission portal (SFTP) |

The application keeps its resource use modest. Work such as checking NCBI for
submission status is done during ordinary page requests, with throttling, so
no separate background jobs are needed. Each change pushed to this
repository's `main` branch is deployed automatically: a GitHub Action
notifies the server, which pulls the update and restarts its services.


## Server Setup

An AWS Lightsail Debian 13 4GB memory instance was configured as follows:

On 'Networking' tab, allow ports 22 (ssh), 80 (http), 443 (https), and 3306 (mysql).

```bash
sudo bash

# Create 2GB Swap
fallocate -l 2G /swapfile && chmod 600 /swapfile
mkswap /swapfile && swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab


# System Updates & Dependencies
apt update && apt upgrade -y
apt install -y nginx certbot mariadb-server r-base awscli git fail2ban
R -e "install.packages('pak', repos='https://r-lib.github.io/p/pak/stable/source/linux-gnu/x86_64'); \
      options(repos = c(CRAN = 'https://packagemanager.posit.co/cran/__linux__/trixie/latest'));     \
      pak::pak(c('crul', 'data.table', 'DBI', 'httpuv', 'jsonlite', 'openxlsx2', 'plyr', 'readxl', 'rentrez', 'RMariaDB', 'sftpR', 'stringi', 'webutils', 'xml2'))"

certbot certonly --webroot -w /var/www/html -d metadata.human-virome.org --register-unsafely-without-email --agree-tos


# Install OAuth2 Proxy
wget https://github.com/oauth2-proxy/oauth2-proxy/releases/download/v7.15.2/oauth2-proxy-v7.15.2.linux-amd64.tar.gz
tar -xf oauth2-proxy-v7.15.2.linux-amd64.tar.gz
mv oauth2-proxy-v7.15.2.linux-amd64/oauth2-proxy /usr/local/bin/
chmod +x /usr/local/bin/oauth2-proxy
rm -rf oauth2-proxy-v7.15.2.linux-amd64*

# Change these values. Generate cookie_secret with `openssl rand -base64 32`.
echo 'OAUTH2_PROXY_CLIENT_ID="your_globus_client_id"'          >  /etc/oauth2-proxy.env
echo 'OAUTH2_PROXY_CLIENT_SECRET="your_globus_client_secret"'  >> /etc/oauth2-proxy.env
echo 'OAUTH2_PROXY_COOKIE_SECRET="your_32_byte_cookie_secret"' >> /etc/oauth2-proxy.env
chmod 600 /etc/oauth2-proxy.env

# Change these values.
echo 'NCBI_SFTP_USERNAME="your_ncbi_sftp_username"' >  /etc/httpuv.env
echo 'NCBI_SFTP_PASSWORD="your_ncbi_sftp_password"' >> /etc/httpuv.env
echo 'ENTREZ_KEY="your_ncbi_eutils_api_key"'        >> /etc/httpuv.env
sudo chown root:www-data /etc/httpuv.env
chmod 640 /etc/httpuv.env


git clone https://github.com/Human-Virome/virtual-biorepository.git /var/www/vbr
git config --global --add safe.directory /var/www/vbr
chown -R www-data:www-data /var/www

# Apply Configs (Backup defaults first to prevent symlink errors)
mv /etc/nginx/nginx.conf  /etc/nginx/nginx.conf.bak
mv /etc/mysql/mariadb.cnf /etc/mysql/mariadb.cnf.bak 
ln -s /var/www/vbr/config/nginx.conf           /etc/nginx/nginx.conf
ln -s /var/www/vbr/config/mariadb.cnf          /etc/mysql/mariadb.cnf
ln -s /var/www/vbr/config/jail.local           /etc/fail2ban/jail.local
ln -s /var/www/vbr/config/oauth2-proxy.conf    /etc/oauth2-proxy.conf
ln -s /var/www/vbr/config/oauth2-proxy.service /etc/systemd/system/oauth2-proxy.service
ln -s /var/www/vbr/config/httpuv@.service      /etc/systemd/system/httpuv@.service
ln -s /var/www/vbr/config/vbr-updater.service  /etc/systemd/system/vbr-updater.service
ln -s /var/www/vbr/config/vbr-updater.path     /etc/systemd/system/vbr-updater.path

# Setup Systemd
systemctl daemon-reload
systemctl enable --now vbr-updater.path
systemctl enable --now oauth2-proxy
systemctl enable --now httpuv@8000
systemctl enable --now httpuv@8001

# Restart Services
systemctl restart mariadb nginx fail2ban

mysql -u root < /var/www/vbr/config/database.sql
```

