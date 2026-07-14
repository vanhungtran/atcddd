# Search for drugs by name in the ATC database

Searches the bundled WHO ATC database for drugs matching a query string.
Performs a multi-stage search: exact match → prefix match → substring
match → word-boundary match. Results are ranked by match quality.

This function works **fully offline** against the bundled data — no
internet connection is needed once the database is loaded.

## Usage

``` r
search_drug(query, data = NULL, max_results = 20L)
```

## Arguments

- query:

  Character scalar; the drug name or partial name to search for. Not
  case-sensitive. Examples: `"aspirin"`, `"paracetamol"`, `"statin"`.

- data:

  Optional data frame to search (from
  [`atc_load_db()`](https://vanhungtran.github.io/atcddd/reference/atc_load_db.md)
  or a custom source). If `NULL`, the bundled database is loaded
  automatically.

- max_results:

  Integer; maximum number of results to return. Default is 20.

## Value

A tibble of matching ATC codes and names, sorted by match quality (best
matches first). Returns a 0-row tibble if no matches are found.

## Match Types

Results include a `match_type` column indicating how each result was
found:

- `exact` — query exactly equals the drug name

- `starts_with` — drug name starts with the query

- `contains` — drug name contains the query as a substring

- `word_match` — query matches a whole word within the drug name

## See also

[`fuzzy_match_drug()`](https://vanhungtran.github.io/atcddd/reference/fuzzy_match_drug.md)
for typo-tolerant matching,
[`resolve_atc()`](https://vanhungtran.github.io/atcddd/reference/resolve_atc.md)
for hybrid local/live resolution.

## Examples

``` r
# \donttest{
search_drug("aspirin")
#> # A tibble: 1 × 4
#>   match_type atc_code atc_name             level
#>   <chr>      <chr>    <chr>                <int>
#> 1 synonym    N02BA01  acetylsalicylic acid     5
search_drug("paracetamol")
#> # A tibble: 8 × 4
#>   match_type  atc_code atc_name                                      level
#>   <chr>       <chr>    <chr>                                         <int>
#> 1 exact       N02BE01  paracetamol                                       5
#> 2 starts_with N02BE51  paracetamol, combinations excl. psycholeptics     5
#> 3 starts_with N02BE71  paracetamol, combinations with psycholeptics      5
#> 4 contains    N02AJ01  dihydrocodeine and paracetamol                    5
#> 5 contains    N02AJ06  codeine and paracetamol                           5
#> 6 contains    N02AJ13  tramadol and paracetamol                          5
#> 7 contains    N02AJ17  oxycodone and paracetamol                         5
#> 8 contains    N02AJ22  hydrocodone and paracetamol                       5
search_drug("statin", max_results = 10)
#> # A tibble: 10 × 4
#>    match_type atc_code atc_name                     level
#>    <chr>      <chr>    <chr>                        <int>
#>  1 contains   A07AA02  nystatin                         5
#>  2 contains   A10BH51  sitagliptin and simvastatin      5
#>  3 contains   A10BH52  gemigliptin and rosuvastatin     5
#>  4 contains   B02AB05  ulinastatin                      5
#>  5 contains   C10AA01  simvastatin                      5
#>  6 contains   C10AA02  lovastatin                       5
#>  7 contains   C10AA03  pravastatin                      5
#>  8 contains   C10AA04  fluvastatin                      5
#>  9 contains   C10AA05  atorvastatin                     5
#> 10 contains   C10AA06  cerivastatin                     5
search_drug("hydrocortisone")
#> # A tibble: 20 × 4
#>    match_type  atc_code atc_name                                level
#>    <chr>       <chr>    <chr>                                   <int>
#>  1 exact       A01AC03  hydrocortisone                              5
#>  2 exact       A07EA02  hydrocortisone                              5
#>  3 exact       C05AA01  hydrocortisone                              5
#>  4 exact       D07AA02  hydrocortisone                              5
#>  5 exact       D07XA01  hydrocortisone                              5
#>  6 exact       H02AB09  hydrocortisone                              5
#>  7 exact       S01BA02  hydrocortisone                              5
#>  8 exact       S01CB03  hydrocortisone                              5
#>  9 exact       S02BA01  hydrocortisone                              5
#> 10 starts_with D07AB02  hydrocortisone butyrate                     5
#> 11 starts_with D07AB11  hydrocortisone buteprate                    5
#> 12 starts_with D07AC16  hydrocortisone aceponate                    5
#> 13 starts_with D07BA04  hydrocortisone and antiseptics              5
#> 14 starts_with D07BB04  hydrocortisone butyrate and antiseptics     5
#> 15 starts_with D07CA01  hydrocortisone and antibiotics              5
#> 16 starts_with R01AD60  hydrocortisone, combinations                5
#> 17 starts_with S01BB01  hydrocortisone and mydriatics               5
#> 18 starts_with S01CA03  hydrocortisone and antiinfectives           5
#> 19 starts_with S02CA03  hydrocortisone and antiinfectives           5
#> 20 starts_with S03CA04  hydrocortisone and antiinfectives           5
# }
```
