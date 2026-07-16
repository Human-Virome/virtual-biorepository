# Test metadata for upload/validation testing

Six TSV files, one per dictionary table, covering a small but interconnected
batch of synthetic data (3 participants, 4 events, 7 samples, 6 libraries,
2 analyses, 8 files). All identifiers are tagged with the batch prefix
`vast_hvpqa2026_` so they're easy to spot and unlikely to collide with real
data (`vast_` is a valid `UID_PREFIXES` entry per `api/R/globals.r`).

## Upload order (must commit, not just validate, each step first)

Upload and **commit** each file in this order, because `validate_refs()` in
`api/R/validate.r` checks foreign keys against what's already live in the
database — it does not see the other five files as a batch:

1. `1_participants.tsv`
2. `2_events.tsv` (references participants)
3. `3_samples.tsv` (references participants + events; also contains a
   subsample and a composite sample that reference sibling rows in the same
   file — same-table self-references are resolved within one upload)
4. `4_libraries.tsv` (references samples; the aliquot row references its
   parent library within the same file)
5. `5_analyses.tsv`
6. `6_files.tsv` (references libraries and analyses)

If you only click "validate" (dry run) instead of "commit" for an earlier
step, the later steps' foreign-key checks will fail because the parent rows
were rolled back and never actually landed in the database.

## What's exercised

- Required-field enforcement, controlled vocabularies, prefix-ID fields
  (NCBI, UBERON, OBI, SNOMED, DOID, EDAM, DUO, DrugBank-style), `multiple`
  (semicolon-delimited) values, URL reachability checks, MD5 format checks,
  and a real NCBI BioProject accession `PRJNA1336844`.
- Conditional rules: `age` vs `age_range` (incl. the 90+ case), paired
  weight/height + units, animal exposure ↔ exposure type consistency,
  anatomical_site vs body_product, control sample/library flags and types,
  composite samples/libraries, subsamples/aliquots (single self-ref) vs
  composites (semicolon-delimited self-ref), the library "all-or-none"
  sequencing-field rule, and the files table's "exactly one of
  library_uid/analysis_uid" + disease-specific data-use-condition rules.

## Known gap found while building this data set

`samples.participant_uid` and `samples.event_uid` are documented in
`dictionary.js` as accepting the literal value `"mock"` for synthetic
samples (and `database.sql` seeds a matching `mock`/`mock` row), but
`reformat_ids()` in `api/R/validate.r` only ever builds its regex from
`UID_PREFIXES` — it has no special case for the literal string `"mock"`.
As written, submitting `"mock"` in those fields will fail validation with
"missing or invalid identifier". These test files avoid `"mock"`
deliberately, tying every sample to a real participant/event instead. If
mock-sample support matters, `reformat_ids()` needs a special case.

## Regenerating

`generate_test_data.ps1` (run with `powershell -File generate_test_data.ps1`)
rebuilds all six files from scratch. Edit the `hvpqa2026` batch tag if you
need a fresh, non-colliding batch for repeat commit testing (primary keys
can't be reused once committed).
