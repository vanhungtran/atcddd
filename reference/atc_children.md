# Get direct children of an ATC code in the hierarchy

Returns all ATC codes that are immediate children of the given parent
code. This works offline using any data frame of ATC codes (such as the
bundled WHO snapshot) — no internet connection is required.

The parent-child relationship follows the natural ATC hierarchy:

- Children of Level 1 `"N"` are Level 2 codes starting with `N` (e.g.
  `"N01"`, `"N02"`, …)

- Children of Level 4 `"N02BE"` are Level 5 substances (e.g.
  `"N02BE01"`, `"N02BE51"`, …)

## Usage

``` r
atc_children(code, data)
```

## Arguments

- code:

  Character scalar; the ATC parent code.

- data:

  Data frame containing at least an `atc_code` column (e.g. from the
  bundled WHO CSV or the output of
  [`atc_crawl()`](https://vanhungtran.github.io/atcddd/reference/atc_crawl.md)).

## Value

Character vector of child ATC codes, or `character(0)` if the code is a
leaf or not found.

## See also

[`atc_descendants()`](https://vanhungtran.github.io/atcddd/reference/atc_descendants.md),
[`atc_parent()`](https://vanhungtran.github.io/atcddd/reference/atc_parent.md),
[`atc_level()`](https://vanhungtran.github.io/atcddd/reference/atc_level.md)

## Examples

``` r
# Use the bundled WHO snapshot
data_path <- system.file("extdata", "WHO_ATC_codes_2026-07-14.csv",
                          package = "atcddd")
codes <- readr::read_csv(data_path, show_col_types = FALSE)

# Direct children of statins (C10AA)
atc_children("C10AA", codes)
#> [1] "C10AA01" "C10AA02" "C10AA03" "C10AA04" "C10AA05" "C10AA06" "C10AA07"
#> [8] "C10AA08"

# Direct children of the nervous system group
atc_children("N", codes)
#> [1] "N01" "N02" "N03" "N04" "N05" "N06" "N07"
```
