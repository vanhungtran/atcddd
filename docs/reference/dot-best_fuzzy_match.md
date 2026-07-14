# Find the best fuzzy match for a token across codes and synonyms

Checks both the WHO codes table and the synonym table for the closest
fuzzy match (Levenshtein distance \<= 3). Returns a list with atc_code,
atc_name, and confidence, or NULL if no acceptable match is found.

## Usage

``` r
.best_fuzzy_match(token, codes)
```

## Arguments

- token:

  Character; lowercased token to match.

- codes:

  Data frame; the WHO ATC codes table.

## Value

A list with elements atc_code, atc_name, confidence, or NULL.
