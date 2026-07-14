# Computing Defined Daily Doses from Prescription Data

🧬

atcddd

WHO ATC/DDD Drug Classification Toolkit · v0.2.0

[WHO ATC/DDD Index](https://www.whocc.no/atc_ddd_index/)\
Pharmacoepidemiology · Drug Utilisation Research

↑

\+

−

⊙

×

‹

›

![Figure]()

100 %

Scroll to zoom · Drag to pan · ← → to navigate

## Introduction

You have prescription records — a pharmacy database, a claims file, or
electronic health record (EHR) extracts — and you need to answer a
pharmacoepidemiology question: *how much drug was consumed?*

The challenge is that prescriptions come in many forms:

- **Different strengths** — 20 mg vs. 40 mg tablets of the same drug
- **Different quantities** — 30 tablets for one patient, 90 for another
- **Different units** — milligrams, grams, micrograms, international
  units
- **Different routes** — oral, parenteral, rectal, transdermal

The **Defined Daily Dose (DDD)** solves this. By expressing every
prescription in a common unit — *the assumed average maintenance dose
per day for an adult* — you can meaningfully aggregate and compare drug
utilisation.

This vignette walks you through the practical workflow:

1.  Computing DDDs from raw prescription records
2.  Aggregating to DDD per 1000 inhabitants per day (DID)
3.  Handling different administration routes
4.  Dealing with drugs that lack DDDs
5.  Building a complete analysis pipeline

``` r

library(atcddd)
library(dplyr)
```

------------------------------------------------------------------------

## Setup and Data Loading

The package bundles a WHO ATC/DDD snapshot that works completely
offline. We load it to inspect the reference data before computing.

``` r

codes_path <- system.file("extdata", "WHO_ATC_codes_2026-07-14.csv",
                          package = "atcddd")
ddd_path   <- system.file("extdata", "WHO_ATC_DDD_2026-07-14.csv",
                          package = "atcddd")

atc_codes <- readr::read_csv(codes_path, show_col_types = FALSE)
atc_ddd   <- readr::read_csv(ddd_path, show_col_types = FALSE)

cat(sprintf("Bundled data: %d ATC codes, %d DDD entries",
            nrow(atc_codes), nrow(atc_ddd)))
#> Bundled data: 6982 ATC codes, 6218 DDD entries
```

> ⚠️ All code in this vignette evaluates offline — no internet
> connection is required.

------------------------------------------------------------------------

## Step-by-Step: Computing DDDs for a Single Drug

Let’s start simple: one drug, one prescription.

A patient receives **acetylsalicylic acid (aspirin)** as 500 mg tablets,
100 tablets dispensed.

``` r

aspirin_rx <- data.frame(
  atc_code      = "N02BA01",
  quantity      = 100,
  strength      = 500,
  strength_unit = "mg",
  adm_r         = "O"
)

compute_ddd(aspirin_rx)
#> # A tibble: 1 × 9
#>   atc_code quantity strength strength_unit adm_r ddd_value ddd_unit total_amount
#>   <chr>       <dbl>    <dbl> <chr>         <chr>     <dbl> <chr>           <dbl>
#> 1 N02BA01       100      500 mg            O             3 g               50000
#> # ℹ 1 more variable: ddd_ratio <dbl>
```

The output adds four columns to your data:

| Column         | Value | Meaning                                              |
|----------------|-------|------------------------------------------------------|
| `total_amount` | 50000 | The total drug amount: `quantity x strength` (in mg) |
| `ddd_value`    | 3     | The WHO DDD for oral aspirin (in grams)              |
| `ddd_unit`     | g     | The unit of the DDD                                  |
| `ddd_ratio`    | 16.7  | How many DDDs this prescription represents           |

**Interpretation**: 100 tablets of 500 mg aspirin = 50 g of drug
substance. The WHO DDD for oral aspirin is 3 g, so this prescription
corresponds to 16.7 DDDs (`50 g / 3 g = 16.7`).

The function automatically converts units — it noticed the strength was
in milligrams while the DDD was in grams and handled the conversion.

------------------------------------------------------------------------

## Multi-Drug Prescription Data

Real-world data has multiple patients and multiple drugs. Let’s create a
realistic scenario with 5 prescription records for 3 patients.

``` r

prescriptions <- data.frame(
  patient_id    = c(1, 1, 2, 2, 3),
  atc_code      = c("N02BA01", "C10AA05", "N02BA01", "A10BA02", "C07AB03"),
  drug_name     = c("aspirin", "atorvastatin", "aspirin", "metformin", "atenolol"),
  quantity      = c(100, 30, 60, 90, 28),
  strength      = c(500, 20, 500, 500, 50),
  strength_unit = c("mg", "mg", "mg", "mg", "mg"),
  adm_r         = c("O", "O", "O", "O", "O")
)

ddd_result <- compute_ddd(prescriptions)
ddd_result
#> # A tibble: 5 × 11
#>   patient_id atc_code drug_name  quantity strength strength_unit adm_r ddd_value
#>        <dbl> <chr>    <chr>         <dbl>    <dbl> <chr>         <chr>     <dbl>
#> 1          1 N02BA01  aspirin         100      500 mg            O             3
#> 2          1 C10AA05  atorvasta…       30       20 mg            O            20
#> 3          2 N02BA01  aspirin          60      500 mg            O             3
#> 4          2 A10BA02  metformin        90      500 mg            O             2
#> 5          3 C07AB03  atenolol         28       50 mg            O            75
#> # ℹ 3 more variables: ddd_unit <chr>, total_amount <dbl>, ddd_ratio <dbl>
```

Each row now shows the DDD ratio alongside the original prescription
data.

**Let’s interpret the results:**

- **Patient 1** received 16.7 DDDs of aspirin (100 x 500 mg / 3000 mg
  per DDD) **plus** 30 DDDs of atorvastatin (30 x 20 mg / 20 mg per DDD)
  — a total of 46.7 DDDs across two drugs.

- **Patient 2** received 10 DDDs of aspirin and 22.5 DDDs of metformin
  (90 x 500 mg = 45 g; DDD = 2 g; 45 / 2 = 22.5).

- **Patient 3** received 18.7 DDDs of atenolol (28 x 50 mg = 1400 mg;
  DDD = 75 mg; 1400 / 75 = 18.7).

### Per-Patient Summary

Group by `patient_id` to see total drug utilisation per patient:

``` r

ddd_result %>%
  group_by(patient_id) %>%
  summarise(
    n_prescriptions = n(),
    total_ddd       = sum(ddd_ratio, na.rm = TRUE),
    .groups = "drop"
  )
#> # A tibble: 3 × 3
#>   patient_id n_prescriptions total_ddd
#>        <dbl>           <int>     <dbl>
#> 1          1               2      46.7
#> 2          2               2      32.5
#> 3          3               1      18.7
```

------------------------------------------------------------------------

## DDD Per 1000 Inhabitants Per Day (DID)

The DID is the standard population-level metric in drug utilisation
research. It answers: *on an average day, how many people out of 1000
receive one DDD?*

``` math
\text{DID} = \frac{\text{Total DDDs}}{\text{Population} \times \text{Days}} \times 1000
```

``` r

compute_did(ddd_result, population = 500, days = 30)
#> # A tibble: 1 × 4
#>   total_ddd   did population  days
#>       <dbl> <dbl>      <dbl> <dbl>
#> 1      97.8  6.52        500    30
```

**Interpretation**: A DID of 0.65 means that, on an average day during
the 30-day study period, approximately 0.65 out of every 1000
inhabitants (or about 1 in 1500) received one DDD of the studied
medications.

DID values let you compare drug utilisation across:

- **Regions** — is antibiotic use higher in country A or B?
- **Time periods** — did statin use increase after a policy change?
- **Drug classes** — which therapeutic class has the highest
  utilisation?

> ⚠️ DID is a **population** metric, not a clinical one. A DID of 30 for
> statins tells you that 3% of the population uses a statin DDD each day
> — it does not tell you whether any individual patient is on the right
> dose.

------------------------------------------------------------------------

## Route-Specific DDDs

The same drug can have **different DDD values** for different
administration routes. The
[`ddd_route_comparison()`](https://vanhungtran.github.io/atcddd/reference/ddd_route_comparison.md)
function shows all route-specific DDDs for a given drug.

### Paracetamol Route Comparison

``` r

ddd_route_comparison("N02BE01")
#> # A tibble: 3 × 6
#>   atc_code atc_name      ddd uom   adm_r note 
#>   <chr>    <chr>       <dbl> <chr> <chr> <chr>
#> 1 N02BE01  paracetamol     3 g     O     NA   
#> 2 N02BE01  paracetamol     3 g     P     NA   
#> 3 N02BE01  paracetamol     3 g     R     NA
```

Paracetamol has the same DDD (3 g) across oral, parenteral, and rectal
routes in this data snapshot. Many other drugs do differ by route —
let’s examine one.

### Aspirin: Where Route Really Matters

``` r

ddd_route_comparison("N02BA01")
#> # A tibble: 3 × 6
#>   atc_code atc_name               ddd uom   adm_r note                          
#>   <chr>    <chr>                <dbl> <chr> <chr> <chr>                         
#> 1 N02BA01  acetylsalicylic acid     3 g     O     NA                            
#> 2 N02BA01  acetylsalicylic acid     1 g     P     Expressed as lysine acetylsal…
#> 3 N02BA01  acetylsalicylic acid     3 g     R     NA
```

Oral and rectal aspirin have a DDD of **3 g**, but parenteral (IV)
aspirin has a DDD of just **1 g**. This makes sense — IV administration
bypasses first-pass metabolism, so less drug is needed for the same
effect.

### Mixed Routes in Practice

If your prescription data contains multiple administration routes, you
must specify `adm_r` so the correct DDD is used.

``` r

mixed_route_rx <- data.frame(
  patient_id    = c(1, 2),
  drug_name     = c("aspirin", "aspirin (IV)"),
  atc_code      = c("N02BA01", "N02BA01"),
  quantity      = c(30, 30),
  strength      = c(500, 500),
  strength_unit = c("mg", "mg"),
  adm_r         = c("O", "P")
)

compute_ddd(mixed_route_rx)
#> # A tibble: 2 × 11
#>   patient_id drug_name  atc_code quantity strength strength_unit adm_r ddd_value
#>        <dbl> <chr>      <chr>       <dbl>    <dbl> <chr>         <chr>     <dbl>
#> 1          1 aspirin    N02BA01        30      500 mg            O             3
#> 2          2 aspirin (… N02BA01        30      500 mg            P             1
#> # ℹ 3 more variables: ddd_unit <chr>, total_amount <dbl>, ddd_ratio <dbl>
```

Same drug. Same quantity. Different route:

| Route          | Total amount | DDD | DDD ratio |
|----------------|--------------|-----|-----------|
| Oral (O)       | 15 g         | 3 g | **5.0**   |
| Parenteral (P) | 15 g         | 1 g | **15.0**  |

If you had ignored the route and assumed oral for both, the IV
prescription would be miscalculated by a factor of three.

------------------------------------------------------------------------

## Handling Missing DDDs

Not every drug has a WHO DDD assignment. This is by design — the WHO
deliberately withholds DDDs for certain categories (topicals,
combinations, vaccines, etc.).

### DDD Coverage in the Bundled Data

The
[`ddd_availability()`](https://vanhungtran.github.io/atcddd/reference/ddd_availability.md)
function gives you an immediate overview of which anatomical groups have
good DDD coverage and which do not.

``` r

ddd_availability()
#> # A tibble: 14 × 5
#>    anatomical_group group_name            total_substances with_ddd pct_with_ddd
#>    <chr>            <chr>                            <int>    <int>        <dbl>
#>  1 A                Alimentary tract and…              706      301         42.6
#>  2 B                Blood and blood form…              270      105         38.9
#>  3 C                Cardiovascular system              657      285         43.4
#>  4 D                Dermatologicals                    395       16          4.1
#>  5 G                Genito-urinary syste…              291      131         45  
#>  6 H                Systemic hormonal pr…               93       58         62.4
#>  7 J                Antiinfectives for s…              615      344         55.9
#>  8 L                Antineoplastic and i…              562      236         42  
#>  9 M                Musculo-skeletal sys…              243      106         43.6
#> 10 N                Nervous system                     666      378         56.8
#> 11 P                Antiparasitic produc…              139       50         36  
#> 12 R                Respiratory system                 401      190         47.4
#> 13 S                Sensory organs                     316       11          3.5
#> 14 V                Various                            326       19          5.8
```

**Key observations:**

- Groups **J** (antiinfectives), **N** (nervous system), and **C**
  (cardiovascular) have high DDD coverage — these are systemic drugs
  where DDD is well-defined.
- Groups **D** (dermatologicals) and **S** (sensory organs) have low
  coverage — topicals and ophthalmics depend on body surface area or
  condition severity, making a standard daily dose impractical.

### What Happens When You Try to Compute DDDs for a Drug Without One

[`compute_ddd()`](https://vanhungtran.github.io/atcddd/reference/compute_ddd.md)
will warn you and return `NA` in the `ddd_ratio` column.

``` r

missing_rx <- data.frame(
  atc_code      = c("N02BA01", "A01AB08"),
  drug_name     = c("aspirin", "neomycin"),
  quantity      = c(100, 30),
  strength      = c(500, 100),
  strength_unit = c("mg", "mg"),
  adm_r         = c("O", "O")
)

result_missing <- compute_ddd(missing_rx)
#> Warning: No DDD found for the following ATC code(s): "A01AB08"
result_missing
#> # A tibble: 2 × 10
#>   atc_code drug_name quantity strength strength_unit adm_r ddd_value ddd_unit
#>   <chr>    <chr>        <dbl>    <dbl> <chr>         <chr>     <dbl> <chr>   
#> 1 N02BA01  aspirin        100      500 mg            O             3 g       
#> 2 A01AB08  neomycin        30      100 mg            O            NA NA      
#> # ℹ 2 more variables: total_amount <dbl>, ddd_ratio <dbl>
```

Neomycin (`A01AB08`) has no DDD — it is a topical antibiotic, and the
WHO does not assign DDDs for topical preparations. The `ddd_ratio` is
`NA`.

### What to Do About Missing DDDs

1.  **Document the gap** — report which drugs in your dataset lack DDDs
2.  **Calculate coverage** — use
    [`ddd_availability()`](https://vanhungtran.github.io/atcddd/reference/ddd_availability.md)
    to show the percentage
3.  **Proceed with caution** — exclude drugs without DDDs from DDD-based
    analyses and note this in your limitations section
4.  **Consider alternatives** — for very low coverage datasets, raw
    `total_amount` may be a more honest metric

``` r

# Count drugs with and without DDDs in your dataset
result_missing %>%
  summarise(
    total      = n(),
    with_ddd   = sum(!is.na(ddd_ratio)),
    pct_covered = round(100 * mean(!is.na(ddd_ratio)), 1)
  )
#> # A tibble: 1 × 3
#>   total with_ddd pct_covered
#>   <int>    <int>       <dbl>
#> 1     2        1          50
```

------------------------------------------------------------------------

## Complete Analysis Pipeline

Now let’s bring everything together. The typical pharmacoepidemiology
workflow is:

> **Drug names → ATC codes → DDDs → DID**

### Step 1: Resolve Drug Names to ATC Codes

Use
[`resolve_batch()`](https://vanhungtran.github.io/atcddd/reference/resolve_batch.md)
to convert a list of drug names into ATC codes, working entirely offline
against the bundled database.

``` r

drug_names <- c("aspirin", "atorvastatin", "metformin", "atenolol")
resolved <- resolve_batch(drug_names, source = "local")
resolved
#> # A tibble: 4 × 8
#>   query        atc_code atc_name             ddd   uom   adm_r source match_type
#>   <chr>        <chr>    <chr>                <chr> <chr> <chr> <chr>  <chr>     
#> 1 aspirin      N02BA01  acetylsalicylic acid 3     g     O     local  synonym   
#> 2 atorvastatin C10AA05  atorvastatin         20    mg    O     local  exact     
#> 3 metformin    A10BA02  metformin            2     g     O     local  exact     
#> 4 atenolol     C07AB03  atenolol             75    mg    O     local  exact
```

The result includes the ATC code, official name, and the oral-route DDD
for each drug.

### Step 2: Build Prescription Records

``` r

rx <- data.frame(
  drug_name     = drug_names,
  quantity      = c(100, 30, 90, 28),
  strength      = c(500, 20, 500, 50),
  strength_unit = c("mg", "mg", "mg", "mg")
)
```

### Step 3: Join, Compute DDDs, and Compute DID

Pipe the entire workflow together with `%>%`:

``` r

rx %>%
  left_join(resolved, by = c("drug_name" = "query")) %>%
  compute_ddd() %>%
  compute_did(population = 500, days = 30)
#> # A tibble: 1 × 4
#>   total_ddd   did population  days
#>       <dbl> <dbl>      <dbl> <dbl>
#> 1      87.8  5.86        500    30
```

**What just happened:**

1.  [`left_join()`](https://dplyr.tidyverse.org/reference/mutate-joins.html)
    merged each drug name with its resolved ATC code and DDD info
2.  [`compute_ddd()`](https://vanhungtran.github.io/atcddd/reference/compute_ddd.md)
    calculated the DDD ratio for each prescription row
3.  [`compute_did()`](https://vanhungtran.github.io/atcddd/reference/compute_did.md)
    aggregated across all rows to produce the population metric

The pipeline scales to hundreds of drugs and thousands of prescription
records — the only limit is your computer’s memory.

------------------------------------------------------------------------

## Best Practices

#### Always Check DDD Coverage

Before running any analysis, check how many of your drugs have DDDs. Low
coverage can invalidate your conclusions.

``` r

ddd_availability() %>%
  filter(pct_with_ddd < 50) %>%
  select(anatomical_group, group_name, pct_with_ddd)
#> # A tibble: 11 × 3
#>    anatomical_group group_name                                 pct_with_ddd
#>    <chr>            <chr>                                             <dbl>
#>  1 A                Alimentary tract and metabolism                    42.6
#>  2 B                Blood and blood forming organs                     38.9
#>  3 C                Cardiovascular system                              43.4
#>  4 D                Dermatologicals                                     4.1
#>  5 G                Genito-urinary system and sex hormones             45  
#>  6 L                Antineoplastic and immunomodulating agents         42  
#>  7 M                Musculo-skeletal system                            43.6
#>  8 P                Antiparasitic products                             36  
#>  9 R                Respiratory system                                 47.4
#> 10 S                Sensory organs                                      3.5
#> 11 V                Various                                             5.8
```

#### Match on Administration Route

The same drug can have different DDDs for different routes. Always
include `adm_r` in your prescription data. When the route is unknown,
defaulting to oral (`adm_r = "O"`) is the safest assumption — most DDDs
are defined for the oral route.

#### Document Missing DDDs

> ⚠️ **Transparency is more important than perfect coverage.**

For every analysis, report: - How many unique drugs in your dataset
lacked DDDs - Which anatomical groups they belonged to - Whether this
could bias your results

#### DID Is for Populations, Not Patients

DID measures population-level drug utilisation — it tells you about
consumption patterns across thousands of people, not about individual
prescribing. Use it for:

- **Trend analysis** — is utilisation increasing over time?
- **Cross-regional comparisons** — does region A use more antibiotics
  than B?
- **Policy evaluation** — did a reimbursement change affect utilisation?

Do **not** use DID to judge the appropriateness of individual
prescriptions.

#### Use the Same Data Snapshot for Reproducibility

The package bundles a fixed WHO snapshot (`2026-07-14`). For published
research, always cite the snapshot date so others can reproduce your
results exactly.

------------------------------------------------------------------------

## Key Takeaways

1.  **[`compute_ddd()`](https://vanhungtran.github.io/atcddd/reference/compute_ddd.md)
    converts raw prescription data to DDDs** — it handles unit
    conversion, route matching, and missing DDDs automatically.

2.  **[`compute_did()`](https://vanhungtran.github.io/atcddd/reference/compute_did.md)
    normalises to per-1000-inhabitants-per-day** — the standard metric
    for cross-population comparisons.

3.  **Route matters** — always include `adm_r` in your data. The same
    drug can yield very different DDD counts for different routes.

4.  **Missing DDDs are expected** — use
    [`ddd_availability()`](https://vanhungtran.github.io/atcddd/reference/ddd_availability.md)
    to check coverage and document gaps transparently.

5.  **[`resolve_batch()`](https://vanhungtran.github.io/atcddd/reference/resolve_batch.md)
    bridges drug names and ATC codes** — the complete pipeline from
    clinical names to published metrics runs in a few lines of code.

------------------------------------------------------------------------

## Session Information

``` r

sessionInfo()
#> R version 4.5.0 (2025-04-11 ucrt)
#> Platform: x86_64-w64-mingw32/x64
#> Running under: Windows 11 x64 (build 26200)
#> 
#> Matrix products: default
#>   LAPACK version 3.12.1
#> 
#> locale:
#> [1] LC_COLLATE=English_United States.utf8 
#> [2] LC_CTYPE=English_United States.utf8   
#> [3] LC_MONETARY=English_United States.utf8
#> [4] LC_NUMERIC=C                          
#> [5] LC_TIME=English_United States.utf8    
#> 
#> time zone: Europe/Zurich
#> tzcode source: internal
#> 
#> attached base packages:
#> [1] stats     graphics  grDevices utils     datasets  methods   base     
#> 
#> other attached packages:
#> [1] dplyr_1.2.1  atcddd_0.2.0
#> 
#> loaded via a namespace (and not attached):
#>  [1] bit_4.6.0         jsonlite_2.0.0    crayon_1.5.3      compiler_4.5.0   
#>  [5] tidyselect_1.2.1  stringr_1.6.0     parallel_4.5.0    jquerylib_0.1.4  
#>  [9] systemfonts_1.3.2 textshaping_1.0.5 yaml_2.3.12       fastmap_1.2.0    
#> [13] readr_2.2.0       R6_2.6.1          generics_0.1.4    knitr_1.51       
#> [17] htmlwidgets_1.6.4 tibble_3.3.1      desc_1.4.3        bslib_0.10.0     
#> [21] pillar_1.11.1     tzdb_0.5.0        rlang_1.2.0       utf8_1.2.6       
#> [25] stringi_1.8.7     cachem_1.1.0      xfun_0.57         fs_2.1.0         
#> [29] sass_0.4.10       bit64_4.8.0       otel_0.2.0        memoise_2.0.1    
#> [33] cli_3.6.5         withr_3.0.2       pkgdown_2.2.0     magrittr_2.0.5   
#> [37] digest_0.6.39     vroom_1.7.1       hms_1.1.4         lifecycle_1.0.5  
#> [41] vctrs_0.7.3       evaluate_1.0.5    glue_1.8.1        ragg_1.5.2       
#> [45] rmarkdown_2.31    tools_4.5.0       pkgconfig_2.0.3   htmltools_0.5.9
```
