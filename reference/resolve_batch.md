# Resolve multiple drug names at once

Vectorised version of
[`resolve_atc()`](https://vanhungtran.github.io/atcddd/reference/resolve_atc.md)
— resolves a character vector of drug names to their ATC codes. Runs
sequentially with rate limiting to be respectful of the WHO server when
live fallback is used.

## Usage

``` r
resolve_batch(queries, source = c("hybrid", "local", "live"), ...)
```

## Arguments

- queries:

  Character vector of drug names to resolve.

- source:

  Character; `"hybrid"`, `"local"`, or `"live"`. Passed to
  [`resolve_atc()`](https://vanhungtran.github.io/atcddd/reference/resolve_atc.md).
  Default is `"hybrid"`.

- ...:

  Additional arguments passed to
  [`resolve_atc()`](https://vanhungtran.github.io/atcddd/reference/resolve_atc.md).

## Value

A tibble stacking the results from each query, with the same columns as
[`resolve_atc()`](https://vanhungtran.github.io/atcddd/reference/resolve_atc.md).

## See also

[`resolve_atc()`](https://vanhungtran.github.io/atcddd/reference/resolve_atc.md)
for single-name resolution.

## Examples

``` r
# \donttest{
meds <- c("aspirin", "paracetamol", "ibuprofen", "metformin")
resolve_batch(meds)
#> # A tibble: 4 × 8
#>   query       atc_code atc_name             ddd   uom   adm_r source match_type
#>   <chr>       <chr>    <chr>                <chr> <chr> <chr> <chr>  <chr>     
#> 1 aspirin     N02BA01  acetylsalicylic acid 3     g     O     local  synonym   
#> 2 paracetamol N02BE01  paracetamol          3     g     O     local  exact     
#> 3 ibuprofen   C01EB16  ibuprofen            30    mg    P     local  exact     
#> 4 metformin   A10BA02  metformin            2     g     O     local  exact     

# Offline only
resolve_batch(meds, source = "local")
#> # A tibble: 4 × 8
#>   query       atc_code atc_name             ddd   uom   adm_r source match_type
#>   <chr>       <chr>    <chr>                <chr> <chr> <chr> <chr>  <chr>     
#> 1 aspirin     N02BA01  acetylsalicylic acid 3     g     O     local  synonym   
#> 2 paracetamol N02BE01  paracetamol          3     g     O     local  exact     
#> 3 ibuprofen   C01EB16  ibuprofen            30    mg    P     local  exact     
#> 4 metformin   A10BA02  metformin            2     g     O     local  exact     
# }
```
