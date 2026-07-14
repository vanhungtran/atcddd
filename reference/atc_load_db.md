# Load the bundled WHO ATC database into memory

Loads the bundled WHO ATC/DDD CSV files into an in-memory cache, making
subsequent
[`search_drug()`](https://vanhungtran.github.io/atcddd/reference/search_drug.md),
[`fuzzy_match_drug()`](https://vanhungtran.github.io/atcddd/reference/fuzzy_match_drug.md),
and
[`resolve_atc()`](https://vanhungtran.github.io/atcddd/reference/resolve_atc.md)
calls fast and offline-capable.

Call this once at the start of your session (or let search functions
call it automatically on first use). Set `refresh = TRUE` to force a
reload.

## Usage

``` r
atc_load_db(refresh = FALSE)
```

## Arguments

- refresh:

  Logical; if `TRUE`, reloads the database even if already cached.
  Default is `FALSE`.

## Value

Invisibly returns a list with `codes` and `ddd` tibbles.

## See also

[`search_drug()`](https://vanhungtran.github.io/atcddd/reference/search_drug.md),
[`fuzzy_match_drug()`](https://vanhungtran.github.io/atcddd/reference/fuzzy_match_drug.md),
[`resolve_atc()`](https://vanhungtran.github.io/atcddd/reference/resolve_atc.md)

## Examples

``` r
atc_load_db()

# Force reload
atc_load_db(refresh = TRUE)
```
