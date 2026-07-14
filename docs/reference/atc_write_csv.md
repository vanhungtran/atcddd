# Write ATC Codes and DDD Tables to CSV Files

Exports the results from
[`atc_crawl`](https://vanhungtran.github.io/atcddd/reference/atc_crawl.md)
to two separate CSV files: one for ATC codes and names, and one for DDD
(Defined Daily Dose) data. Files can optionally include a date stamp for
version tracking.

## Usage

``` r
atc_write_csv(x, dir = ".", stamp = TRUE)
```

## Arguments

- x:

  List; output from
  [`atc_crawl`](https://vanhungtran.github.io/atcddd/reference/atc_crawl.md)
  containing `codes` and `ddd` tibbles.

- dir:

  Character; output directory path (default: current directory).
  Directory will be created if it doesn't exist.

- stamp:

  Logical; whether to include date stamp in filenames (default: TRUE).
  Format: `_YYYY-MM-DD`.

## Value

Character vector of file paths (invisible). Use this for subsequent
operations like manifest generation.

## Output Files

- `WHO_ATC_codes[_YYYY-MM-DD].csv`: Contains atc_code and atc_name

- `WHO_ATC_DDD[_YYYY-MM-DD].csv`: Contains DDD specifications

## See also

[`atc_crawl`](https://vanhungtran.github.io/atcddd/reference/atc_crawl.md)
for data collection,
[`atc_write_manifest`](https://vanhungtran.github.io/atcddd/reference/atc_write_manifest.md)
for checksum generation

## Examples

``` r
if (FALSE) { # \dontrun{
# Basic usage
res <- atc_crawl(roots = "D", max_codes = 50)
paths <- atc_write_csv(res)

# Custom directory without date stamp
atc_write_csv(res, dir = "output/atc_data", stamp = FALSE)

# With manifest generation
paths <- atc_write_csv(res, dir = "data")
atc_write_manifest(paths)
} # }
```
