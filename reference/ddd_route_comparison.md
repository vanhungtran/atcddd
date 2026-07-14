# Compare DDD values for a drug across administration routes

Displays the Defined Daily Dose (DDD) values for a single drug across
all available administration routes in the WHO DDD Index. This is useful
for understanding how DDDs differ by route of administration.

## Usage

``` r
ddd_route_comparison(atc_code, data = NULL)
```

## Arguments

- atc_code:

  A single ATC code (character string, e.g. `"N02BE01"` for
  paracetamol).

- data:

  Optional pre-loaded DDD data frame. If `NULL`, the bundled database is
  loaded automatically.

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) with
columns:

- `atc_code`:

  The ATC code.

- `atc_name`:

  The drug name.

- `ddd`:

  The DDD value.

- `uom`:

  The unit of the DDD value.

- `adm_r`:

  The administration route.

- `note`:

  Additional notes.

If no DDD entries are found, a message is printed and a 0-row tibble is
returned invisibly.

## See also

[`compute_ddd`](https://vanhungtran.github.io/atcddd/reference/compute_ddd.md)
for DDD computation.

## Examples

``` r
# \donttest{
# Paracetamol — compare oral, parenteral, rectal DDDs
ddd_route_comparison("N02BE01")
#> # A tibble: 3 × 6
#>   atc_code atc_name      ddd uom   adm_r note 
#>   <chr>    <chr>       <dbl> <chr> <chr> <chr>
#> 1 N02BE01  paracetamol     3 g     O     NA   
#> 2 N02BE01  paracetamol     3 g     P     NA   
#> 3 N02BE01  paracetamol     3 g     R     NA   

# Estradiol — multiple routes with differing DDDs
ddd_route_comparison("G03CA03")
#> # A tibble: 10 × 6
#>    atc_code atc_name    ddd uom   adm_r note                                    
#>    <chr>    <chr>     <dbl> <chr> <chr> <chr>                                   
#>  1 G03CA03  estradiol  0.3  mg    N     NA                                      
#>  2 G03CA03  estradiol  2    mg    O     NA                                      
#>  3 G03CA03  estradiol  1    mg    P     depot short duration                    
#>  4 G03CA03  estradiol  0.3  mg    P     depot long duration                     
#>  5 G03CA03  estradiol  5    mg    R     NA                                      
#>  6 G03CA03  estradiol 50    mcg   TD    patch, refer to amount delivered per 24…
#>  7 G03CA03  estradiol  1    mg    TD    gel                                     
#>  8 G03CA03  estradiol  1.53 mg    TD    spray                                   
#>  9 G03CA03  estradiol 25    mcg   V     NA                                      
#> 10 G03CA03  estradiol  7.5  mcg   V     vaginal ring, refers to amount delivere…
# }
```
