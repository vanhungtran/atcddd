
- [Tutorial for R package ‘atcddd’](#tutorial-for-r-package-atcddd)
  - [Introduction](#introduction)
- [🧬 atcddd](#dna-atcddd)
  - [*Work with ATC (Anatomical Therapeutic Chemical) Codes in
    R*](#work-with-atc-anatomical-therapeutic-chemical-codes-in-r)
- [📖 Overview](#open_book-overview)
  - [✅ Key Features](#white_check_mark-key-features)
- [🚀 Installation](#rocket-installation)
- [🧪 Quick Examples](#test_tube-quick-examples)
  - [Validate an ATC code](#validate-an-atc-code)
  - [Get description](#get-description)
  - [Extract anatomical group (Level
    1)](#extract-anatomical-group-level-1)
  - [Fuzzy match drug name → ATC code](#fuzzy-match-drug-name--atc-code)
- [📚 Core Functions](#books-core-functions)
- [📊 Example: Visualize ATC Hierarchy Distribution](#bar_chart-example-visualize-atc-hierarchy-distribution)
- [🤝 Contributing](#handshake-contributing)
- [📜 License](#scroll-license)
- [❓ Need Help?](#question-need-help)
- [Reference](#reference)
- [🙏 Acknowledgements](#pray-acknowledgements)
- [🎨 Create Your Own Logo](#art-create-your-own-logo)

<!-- README.md is auto-generated from README.Rmd -->
<!-- Please edit README.Rmd, not README.md directly -->

# Tutorial for R Package 'atcddd'

**Lucas VHH TRAN**  
*Last Updated: November 9, 2025*

<div align="center">

<img src="man/figures/logo.png" align="center" width="200" alt="atcddd logo"/>

# 🧬 atcddd

### *Work with ATC (Anatomical Therapeutic Chemical) Codes in R*

[![Lifecycle:
stable](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html)
[![R-CMD-check](https://github.com/yourusername/atcddd/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/yourusername/atcddd/actions)
[![CRAN_Status_Badge](https://www.r-pkg.org/badges/version/atcddd)](https://cran.r-project.org/package=atcddd)
[![License:
MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

<br>

> *“Classify, validate, and explore drugs with WHO ATC codes — all in
> R.”*

</div>

------------------------------------------------------------------------

## 📖 Overview

**`atcddd`** is a comprehensive R package for working with the **World Health Organization's 
Anatomical Therapeutic Chemical (ATC) Classification System** and **Defined Daily Dose (DDD)** 
values. This package provides robust tools for:

- 🌐 **Web Crawling**: Automated retrieval from the WHO ATC/DDD index
- 💾 **Data Management**: Efficient caching and rate-limited requests
- 📊 **Data Processing**: Parse and organize ATC hierarchies and DDD specifications
- ✅ **Reproducibility**: Generate SHA256 checksums for data verification
- 📦 **Export**: Save results in tidy CSV format with optional date stamping

### ✅ Key Features

- ✔ **Crawl the entire ATC/DDD index** or specific anatomical groups
- ✔ **Hierarchical navigation** through the 5-level ATC classification
- ✔ **Robust error handling** for malformed HTML and missing data
- ✔ **Filesystem caching** to minimize redundant HTTP requests
- ✔ **Rate limiting** to respect WHO server resources
- ✔ **Checksum manifests** for reproducible research workflows
- ✔ **Tidy data output** compatible with tidyverse tools

**Perfect for:**
- 💊 Pharmacoepidemiology research
- 🏥 Health services and outcomes research
- 📈 Drug utilization studies
- 🔬 Clinical data science and pharmacovigilance
- 📚 Pharmaceutical classification and regulatory analysis

------------------------------------------------------------------------

## 🚀 Installation

### From GitHub (Development Version)

The source code for **`atcddd`** is freely available at 
<https://github.com/vanhungtran/atcddd>.

**Requirements:** R version ≥ 4.2.3

```r
# Install from GitHub using devtools
install.packages("devtools")
devtools::install_github("vanhungtran/atcddd")

# Or using remotes
install.packages("remotes")
remotes::install_github("vanhungtran/atcddd")
```

### Load the Package

```r
library(atcddd)
```

### System Dependencies

The package requires an internet connection for crawling WHO data. All other
dependencies are automatically installed:

- `httr2` - Modern HTTP client
- `rvest` - Web scraping
- `dplyr`, `tidyr` - Data manipulation
- `cli` - User-friendly messages
- `memoise` - Caching
- `digest` - Checksums

------------------------------------------------------------------------

## 🧪 Quick Start

### Option 1: High-Level API (Recommended)

Use the clean API functions for most tasks:

```r
library(atcddd)

# Get data for a specific drug (aspirin)
aspirin <- get_atc_data("N02BA01")
aspirin
#> # A tibble: 1 × 7
#>   atc_code atc_name level ddd   uom   adm_r note
#>   <chr>    <chr>    <int> <chr> <chr> <chr> <chr>
#> 1 N02BA01  aspirin      5 3 g   g     O     ...

# Get all analgesics with their sub-classifications
analgesics <- get_atc_data("N02", include_children = TRUE)
head(analgesics, 5)
#> # A tibble: 5 × 7
#>   atc_code atc_name                     level ddd   uom   adm_r note
#>   <chr>    <chr>                        <int> <chr> <chr> <chr> <chr>
#> 1 N02      ANALGESICS                       2 NA    NA    NA    NA
#> 2 N02A     OPIOIDS                          3 NA    NA    NA    NA
#> 3 N02AA    Natural opium alkaloids          4 NA    NA    NA    NA
#> 4 N02AA01  morphine                         5 0.1 g g     O     ...
#> 5 N02AA02  opium                            5 NA    NA    NA    NA

# Get hierarchical tree with parent-child relationships
tree <- get_atc_hierarchy("N02", max_levels = 4)
tree
#> # A tibble: 25 × 9
#>   atc_code atc_name       level parent_code has_children ddd   uom   adm_r note
#>   <chr>    <chr>          <int> <chr>       <lgl>        <chr> <chr> <chr> <chr>
#> 1 N02      ANALGESICS         2 N           TRUE         NA    NA    NA    NA
#> 2 N02A     OPIOIDS            3 N02         TRUE         NA    NA    NA    NA
#> 3 N02AA    Natural opium...   4 N02A        TRUE         NA    NA    NA    NA

# Validate ATC codes
is_valid_atc("N02BE01")  # TRUE
is_valid_atc("invalid")  # FALSE
```

### Option 2: Low-Level Crawling (Advanced)

For more control over the crawling process:

```r
# Crawl dermatological drugs (ATC code D)
res <- atc_crawl(roots = "D", rate = 0.5, progress = TRUE, max_codes = 100)

# View structure
str(res)
#> List of 2
#>  $ codes:tibble [100 × 2] (S3: tbl_df/tbl/data.frame)
#>   ..$ atc_code: chr [1:100] "D" "D01" "D01A" "D01AA" ...
#>   ..$ atc_name: chr [1:100] "DERMATOLOGICALS" "ANTIFUNGALS FOR DERMATOLOGICAL USE" ...
#>  $ ddd  :tibble [50 × 7] (S3: tbl_df/tbl/data.frame)
#>   ..$ source_code: chr [1:50] "D01AA" "D01AA" ...
#>   ..$ atc_code   : chr [1:50] "D01AA01" "D01AA02" ...
#>   ..$ atc_name   : chr [1:50] "nystatin" "natamycin" ...
#>   ..$ ddd        : chr [1:50] NA NA ...
#>   ..$ uom        : chr [1:50] NA NA ...
#>   ..$ adm_r      : chr [1:50] NA NA ...
#>   ..$ note       : chr [1:50] NA NA ...

# Examine codes
head(res$codes, 10)
#> # A tibble: 10 × 2
#>    atc_code atc_name                          
#>    <chr>    <chr>                             
#>  1 D01      ANTIFUNGALS FOR DERMATOLOGICAL USE
#>  2 D01A     ANTIFUNGALS FOR TOPICAL USE       
#>  3 D01AA    Antibiotics                       
#>  4 D01AA01  nystatin                          
#>  5 D01AA02  natamycin                         
#> ...

# Examine DDD data
head(res$ddd, 5)
#> # A tibble: 5 × 7
#>   source_code atc_code atc_name  ddd   uom   adm_r note 
#>   <chr>       <chr>    <chr>     <chr> <chr> <chr> <chr>
#> 1 D01AA       D01AA01  nystatin  NA    NA    NA    NA   
#> 2 D01AA       D01AA02  natamycin NA    NA    NA    NA   
#> ...
```

### Export to CSV

```r
# Write results to CSV files with date stamp
paths <- atc_write_csv(res, dir = "output", stamp = TRUE)
#> ℹ Writing WHO_ATC_codes_2025-11-09.csv (100 rows)
#> ℹ Writing WHO_ATC_DDD_2025-11-09.csv (50 rows)
#> ✔ Successfully wrote 2 files to output/

# View file paths
paths
#> [1] "output/WHO_ATC_codes_2025-11-09.csv"
#> [2] "output/WHO_ATC_DDD_2025-11-09.csv"
```

### Generate Checksums

```r
# Create manifest for reproducibility
atc_write_manifest(paths)
#> ℹ Computing checksums for 2 files...
#> ✔ Wrote manifest: output/MANIFEST.csv
```

------------------------------------------------------------------------

## ⚠️ Understanding DDD Data Quality

**Not all medications have Defined Daily Dose (DDD) values** - this is expected from WHO source data.

### Why Some Drugs Show NA Values:

1. **Topical/Dermatological Medications** (D group)
   - Variable absorption and application area
   - Dosing depends on body surface treated
   - Example: Antifungal creams, corticosteroid ointments

2. **Fixed-Dose Combinations**
   - WHO policy: No DDD assigned to combinations
   - Example: "combinations of tetracyclines"

3. **Ophthalmics, Nasal, Otic Preparations**
   - Local application with minimal systemic absorption
   - Highly individualized dosing

4. **Less Commonly Used Drugs**
   - Older medications not prioritized for DDD assignment

### Verifying Data Quality:

```r
# Compare systemic vs. topical drugs
antibiotics <- atc_crawl(roots = "J01AA", rate = 0.5, max_codes = 20)
cat("Antibiotics with DDD:", 
    sum(!is.na(antibiotics$ddd$ddd)), "/", nrow(antibiotics$ddd))
#> Antibiotics with DDD: 20 / 23  ✓ High percentage expected

dermatologicals <- atc_crawl(roots = "D01", rate = 0.5, max_codes = 50)
cat("Dermatologicals with DDD:", 
    sum(!is.na(dermatologicals$ddd$ddd)), "/", nrow(dermatologicals$ddd))
#> Dermatologicals with DDD: 0 / 50  ✓ Low/zero percentage expected
```

**This is correct behavior** - the parser works as intended. NA values reflect WHO source data limitations, not package errors.

------------------------------------------------------------------------

------------------------------------------------------------------------

## 📚 Core Functions

### High-Level API Functions

**Recommended for most users** - Clean, user-friendly interface:

| Function                 | Description                                                      |
|--------------------------|------------------------------------------------------------------|
| `get_atc_data()`         | Get ATC classification data from WHO database (API-style)        |
| `get_atc_hierarchy()`    | Retrieve complete hierarchical tree structure                    |
| `is_valid_atc_code()`    | Validate ATC code format                                         |
| `is_valid_atc()`         | Alias for `is_valid_atc_code()`                                  |

### Low-Level Functions

**For advanced users** - More control over crawling behavior:

| Function                 | Description                                                      |
|--------------------------|------------------------------------------------------------------|
| `atc_crawl()`            | Main crawling function - retrieves ATC codes and DDD data        |
| `atc_roots_default()`    | Returns the 14 main anatomical groups (A-V)                      |
| `atc_write_csv()`        | Export crawl results to dated CSV files                          |
| `atc_manifest()`         | Generate SHA256 checksums for file verification                  |
| `atc_write_manifest()`   | Save checksum manifest to CSV                                    |

### Detailed Function Information

Run `?function_name` in R for comprehensive documentation:

```r
# High-level API
?get_atc_data       # API-style data retrieval
?get_atc_hierarchy  # Hierarchical tree structure
?is_valid_atc_code  # Code validation

# Low-level functions
?atc_crawl          # Full crawling documentation
?atc_write_csv      # CSV export options
?atc_manifest       # Checksum generation
```

------------------------------------------------------------------------

------------------------------------------------------------------------

## 📊 Example: Visualize ATC Hierarchy Distribution

Explore the distribution of codes across the 5-level ATC hierarchy:

```r
library(atcddd)
library(dplyr)
library(ggplot2)

# Crawl dermatological drugs
res <- atc_crawl(roots = "D", rate = 0.5, max_codes = 100)

# Calculate ATC code levels
code_levels <- res$codes %>%
  mutate(
    code_length = nchar(atc_code),
    level = case_when(
      code_length == 1 ~ "Level 1 (Anatomical)",
      code_length == 3 ~ "Level 2 (Therapeutic)",
      code_length == 4 ~ "Level 3 (Pharmacological)",
      code_length == 5 ~ "Level 4 (Chemical)",
      code_length == 7 ~ "Level 5 (Substance)",
      TRUE ~ "Other"
    )
  ) %>%
  count(level) %>%
  filter(level != "Other") %>%
  mutate(level = factor(level, levels = c(
    "Level 1 (Anatomical)", 
    "Level 2 (Therapeutic)", 
    "Level 3 (Pharmacological)", 
    "Level 4 (Chemical)", 
    "Level 5 (Substance)"
  )))

# Visualize
ggplot(code_levels, aes(x = level, y = n, fill = level)) +
  geom_col(width = 0.7, alpha = 0.9) +
  geom_text(aes(label = n), vjust = -0.5, size = 4) +
  scale_fill_brewer(palette = "Set2") +
  labs(
    title = "Distribution of ATC Codes by Hierarchy Level",
    x = "ATC Level",
    y = "Number of Codes",
    caption = "Source: WHO ATC/DDD Index"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    legend.position = "none",
    plot.title = element_text(face = "bold", hjust = 0.5),
    panel.grid.major.x = element_blank(),
    axis.text.x = element_text(angle = 45, hjust = 1)
  )
```

### Example Output:

- **Level 1** (Anatomical): 1 code
- **Level 2** (Therapeutic): 8-10 codes  
- **Level 3** (Pharmacological): 10-15 codes
- **Level 4** (Chemical): 15-25 codes
- **Level 5** (Substance): 40-80 individual drugs

------------------------------------------------------------------------

## 🤝 Contributing

We welcome contributions from the R and healthcare data science community!

### How to Contribute

1. **Report Bugs**: Open an issue on [GitHub Issues](https://github.com/vanhungtran/atcddd/issues)
   - Include a reproducible example
   - Describe expected vs. actual behavior
   - Note your R version and operating system

2. **Suggest Features**: Propose enhancements via GitHub Issues
   - Explain the use case and benefits
   - Provide example workflows if possible

3. **Submit Pull Requests**:
   - Fork the repository
   - Create a feature branch (`git checkout -b feature/amazing-feature`)
   - Make your changes with tests
   - Update documentation as needed
   - Submit a PR with a clear description

4. **Improve Documentation**:
   - Fix typos or clarify examples
   - Add vignettes for advanced use cases
   - Translate documentation

### Code of Conduct

Please note that this project follows a [Contributor Code of Conduct](CODE_OF_CONDUCT.md). 
By participating, you agree to abide by its terms.

------------------------------------------------------------------------

## 📜 License

MIT © 2025 \[Lucas VHH Tran\]

> Permission is hereby granted, free of charge, to any person obtaining
> a copy of this software…

See [LICENSE.md](LICENSE.md) for full text.

------------------------------------------------------------------------

------------------------------------------------------------------------

## ❓ Need Help?

Open an issue on [GitHub](https://github.com/vanhungtran/atcddd/issues)
or email \[<tranhungydhcm@gmail.com>\].

------------------------------------------------------------------------

<div align="center">

<br> <em>Developed with 💊 and 🧬 for the R and health data science
community.</em> <br><br>

</div>

------------------------------------------------------------------------

## Reference

## 🙏 Acknowledgements

- WHO Collaborating Centre for Drug Statistics Methodology — for maintaining the ATC/DDD Index
- Inspired by packages: `httr2`, `rvest`, `dplyr`, `memoise`

------------------------------------------------------------------------

## 🎨 Create Your Own Logo

Want to customize the package logo? We provide a script that generates **5 professional hex sticker designs with transparent backgrounds**:

```r
# Run the logo generator
source("create_logo.R")

# This creates 5 options in man/figures/:
# - logo_option1.png - Hierarchy bar chart
# - logo_option2.png - Molecular network
# - logo_option3.png - Medical cross + data
# - logo_option4.png - Pills/capsules (RECOMMENDED)
# - logo_option5.png - Minimalist ATC text

# Choose your favorite:
file.copy("man/figures/logo_option4.png", 
          "man/figures/logo.png", 
          overwrite = TRUE)
```

**Features:**
- ✨ Transparent backgrounds (works on any color)
- 🎨 Professional design with consistent color palette
- 📐 High resolution 300 DPI PNG format
- 💎 Clean hexagon sticker style

**Requirements:** `hexSticker`, `ggplot2`, `dplyr`, `showtext`

See [`LOGO_README.md`](LOGO_README.md) for detailed customization options and design tips.

------------------------------------------------------------------------

