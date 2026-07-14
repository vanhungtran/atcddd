## Submission 1: atcddd v0.2.0

### Test environments
- Local: Windows 11, R 4.5.1
- GitHub Actions: ubuntu-latest, R-release
- GitHub Actions: windows-latest, R-release

### R CMD check results
0 errors | 0 warnings | 0 notes

### Reverse dependencies
This is a first CRAN submission — no reverse dependencies.

### Notes for CRAN reviewers

This package provides tools for the WHO ATC/DDD classification system for
pharmaceutical substances. Key capabilities:

1. **Offline drug name search**: Bundles WHO classification data for instant,
   network-free drug name → ATC code resolution. The data is shipped in
   `inst/extdata/` as CSV files (WHO-licensed, freely redistributable).

2. **WHO website crawling**: The package can optionally crawl the WHO ATC/DDD
   index (whocc.no) for live data. This is opt-in and requires the user to
   explicitly call `atc_crawl()` — no automatic or CRAN-test-time network
   access occurs.

3. **DDD computation**: Functions to compute Defined Daily Doses from
   prescription records, supporting unit conversion and route-specific
   dosing.

4. **No heavy dependencies**: Core functionality uses only tidyverse-adjacent
   packages (dplyr, readr, tibble, etc.). ggplot2 is in Suggests only.

### Data licensing note

The bundled WHO data files are freely available for non-commercial use from
the WHO Collaborating Centre for Drug Statistics Methodology
(https://atcddd.fhi.no/). They are redistributed under the same terms.
A CITATION file with attribution is included.
