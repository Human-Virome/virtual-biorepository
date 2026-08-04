$ErrorActionPreference = "Stop"
$dir = Split-Path -Parent $MyInvocation.MyCommand.Path

function Write-Tsv($path, $headers, $rows) {
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add(($headers -join "`t"))
    foreach ($row in $rows) {
        if ($row.Length -ne $headers.Length) {
            throw "Row length $($row.Length) does not match header length $($headers.Length) for $path : $($row -join '|')"
        }
        $lines.Add(($row -join "`t"))
    }
    $content = ($lines -join "`n") + "`n"
    [System.IO.File]::WriteAllText($path, $content, (New-Object System.Text.UTF8Encoding $false))
}

# ---------------- participants ----------------
$headers = @("participant_uid","cohort_uid","host_taxon","race","ethnicity","sex_at_birth","country_of_birth","blood_type","family_medical_history")
$rows = @(
    ,@("vast_hvpqa2026_p001","vast_hvpqa2026_cohort1","NCBI:txid9606","White","Not Hispanic or Latino","female","United States of America","O+","yes")
    ,@("vast_hvpqa2026_p002","vast_hvpqa2026_cohort1","NCBI:txid9606","Black or African American","Not Hispanic or Latino","male","United States of America","A+","yes")
    ,@("vast_hvpqa2026_p003","vast_hvpqa2026_cohort1","NCBI:txid9606","","","","","","")
)
Write-Tsv (Join-Path $dir "1_participants.tsv") $headers $rows

# ---------------- events ----------------
$headers = @("participant_uid","event_uid","age","age_units","age_range","state_or_province_of_residence","vital_status","weight","weight_units","height","height_units","animal_exposure","exposure_animal_type","occupation")
$rows = @(
    ,@("vast_hvpqa2026_p001","vast_hvpqa2026_p001_e1","34","years","","USA: Texas","alive","68","kilograms","165","centimeters","domestic","NCBI:txid9615;NCBI:txid9685","SNOMED:159138004")
    ,@("vast_hvpqa2026_p001","vast_hvpqa2026_p001_e2","","","90+","USA: Texas","alive","","","","","none","","")
    ,@("vast_hvpqa2026_p002","vast_hvpqa2026_p002_e1","45","years","","USA: California","alive","82","kilograms","","","none","","")
    ,@("vast_hvpqa2026_p003","vast_hvpqa2026_p003_e1","8","years","","Mexico: Jalisco","alive","","","","","wildlife","NCBI:txid9986","")
)
Write-Tsv (Join-Path $dir "2_events.tsv") $headers $rows

# ---------------- samples ----------------
$headers = @("sample_uid","participant_uid","event_uid","collection_lab","sample_type","sample_subtype","parent_sample_uid","sampling_protocol","sample_taxonomy","anatomical_site","body_product","collection_month_year","collection_date","sample_storage","sample_additive","is_control_sample","negative_control_type")
$rows = @(
    ,@("vast_hvpqa2026_p001_e1_s1","vast_hvpqa2026_p001","vast_hvpqa2026_p001_e1","bhatt","individual_participant","","","https://www.protocols.io/","NCBI:txid1070528","","UBERON:0001988","2025-01","2025-01-15","-80C","Zymo DNA/RNA Shield","no","")
    ,@("vast_hvpqa2026_p001_e2_s1","vast_hvpqa2026_p001","vast_hvpqa2026_p001_e2","bhatt","individual_participant","","","https://www.protocols.io/","NCBI:txid1070528","UBERON:0002097","","2025-06","2025-06-20","-80C","","no","")
    ,@("vast_hvpqa2026_p002_e1_s1","vast_hvpqa2026_p002","vast_hvpqa2026_p002_e1","dantas","individual_participant","","","https://www.protocols.io/","NCBI:txid1070528","","UBERON:0001988","2025-02","2025-02-10","-80C","RNA Later","no","")
    ,@("vast_hvpqa2026_p003_e1_s1","vast_hvpqa2026_p003","vast_hvpqa2026_p003_e1","dantas","individual_participant","","","https://www.protocols.io/","NCBI:txid1070528","","UBERON:0001988","2025-03","2025-03-05","-80C","","no","")
    ,@("vast_hvpqa2026_p001_e1_s1_sub1","vast_hvpqa2026_p001","vast_hvpqa2026_p001_e1","bhatt","individual_participant","acellular_fraction","vast_hvpqa2026_p001_e1_s1","https://www.protocols.io/","NCBI:txid1070528","","UBERON:0001988","2025-01","2025-01-16","-80C","","no","")
    ,@("vast_hvpqa2026_negctrl01","vast_hvpqa2026_p001","vast_hvpqa2026_p001_e1","bhatt","individual_participant","","","https://www.protocols.io/","NCBI:txid1070528","","UBERON:0001988","2025-01","2025-01-15","-80C","","yes","empty collection device")
)
Write-Tsv (Join-Path $dir "3_samples.tsv") $headers $rows

