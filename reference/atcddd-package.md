# atcddd: WHO ATC/DDD Crawler and Parser

Crawl and parse the WHO ATC/DDD index (whocc.no) into tidy tables with
robust HTTP (retries, timeouts, user agent), on-disk caching, rate
limiting, iterative traversal, resilient parsing, and checksum manifests
for reproducibility.

This package provides tools for working with the World Health
Organization's Anatomical Therapeutic Chemical (ATC) classification
system and Defined Daily Dose (DDD) values for medications. It enables
researchers and healthcare professionals to systematically retrieve,
parse, and analyze pharmaceutical classification data.

## Main Features

- **Web Crawling**: Automated retrieval from WHO ATC/DDD index

- **Caching**: Filesystem-based caching to minimize HTTP requests

- **Rate Limiting**: Respectful crawling with configurable delays

- **Reproducibility**: SHA256 checksums and manifest generation

- **Robust Parsing**: Handles malformed HTML and missing data

## Core Functions

- [`atc_crawl`](https://vanhungtran.github.io/atcddd/reference/atc_crawl.md):
  Crawl ATC/DDD index from specified roots

- [`atc_write_csv`](https://vanhungtran.github.io/atcddd/reference/atc_write_csv.md):
  Export results to CSV files

- [`atc_manifest`](https://vanhungtran.github.io/atcddd/reference/atc_manifest.md):
  Generate checksums for reproducibility

## See also

- WHO ATC/DDD Index: <https://www.whocc.no/atc_ddd_index/>

- Package Repository: <https://github.com/vanhungtran/atcddd>

## Author

Lucas VHH TRAN <tranhungydhcm@gmail.com>
