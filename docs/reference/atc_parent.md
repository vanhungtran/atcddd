# Get the parent ATC code one level up in the hierarchy

Given an ATC code, returns the code of its immediate parent in the
five-level hierarchy. Level-1 codes (single letters) have no parent.

## Usage

``` r
atc_parent(code)
```

## Arguments

- code:

  Character vector of ATC codes.

## Value

Character vector of parent codes. Returns `NA` for Level-1 codes and for
codes that do not match a recognised ATC pattern.

## See also

[`atc_level()`](https://vanhungtran.github.io/atcddd/reference/atc_level.md),
[`atc_children()`](https://vanhungtran.github.io/atcddd/reference/atc_children.md)

## Examples

``` r
atc_parent("N02BE01")   # "N02BE"
#> [1] "N02BE"
atc_parent("N02BE")     # "N02B"
#> [1] "N02B"
atc_parent("N02B")      # "N02"
#> [1] "N02"
atc_parent("N02")       # "N"
#> [1] "N"
atc_parent("N")         # NA (Level 1 has no parent)
#> [1] NA
```
