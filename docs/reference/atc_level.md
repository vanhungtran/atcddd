# Determine the ATC hierarchy level of a code

Returns the hierarchy level (1–5) for each ATC code based on its
character pattern. The five levels of the WHO ATC classification are:

- Level 1 — Anatomical main group (1 letter, e.g. `"N"`)

- Level 2 — Therapeutic subgroup (1 letter + 2 digits, e.g. `"N02"`)

- Level 3 — Pharmacological subgroup (4 chars, e.g. `"N02B"`)

- Level 4 — Chemical subgroup (5 chars, e.g. `"N02BE"`)

- Level 5 — Chemical substance (7 chars, e.g. `"N02BE01"`)

## Usage

``` r
atc_level(code)
```

## Arguments

- code:

  Character vector of ATC codes.

## Value

Integer vector of the same length, with values 1–5, or `NA` for codes
that do not match any recognised ATC pattern.

## See also

[`atc_parent()`](https://vanhungtran.github.io/atcddd/reference/atc_parent.md),
[`is_valid_atc_code()`](https://vanhungtran.github.io/atcddd/reference/is_valid_atc_code.md)

## Examples

``` r
atc_level("N")          # 1
#> [1] 1
atc_level("N02")        # 2
#> [1] 2
atc_level("N02BE01")    # 5
#> [1] 5
atc_level(c("C", "C10", "C10AA", "C10AA05"))
#> [1] 1 2 4 5
atc_level("garbage")    # NA
#> [1] NA
```
