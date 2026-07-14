# Compute a Checksum Manifest for Output Files

Generates a data frame with file paths, sizes, and SHA256 checksums.
This provides cryptographic verification of file integrity and supports
reproducible research by documenting exact file contents.

## Usage

``` r
atc_manifest(paths)
```

## Arguments

- paths:

  Character vector of file paths to include in manifest. All paths must
  exist and be readable.

## Value

A tibble with columns:

- file:

  Character; normalized absolute file path

- size:

  Numeric; file size in bytes

- sha256:

  Character; SHA256 cryptographic hash

## Reproducibility

SHA256 checksums provide a unique fingerprint for each file. Even minor
changes to file contents will result in completely different checksums,
making this ideal for verifying data integrity and documenting exact
versions used in analyses.

## See also

[`atc_write_manifest`](https://vanhungtran.github.io/atcddd/reference/atc_write_manifest.md)
for saving manifest to CSV,
[`atc_write_csv`](https://vanhungtran.github.io/atcddd/reference/atc_write_csv.md)
for exporting data

## Examples

``` r
if (FALSE) { # \dontrun{
# Generate manifest for crawled data
res <- atc_crawl(roots = "D", max_codes = 50)
paths <- atc_write_csv(res, dir = "data")
manifest <- atc_manifest(paths)
print(manifest)

# Check file integrity later
current_manifest <- atc_manifest(paths)
identical(manifest, current_manifest)  # TRUE if files unchanged
} # }
```
