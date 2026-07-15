# Benchmarking Reproducible Drug Normalization and Dose-Exposure Pipelines for Multimodal Analysis of Atopic Dermatitis and Comorbidity

## 1. Purpose

This project will evaluate how accurately and reproducibly drug-normalization and dose-exposure pipelines transform heterogeneous medication records into clinically and biologically meaningful exposure variables for patients with atopic dermatitis and comorbidities.

The work is designed as an independent comparative benchmark with a clinical and molecular case study. The `atcddd` package is one evaluated pipeline, not the sole subject of the study.

## 2. Research Question and Hypotheses

### Primary question

How do available end-to-end pipelines differ in drug-name normalization, active-ingredient identification, ATC assignment, route and formulation resolution, DDD calculation, and longitudinal exposure estimation?

### Primary hypothesis

Pipeline choice produces measurable differences in medication classification and cumulative dose exposure.

### Secondary hypotheses

1. Errors are concentrated in brand names, misspellings, combination products, topical formulations, and drugs without an assigned DDD.
2. Differences in exposure processing alter estimated treatment-comorbidity associations.
3. Differences in normalized active ingredients alter drug-target, pathway, biomarker, and omics interpretations.
4. Fixed terminology versions, explicit abstention, and reproducible configuration improve transportability across institutions and software environments.

## 3. Study Outputs

The project will produce:

1. A public, adjudicated medication benchmark using synthetic or legally redistributable records.
2. A versioned workflow that executes all comparison pipelines with fixed configurations.
3. A clinical analysis of atopic dermatitis treatment exposure and comorbidity outcomes.
4. A molecular analysis linking treatments to targets, pathways, biomarkers, and available omics measurements.
5. A reporting protocol for reproducible medication normalization and DDD-based research.

## 4. Data Design

### 4.1 Public benchmark

The benchmark will contain approximately 2,000 to 5,000 medication records representing:

- topical corticosteroids and calcineurin inhibitors;
- systemic immunosuppressants;
- biologics and JAK inhibitors;
- antibiotics and antihistamines;
- common treatments for relevant comorbidities;
- generic and brand names;
- abbreviations, misspellings, and incomplete records;
- single-ingredient and combination products;
- different strengths, routes, and formulations.

Two qualified clinical reviewers will independently assign active ingredients, ATC codes, routes, formulations, and DDD eligibility. Disagreements will be resolved by consensus or a third reviewer. Inter-rater agreement will be reported before consensus.

The public benchmark must not contain copied WHO ATC/DDD datasets unless written redistribution permission has been obtained. Synthetic test cases may reference individual factual codes where legally permissible, with clear attribution and provenance.

### 4.2 Institutional cohort

The atopic dermatitis cohort should require either two diagnosis records or one specialist-confirmed diagnosis. The protocol will define an observation period before cohort entry and a follow-up period after cohort entry.

Requested variables include:

- medication orders or dispensings, including dates, strength, quantity, route, and frequency;
- demographics and disease-severity proxies;
- diagnoses, procedures, and healthcare utilization;
- laboratory measurements, adverse events, and clinical outcomes;
- genomic, transcriptomic, proteomic, or biomarker data where available.

Comorbidity groups will be defined before analysis and will include asthma, allergic rhinitis, food allergy, infection, cardiovascular disease, metabolic disease, autoimmune disease, psychiatric disorders, and sleep disorders where data quality and sample size permit.

### 4.3 Data partitioning

Data will be separated into:

- a development set for pipeline integration;
- a locked medication benchmark for final performance evaluation;
- a clinical validation cohort for downstream analyses;
- an external institutional cohort, if available, for transportability analysis.

Patient-level splitting will prevent records from the same patient appearing in development and validation partitions.

## 5. Compared Pipelines

At least three pipeline families will be compared:

1. `atcddd`, including exact, synonym, and fuzzy-matching modes;
2. existing R or Python terminology and drug-normalization tools;
3. a standards-based baseline using RxNorm, SNOMED CT, OMOP vocabularies, or another terminology available under applicable licenses.

Each pipeline's software version, terminology version, configuration, confidence threshold, network requirements, and execution environment will be frozen before the locked evaluation. Pipeline failures and abstentions will remain visible rather than being silently replaced with manual results.

## 6. Benchmark Outcomes

### 6.1 Normalization and classification

Primary metrics are:

- exact-match accuracy;
- precision, recall, and macro F1;
- top-1 and top-k ingredient accuracy;
- hierarchical ATC accuracy at levels 1 through 5;
- combination-product accuracy;
- route and formulation accuracy;
- coverage and abstention rate;
- selective accuracy among accepted predictions.

### 6.2 DDD computation

DDD metrics are:

