# Convert prescription data into Defined Daily Doses (DDDs)

Converts a data frame of prescription-level drug utilisation data into
Defined Daily Doses (DDDs) per drug per prescription. Each row
represents one prescription line (one drug for one patient). The
function looks up the WHO DDD for each ATC code, accounting for route of
administration, then computes the number of DDDs dispensed.

## Usage

``` r
compute_ddd(x, adm_r = "O", ...)
```

## Arguments

- x:

  A data frame with the following columns:

  `atc_code`

  : Character vector of ATC codes (Level 5, e.g. `"N02BE01"`).

  `quantity`

  : Numeric; the number of units administered (tablets, ml, etc.).

  `strength`

  : Numeric; the amount per unit (mg per tablet, mg per ml, etc.).

  `strength_unit`

  : Optional character; the unit of `strength`. Defaults to `"mg"` if
    not supplied.

  `adm_r`

  : Optional character; the route of administration per row. If absent,
    the global `adm_r` parameter is used.

  Any additional columns (e.g. `patient_id`, `prescription_date`) are
  preserved in the output.

- adm_r:

  Default administration route for rows without a per-row `adm_r`
  column. Default `"O"` (oral).

- ...:

  Reserved for future extensions. Currently unused.

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html)
inheriting all columns from `x` plus:

- `ddd_value`:

  The DDD value looked up from the WHO database, in the WHO unit (e.g.
  g, mg).

- `ddd_unit`:

  The unit of the WHO DDD value.

- `total_amount`:

  The total amount of drug: `quantity * strength`, expressed in
  `strength_unit`.

- `ddd_ratio`:

  The number of DDDs: `total_amount / ddd_value`, properly
  unit-converted.

## Details

**DDD Lookup Logic**

1.  Try to match `atc_code + adm_r` (route-specific DDD).

2.  If no route-specific DDD exists, fall back to any non-NA DDD for
    that ATC code.

3.  If no DDD is found at all, the result is `NA` and a warning is
    issued listing the codes with missing DDDs.

**Unit Conversion** The function automatically converts between
compatible units when the prescription `strength_unit` differs from the
WHO DDD unit. Supported conversions:

- **Mass**: g, mg, mcg (grams)

- **Units**: U, TU, MU (units, thousand units, million units)

- **Volume**: ml (exact match only)

Incompatible unit pairs (e.g. mg vs MU) produce `NA` with a warning.

## See also

[`compute_did`](https://vanhungtran.github.io/atcddd/reference/compute_did.md)
for DDDs per 1000 inhabitants per day,
[`ddd_availability`](https://vanhungtran.github.io/atcddd/reference/ddd_availability.md)
for DDD coverage summaries,
[`ddd_route_comparison`](https://vanhungtran.github.io/atcddd/reference/ddd_route_comparison.md)
for route-specific DDDs.

## Examples

``` r
# \donttest{
prescriptions <- data.frame(
  patient_id    = c(1, 1, 2, 3),
  atc_code      = c("N02BA01", "C10AA05", "N02BA01", "A10BA02"),
  quantity      = c(100, 30, 60, 90),
  strength      = c(500, 20, 500, 500),
  strength_unit = c("mg", "mg", "mg", "mg"),
  adm_r         = c("O", "O", "O", "O")
)
compute_ddd(prescriptions)
#> # A tibble: 4 × 10
#>   patient_id atc_code quantity strength strength_unit adm_r ddd_value ddd_unit
#>        <dbl> <chr>       <dbl>    <dbl> <chr>         <chr>     <dbl> <chr>   
#> 1          1 N02BA01       100      500 mg            O             3 g       
#> 2          1 C10AA05        30       20 mg            O            20 mg      
#> 3          2 N02BA01        60      500 mg            O             3 g       
#> 4          3 A10BA02        90      500 mg            O             2 g       
#> # ℹ 2 more variables: total_amount <dbl>, ddd_ratio <dbl>

# Without strength_unit column (defaults to "mg")
df <- data.frame(
  atc_code = c("N02BA01", "C10AA05"),
  quantity = c(100, 30),
  strength = c(500, 20)
)
compute_ddd(df)
#> # A tibble: 2 × 9
#>   atc_code quantity strength strength_unit adm_r ddd_value ddd_unit total_amount
#>   <chr>       <dbl>    <dbl> <chr>         <chr>     <dbl> <chr>           <dbl>
#> 1 N02BA01       100      500 mg            O             3 g               50000
#> 2 C10AA05        30       20 mg            O            20 mg                600
#> # ℹ 1 more variable: ddd_ratio <dbl>
# }
```
