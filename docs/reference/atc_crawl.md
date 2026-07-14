# Crawl the WHO ATC/DDD Index

Iteratively traverses ATC codes starting from one or more root codes,
respecting rate limits and using the HTTP layer's caching. Returns two
tidy tables: `codes` (unique ATC codes with names) and `ddd` (dose
definitions and related fields).

## Usage

``` r
atc_crawl(
  roots = atc_roots_default(),
  rate = 0.5,
  progress = interactive(),
  max_codes = Inf,
  quiet = FALSE
)
```

## Arguments

- roots:

  Character vector of root ATC codes to start from. Must be uppercase
  codes. Default:
  [`atc_roots_default()`](https://vanhungtran.github.io/atcddd/reference/atc_roots_default.md).

- rate:

  Numeric; minimum seconds between HTTP requests (default: 0.5).

- progress:

  Logical; show a progress bar (default:
  [`interactive()`](https://rdrr.io/r/base/interactive.html)).

- max_codes:

  Integer; limit on number of codes to visit (default: `Inf`).

- quiet:

  Logical; reduce informational messages (default: FALSE).

## Value

A list with `codes` and `ddd` tibbles.

## See also

[`atc_write_csv()`](https://vanhungtran.github.io/atcddd/reference/atc_write_csv.md),
[`atc_roots_default()`](https://vanhungtran.github.io/atcddd/reference/atc_roots_default.md)

## Examples

``` r
if (FALSE) { # \dontrun{
res <- atc_crawl(roots = "D", rate = 0.8, max_codes = 50)
head(res$codes)
head(res$ddd)
} # }
```
