# Validate ATC Code Format

Checks whether one or more strings conform to the official WHO ATC code
format. The function accepts character vectors and validates each
element independently against the five recognised level patterns.

Valid patterns (all uppercase):

- Level 1: `^[A-Z]$`

- Level 2: `^[A-Z][0-9]{2}$`

- Level 3: `^[A-Z][0-9]{2}[A-Z]$`

- Level 4: `^[A-Z][0-9]{2}[A-Z]{2}$`

- Level 5: `^[A-Z][0-9]{2}[A-Z]{2}[0-9]{2}$`

## Usage

``` r
is_valid_atc_code(x)

is_valid_atc(x)
```

## Arguments

- x:

  Character vector of potential ATC codes to validate.

## Value

Logical vector of the same length; `TRUE` for each element that matches
a valid ATC pattern, `FALSE` otherwise.

## See also

[`atc_level()`](https://vanhungtran.github.io/atcddd/reference/atc_level.md),
[`normalize_atc_code()`](https://vanhungtran.github.io/atcddd/reference/normalize_atc_code.md)

## Examples

``` r
is_valid_atc_code("N02BE01")              # TRUE
#> [1] TRUE
is_valid_atc_code(c("N02BE01", "C10AA05")) # TRUE TRUE
#> [1] TRUE TRUE
is_valid_atc_code(c("n02be01", "ZZZ"))     # FALSE FALSE
#> [1] FALSE FALSE
is_valid_atc_code(NA_character_)           # FALSE
#> [1] FALSE
```
