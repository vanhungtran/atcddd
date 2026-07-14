# Resolve a drug name to its ATC code with hybrid local/live lookup

The primary drug-name resolution function. Tries to find the ATC code
for a given drug name by searching the bundled local database first,
then optionally falling back to a live WHO crawl if the drug is not
found locally.

This is the function you reach for when you have a drug name and need
its ATC code — the \#1 workflow in pharmacoepidemiology.

## Usage

``` r
resolve_atc(
  query,
  source = c("hybrid", "local", "live"),
  data = NULL,
  fuzzy = TRUE,
  rate_limit = 0.5
)
```

## Arguments

- query:

  Character scalar; the drug name to resolve. Case-insensitive.
  Examples: `"aspirin"`, `"atorvastatin"`.

- source:

  Character; resolution strategy:

  - `"local"` — bundled database only (offline, fast)

  - `"live"` — WHO website only (always up-to-date, requires internet)

  - `"hybrid"` — try local first, fall back to live (default)

- data:

  Optional data frame for local search. If `NULL`, auto-loads the
  bundled database.

- fuzzy:

  Logical; if `TRUE` and the exact lookup fails, fall back to fuzzy
  matching before trying live resolution. Default is `TRUE`.

- rate_limit:

  Numeric; delay between live WHO requests (seconds). Only used when
  `source` is `"live"` or `"hybrid"`. Default is 0.5.

## Value

A tibble with columns:

- `query` — the original query

- `atc_code` — the resolved ATC code

- `atc_name` — the drug name from the database

- `source` — `"local"` or `"live"` indicating where the match came from

- `match_type` — how the match was found (`"exact"`, `"fuzzy"`,
  `"live"`)

Returns a 0-row tibble if the drug cannot be resolved.

## Resolution Order (hybrid mode)

1.  Exact name match in local database

2.  Fuzzy match in local database (if `fuzzy = TRUE`)

3.  Live WHO crawl as last resort

## See also

[`resolve_batch()`](https://vanhungtran.github.io/atcddd/reference/resolve_batch.md)
for vectorised resolution,
[`search_drug()`](https://vanhungtran.github.io/atcddd/reference/search_drug.md)
for exploratory search.

## Examples

``` r
# \donttest{
# Offline — fast, no internet needed
resolve_atc("aspirin", source = "local")
#> # A tibble: 1 × 8
#>   query   atc_code atc_name             ddd   uom   adm_r source match_type
#>   <chr>   <chr>    <chr>                <chr> <chr> <chr> <chr>  <chr>     
#> 1 aspirin N02BA01  acetylsalicylic acid 3     g     O     local  synonym   

# Live — always current
resolve_atc("aspirin", source = "live")
#> Invalid ATC code format: ASPIRIN. Expect patterns like 'N', 'N02', 'N02B', 'N02BE', 'N02BE01'.
#> # A tibble: 0 × 8
#> # ℹ 8 variables: query <chr>, atc_code <chr>, atc_name <chr>, ddd <chr>,
#> #   uom <chr>, adm_r <chr>, source <chr>, match_type <chr>

# Hybrid (default) — local first, live fallback
resolve_atc("atorvastatin")
#> # A tibble: 1 × 8
#>   query        atc_code atc_name     ddd   uom   adm_r source match_type
#>   <chr>        <chr>    <chr>        <chr> <chr> <chr> <chr>  <chr>     
#> 1 atorvastatin C10AA05  atorvastatin 20    mg    O     local  exact     

# Batch resolution
meds <- c("aspirin", "metformin", "atorvastatin")
resolve_batch(meds)
#> # A tibble: 3 × 8
#>   query        atc_code atc_name             ddd   uom   adm_r source match_type
#>   <chr>        <chr>    <chr>                <chr> <chr> <chr> <chr>  <chr>     
#> 1 aspirin      N02BA01  acetylsalicylic acid 3     g     O     local  synonym   
#> 2 metformin    A10BA02  metformin            2     g     O     local  exact     
#> 3 atorvastatin C10AA05  atorvastatin         20    mg    O     local  exact     
# }
```
