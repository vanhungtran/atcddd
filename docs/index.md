# atcddd

![atcddd logo](reference/figures/logo.png)

### *Work with ATC Drug Classification Codes in R*

\

[![Lifecycle:
stable](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html)
[![R-CMD-check](https://github.com/vanhungtran/atcddd/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/vanhungtran/atcddd/actions)
[![License:
MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.21360365.svg)](https://doi.org/10.5281/zenodo.21360365)

\

> 🧬 A complete R toolkit for the WHO Anatomical Therapeutic Chemical
> (ATC) classification system and Defined Daily Doses (DDD).\
> **Offline drug name resolution · Brand synonyms · Fuzzy matching · DDD
> computation · Hierarchy navigation · Clinical text extraction**

------------------------------------------------------------------------

## ✨ What is atcddd?

Imagine you’re a pharmacoepidemiologist with a list of drug names —
aspirin, lipitor, metformin — and you need their ATC codes and Defined
Daily Doses. You could browse the WHO website one drug at a time… or you
could type:

``` r

library(atcddd)
resolve_atc("aspirin", source = "local")
```

And get back: `N02BA01 · acetylsalicylic acid · DDD: 3 g (Oral)` —
instantly, offline.

**atcddd** bundles the complete WHO ATC/DDD index (6,982 codes, 6,218
DDD entries) so you can search, resolve, compute, and explore without
ever needing an internet connection. It also knows brand names (lipitor
→ atorvastatin), handles typos (acetominophen → paracetamol), and can
compute DDDs from raw prescription data.

------------------------------------------------------------------------

## 🚀 Install

``` r

remotes::install_github("vanhungtran/atcddd")
library(atcddd)
```

------------------------------------------------------------------------

## 🧪 In 30 Seconds

[TABLE]

------------------------------------------------------------------------

## 📊 What’s in the Data?

The WHO ATC classification organises every drug into a 5-level tree,
from broad anatomical groups down to individual substances:

| Level               | Pattern   | Example | Meaning                         |
|---------------------|-----------|---------|---------------------------------|
| 1 · Anatomical      | `N`       | N       | Nervous system                  |
| 2 · Therapeutic     | `N02`     | N02     | Analgesics                      |
| 3 · Pharmacological | `N02B`    | N02B    | Other analgesics & antipyretics |
| 4 · Chemical        | `N02BE`   | N02BE   | Anilides                        |
| 5 · Substance       | `N02BE01` | N02BE01 | Paracetamol                     |

**6,982 codes · 6,218 DDD entries** — bundled with the package, crawled
fresh from WHO in July 2026.

------------------------------------------------------------------------

## 🎨 Visualising the WHO ATC/DDD Index

### How many drugs have a Defined Daily Dose?

![DDD Coverage](reference/figures/readme-ddd-coverage-v2.png)

DDD Coverage

### Which drugs actually have DDDs?

![DDD Waffle](reference/figures/readme-ddd-waffle.png)

DDD Waffle

### How the ATC tree fans out

![ATC Pyramid](reference/figures/readme-atc-pyramid-v2.png)

ATC Pyramid

### ATC Level 1 → Level 2: anatomical to therapeutic

![ATC L1L2](reference/figures/readme-atc-l1l2.png)

ATC L1L2

### DDD coverage × route, across all drug classes

![DDD Heatmap](reference/figures/readme-ddd-heatmap-v2.png)

DDD Heatmap

### The ATC hierarchy as a network

Every ATC code is a node in a beautiful bipartite tree — from 14
anatomical roots branching into thousands of substances. These
visualisations show the hierarchy from multiple angles:

\

| 🧬 Hierarchy Fan-out | 📊 Level 1 → Level 2 Distribution |
|:--:|:--:|
| ![ATC Fanout](reference/figures/readme-atc-fanout.png) | ![ATC Treemap](reference/figures/readme-atc-treemap.png) |
| All 5 levels: Anatomical → Substance | 14 groups branch into therapeutic subgroups |

| 💊 Substances per Group | 🔬 Cardiovascular System (igraph) |
|:--:|:--:|
| ![ATC Substances](reference/figures/readme-atc-substances.png) | ![CV igraph](reference/figures/atc-network-igraph.png) |
| Level-5 chemical substances by anatomical group | 830 connections, Fruchterman-Reingold layout |

| 🌐 All ATC Groups (L1–L4) | 🧠 Nervous System (igraph) |
|:--:|:--:|
| ![Full igraph](reference/figures/atc-network-full.png) | ![Nervous igraph](reference/figures/atc-network-nervous.png) |
| 445 connections across all 14 anatomical groups | 787 connections in the nervous system branch |

| 🫀 CV Top Level | 🎵 ATC Level 1 → Level 2 |
|:--:|:--:|
| ![CV L1L2](reference/figures/atc-network-ggraph-v2.png) | ![ATC Chord](reference/figures/atc-network-chord-v2.png) |
| L1→L2: 14 groups → therapeutic subgroups | Each anatomical group connects to multiple subgroups |

| 🔥 Drug × Gene Heatmap | 🫧 Gene × Drug-Class Dot Matrix |
|:--:|:--:|
| ![ATC Heatmap](reference/figures/atc-network-heatmap-v2.png) | ![ATC Dot Matrix](reference/figures/atc-network-dotmatrix-v2.png) |
| Therapeutic × pharmacological interaction matrix | Each dot = a parent–child ATC connection |

These networks show how 14 anatomical roots branch into therapeutic
subgroups, chemical classes, and 6,982 individual substances — all from
a single table of parent–child relationships.

------------------------------------------------------------------------

## 🔍 What Can You Do?

**🔍 Drug Name Search & Resolution** — *Your everyday workflow*

\

| Function | What it does |
|----|----|
| `resolve_atc("aspirin")` | Drug name → ATC code + DDD. Works offline. |
| `resolve_batch(c("a", "b"))` | Vectorised resolution for many drugs at once |
| `search_drug("statin")` | Ranked search: synonym → exact → prefix → substring |
| `fuzzy_match_drug("asprin")` | Levenshtein distance for typos |
| `atc_from_text("...")` | Extract drug names from clinical notes |
| `atc_add_synonym("eliquis", "B01AF02")` | Add your own brand name mappings |

``` r

# Your daily workflow — offline, instant
resolve_batch(c("aspirin", "lipitor", "metformin"), source = "local")
```

**💊 DDD Computation** — *From prescriptions to Defined Daily Doses*

\

| Function | What it does |
|----|----|
| [`compute_ddd()`](https://vanhungtran.github.io/atcddd/reference/compute_ddd.md) | Convert prescription data into DDDs per drug |
| [`compute_did()`](https://vanhungtran.github.io/atcddd/reference/compute_did.md) | DDDs per 1000 inhabitants per day (DID) |
| [`ddd_availability()`](https://vanhungtran.github.io/atcddd/reference/ddd_availability.md) | Which groups have DDDs assigned |
| `ddd_route_comparison("N02BE01")` | Compare DDDs across administration routes |

``` r

prescriptions <- data.frame(
  atc_code = c("N02BA01", "C10AA05", "A10BA02"),
  quantity = c(100, 30, 90),
  strength = c(500, 20, 500)
)

ddd <- compute_ddd(prescriptions)
compute_did(ddd, population = 10000, days = 30)
```

**Unit conversion is automatic** — mg ↔︎ g ↔︎ mcg, U ↔︎ TU ↔︎ MU. No manual
maths.

**🌳 Offline Hierarchy Navigation** — *No internet needed*

\

| Function                      | What it does                      |
|-------------------------------|-----------------------------------|
| `atc_children("C10AA", data)` | Direct children of any ATC code   |
| `atc_descendants("C", data)`  | Everything below, down to Level 5 |
| `atc_level("N02BE01")`        | Returns the hierarchy level (1–5) |
| `atc_parent("N02BE01")`       | The immediate parent code         |

``` r

atc_children("C10AA", codes)        # All statins
atc_descendants("N", codes)         # All nervous system substances
atc_parent("N02BE01")               # → N02BE
atc_level(c("N", "N02", "N02BE01")) # → 1, 2, 5
```

**✅ Validation & Utilities**

\

``` r

is_valid_atc_code(c("N02BE01", "C10AA05", "garbage"))
# [1]  TRUE  TRUE FALSE
normalize_atc_code(" n02be01 ")  # → "N02BE01"
```

**🌐 WHO Data Crawling** — *Live retrieval with caching*

\

``` r

res <- atc_crawl(roots = "D", rate = 0.5, max_codes = 100)
get_atc_data("N02")
get_atc_hierarchy("N02")
atc_roots_default()
```

**📁 Data I/O & Reproducibility**

\

``` r

atc_write_csv(res, dir = "data")         # Export to CSV
atc_write_manifest(paths)                # SHA256 checksums
atc_load_db()                            # Load bundled data into memory
```

------------------------------------------------------------------------

## 🎯 Why atcddd?

| Feature                                      | **atcddd**  | AMR (CRAN) |
|----------------------------------------------|:-----------:|:----------:|
| **All ATC groups** (not just antimicrobials) |     ✅      |     ❌     |
| **Offline drug name lookup**                 |     ✅      |     ❌     |
| **Fuzzy matching** (typos)                   |     ✅      |     ❌     |
| **Brand name synonyms**                      |     ✅      |     ❌     |
| **Free-text extraction**                     |     ✅      | ⚠️ limited |
| **DDD computation** with unit conversion     |     ✅      |     ❌     |
| **Hierarchy tools**                          |     ✅      |     ❌     |
| **Bundled data**                             | 6,982 codes | ~620 drugs |

------------------------------------------------------------------------

## 📖 Vignettes

| Vignette | What you’ll learn |
|----|----|
| [Getting Started](https://vanhungtran.github.io/atcddd/articles/vignettes.html) | Install, first steps, crawl, validate |
| [Navigating the ATC Hierarchy](https://vanhungtran.github.io/atcddd/articles/atc-hierarchy.html) | Parents, children, descendants, ancestry |
| [Working with DDDs](https://vanhungtran.github.io/atcddd/articles/ddd-analysis.html) | Understanding DDD coverage and data quality |
| [Computing DDDs](https://vanhungtran.github.io/atcddd/articles/computing-ddd.html) | Prescription data → DDDs, step by step |

------------------------------------------------------------------------

## 📖 Citation

If you use `atcddd` in your work, please cite:

> Van Hung (Huynh) TRAN. (2026). vanhungtran/atcddd: v0.2.0 (Version
> v0.2.0) \[Computer software\]. Zenodo.
> <https://doi.org/10.5281/zenodo.21360365>

``` bibtex
@software{tran2026atcddd,
  author    = {Van Hung (Huynh) TRAN},
  title     = {vanhungtran/atcddd: v0.2.0},
  year      = {2026},
  publisher = {Zenodo},
  version   = {v0.2.0},
  doi       = {10.5281/zenodo.21360365}
}
```

------------------------------------------------------------------------

## 🤝 Contributing

Bug reports, feature requests, and pull requests are welcome.\
See
[CONTRIBUTING.md](https://vanhungtran.github.io/atcddd/CONTRIBUTING.md)
and the [Code of
Conduct](https://vanhungtran.github.io/atcddd/CODE_OF_CONDUCT.md).

------------------------------------------------------------------------

## 📜 License

**MIT** © 2025 Lucas VHH TRAN. See
[LICENSE.md](https://vanhungtran.github.io/atcddd/LICENSE.md).

**Data**: WHO ATC/DDD Index © WHO Collaborating Centre for Drug
Statistics Methodology. Freely available for non-commercial research.
<https://atcddd.fhi.no/>

------------------------------------------------------------------------

\
*Built with 💊 and 🧬 for the R health data science community.*\
\
