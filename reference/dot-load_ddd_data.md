# Load the bundled WHO DDD data into memory

Load the bundled WHO DDD data into memory

## Usage

``` r
.load_ddd_data(data = NULL)
```

## Arguments

- data:

  Optional pre-loaded DDD data frame. If `NULL`, loads from the
  in-memory cache (via
  [`atc_load_db`](https://vanhungtran.github.io/atcddd/reference/atc_load_db.md))
  or the bundled CSV file.

## Value

A tibble of DDD definitions with a `ddd_numeric` column.
