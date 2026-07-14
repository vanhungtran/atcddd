# Get ATC Hierarchy Tree

Retrieves the complete hierarchical structure for specified ATC codes,
including all parent and child relationships. Useful for understanding
the classification structure and building tree visualizations.

## Usage

``` r
get_atc_hierarchy(codes = NULL, max_levels = 5, rate_limit = 0.5)
```

## Arguments

- codes:

  Character vector; one or more ATC codes to build tree from. If NULL,
  builds tree for all main anatomical groups (may be slow).

- max_levels:

  Integer; maximum depth to traverse. Default is 5 (complete hierarchy).

- rate_limit:

  Numeric; minimum delay in seconds between requests. Default is 0.5.

## Value

A tibble with hierarchical structure including:

- `atc_code`: The ATC code

- `atc_name`: Name/description

- `level`: Hierarchy level (1-5)

- `parent_code`: Parent code in hierarchy (NA for Level 1)

- `has_children`: Logical indicating if code has sub-classifications

## Examples

``` r
# \donttest{
# Get hierarchy tree for opioids
get_atc_hierarchy("N02A")
#> # A tibble: 91 × 8
#>    atc_code level parent_code has_children ddd   uom   adm_r note 
#>    <chr>    <int> <chr>       <lgl>        <chr> <chr> <chr> <chr>
#>  1 N02AA        4 N02A        TRUE         NA    NA    NA    NA   
#>  2 N02AA01      5 N02AA       FALSE        0.1   g     O     NA   
#>  3 N02AA01      5 N02AA       FALSE        30    mg    P     NA   
#>  4 N02AA01      5 N02AA       FALSE        30    mg    R     NA   
#>  5 N02AA02      5 N02AA       FALSE        NA    NA    NA    NA   
#>  6 N02AA03      5 N02AA       FALSE        20    mg    O     NA   
#>  7 N02AA03      5 N02AA       FALSE        4     mg    P     NA   
#>  8 N02AA03      5 N02AA       FALSE        4     mg    R     NA   
#>  9 N02AA04      5 N02AA       FALSE        30    mg    O     NA   
#> 10 N02AA04      5 N02AA       FALSE        30    mg    P     NA   
#> # ℹ 81 more rows

# Get complete nervous system tree (may take time)
get_atc_hierarchy("N", max_levels = 5)
#> # A tibble: 924 × 8
#>    atc_code level parent_code has_children ddd   uom   adm_r note 
#>    <chr>    <int> <chr>       <lgl>        <chr> <chr> <chr> <chr>
#>  1 N01          2 N           TRUE         NA    NA    NA    NA   
#>  2 N01A         3 N01         TRUE         NA    NA    NA    NA   
#>  3 N01AA        4 N01A        TRUE         NA    NA    NA    NA   
#>  4 N01AA01      5 N01AA       FALSE        NA    NA    NA    NA   
#>  5 N01AA02      5 N01AA       FALSE        NA    NA    NA    NA   
#>  6 N01AB        4 N01A        TRUE         NA    NA    NA    NA   
#>  7 N01AB01      5 N01AB       FALSE        NA    NA    NA    NA   
#>  8 N01AB02      5 N01AB       FALSE        NA    NA    NA    NA   
#>  9 N01AB04      5 N01AB       FALSE        NA    NA    NA    NA   
#> 10 N01AB05      5 N01AB       FALSE        NA    NA    NA    NA   
#> # ℹ 914 more rows
# }
```
