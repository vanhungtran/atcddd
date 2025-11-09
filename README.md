
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
- [📊 Example: Visualize Top Anatomical
  Groups](#bar_chart-example-visualize-top-anatomical-groups)
- [🤝 Contributing](#handshake-contributing)
- [📜 License](#scroll-license)
- [❓ Need Help?](#question-need-help)
- [Reference](#reference)
- [🙏 Acknowledgements](#pray-acknowledgements)

<!-- README.md is auto-generated from README.Rmd -->
<!-- Please edit README.Rmd, not README.md directly -->

# Tutorial for R Package 'atcddd'

**Lucas VHH TRAN**  
*Last Updated: November 9, 2025*

<div align="center">

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

### Basic Crawling

Crawl a specific anatomical group (e.g., Dermatologicals):

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

------------------------------------------------------------------------

## 📚 Core Functions

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
?atc_crawl          # Full crawling documentation
?atc_write_csv      # CSV export options
?atc_manifest       # Checksum generation
```

------------------------------------------------------------------------

------------------------------------------------------------------------

## 📊 Example: Visualize Top Anatomical Groups

Let’s explore how many drugs exist in each top-level anatomical group.

``` r
library(dplyr)
library(ggplot2)

atc_table() %>%
  filter(level == 1) %>%
  count(code, name, .drop = FALSE) %>%
  arrange(desc(n)) %>%
  head(10) %>%
  ggplot(aes(x = reorder(name, n), y = n)) +
  geom_col(fill = "#2a9d8f", width = 0.7, alpha = 0.9) +
  coord_flip() +
  labs(
    title = "Top 10 Anatomical Groups by Number of Drugs",
    subtitle = "Based on WHO ATC/DDD Index",
    x = NULL,
    y = "Number of Drugs",
    caption = "Source: WHO Collaborating Centre for Drug Statistics Methodology"
  ) +
  theme_minimal(base_size = 12, base_family = "Helvetica") +
  theme(
    plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(hjust = 0.5, size = 12, color = "#555555"),
    axis.text = element_text(size = 11),
    panel.grid.minor = element_blank(),
    panel.grid.major.y = element_blank(),
    panel.grid.major.x = element_line(color = "#e0e0e0", linetype = "dashed"),
    plot.caption = element_text(size = 9, color = "#777777", hjust = 0.5)
  )
```

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

<div align="center">

<img src="man/figures/logo.png" width="220">

</div>

## Reference

## 🙏 Acknowledgements

- WHO Collaborating Centre for Drug Statistics Methodology — for
  maintaining the ATC/DDD Index
- Inspired by packages: `stringdist`, `dplyr`, `fuzzyjoin`, `rvest`
- Hex sticker design: Use `hexSticker` package or
  [hexb.in](https://hexb.in)

<!---
&#10;
4. Commit both `README.Rmd` and `README.md` to GitHub.
&#10;> 💡 Tip: Add `README.md` to `.Rbuildignore` if you don’t want it in the built package (optional).
&#10;
## 🖌️ Customize Further
- Replace `yourusername` with your GitHub username
- Replace `[Your Name or Organization]` and email
- Add your hex sticker image under `man/figures/logo.png` and uncomment the image line if desired
- Update example code to match your actual function names and outputs
&#10;
&#10;
&#10;🎁 Bonus: Generate a Hex Sticker in R
&#10;If you want to create a hex sticker, install `hexSticker` and run:
&#10;
library(ggplot2)
library(hexSticker)
&#10;# Just a centered "A" for ATC
p <- ggplot() + 
  annotate("text", x = 1, y = 1, label = "A", size = 20, fontface = "bold") +
  xlim(0.5, 1.5) + ylim(0.5, 1.5) +
  theme_void()
&#10;sticker(
  subplot = p,
  package = "atcddd",
  p_size = 20,
  s_x = 1,
  s_y = 0.8,
  s_width = 1.3,
  filename = "man/figures/logo.png",
  h_fill = "#2a9d8f",
  h_color = "#264653",
&#10;)
 &#10;-->