# ---------------- libraries ----------------
$headers = @("library_uid","sample_uid","library_type","is_library_aliquot","parent_library_uid","extraction_lab","library_prep_lab","sequencing_lab","technique","subspecimen_type","library_processing_url","is_control_library","library_neg_cont_type","paired_or_single","sequencing_platform","sequencing_instrument_model")
$rows = @(
    ,@("vast_hvpqa2026_p001_e1_s1_lib1","vast_hvpqa2026_p001_e1_s1","individual_library","no","","bhatt","bhatt","bhatt","OBI:0002768","bulk","https://www.protocols.io/","","","paired","ILLUMINA","Illumina NovaSeq 6000")
    ,@("vast_hvpqa2026_p001_e1_s1_lib1_aliq1","vast_hvpqa2026_p001_e1_s1","individual_library","yes","vast_hvpqa2026_p001_e1_s1_lib1","bhatt","bhatt","","OBI:0002768","bulk","https://www.protocols.io/","","","","","")
    ,@("vast_hvpqa2026_p002_e1_s1_lib1","vast_hvpqa2026_p002_e1_s1","individual_library","no","","dantas","dantas","dantas","OBI:0002768","bulk","https://www.protocols.io/","","","paired","ILLUMINA","Illumina NovaSeq 6000")
    ,@("vast_hvpqa2026_p003_e1_s1_lib1","vast_hvpqa2026_p003_e1_s1","individual_library","no","","dantas","dantas","dantas","OBI:0002768","bulk","https://www.protocols.io/","","","paired","ILLUMINA","Illumina NovaSeq 6000")
    ,@("vast_hvpqa2026_comp01_lib1","vast_hvpqa2026_comp01","multiplexed_composite_library","no","","bhatt","bhatt","bhatt","OBI:0002117","bulk","https://www.protocols.io/","","","paired","ILLUMINA","Illumina NovaSeq 6000")
    ,@("vast_hvpqa2026_negctrl01_lib1","vast_hvpqa2026_negctrl01","individual_library","no","","bhatt","bhatt","bhatt","OBI:0002768","bulk","https://www.protocols.io/","yes","extraction","paired","ILLUMINA","Illumina NovaSeq 6000")
)
Write-Tsv (Join-Path $dir "4_libraries.tsv") $headers $rows

# ---------------- analyses ----------------
$headers = @("analysis_uid","analysis_description","pipeline_name","pipeline_description","pipeline_version","sop_url","community_workspace","pipeline_container_url")
$rows = @(
    ,@("vast_hvpqa2026_ana_assembly1","Viral metagenome assembly for HVP QA test batch","viral-assembly-pipeline","Quality-trims raw reads, removes host reads, then assembles virus-enriched reads into contigs using metaSPAdes followed by viral contig classification","v1.0.0","https://github.com/","CyVerse","https://hub.docker.com/")
    ,@("vast_hvpqa2026_ana_taxprofile1","Taxonomic profiling of scrubbed sequence reads","tax-profiler","Runs Kraken2 classification against a curated viral reference database followed by Bracken abundance re-estimation","v2.1.0","https://github.com/","Terra","")
)
Write-Tsv (Join-Path $dir "5_analyses.tsv") $headers $rows

# ---------------- files ----------------
$headers = @("file_uid","data_type","file_format","md5_checksum","library_uid","analysis_uid","parent_file_uid","bioproject_id","access","data_use_condition","data_use_specific_limit")
$rows = @(
    ,@("vast_hvpqa2026_p001_e1_s1_lib1_R1.fastq.gz","unscrubbed_sequence_reads","EDAM:format_1930","3d46ec9e7b1d1a7935097318d2e1903e","vast_hvpqa2026_p001_e1_s1_lib1","","","PRJNA1336844","restricted","DUO:0000042","")
    ,@("vast_hvpqa2026_p001_e1_s1_lib1_R2.fastq.gz","unscrubbed_sequence_reads","EDAM:format_1930","d5329362c805a0c219266d131616106f","vast_hvpqa2026_p001_e1_s1_lib1","","","PRJNA1336844","restricted","DUO:0000042","")
    ,@("vast_hvpqa2026_p002_e1_s1_lib1_R1.fastq.gz","unscrubbed_sequence_reads","EDAM:format_1930","a3a3ae58e72058eaf6c8ac125af3d0d2","vast_hvpqa2026_p002_e1_s1_lib1","","","PRJNA1336844","restricted","DUO:0000007","DOID:9352")
    ,@("vast_hvpqa2026_p002_e1_s1_lib1_R2.fastq.gz","unscrubbed_sequence_reads","EDAM:format_1930","6cadee11c953b0187e8d502e17ae81c0","vast_hvpqa2026_p002_e1_s1_lib1","","","PRJNA1336844","restricted","DUO:0000007","DOID:9352")
    ,@("vast_hvpqa2026_p003_e1_s1_lib1_R1.fastq.gz","unscrubbed_sequence_reads","EDAM:format_1930","14503725c3adf11f21a370eff1ceff19","vast_hvpqa2026_p003_e1_s1_lib1","","","PRJNA1336844","open","DUO:0000042","")
    ,@("vast_hvpqa2026_p003_e1_s1_lib1_R2.fastq.gz","unscrubbed_sequence_reads","EDAM:format_1930","d68c469fb0ccf55cb8fedd164fd29d58","vast_hvpqa2026_p003_e1_s1_lib1","","","PRJNA1336844","open","DUO:0000042","")
    ,@("vast_hvpqa2026_ana_assembly1_contigs.fasta","assembly","EDAM:format_1929","fe4ce5c117f9d8d75da4e8172b3edf6e","","vast_hvpqa2026_ana_assembly1","vast_hvpqa2026_p001_e1_s1_lib1_R1.fastq.gz;vast_hvpqa2026_p001_e1_s1_lib1_R2.fastq.gz","","open","DUO:0000042","")
    ,@("vast_hvpqa2026_ana_taxprofile1_report.tsv","counts","EDAM:format_3475","173306a29e4f92eade52d1e2f2e8b4c9","","vast_hvpqa2026_ana_taxprofile1","vast_hvpqa2026_p002_e1_s1_lib1_R1.fastq.gz;vast_hvpqa2026_p002_e1_s1_lib1_R2.fastq.gz","","restricted","DUO:0000007","DOID:9352")
)
Write-Tsv (Join-Path $dir "6_files.tsv") $headers $rows

Write-Output "Done."
