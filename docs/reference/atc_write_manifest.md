# Write a Checksum Manifest CSV File

Creates a CSV file documenting file paths, sizes, and SHA256 checksums
for a set of output files. This supports reproducible research and data
verification workflows.

## Usage

``` r
atc_write_manifest(paths, manifest_path = NULL)
```

## Arguments

- paths:

  Character vector of file paths to include in manifest.

- manifest_path:

  Character; optional output path for manifest file. Default:
  `MANIFEST.csv` in the same directory as the first path.

## Value

Character; path to manifest file (invisible).

## See also

[`atc_manifest`](https://vanhungtran.github.io/atcddd/reference/atc_manifest.md)
for generating manifest data,
[`atc_write_csv`](https://vanhungtran.github.io/atcddd/reference/atc_write_csv.md)
for data export

## Examples

``` r
if (FALSE) { # \dontrun{
# Standard workflow
res <- atc_crawl(roots = c("A", "B"))
paths <- atc_write_csv(res, dir = "data/2025-01-09")
atc_write_manifest(paths)

# Custom manifest location
atc_write_manifest(paths, manifest_path = "data/checksums.csv")
} # }
```
