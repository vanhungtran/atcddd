# Summary of DDD coverage by anatomical group

Returns a summary table showing which ATC groups have DDD values
assigned in the WHO DDD Index. The report is grouped by anatomical main
group (Level 1 of the ATC hierarchy).

## Usage

``` r
ddd_availability(data = NULL)
```

## Arguments

- data:

  Optional pre-loaded DDD data frame (from
  [`atc_load_db`](https://vanhungtran.github.io/atcddd/reference/atc_load_db.md)
  or a custom source). If `NULL`, the bundled database is loaded
  automatically.

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) with
columns:

- `anatomical_group`:

  Level 1 letter (e.g. `"A"`, `"B"`, ...).

- `group_name`:

  The anatomical group description (e.g.
  `"Alimentary tract and metabolism"`).

- `total_substances`:

  Number of unique ATC Level-5 substances in that group.

- `with_ddd`:

  Number of substances with an assigned DDD.

- `pct_with_ddd`:

  Percentage of substances with an assigned DDD.

## See also

[`compute_ddd`](https://vanhungtran.github.io/atcddd/reference/compute_ddd.md)
for DDD computation,
[`compute_did`](https://vanhungtran.github.io/atcddd/reference/compute_did.md)
for DID calculation.

## Examples

``` r
# \donttest{
ddd_availability()
#> # A tibble: 14 × 5
#>    anatomical_group group_name            total_substances with_ddd pct_with_ddd
#>    <chr>            <chr>                            <int>    <int>        <dbl>
#>  1 A                Alimentary tract and…              706      301         42.6
#>  2 B                Blood and blood form…              270      105         38.9
#>  3 C                Cardiovascular system              657      285         43.4
#>  4 D                Dermatologicals                    395       16          4.1
#>  5 G                Genito-urinary syste…              291      131         45  
#>  6 H                Systemic hormonal pr…               93       58         62.4
#>  7 J                Antiinfectives for s…              615      344         55.9
#>  8 L                Antineoplastic and i…              562      236         42  
#>  9 M                Musculo-skeletal sys…              243      106         43.6
#> 10 N                Nervous system                     666      378         56.8
#> 11 P                Antiparasitic produc…              139       50         36  
#> 12 R                Respiratory system                 401      190         47.4
#> 13 S                Sensory organs                     316       11          3.5
#> 14 V                Various                            326       19          5.8
# }
```
