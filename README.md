
- [Tutorial for R package ‘atcddd’](#tutorial-for-r-package-atcddd)
  - [Introduction](#introduction)
  - [Package installation](#package-installation)
  - [Example](#example)
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

<!-- README.md is generated from README.Rmd. Please edit that file -->

<!-- README.md is auto-generated from README.Rmd -->

# Tutorial for R package ‘atcddd’

Lucas TRAN 10/09/2025

## Introduction

*atcddd*

## Package installation

The code of *atcddd* is freely available at
<https://github.com/vanhungtran/atcddd>.

The following commands can be used to install this R package, and an R
version \>= 4.2.3 is required.

    library(devtools)
    install_github("vanhungtran/atcddd")

## Example

    res <- atc_crawl(rate = 0.5, progress = TRUE)

    #>res
    #>$codes
    #># A tibble: 500 × 2
    #>   atc_code atc_name                          
    #>   <chr>    <chr>                             
    #> 1 D01      ANTIFUNGALS FOR DERMATOLOGICAL USE
    #> 2 D01A     ANTIFUNGALS FOR TOPICAL USE       
    #> 3 D01AA    Antibiotics                       
    #> 4 D01AA01  nystatin                          
    #> 5 D01AA02  natamycin                         
    #> 6 D01AA03  hachimycin                        
    #> 7 D01AA04  pecilocin                         
    #> 8 D01AA06  mepartricin                       
    #> 9 D01AA07  pyrrolnitrin                      
    #>10 D01AA08  griseofulvin                      
    #># ℹ 490 more rows
    #># ℹ Use `print(n = ...)` to see more rows

    #>$ddd
    #># A tibble: 392 × 7
    #>   source_code atc_code atc_name                                        ddd   uom   adm_r note 
    #>   <chr>       <chr>    <chr>                                           <chr> <chr> <chr> <chr>
    #> 1 D01AA       D01AA01  nystatin                                        NA    NA    NA    NA   
    #> 2 D01AA       D01AA02  natamycin                                       NA    NA    NA    NA   
    #> 3 D01AA       D01AA03  hachimycin                                      NA    NA    NA    NA   
    #> 4 D01AA       D01AA04  pecilocin                                       NA    NA    NA    NA   
    #> 5 D01AA       D01AA06  mepartricin                                     NA    NA    NA    NA   
    #> 6 D01AA       D01AA07  pyrrolnitrin                                    NA    NA    NA    NA   
    #> 7 D01AA       D01AA08  griseofulvin                                    NA    NA    NA    NA   
    #> 8 D01AA       D01AA20  antibiotics in combination with corticosteroids NA    NA    NA    NA   
    #> 9 D01AC       D01AC01  clotrimazole                                    NA    NA    NA    NA   
    #>10 D01AC       D01AC02  miconazole                                      NA    NA    NA    NA   
    #># ℹ 382 more rows
    #># ℹ Use `print(n = ...)` to see more rows

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

**`atcddd`** is an R package that simplifies working with **ATC codes**
— the World Health Organization’s global classification system for
medicinal products. Whether you’re analyzing prescription databases,
mapping drug classes, validating inputs, or linking drug names to codes,
`atcddd` provides intuitive, fast, and reliable tools.

### ✅ Key Features

- ✔ Validate ATC code structure (L1 to L5)
- ✔ Get official WHO descriptions for any code
- ✔ Extract anatomical, therapeutic, or chemical groups
- ✔ Navigate between ATC hierarchy levels
- ✔ Fuzzy-search drug names → ATC codes
- ✔ Access built-in reference tables (updated to latest WHO version)

Perfect for **pharmacoepidemiology**, **health services research**,
**drug utilization studies**, and **clinical data science**.

------------------------------------------------------------------------

## 🚀 Installation

Install the stable version from **CRAN**:

``` r
install.packages("atcddd")
```

Or install the development version from **GitHub**:

``` r
# install.packages("remotes")
remotes::install_github("yourusername/atcddd")
```

Load the package:

``` r
library(atcddd)
```

------------------------------------------------------------------------

## 🧪 Quick Examples

### Validate an ATC code

``` r
is_valid_atc("N02BE01")  # Paracetamol combo
#> [1] TRUE

is_valid_atc("X99ZZ99")  # Invalid
#> [1] FALSE
```

### Get description

``` r
atc_description("N02BE01")
#> [1] "Paracetamol, combinations excl. psycholeptics"
```

### Extract anatomical group (Level 1)

``` r
atc_level("N02BE01", level = 1)
#> [1] "N: Nervous system"
```

### Fuzzy match drug name → ATC code

``` r
find_atc_code("Tylenol")
#> [1] "N02BE01"

find_atc_code("Metformin")
#> [1] "A10BA02"
```

------------------------------------------------------------------------

## 📚 Core Functions

| Function            | Description                                      |
|---------------------|--------------------------------------------------|
| `is_valid_atc()`    | Validate ATC code format and structure           |
| `atc_description()` | Retrieve official WHO description                |
| `atc_level()`       | Extract code at specified level (1-5)            |
| `find_atc_code()`   | Fuzzy match drug name to best ATC code           |
| `atc_table()`       | Get full reference table of ATC codes & metadata |
| `atc_search()`      | Search codes/descriptions by keyword             |

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

We welcome contributions! Please see our
[CONTRIBUTING.md](CONTRIBUTING.md) guide for how to:

- Report bugs
- Suggest features
- Submit pull requests
- Improve documentation

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

\`\`\`
