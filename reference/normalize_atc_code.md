# Normalize an ATC code to canonical form

Trims whitespace and converts to uppercase. This is the canonicalisation
step applied internally before validation, level detection, and parent
derivation.

## Usage

``` r
normalize_atc_code(x)
```

## Arguments

- x:

  Character vector of ATC codes.

## Value

Character vector of trimmed, uppercase codes.

## See also

[`is_valid_atc_code()`](https://vanhungtran.github.io/atcddd/reference/is_valid_atc_code.md),
[`atc_level()`](https://vanhungtran.github.io/atcddd/reference/atc_level.md)

## Examples

``` r
normalize_atc_code(" n02be01 ")
#> [1] "N02BE01"
normalize_atc_code(c("n02BE01", "C10aa05"))
#> [1] "N02BE01" "C10AA05"
```
