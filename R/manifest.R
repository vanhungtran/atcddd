# atcddd: WHO ATC/DDD Crawler and Parser
# Version 0.1.0
# Copyright (C) 2025 Lucas VHH TRAN
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the MIT License.

# Manifest and Checksum Functions

#' Compute a Checksum Manifest for Output Files
#'
#' @description
#' Generates a data frame with file paths, sizes, and SHA256 checksums.
#' This provides cryptographic verification of file integrity and supports
#' reproducible research by documenting exact file contents.
#'
#' @param paths Character vector of file paths to include in manifest.
#'   All paths must exist and be readable.
#'
#' @return A tibble with columns:
#' \describe{
#'   \item{file}{Character; normalized absolute file path}
#'   \item{size}{Numeric; file size in bytes}
#'   \item{sha256}{Character; SHA256 cryptographic hash}
#' }
#'
#' @section Reproducibility:
#' SHA256 checksums provide a unique fingerprint for each file. Even minor
#' changes to file contents will result in completely different checksums,
#' making this ideal for verifying data integrity and documenting exact
#' versions used in analyses.
#'
#' @examples
#' \dontrun{
#' # Generate manifest for crawled data
#' res <- atc_crawl(roots = "D", max_codes = 50)
#' paths <- atc_write_csv(res, dir = "data")
#' manifest <- atc_manifest(paths)
#' print(manifest)
#'
#' # Check file integrity later
#' current_manifest <- atc_manifest(paths)
#' identical(manifest, current_manifest)  # TRUE if files unchanged
#' }
#'
#' @seealso
#' \code{\link{atc_write_manifest}} for saving manifest to CSV,
#' \code{\link{atc_write_csv}} for exporting data
#'
#' @export
atc_manifest <- function(paths) {
  # Input validation
  if (!is.character(paths) || length(paths) == 0L) {
    stop("paths must be a non-empty character vector", call. = FALSE)
  }
  
  missing_files <- paths[!file.exists(paths)]
  if (length(missing_files) > 0L) {
    stop(sprintf(
      "The following files do not exist:\n  %s",
      paste(missing_files, collapse = "\n  ")
    ), call. = FALSE)
  }
  
  # Generate manifest
  cli::cli_inform("Computing checksums for {length(paths)} file{?s}...")
  
  tibble::tibble(
    file = normalizePath(paths, winslash = "/", mustWork = TRUE),
    size = file.info(paths)$size,
    sha256 = vapply(paths, function(p) {
      digest::digest(file = p, algo = "sha256")
    }, character(1), USE.NAMES = FALSE)
  )
}

#' Write a Checksum Manifest CSV File
#'
#' @description
#' Creates a CSV file documenting file paths, sizes, and SHA256 checksums
#' for a set of output files. This supports reproducible research and
#' data verification workflows.
#'
#' @param paths Character vector of file paths to include in manifest.
#' @param manifest_path Character; optional output path for manifest file.
#'   Default: \code{MANIFEST.csv} in the same directory as the first path.
#'
#' @return Character; path to manifest file (invisible).
#'
#' @examples
#' \dontrun{
#' # Standard workflow
#' res <- atc_crawl(roots = c("A", "B"))
#' paths <- atc_write_csv(res, dir = "data/2025-01-09")
#' atc_write_manifest(paths)
#'
#' # Custom manifest location
#' atc_write_manifest(paths, manifest_path = "data/checksums.csv")
#' }
#'
#' @seealso
#' \code{\link{atc_manifest}} for generating manifest data,
#' \code{\link{atc_write_csv}} for data export
#'
#' @export
atc_write_manifest <- function(paths, manifest_path = NULL) {
  # Generate manifest
  man <- atc_manifest(paths)
  
  # Determine output path
  if (is.null(manifest_path)) {
    out <- file.path(dirname(paths[[1]]), "MANIFEST.csv")
  } else {
    if (!is.character(manifest_path) || length(manifest_path) != 1L) {
      stop("manifest_path must be a single character string", call. = FALSE)
    }
    out <- manifest_path
  }
  
  # Write manifest
  readr::write_csv(man, out)
  cli::cli_alert_success("Wrote manifest: {.path {out}}")
  
  invisible(out)
}

