# Fuzzy-match a drug name to ATC codes

Finds ATC codes for drug names that may be misspelled, abbreviated, or
use non-standard formatting. Uses Levenshtein (edit) distance via
[`utils::adist()`](https://rdrr.io/r/utils/adist.html) to find close
matches in the bundled WHO database.

This is useful when:

- Users type drug names from memory (typos)

- Clinical notes use non-standard spellings

- Brand names or abbreviations differ from WHO naming

## Usage

``` r
fuzzy_match_drug(query, data = NULL, max_distance = 3L, max_results = 10L)
```

## Arguments

- query:

  Character scalar; the drug name to match.

- data:

  Optional data frame to search. If `NULL`, loads the bundled database.

- max_distance:

  Integer; maximum allowed Levenshtein distance. Lower values are
  stricter. Default is 3.

- max_results:

  Integer; maximum results to return. Default is 10.

## Value

A tibble of the closest-matching ATC codes, sorted by edit distance
(closest first). Includes a `distance` column with the Levenshtein
distance to each match.

## See also

[`search_drug()`](https://vanhungtran.github.io/atcddd/reference/search_drug.md)
for exact/substring matching,
[`resolve_atc()`](https://vanhungtran.github.io/atcddd/reference/resolve_atc.md)
for hybrid resolution.

## Examples

``` r
# \donttest{
# Common misspellings
fuzzy_match_drug("acetominophen")    # should find "paracetamol"
#> # A tibble: 0 × 0
fuzzy_match_drug("asprin")           # should find "aspirin"
#> # A tibble: 4 × 4
#>   atc_code atc_name level distance
#>   <chr>    <chr>    <int>    <dbl>
#> 1 A09AA03  pepsin       5        3
#> 2 B01AB01  heparin      5        3
#> 3 C05BA03  heparin      5        3
#> 4 S01XA14  heparin      5        3
fuzzy_match_drug("metmorphin")       # should find "metformin"
#> # A tibble: 1 × 4
#>   atc_code atc_name  level distance
#>   <chr>    <chr>     <int>    <dbl>
#> 1 A10BA02  metformin     5        3

# Stricter matching
fuzzy_match_drug("asprin", max_distance = 1)
#> # A tibble: 6 × 4
#>   atc_code atc_name        level distance
#>   <chr>    <chr>           <int>    <dbl>
#> 1 A08AA11  lorcaserin          5        1
#> 2 C01BB04  aprindine           5        1
#> 3 M03BX08  cyclobenzaprine     5        1
#> 4 N04AA11  bornaprine          5        1
#> 5 N06AX07  minaprine           5        1
#> 6 V04CG04  pentagastrin        5        1
# }
```
