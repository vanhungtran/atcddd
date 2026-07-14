# Add a drug name synonym to the lookup table

Registers a common name, brand name, or abbreviation as a synonym for a
WHO ATC code. Synonyms are checked before fuzzy matching in
[`search_drug()`](https://vanhungtran.github.io/atcddd/reference/search_drug.md)
and
[`resolve_atc()`](https://vanhungtran.github.io/atcddd/reference/resolve_atc.md),
making them the fastest path from a clinical drug name to an ATC code.

Use this to build up your own synonym dictionary for drugs frequently
encountered in your data.

## Usage

``` r
atc_add_synonym(synonym, atc_code, atc_name)
```

## Arguments

- synonym:

  Character scalar; the common name or alias (e.g. `"aspirin"`,
  `"tylenol"`).

- atc_code:

  Character scalar; the WHO ATC code the synonym maps to (e.g.
  `"N02BA01"`).

- atc_name:

  Character scalar; the WHO official name for the code (e.g.
  `"acetylsalicylic acid"`).

## Value

Invisibly returns the updated synonym table.

## See also

[`search_drug()`](https://vanhungtran.github.io/atcddd/reference/search_drug.md),
[`resolve_atc()`](https://vanhungtran.github.io/atcddd/reference/resolve_atc.md)

## Examples

``` r
atc_add_synonym("advil", "M01AE01", "ibuprofen")
atc_add_synonym("lasix", "C03CA01", "furosemide")
```
