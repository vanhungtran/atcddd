# Package index

## Drug Name Search & Resolution

Find ATC codes from drug names, synonyms, and free text

- [`search_drug()`](https://vanhungtran.github.io/atcddd/reference/search_drug.md)
  : Search for drugs by name in the ATC database
- [`fuzzy_match_drug()`](https://vanhungtran.github.io/atcddd/reference/fuzzy_match_drug.md)
  : Fuzzy-match a drug name to ATC codes
- [`resolve_atc()`](https://vanhungtran.github.io/atcddd/reference/resolve_atc.md)
  : Resolve a drug name to its ATC code with hybrid local/live lookup
- [`resolve_batch()`](https://vanhungtran.github.io/atcddd/reference/resolve_batch.md)
  : Resolve multiple drug names at once
- [`atc_add_synonym()`](https://vanhungtran.github.io/atcddd/reference/atc_add_synonym.md)
  : Add a drug name synonym to the lookup table
- [`atc_from_text()`](https://vanhungtran.github.io/atcddd/reference/atc_from_text.md)
  : Extract drug names from free-text clinical notes

## DDD Computation

Compute Defined Daily Doses from prescription records

- [`compute_ddd()`](https://vanhungtran.github.io/atcddd/reference/compute_ddd.md)
  : Convert prescription data into Defined Daily Doses (DDDs)
- [`compute_did()`](https://vanhungtran.github.io/atcddd/reference/compute_did.md)
  : Compute DDDs per 1000 inhabitants per day (DID)
- [`ddd_availability()`](https://vanhungtran.github.io/atcddd/reference/ddd_availability.md)
  : Summary of DDD coverage by anatomical group
- [`ddd_route_comparison()`](https://vanhungtran.github.io/atcddd/reference/ddd_route_comparison.md)
  : Compare DDD values for a drug across administration routes

## Offline Hierarchy

Navigate the ATC classification tree without internet

- [`atc_children()`](https://vanhungtran.github.io/atcddd/reference/atc_children.md)
  : Get direct children of an ATC code in the hierarchy
- [`atc_descendants()`](https://vanhungtran.github.io/atcddd/reference/atc_descendants.md)
  : Get all descendants of an ATC code through the hierarchy
- [`atc_level()`](https://vanhungtran.github.io/atcddd/reference/atc_level.md)
  : Determine the ATC hierarchy level of a code
- [`atc_parent()`](https://vanhungtran.github.io/atcddd/reference/atc_parent.md)
  : Get the parent ATC code one level up in the hierarchy
- [`normalize_atc_code()`](https://vanhungtran.github.io/atcddd/reference/normalize_atc_code.md)
  : Normalize an ATC code to canonical form

## ATC Code Validation

Validate and identify ATC codes

- [`is_valid_atc_code()`](https://vanhungtran.github.io/atcddd/reference/is_valid_atc_code.md)
  [`is_valid_atc()`](https://vanhungtran.github.io/atcddd/reference/is_valid_atc_code.md)
  : Validate ATC Code Format

## WHO Data Crawling

Retrieve live data from the WHO ATC/DDD Index

- [`atc_crawl()`](https://vanhungtran.github.io/atcddd/reference/atc_crawl.md)
  : Crawl the WHO ATC/DDD Index
- [`get_atc_data()`](https://vanhungtran.github.io/atcddd/reference/get_atc_data.md)
  : Get ATC Classification Data from WHO Database
- [`get_atc_hierarchy()`](https://vanhungtran.github.io/atcddd/reference/get_atc_hierarchy.md)
  : Get ATC Hierarchy Tree
- [`atc_roots_default()`](https://vanhungtran.github.io/atcddd/reference/atc_roots_default.md)
  : Default ATC Root Codes

## Data I/O

Export and verify your data

- [`atc_write_csv()`](https://vanhungtran.github.io/atcddd/reference/atc_write_csv.md)
  : Write ATC Codes and DDD Tables to CSV Files
- [`atc_manifest()`](https://vanhungtran.github.io/atcddd/reference/atc_manifest.md)
  : Compute a Checksum Manifest for Output Files
- [`atc_write_manifest()`](https://vanhungtran.github.io/atcddd/reference/atc_write_manifest.md)
  : Write a Checksum Manifest CSV File
- [`atc_load_db()`](https://vanhungtran.github.io/atcddd/reference/atc_load_db.md)
  : Load the bundled WHO ATC database into memory
