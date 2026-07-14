# Classify a unit into a conversion family

Classify a unit into a conversion family

## Usage

``` r
.ddd_unit_family(unit)
```

## Arguments

- unit:

  Character unit string (e.g. `"mg"`, `"MU"`).

## Value

Character string naming the family (`"mass"`, `"unit"`, `"volume"`,
`"mmol"`, `"lsu"`, `"tablet"`) or `NA_character_` if unrecognised.