- proportion of records eligible for DDD calculation;
- exact agreement with the adjudicated reference;
- absolute and relative dose error;
- cumulative exposure error;
- intraclass correlation;
- Bland-Altman agreement;
- error stratified by route, formulation, ATC class, and combination status.

### 6.3 Operational reproducibility

The benchmark will also measure runtime, peak memory, network dependence, failure recovery, and consistency across Windows, Linux, and macOS.

Paired comparisons and patient- or medication-level bootstrap confidence intervals will be used because all pipelines process the same records. Effect sizes and uncertainty will be primary; multiple-comparison correction will be applied where formal hypothesis tests are used.

Sensitivity analyses will address spelling corruption, missing fields, brand versus generic names, fuzzy-match thresholds, annual ATC/DDD versions, missing treatment duration or frequency, and drugs without an assigned DDD.

## 7. Clinical Analysis

Each pipeline will generate the same longitudinal exposure variables:

- current and previous treatment;
- cumulative DDD;
- duration and intensity;
- switching and combination therapy;
- class-specific exposure;
- topical versus systemic treatment;
- polypharmacy burden.

Analyses will use a target-trial-style structure with explicit eligibility, time zero, exposure windows, follow-up, censoring, and outcomes. Candidate outcomes include infection, asthma exacerbation, cardiovascular events, psychiatric outcomes, hospitalization, and atopic dermatitis control.

Confounding variables will include age, sex, baseline severity, prior treatment, comorbidities, healthcare utilization, and relevant laboratory measurements. Depending on each estimand, methods may include propensity-score weighting or matching, time-varying Cox models, recurrent-event models, and negative-control outcomes.

Every primary clinical analysis will be repeated using exposure outputs from each pipeline. The study will report changes in cohort inclusion, exposure classification, effect estimates, confidence intervals, and substantive conclusions.

## 8. Molecular Analysis

Normalized active ingredients will be connected to available evidence on:

- targets and mechanisms of action;
- genes and proteins;
- pathways and ontology terms;
- pharmacogenomic variants;
- measured biomarkers and omics features.

The analysis will test whether treatment-associated targets and pathways overlap with molecular signatures of atopic dermatitis and its comorbidities. Candidate methods include pathway enrichment, drug-target-disease networks, network proximity, and treatment-by-biomarker interactions.

Molecular analyses will be repeated for every pipeline. Stability outcomes will include changes in mapped targets, significant pathways, network communities, ranked biological findings, and treatment-biomarker interactions.

## 9. Reproducibility and Validation

The project will:

- preregister primary outcomes, metrics, exclusions, models, and subgroup analyses;
- keep the locked benchmark unavailable to pipeline developers until configuration is frozen;
- use independent clinical adjudication;
- record data and terminology provenance;
- use deterministic seeds where applicable;
- provide an environment lockfile and container specification;
- run automated tests and continuous integration on major operating systems;
- archive code and public benchmark artifacts in a DOI-granting repository.

Restricted patient and molecular data will remain under institutional controls. Public code will include executable specifications, synthetic examples, and instructions for reproducing analyses within an authorized environment.

## 10. Ethics and Licensing

Institutional approvals, data-use agreements, privacy safeguards, and consent or waiver requirements must be resolved before patient-level analysis.

The project's source code may use an open-source license. Third-party terminologies and databases retain their own licenses. ATC/DDD material remains the copyright of the WHO Collaborating Centre for Drug Statistics Methodology and is not relicensed by this project. Full scraped or transformed copies will not be distributed without explicit permission.

## 11. Manuscript Structure and Figures

The manuscript will emphasize comparative evaluation and reproducibility rather than package promotion.

Planned figures are:

1. study and benchmark workflow;
2. normalization accuracy by task and medication category;
3. DDD agreement and error distributions;
4. stability of treatment-comorbidity associations;
5. drug-target-pathway network;
6. stability of molecular findings across pipelines.

The discussion will address terminology licensing, annual ATC/DDD changes, missing DDDs, combination products, data quality, transportability, and the limitations of DDD as an exposure measure.

## 12. Success Criteria

The study will be considered scientifically informative if it demonstrates at least one of the following with adequate uncertainty quantification:

- important accuracy differences among pipelines;
- medication categories where all pipelines systematically fail;
- clinically meaningful changes in association estimates;
- altered pathway or network conclusions caused by exposure-processing choices;
- improved reproducibility from a standardized, versioned workflow.

A well-powered finding that pipeline choice has little downstream effect remains publishable if the benchmark is independent, transparent, and sufficiently challenging.

## 13. Scope Boundaries

This project will not:

- present `atcddd` as the gold standard;
- use the WHO website output itself as independent ground truth without clinical review;
- claim causal treatment effects without a prespecified causal estimand and appropriate design;
- publish restricted patient data or third-party terminology content;
- expand into every disease area beyond atopic dermatitis and its prespecified comorbidities.
