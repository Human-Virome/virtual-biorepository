const vbrDictionary = {
    "participants": [
    {
        "field":"participant_uid",
        "def":"This is a unique identifier for the participant within a given HVP data generator group (at the grant level), built from the data generator's internal participant id prefixed with the project abbreviation, separated with an underscore. NOTE: the data generator's internal id MUST be unique across that data generator.",
        "cv":"project abbreviation CV for prefixes (to be provided)\nexample:   vast_h3754",
        "req":"yes"
    },
    {
        "field":"cohort_id",
        "def":"Identifier for the cohort to which this participant belongs. Institutional Certification forms must be on file with the HVPCC prior to submission of controlled data. Cohort identifiers must be unique within a data generation group.",
        "cv":"none",
        "req":"yes"
    },
    {
        "field":"host_taxon",
        "def":"The natural (as opposed to laboratory) host to the organism from which the sample was obtained. Use the NCBI taxonomy id e.g. NCBI:txid9606",
        "cv":"NCBI taxononmy\nexample: NCBI:txid9606 ( = \"Homo sapiens\")",
        "req":"yes"
    },
    {
        "field":"age",
        "def":"Participant's age at time of sample collection. If age is >90 then use \"unavailable\" for this field and instead fill in the field 'age range' with the value 'greater than or equal to 90'.\nThis field will allow decimals.",
        "cv":"[enter number (unless greater than 90)]\nunavailable",
        "req":"yes"
    },
    {
        "field":"age_units",
        "def":"The units in which age is reported.",
        "cv":"days\nweeks\nmonths\nyears\nunavailable",
        "req":"yes"
    },
    {
        "field":"age_range",
        "def":"The range in which the participant's age falls.",
        "cv":"0 to <2 (Infant)\n2 to <4 (Toddler)\n4 to <18 (Child)\n18 to <25 (Adult)\n25 to <35\n35 to <45\n45 to <55\n55 to <65\n65 to <75 (Senior)\n75 to <85\n85 to <95\ngreater than or equal to 95 (Elderly)\nunavailable",
        "req":"Required if you are unable to fill in the actual age either due to consent restrictions or due to participant being >90 years old."
    },
    {
        "field":"race",
        "def":"Race of the participant",
        "cv":"Asian\nBlack or African American\nAmerican Indian\/Alaska Native\nNative Hawaiian or Other Pacific Islander\nMiddle Eastern or North African\nWhite\nMulti-racial\nunavailable",
        "req":"yes"
    },
    {
        "field":"ethnicity",
        "def":"Ethnicity of the participant",
        "cv":"Hispanic or Latino\nNot Hispanic or Latino\nunavailable",
        "req":"yes"
    },
    {
        "field":"sex_at_birth",
        "def":"Participant's sex assigned at birth",
        "cv":"male\nfemale\nintersex\nunavailable",
        "req":"yes"
    },
    {
        "field":"state_or_province_of_residence",
        "def":"Participant's state or province of residence at time of sample collection",
        "cv":"[List of states\/territories in US]\n[List of provinces in Canada]\n[List of provinces in Mexico]\nother\nunavailable",
        "req":"yes"
    },
    {
        "field":"country_of_birth",
        "def":"Country where participant was born",
        "cv":"[List of all countries]\nunavailable\n",
        "req":"yes"
    },
    {
        "field":"country_of_childhood_residence",
        "def":"Country where participant resided during childhood",
        "cv":"[List of all countries]\nunavailable\n\n",
        "req":"yes"
    },
    {
        "field":"vital_status",
        "def":"Vital status of participant at time of sampling",
        "cv":"alive\ndeceased\nunavailable",
        "req":"yes"
    },
    {
        "field":"weight",
        "def":"Participant's weight at time of sample collection",
        "cv":"none",
        "req":"no"
    },
    {
        "field":"weight_units",
        "def":"The units in which the weight is reported.",
        "cv":"pounds\nkilograms\nounces",
        "req":"no"
    },
    {
        "field":"height",
        "def":"Participant's height at time of sample collection",
        "cv":"none",
        "req":"no"
    },
    {
        "field":"height_units",
        "def":"The units in which the height is measured",
        "cv":"meters\ncentimeters\nfeet\ninches",
        "req":"no"
    },
    {
        "field":"bmi",
        "def":"Participant's BMI at time of sample collection, calculated as weight\/(height)squared\n",
        "cv":"none",
        "req":"no"
    },
    {
        "field":"number_of_household_members",
        "def":"Number of people (not including participant) who live in participant's household at time of sampling",
        "cv":"none",
        "req":"no"
    },
    {
        "field":"animal_exposure",
        "def":"Participant exposure to animals within the last 6 months where exposure happens in the home, with livestock, or hunting.",
        "cv":"domestic animal exposure\nwildlife exposure\n\n",
        "req":"no"
    },
    {
        "field":"exposure_animal_type",
        "def":"Type of animal that participant has exposure to.",
        "cv":"Use any term id (just the id not the term name) from the NCBI Taxonomy.\nExamples of NCBI Taxonomy terms:\nNCBI:txid9615 dog\nNCBI:txid9685 domestic cat\nNCBI:txid9683 wild cat\nNCBI:txid9986 rabbit\nNCBI:txid10114 rats\nNCBI:txid9838 camel\nNCBI:txid9913 cattle\nNCBI:txid72004 yak\nNCBI:txid9825 pig\nNCBI:txid9940 sheep\nNCBI:txid9796 horse\nNCBI:txid9031 chicken\nNCBI:txid9103 turkey\nNCBI:txid8835 ducks\nNCBI:txid9224 parrots\nNCBI:txid7898 fish\nNCBI:txid9989 rodents\nNCBI:txid9850 deer\nNCBI:txid8504 lizards & snakes\nNCBI:txid30640 squirrel",
        "req":"no"
    },
    {
        "field":"family_income",
        "def":"Family income range of the participant at the time of sampling",
        "cv":"under $25,000\n$25,000 to $49,999\n$50,000 to $74,999\n$75,000 to $99,999\n$100,000 to $149,999\n$150,000 to $199,999\n$200,000 and over",
        "req":"no"
    },
    {
        "field":"occupation",
        "def":"Most frequent job performed by participant at the time of sampling",
        "cv":"Use any term id (just the id not the term name) from the SNOMED Ontology \"Occupation (occupation)\" branch.\nExamples of SNOMED terms:\nSNOMED:106510009 painter\nSNOMED:106290006 veterinarian\nSNOMED:73851001 plumber",
        "req":"no"
    },
    {
        "field":"gestational_age_at_birth",
        "def":"Age of pregnancy (in weeks) when participant was born",
        "cv":"none",
        "req":"no"
    },
    {
        "field":"mode_of_birth_delivery",
        "def":"Method through which participant was delivered",
        "cv":"Vaginal\nCesarean",
        "req":"no"
    },
    {
        "field":"breastfed_status",
        "def":"For adults, this captures whether or not participant was breastfed during infancy; for infants, this captures current status with regard to breastfeeding for participant.",
        "cv":"yes\nyes-exclusively\nyes-partially\nno",
        "req":"no"
    },
    {
        "field":"oral_health",
        "def":"Whether oral health history was collected",
        "cv":"yes\nno",
        "req":"no"
    },
    {
        "field":"dental_exam",
        "def":"Whether dental exam was performed on participant",
        "cv":"yes\nno",
        "req":"no"
    },
    {
        "field":"blood_type",
        "def":"Participant's blood type based on the ABO and Rh systems",
        "cv":"A+\nA\u2212\nB+\nB\u2212\nAB+\nAB\u2212\nO+\nO\u2212",
        "req":"no"
    },
    {
        "field":"family_medical_history",
        "def":"Whether full medical history was collected",
        "cv":"yes\nno",
        "req":"no"
    },
    {
        "field":"systemic_comorbidities",
        "def":"Participant's comorbidities (at the time of sampling), can be described at a general or specific level depending on how center gathered that information. A term id (just the id, not the term name) from the Disease Ontology should be used for this.",
        "cv":"These are examples of Disease Ontology terms, you are NOT limited to these terms:\nDOID:3463 breast disease\nDOID:1287 cardiovascular system disease\nDOID:28 endocrine system disease\nDOID:77 gastrointestinal system disease\nDOID:74 hematopoietic system disease\nDOID:2914 immune system disease\nDOID:16 integumentary system disease\nDOID:17 musculoskeletal system disease\nDOID:863 nervous system disease\nDOID:15 reproductive system disease\nDOID:1579 respiratory system disease\nDOID:0060118 thoracic disease\nDOID:18 urinary system disease\n---\nDOID:6713 cerebrovascular disease\nDOID:1307 dementia\nDOID:10763 hypertension\nDOID:0050589 inflammatory bowel disease\nDOID:11714 gestational diabetes\nDOID:11476 Osteoporosis",
        "req":"no"
    },
    {
        "field":"mental_health_history",
        "def":"Mental health conditions that participant has experienced in the past, but is not currently experiencing. Use a term id (just the id, not the term name) from the disease of mental health branch of the Disease Ontology",
        "cv":"Disease Ontology\nexample terms:\nDOID:1596 - depressive disorder\nDOID:10933 - obsessive-compulsive disorder\nDOID:3312 - bipolar disorder\nDOID:2030 - anxiety disorder\nYou are NOT limited to these terms, they are just examples. Browse the whole mental health branch at DO here",
        "req":"no"
    },
    {
        "field":"mental_health_at_sampling",
        "def":"Mental health conditions that participant is experiencing at time of sample collection. Use a term id (just the id, not the term name) from the disease of mental health branch of the Disease Ontology",
        "cv":"Disease Ontology\nexample terms:\nDOID:1596 - depressive disorder\nDOID:10933 - obsessive-compulsive disorder\nDOID:3312 - bipolar disorder\nDOID:2030 - anxiety disorder\nYou are NOT limited to these terms, they are just examples. Browse the whole mental health branch at DO here",
        "req":"no"
    },
    {
        "field":"disabilities",
        "def":"Participant's disabilities at time of sample collection",
        "cv":"We encourage people to use terms from the Disease Ontology or Symptom Ontology where available. Use just the term id (just the id, not the term name).\nSome example terms:\nDOID:1059 - intellectual disability\nDOID:8927 - learning disability\nDOID:1432 - blindness\nSYMP:0000019 - deafness\nDOID:0050563 - nonsyndromic deafness\nDOID:150 - disease of mental health\n(be sure to also consider the children of the above example terms)\nOtherwise a term from below can be chosen or free text is allowed, but please contact us when you need to use free text so that we can try to find a term.\nCommunication Disabilities\nHearing Disabilities\nVisual Disabilities\nPhysical Disabilities\nTemporary Disabilities",
        "req":"no"
    },
    {
        "field":"prescription_medications",
        "def":"Prescription medication participant was taking regularly as prescribed at time of sample collection. Use any drug term (format DB#####) from the DrugBank collection.",
        "cv":"Please use a DrugBank term id (just the id, not the term name), such as those provided in the examples below. Note that terms in the list below are just a few examples out of thousands of terms.\nDB01076 Atorvastatin\nDB00722 Lisinopril\nDB00996 Gabapentin\nDB01001 Albuterol\nYou can also use the search function on the DrugBank website to find needed terms. We will also provide a look-up table (as spreadsheet or tsv) that you can use to find the id for the medication in question. This table will have the primary name as well as all synonyms for the medication in it so that no matter what name you are searching with, you should still find the DrugBank drug id that you need. This can be used to largely automate the process of mapping your metadata to the DrugBank terms. If DrugBank does not have the term you need, please use \"other:freetext\" (for example \"other:amazinase\") and contact the HVPCC.",
        "req":"no"
    },
    {
        "field":"mode_of_administration",
        "def":"Mode of administration of each prescription medication",
        "cv":"oral\nintranasal\ninhalation\nrectal\nvaginal\ninjected\ntopical",
        "req":"no"
    },
    {
        "field":"systemic_antibiotic_or_antiviral_use",
        "def":"List any antibiotics or antivirals taken orally or intravenously within 3 months of sampling. Use DrugBank identifiers and separate them with semicolons.",
        "cv":"Please use a Drugbank term id (just the id, not the term name), such as the examples provided in the list below. Note that the list below is not exhaustive, it's just a few examples.\nDB01060 Amoxicillin\nDB16691 Nirmatrelvir",
        "req":"no"
    },
    {
        "field":"topical_antibiotic_or_antiviral_use",
        "def":"List any antibiotics or antivirals used topically within 3 months of sampling. Use DrugBank identifiers and separate them with semicolons.",
        "cv":"Please use a Drugbank term id (just the id, not the term name), such as the examples provided in the list below. Note that the list below is not exhaustive, it's just a few examples.\nDB00781 Polymyxin B\nDB00626 Bacitracin",
        "req":"no"
    },
    {
        "field":"otc_medications",
        "def":"Over-the-counter medication participant was taking or had taken at time of sample collection. Use any drug term id (format DB#####) from the DrugBank collection.",
        "cv":"Please use a Drugbank term id (just the id, not the term name), such as the examples provided in the list below. Note that the list below is not exhaustive, it's just a few examples.\nDB00945 Aspirin\nDB00316 Acetaminophen\nDB01050 Ibuprofen\nDB00341 Cetirizine\nYou can also use the search function on the DrugBank website to find needed terms. We will also provide a look-up table (as spreadsheet or tsv) that you can use to find the id for the medication in question. This table will have the primary name as well as all synonyms for the medication in it so that no matter what name you are searching with, you should still find the DrugBank drug id that you need. This can be used to largely automate the process of mapping your metadata to the DrugBank terms.  If DrugBank does not have the term you need, please use \"other:freetext\" (for example \"other:fantastica\") and contact the HVPCC.",
        "req":"no"
    },
    {
        "field":"supplements_or_vitamins_or_herbal",
        "def":"Supplements, vitamins, herbal items, etc. that participant was taking or had taken at time of sample collection. Use any drug term (format DB#####) from the DrugBank collection.",
        "cv":"Please use a Drugbank term identifier (just the id, not the term name), such as those provided in the list below. Note that the list below is not exhaustive.\nDB14276 Turmeric\nDB06755 Beta carotene\nDB11321 Cod liver oil\nDB01323 St. John's wort\nYou can also use the search function on the DrugBank website to find needed terms. We will also provide a look-up table (as spreadsheet or tsv) that you can use to find the id for the medication in question. This table will have the primary name as well as all synonyms for the medication in it so that no matter what name you are searching with, you should still find the DrugBank drug id that you need. This can be used to largely automate the process of mapping your metadata to the DrugBank terms. If DrugBank does not have the term you need, please use \"other:freetext\" (for example \"other:weird_supplement\") and contact the HVPCC.",
        "req":"no"
    },
    {
        "field":"lifetime_vaccinations",
        "def":"All vaccinations patient has received",
        "cv":"[CV of CDC list of vaccines]\nList all vaccines in one field separated by semicolons.\n",
        "req":"no"
    },
    {
        "field":"seasonal_vaccinations",
        "def":"Seasonal vaccinations participant received within the past year, such as those for COVID-19 and influenza",
        "cv":"List all vaccines in one field separated by semicolons.",
        "req":"no"
    },
    {
        "field":"alcohol_activity_collected",
        "def":"Is information on alcohol activity collected?",
        "cv":"yes\nno",
        "req":"no"
    },
    {
        "field":"alcohol_consumption",
        "def":"A description of the level of alchohol consumption in which the participant engages. This field can also capture former use.",
        "cv":"never\noccasionally (1-3 times per month or less)\nweekly\ndaily\nformer alcohol consumer, at least one month without \nformer alcohol consumer, at least one year without\ncurrent alcohol consumer (use when more specific information on frequency is not availalbe)",
        "req":"no"
    },
    {
        "field":"tobacco_use_collected",
        "def":"Is information on tobacco use collected?",
        "cv":"yes\nno",
        "req":"no"
    },
    {
        "field":"cigarette_smoking",
        "def":"A description of the level of participant cigarette use. This field can also capture former use. Note that a smoker is defined as someone who has had more than 100 cigarettes in their lifetime. Anyone who has had less than 100 is considered a non-smoker.",
        "cv":"non-smoker (<100 cigarettes lifetime)\nformer cigarette smoker, at least one month without\nformer cigarette smoker, at least one year without\ncurrent cigarette smoker",
        "req":"no"
    },
    {
        "field":"former_pack_years",
        "def":"Measurement of amount of cigarette smoking that is calaculated as packs-per-day times the number of years",
        "cv":"none",
        "req":"no"
    },
    {
        "field":"current_pack_years",
        "def":"Measurement of amount of cigarette smoking that is calaculated as packs-per-day times the number of years",
        "cv":"none",
        "req":"no"
    },
    {
        "field":"other_tobacco_exposure",
        "def":"A description of the level of particiopant tobacco use other than smoking cigarettes such as chewing, cigars, etc. This field can also capture former use.",
        "cv":"never\noccasionally (1-3 times per month or less)\nweekly\ndaily\nformer other tobacco use, at least one month without \nformer other tobacco use, at least one year without\ncurrently other tobacco use (use when more specific information on frequency is not availalbe)",
        "req":"no"
    },
    {
        "field":"vaping_behavior",
        "def":"A description of the level of vaping in which the participant engages. This field can also capture former use.",
        "cv":"never\noccasionally (1-3 times per month or less)\nweekly\ndaily\nformer vaping, at least one month without \nformer vaping, at least one year without\ncurrently vaping (use when more specific information on frequency is not availalbe)",
        "req":"no"
    },
    {
        "field":"cannabis",
        "def":"A description of the level of cannabis exposure the participant has experiened, This field can also capture former use.",
        "cv":"never\noccasionally (1-3 times per month or less)\nweekly\ndaily\nformer cannabis user, at leats one month without \nformer cannabis user, at leats one year without \ncurrent cannabis user (use when more specific information on frequency is not availalbe)",
        "req":"no"
    },
    {
        "field":"recreational_or_illicit_drugs",
        "def":"A description of the level of recreational\/illicit drug, excluding cannabis, exposure the participant has experienced, This field can also capture former use. More than one value can be entered and should be separated with semicolons",
        "cv":"Populate this field with two things a DrugBank id (just the id not the term name) for the substance in question, if known, followed by a colon and then one of the below terms for amount of use. \nIf the substance is not known\/available\/provided, replace the DrugBank id with \"unknown\". If there is no term in DrugBank for the substance, use free text and also inform the HVPCC.\nTerms for amount of use:\nnever\noccasionally (1-3 times per month or less)\nweekly\ndaily\nformer use, at least one month without\nformer use, at least one year without \ncurrent use (use when more specific information on frequency is not availalbe)\nTerm for mode of delivery:\noral\nintranasal\ninhalation\nrectal\nvaginal\ninjected\ntopical\nExample entries:\nDB01452:weekly:injection\nDB00907:daily:oral\nunknown:occasionally;unknown (\"unknown\" in this example indicates times when the exact drug as well as the. mode of delivery is not known\/provided\/available)\nfree_text:daily:oral (\"free_text\" is filled in with the name of the drug for times when the substance is known, but there is no term in DrugBank for it)",
        "req":"no"
    },
    {
        "field":"current_geography",
        "def":"Geographic setting of participant at time of sampling",
        "cv":"urban: densely populated area with extensive housing, infrastructure, and services (e.g., cities).\n\nsuburban: residential area on the outskirts of a city with moderate population density and access to urban amenities.\n\nsemi-rural: area with mixed suburban and rural characteristics, such as small towns or communities near open land.\n\nrural: sparsely populated area with open land or farmland and limited infrastructure or services.",
        "req":"no"
    },
    {
        "field":"diet",
        "def":"Is information on diet available?",
        "cv":"yes\nno",
        "req":"no"
    },
    {
        "field":"diet_comment",
        "def":"free text to put whatever additional info related to diet that you wish",
        "cv":"none",
        "req":"no"
    },
    {
        "field":"physical_activity",
        "def":"Is information on physical activity available?\n",
        "cv":"yes_self_reported\nyes_wearables\nno\n",
        "req":"no"
    },
    {
        "field":"physical_activity_comment",
        "def":"free text to put whatever additional info related to physical activity that you wish",
        "cv":"none",
        "req":"no"
    },
    {
        "field":"wellness_information_available",
        "def":"Is information on wellness measures available? Examples may include stress exposure, mindfulness or gratitude practices, prayer, self-care, professional fulfillment, burnout assessments, etc",
        "cv":"yes\nno",
        "req":"no"
    },
    {
        "field":"wellness_info_comment",
        "def":"free text to put whatever additional info related to wellness information that you wish",
        "cv":"none",
        "req":"no"
    },
    {
        "field":"social_determinants_of_health",
        "def":"Is information on social determinants of health available? Examples include financial issues, emotional, degree, employment, etc",
        "cv":"yes\nno",
        "req":"no"
    },
    {
        "field":"soc_det_health_comment",
        "def":"free text to put whatever additional info related to social determinants of health that you wish",
        "cv":"none",
        "req":"no"
    },
    {
        "field":"acute_health_status_at_sampling",
        "def":"Whether participant is or has been acutely ill with an infection within the past month before sampling. Examples of acute illness include the common cold, the flu, and COVID",
        "cv":"yes\nno",
        "req":"no"
    },
    {
        "field":"acute_health_status_at_sampling_comment",
        "def":"free text to put whatever additional info related to acute illness at sampling (such as what the illness is) that you wish",
        "cv":"none",
        "req":"no"
    },
    {
        "field":"time_last_toothbrush",
        "def":"Specification of the time in hours since last toothbrushing",
        "cv":"none",
        "req":"no"
    }
],
    "samples": [
    {
        "field":"sample_uid",
        "def":"This is a unique identifier for the sample within a given HVP data generator group (at the grant level), built from the data generator's internal sample id prefixed with the project abbreviation, separated with an underscore. NOTE: the data generator's internal id MUST be unique across that data generator.",
        "cv":"project abbreviation CV for prefixes (to be provided)\nexample:   vast_sam_3754",
        "req":"yes"
    },
    {
        "field":"lab",
        "def":"Lab, group, or facility within a grant-level project where the sample was collected and\/or processed. This should be the group responsible for metadata about the sample.",
        "cv":"CV from HVPCC (to be provided)",
        "req":"yes"
    },
    {
        "field":"participant_uid",
        "def":"Identifier of the participant (s) from which the sample came. Participant id must be unique within a project. This participant id should have associated metadata from the Participant Metadata dictionary. For composite samples, indicate identifers of all participants from which the composite sample was built, separate values with a semicolon. If this is a mock or synthetic sample, put \"mock\" in this field",
        "cv":"none but use \"mock\" for mock or synthetic samples",
        "req":"yes"
    },
    {
        "field":"sample_type",
        "def":"Indicates the composition of the sample -  describes if the sample comes from one participant or is a mixture of material from more than one participant. This field can also include terms for various in vitro or cell culture systems. Contact the HVPCC if you need additional vocabulary terms for this field.\n\nNeed to think about spike ins - separate field or combined CV terms",
        "cv":"individual_participant\nindividual_participant_with_spikein\ncomposite_of_individuals\ncomposite_of_individuals_with_spikein\norganoid\norganoid_with_spikein\ncomposite_of_organoids\ncomposite_of_organoids_with_spikein\n\nContact the HVPCC if you need additional CV terms for this field",
        "req":"yes"
    },
    {
        "field":"sample_subtype",
        "def":"Term to describe the type of subsample that was derived from a primary sample. For example:  if stool is collected as a primary sample, the acellular portion of the stool could be a subsample of the primary sample with its own sample_id identifier. In cases such as blood fractions (e.g. plasma) derived from whole blood, there are available terms here, but there may also be Uberon and Cell Ontology terms that can be used in one or both of the fields anatomical_site and body_product.  ",
        "cv":"Internal CV -  data generators should tell HVPCC what other terms are needed. Note: if a term for the item exists in Uberon or the Cell Ontology, please use that instead of making an internal CV term:\nviral_particles\nacellular_fraction\ncellular_fraction\nwhole_neat_blood\nwhole_blood (consider use of uberon term as described below)\nblood_fraction_plasma (consider use of uberon as described terms below)\nblood_fraction_buffy_coat\nblood_fraction_erythrocytes (consider use of uberon\/CL terms below)\ntissue",
        "req":"no"
    },
    {
        "field":"parent_sample_id",
        "def":"This field holds parent sample identifiers from two scenarios: the identifiers of the individual samples from which a composite sample was built, separate values with a semicolon; OR the sample identifier of the primary sample or subsample which is the parent to a subsample.",
        "cv":"none",
        "req":"Required for composite samples and subsamples."
    },
    {
        "field":"sampling_protocol ",
        "def":"A stable, permanent url where documentation on the details of the sampling protocol and how it was performed can be found. The description must be detailed enough that others can reproduce the process. Suggested locations for this information include, but are not limited to, GitHub, Read the Docs, and protocols.io",
        "cv":"url",
        "req":"yes"
    },
    {
        "field":"sample_taxonomy",
        "def":"Sample taxonomy. You can use any term from the NCBI taxonomy database but we anticipate frequent use of NCBI:txid1070528 - human viral metagenome",
        "cv":"Example:  NCBI:txid1070528 - human viral metagenome",
        "req":"yes"
    },
    {
        "field":"anatomical_site",
        "def":"Uberon ontology term for anatomical structure from which sample was obtained. You can use any term from the Uberon ontology \"anatomical structure\" branch. \nWhen you have a sample that is at the cell type level, you can use a Cell Ontology term, the Cell Ontology terms are included as part of the Uberon structure as the most specific terms in an anatomical site. Cell Ontology terms have \"CL:####\" ids and Uberon terms have \"UBERON:####\" ids - both are allowed in this field.\nUberon home where you can search for both uberon and cell ontology terms:  https:\/\/www.ebi.ac.uk\/ols4\/ontologies\/uberon\n\n",
        "cv":"Examples of Uberon terms. These are just examples, there are many more terms that are both more specific and more general for you to choose from in Uberon. You are NOT limited to use just the terms listed here - you should use any term from Uberon (and at the most granular level, the Cell Ontology) that is appropriate. Ideally you should use the most specific term that applies to your data. Please browse around Uberon using the Ontology Lookup Service to find the most appropriate term for your samples. You will be able to see Cell Ontology terms when you search Uberon (as cells are the most granular anatomical structure). \nUberon home where you can search for both Uberon and Cell Ontology terms:  https:\/\/www.ebi.ac.uk\/ols4\/ontologies\/uberon.  \nUBERON:0002097 - skin\nUBERON:0003672 - dentition (teeth)\nUBERON:0001567 - cheek\nUBERON:0006956 - buccal mucosa\nUBERON:0001723 - tongue\nUBERON:0009471 - dorsum of tongue\nUBERON:0000165 - mouth\nUBERON:0000167 - oral cavity\nUBERON:0000341 - throat\nUBERON:0000004 - nose\nUBERON:0001729 - oropharynx\nUBERON:0001728 - nasopharynx\nUBERON:0036263 - supraglottic part of larynx\nUBERON:0001737 - larynx\nUBERON:0000970 - eye\nUBERON:0000955 - brain\nUBERON:0002298 - brainstem\nUBERON:0002240 - spinal cord\nUBERON:0000029 - lymph node\nUBERON:0000948 - heart\nUBERON:0002048 - lung\nUBERON:0008951 - left lung lobe\nUBERON:0006518 - right lung lobe\nUBERON:0002174 - middle lobe of right lung\nUBERON:0002107 - liver\nUBERON:0000059 - large intestine\nUBERON:2001371 - pancreatic system\nUBERON:0000996 - vagina\nUBERON:0000079 - male reproductive system\nUBERON:0001987 - placenta\nUBERON:0000310 - breast\nUBERON:0013691 - buttock\nUBERON:0002331 - umbilical cord\nUBERON:0001009 - circulatory system\nCL:0000232 - erythrocyte\nCL:0002253 - epithelial cell of large intestine\nCL:1001578 - vagina squamous cell\nCL:1001576 - oral mucosa squamous cell\nunavailable",
        "req":"At least one of either anatomical_site or body_product must be filled in."
    },
    {
        "field":"body_product",
        "def":"Uberon ontology term for the substance collected from the participant, e.g. stool, mucus, urine. You can use any term from the Uberon ontology \"organism substance\" branch. Uberon home: https:\/\/www.ebi.ac.uk\/ols4\/ontologies\/uberon",
        "cv":"Examples of terms from the 'organism substance' branch of Uberon. These are just examples - you are NOT limited to use just these terms, anything from the 'organism substance' branch is allowed.\nUBERON:0016482 - dental plaque\nUBERON:0016485 - supragingival plaque\nUBERON:0001088 - urine\nUBERON:0001988 - feces\nUBERON:0001913 - milk\nUBERON:0000316 - cervical mucus\nUBERON:0002306 - nasal mucus\nUBERON:0000912 - mucus\nUBERON:0001827 - tear fluid\nUBERON:0001836 - saliva\nUBERON:0000178 - whole blood\nUBERON:0012168 - umbilical cord blood\nUBERON:0001969 - blood plasma\nUBERON:0001977 - blood serum\nUBERON:0001359 - cerebrospinal fluid\nUBERON:0001089 - sweat\nUBERON:0001968 - semen\nUBERON:0000173 - amniotic fluid\nUBERON:0036243 - vaginal fluid\nUBERON:0009511 - bronchoalveolar lavage fluid\nUBERON:0000479 - tissue\nunavailable",
        "req":"At least one of either anatomical_site or body_product must be filled in."
    },
    {
        "field":"collection_method",
        "def":"Process used to collect the sample, (e.g., bronchoalveolar lavage (BAL))\nComment: Terms from  the 'biospecimen collection method' or 'diagnostic procedure' branches in NCIT should be used for this field. If you have difficulty finding a term in NCIT that corresponds to your method, contact the HVPCC.",
        "cv":"Examples of terms from the 'biospecimen collection method' or 'diagnostic procedure' branches of NCIT. You are NOT limited to use just these terms, other terms in the NCIT branches are fine,\nNCIT:C113747 - buccal swab\nNCIT:C132119 - nasal swab\nNCIT:C207895 - skin swab\nNCIT:C15189 - biopsy procedure\nNCIT:C28221 - phlebotomy\nNCIT:C85551 - finger stick\nNCIT:C94576 - scrape\nNCIT:C28743 - punch Biopsy\nNCIT:C15327 - lumber puncture\nNCIT:C200884 - stool collection\nNCIT:C200883 - saliva collection\nNCIT:C200885 - urine collection\nNCIT:C132126 - nasal wash and collection\nNCIT:C61409 - tissue dissection\nNCIT:C51913 - bronchoalveolar lavage\nNCIT:C192845 - esophageal endoscopic brush cytology\nunavailable",
        "req":"yes"
    },
    {
        "field":"sample_collection_device",
        "def":"Method or device employed for collecting sample. You can use any term from the SNOMED ontology \"Device (physical object)\" branch  ",
        "cv":"Examples of terms from the 'device (physical object)' branche of SNOMED. You are NOT limited to use just these terms, other terms in the SNOMED branch are also fine,\nSNOMED:466460008 - Blood collection paper (physical object)\nSNOMED:700956008 - Blood collection needle, basic (physical object)\nSNOMED:706067003 - Blood collection\/transfer device (physical object)\nSNOMED:466722000 - Blood collection tube holder\/needle (physical object)\nSNOMED:350810002 - Lancet (physical object)\nSNOMED:702223006 - Sputum specimen container (physical object)\nSNOMED:118377000 - Biopsy needle, device (physical object)\nSNOMED:466467006 - Biopsy punch (physical object)\nSNOMED:37759000 - Surgical instrument, device (physical object)\nSNOMED:272206003 - Curette (physical object)\nSNOMED:408098004 - Swab (physical object)\nSNOMED:1141810006 - Cytology scraper (physical object)\nSNOMED:994005 - Brush, device (physical object)\nSNOMED:469214007 - Lumbar puncture needle (physical object)\nSNOMED:465630004 - Suction system catheter, general-purpose (physical object)\nSNOMED:105790004 - Bag\/balloon\/bottle, device (physical object)\nSNOMED:360005000 - Urine bottle (physical object)\nSNOMED:1141821002 - Flexible video bronchoscope (physical object)\nSNOMED:24174009 - Bronchoscope, device (physical object)\nSNOMED:706047007 - Fecal specimen container (physical object)\nSNOMED:706056004 - Evacuated urine specimen container (physical object)\nSNOMED:446033002 - Protected specimen brush (physical object)\nUnavailable",
        "req":"no"
    },
    {
        "field":"collection_month_year",
        "def":"Month and year sample was collected using format YYYY-MM e.g. 2025-07",
        "cv":"none",
        "req":"yes"
    },
    {
        "field":"collection_date",
        "def":"Date sample was collected using format YYYY-MM-DD e.g. 1990-10-30",
        "cv":"none",
        "req":"no"
    },
    {
        "field":"collection_day_of_week",
        "def":"Day of the week the sample was collected.",
        "cv":"[Days of the week]",
        "req":"no"
    },
    {
        "field":"sample_storage",
        "def":"Method or condition of sample storage",
        "cv":"This is an internal CV maintained by the HVPCC, if you need a term that is not here, please contact the HVPCC:\nLiquid Nitrogen\nRoom Temperature\n-80\u00b0C\n4\u00b0C\nFFPE\nunavailable",
        "req":"yes"
    },
    {
        "field":"sample_additive",
        "def":"Additive\/preservative in which sample is stored or initially stored",
        "cv":"This is an internal CV maintained by the HVPCC, if you need a term that is not here, please contact the HVPCC:\nRNA Later\nQiagen Allprotect\nGlycerol\nEthanol\nOral Cocktail \nPBS\/Saline\nVTM \nZymo DNA\/RNA Shield\nNone\/Neat\nPIC\nDNA Shield\nunavailable",
        "req":"yes"
    },
    {
        "field":"control_sample_id",
        "def":"Sample identifier of linked control. This can be a semicolon separated list, if there are multiple controls associated with the sample. This field is to be populated for experimental samples, not for control sample. This field is to link to an experimental sample to any control samples that were generated in association with the experimental sample.",
        "cv":"none",
        "req":"no"
    },
    {
        "field":"sample_processing",
        "def":"Processing applied to the sample during or after isolation",
        "cv":"none",
        "req":"no"
    },
    {
        "field":"sample_transit_temp",
        "def":"Temparature between sample collection and processing or archive in degrees Celsius",
        "cv":"none",
        "req":"no"
    },
    {
        "field":"sample_transit_duration",
        "def":"Time between sample collection and either processing or archiving",
        "cv":"none",
        "req":"no"
    },
    {
        "field":"stool_type",
        "def":"Consistency of stool, using the Bristol stool chart",
        "cv":"Type 1 - Separate hard lumps, like nuts\nType 2 - Sausage-shaped but lumpy\nType 3 - Sausage-like with cracks on surface\nType 4 - Smooth, soft, snake-like\nType 5 - Soft blobs with clear edges\nType 6 - Mushy, ragged edges\nType 7 - Watery, no solid pieces",
        "req":"no"
    },
    {
        "field":"self_collection",
        "def":"Whether sample was collected by participant",
        "cv":"yes\nno",
        "req":"no"
    },
    {
        "field":"is_control_sample",
        "def":"whether this sample is a control (negative or positive) ",
        "cv":"yes\nno",
        "req":"yes"
    },
    {
        "field":"negative_control_type",
        "def":"The substance or equipment used as a negative control in an investigation, e.g. distilled water empty collection device.\nRequired only for negative control samples",
        "cv":"This is an internal CV maintained by the HVPCC, if you need a term that is not here, please contact the HVPCC:\ndistilled water\nphosphate buffer\nempty collection device\nDNA-free PCR mix\nsterile swab\nsterile syringe\nsynthetic community",
        "req":"If is_control_sample values is \"yes\", then this field OR positive_control_type is required."
    },
    {
        "field":"postive_control_type",
        "def":"The substance or equipment used as a positive control in an investigation, e.g. synthetic community.\nRequired only for positive control samples",
        "cv":"This is an internal CV maintained by the HVPCC, if you need a term that is not here, please contact the HVPCC:\nsynthetic community\nspike-in sample",
        "req":"If is_control_sample values is \"yes\", then this field OR negative_control_type are required."
    }
],
    "libraries": [
    {
        "field":"library_uid",
        "def":"This is a unique identifier for the sequencing library or processed sample for other technoloiges (e.g. mass spectrometry) within a given HVP data generator group (at the grant level), built from the data generator's internal library\/processed sample id prefixed with the project abbreviation, separated with an underscore. NOTE: the data generator's internal id MUST be unique across that data generator.",
        "cv":"project abbreviation CV for prefixes (to be provided)\nexample:   vast_lib_3754",
        "req":"yes"
    },
    {
        "field":"sample_uid",
        "def":"Sample identifier from which the library or processed sample was derived. ",
        "cv":"none",
        "req":"yes"
    },
    {
        "field":"bioproject_id",
        "def":"The NCBI bioproject_id associated with this library\/processed sample at the sub_bioproject level that is specific to the study this library is part of.\n",
        "cv":"none",
        "req":"yes"
    },
    {
        "field":"library_type",
        "def":"Indicates the composition of the library or processed sample with respect to whether it is a single individual library or a composite library composed of multiple individual libraries\/processed samples. ",
        "cv":"individual_library\nmultiplexed_composite_library",
        "req":"yes"
    },
    {
        "field":"library_aliquot",
        "def":"Is this an aliquot, or subsample, of the original library or processed sample?",
        "cv":"yes\nno",
        "req":"yes"
    },
    {
        "field":"parent_library_id",
        "def":"Only applicable if library_aliquot equals yes or to composite libraries. The identifier(s) of the library(ies)\/processed samples from which a library\/processed sample is built or from which an aliquot was taken. ",
        "cv":"list of library_id identifiers separated by semicolons.",
        "req":"no"
    },
    {
        "field":"technique",
        "def":"Technique performed to create the library\/processed sample",
        "cv":"Use a term from the OBI ontology assay branch. Here are some examples, this is NOT an exhaustive list:\nOBI:0002768, whole virome sequencing assay\nOBI:0000748, bisulfite sequencing assay\nOBI:0002117, whole genome sequencing assay\nOBI:0002765,  microbiome protein expression profiling assay\n\n[Contact the HVPCC if you need a term not found in OBI or if you need help finding a term in OBI.]",
        "req":"yes"
    },
    {
        "field":"subspecimen_type",
        "def":"A term to describe the nature of the sample to differentiate between processes focusing on single cells or nuclei and processes that operate on many cells in a mixture.",
        "cv":"single cells\nsingle nuclei\nbulk",
        "req":"no"
    },
    {
        "field":"library_processing",
        "def":"Processes applied during library preparation or sample processing.",
        "cv":"A stable, permanent url where documentation on the details of the library preparation or sample processing protocol can be found. The description must be detailed enough that others can reproduce the process. Suggested locations for this information include, but are not limited to, GitHub, Read the Docs, and protocols.io",
        "req":"no"
    },
    {
        "field":"samp_store_dur",
        "def":"How long has the sample been in storage at time of final sample processing and\/or library prep",
        "cv":"none",
        "req":"no"
    },
    {
        "field":"control_library_id",
        "def":"Library identifier of linked control. This can be a semicolon separated list, if there are multiple controls associated with the library\/processed sample. This field is to be populated for experimental libraries\/processed samples, not for control libraries\/processed samples. This field is to link to an experimental libary\/processed sample to any control libraries\/processed samples that were generated in association with the experimental library\/processed sample.",
        "cv":"none",
        "req":"no"
    },
    {
        "field":"is_control_library",
        "def":"whether this library is a negative or positive control",
        "cv":"yes\nno",
        "req":"no"
    },
    {
        "field":"library_pos_cont_type",
        "def":"The element or step in the sample processing and\/or library generation process for which the control library or processed sample has been generated.",
        "cv":"extraction\nextraction_kit\nhybridization\nlibrary prep\nsequencing\ncapture\n[Contact the HVPCC to add terms to this vocabulary]",
        "req":"If is_control_library value is yes, then either this field OR library_neg_cont_type must be filled in."
    },
    {
        "field":"library_neg_cont_type",
        "def":"The element or step in the sample processing and\/or library generation process for which the control library or processed sample has been generated.",
        "cv":"extraction\nextraction_kit\nhybridization\nlibrary prep\nsequencing\ncapture\n[Contact the HVPCC to add terms to this vocabulary]",
        "req":"If is_control_library value is yes, then either this field OR library_pos_cont_type must be filled in."
    },
    {
        "field":"paired_or_single",
        "def":"Was the sequencing run using paired-end technology or single-end technology ",
        "cv":"paired\nsingle",
        "req":"Required for sequence data."
    },
    {
        "field":"sequencing_platform",
        "def":"The sequencing technology platform used",
        "cv":"CV from NCBI:\nILLUMINA\nHELICOS\nABI_SOLID\nCOMPLETE_GENOMICS\nPACBIO_SMRT\nION_TORRENT\nCAPILLARY\nOXFORD_NANOPORE\nBGISEQ\nDNBSEQ\nELEMENT\nGENAPSYS\nGENEMIND\nTAPESTRI\nULTIMA\nVELA_DIAGNOSTICS",
        "req":"Required for sequence data."
    },
    {
        "field":"sequencing_instrument_model",
        "def":"Specific sequencer model that was used",
        "cv":"Illumina NovaSeq 6000\nMinION",
        "req":"Required for sequence data."
    }
],
    "files": [
    {
        "field":"file_uniq_name",
        "def":"This is a unique name for the file within a given HVP data generator group (at the grant level), built from the data generator's internal file id\/name prefixed with the project abbreviation, separated with an underscore",
        "cv":"project abbreviation CV for prefixes (to be provided)\nexample:   vast_skin_3754.fastq",
        "req":"yes"
    },
    {
        "field":"library_uid",
        "def":"This is a unique identifier for the file, it must be unique across a given HVP data generator group (at the grant level), thus within a single VCC or Functional Studies group all file IDs submitted to HVPCC must be unique.",
        "cv":"none",
        "req":"conditionally"
    },
    {
        "field":"library_aliqout_id",
        "def":"For sequencing data, this is the aliquot used from the sequencing library. For non-sequence data, this is the aliquot from the processed sample.",
        "cv":"none",
        "req":"no"
    },
    {
        "field":"bioproject_id",
        "def":"The NCBI bioproject_id associated with this data at the sub_bioproject level that is specific to the study this file is part of.\n",
        "cv":"none",
        "req":"conditionally"
    },
    {
        "field":"data_type",
        "def":"Term that indicates the type of data contained in the file. Counts should only be used for summary information from a single sample. If fastq files are demultiplexed, please use demultiplexed_fastq. ",
        "cv":"Internal HVP CV, let the HVPCC know if you need additional terms that are not here:\nscrubbed_sequence_reads\nunscrubbed_sequence_reads\nalignment\ncounts\nassembly\nseq_run_metrics\nanalysis_metrics ",
        "req":"yes"
    },
    {
        "field":"file_format",
        "def":"Term to describe the format of file. Use any term from the \"format\" branch of the EDAM Ontology. ",
        "cv":"edam or internal CV, e.g. bam or fastq",
        "req":"yes"
    },
    {
        "field":"md5_checksum",
        "def":"A lower-case hexadecimal formatted MD5 checksum must be provided for every file.",
        "cv":"none",
        "req":"yes"
    },
    {
        "field":"file_derived_from",
        "def":"Enter here a semicolon seperated list of the file names that were used as input to generate the results.\n",
        "cv":"none",
        "req":"This is for cases where you are submitting a file containing results of a process such as assembly, taxonomic profiling, annotation, alignment, etc."
    },
    {
        "field":"analysis_id",
        "def":"Identifer of the analysis (from the analysis table) that a file is the result of.\n",
        "cv":"none",
        "req":"conditionally"
    },
    {
        "field":"access",
        "def":"The consented access level of data.",
        "cv":"open\nopen_embargo\nrestricted\nrestricted_embargo",
        "req":"yes"
    },
    {
        "field":"data_use_condition",
        "def":"Term from the Data Use Ontology (DUO) to describe how the data is allowed to be used. The term here must match with the value expected for the cohort associated with this data",
        "cv":"A term from the Data Use Ontology (DUO). \nDUO:0000004, no restricition\nDUO:0000042, general research use\nDUO:0000006, health or medical or biomedical research \nDUO:0000007, disease specific research\nDUO:0000011, population origins or ancestry research only\n",
        "req":"yes"
    },
    {
        "field":"data_use_specific_limit",
        "def":"Specific disease associated with the DUO disease specific research restriction.",
        "cv":"A term from the Disease Ontology. Required for data_use_condition = disease specific research (DUO:0000007), blank for others.",
        "req":"conditionally"
    }
],
    "analyses": [
    {
        "field":"analysis_uid",
        "def":"This is a unique identifier for a specific run of an analysis within a given HVP data generator group (at the grant level), built from the data generator's internal analysis id prefixed with the project abbreviation, separated with an underscore. NOTE: the data generator's internal id MUST be unique across that data generator.",
        "cv":"project abbreviation CV for prefixes (to be provided)\nexample:   vast_anl1234",
        "req":"yes"
    },
    {
        "field":"analysis_description",
        "def":"Brief free text description of the analysis.",
        "cv":"none",
        "req":"yes"
    },
    {
        "field":"pipeline_name",
        "def":"Name of pipeline used for the analysis. This could be an internal pipeline or one available to the community. If the pipeline was used from github then the name of the pipeline placed here should match the name used on github.",
        "cv":"none",
        "req":"yes"
    },
    {
        "field":"pipeline_description",
        "def":"Brief description of the pipeline used for the analysis process including overall goal, starting inputs, final outputs,and tools that are included.",
        "cv":"none",
        "req":"yes"
    },
    {
        "field":"pipeline_version",
        "def":"Version of pipeline used for the analysis. If the pipeline is versioned in a location like github, it should be the official version number. If not, this could be a combination of the pipeline name and date it was run. ",
        "cv":"none",
        "req":"yes"
    },
    {
        "field":"sop_url",
        "def":"A stable, permanent url where documentation on the details of the analysis and how it was performed can be found. The description must be detailed enough that others can reproduce the process. Suggested locations for this information include, but are not limited to, GitHub, Read the Docs, and protocols.io\nThe SOP should contain:\n- expected input\/output and formats\n- major dependencies \n- compute resource requirements\n- critical parameters & arguments, and\/or config files (if relevant)\n- link to code if possible ",
        "cv":"none",
        "req":"yes"
    },
    {
        "field":"community_workspace",
        "def":"The community workspace or compute infrastructure (such as Terra or CyVerse) that was used for the analysis. ",
        "cv":"none",
        "req":"no"
    },
    {
        "field":"pipeline_container_url",
        "def":"If a containerized version of the pipeline was used, the url of where that container can be found.",
        "cv":"none",
        "req":"no"
    }
]
};
