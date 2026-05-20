* SRA - stick to predefined fields only. "not collected" value NOT okay
* BioSamples - any custom fields. "not collected" value IS okay

* Kemi is working from the MIMS packages/templates; all human-like ones combined
https://www.ncbi.nlm.nih.gov/biosample/docs/packages/MIMS.me.human-associated.6.0/



5/5/2026
  - mode_of_administration: Allow multiple values? How to map to multiple prescriptions?
  - lifetime_vaccinations and seasonal_vaccinations: Ok to use CVX IDs?
  - sample_transit_duration and samp_store_dur: What units? -> hours
  - lab: CV needed.

5/14/2026
  - library_aliqout_id: Unclear what this is. Apply uid rules? - Yes
  - sequencing_instrument_model: Far fewer CV entries than sequencing_platform.

combine abx systemic and topical
apply colon seps as optional DB ID addon/suffix




# In case of git complaints:
git push origin main --force
