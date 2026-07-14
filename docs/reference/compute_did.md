# Compute DDDs per 1000 inhabitants per day (DID)

Computes the standard WHO drug utilisation metric: the number of Defined
Daily Doses per 1000 inhabitants per day. This normalises drug
consumption across different population sizes and observation periods,
enabling fair comparisons between populations or time periods.

## Usage

``` r
compute_did(ddd_data, population, days)
```

## Arguments

- ddd_data:

  A data frame containing at least a `ddd_ratio` column, typically the
  output of
  [`compute_ddd`](https://vanhungtran.github.io/atcddd/reference/compute_ddd.md).

- population:

  Integer; the study population size.

- days:

  Integer; the number of days in the study period.

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) with
columns:

- `total_ddd`:

  Sum of all `ddd_ratio` values.

- `did`:

  DDDs per 1000 inhabitants per day.

- `population`:

  Study population size.

- `days`:

  Number of days in the study period.

## Details

The DID formula is: \$\$DID = \frac{\sum(ddd\\ratio)}{population \times
days} \times 1000\$\$

## See also

[`compute_ddd`](https://vanhungtran.github.io/atcddd/reference/compute_ddd.md)
for computing DDD ratios,
[`ddd_availability`](https://vanhungtran.github.io/atcddd/reference/ddd_availability.md)
for DDD coverage summaries.

## Examples

``` r
# \donttest{
prescriptions <- data.frame(
  atc_code      = c("N02BA01", "C10AA05", "A10BA02"),
  quantity      = c(100, 30, 90),
  strength      = c(500, 20, 500),
  strength_unit = c("mg", "mg", "mg")
)
ddd_result <- compute_ddd(prescriptions)
compute_did(ddd_result, population = 10000, days = 30)
#> # A tibble: 1 × 4
#>   total_ddd   did population  days
#>       <dbl> <dbl>      <dbl> <dbl>
#> 1      69.2 0.231      10000    30
# }
```
