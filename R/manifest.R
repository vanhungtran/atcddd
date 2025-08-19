#' Compute a checksum manifest for outputs
#'
#' Generates a data frame with file paths, sizes, and SHA256 checksums.
#' @param paths character vector of file paths
#' @return tibble with columns: file, size, sha256
#' @export
atc_manifest <- function(paths) {
  stopifnot(is.character(paths), length(paths) > 0, all(file.exists(paths)))
  tibble::tibble(
    file = normalizePath(paths, winslash = "/", mustWork = TRUE),
    size = file.info(paths)$size,
    sha256 = vapply(paths, function(p) digest::digest(file = p, algo = "sha256"), character(1))
  )
}

#' Write a checksum manifest next to outputs
#' @param paths vector of file paths
#' @param manifest_path optional output path (default: MANIFEST.csv in same dir as first path)
#' @export
atc_write_manifest <- function(paths, manifest_path = NULL) {
  man <- atc_manifest(paths)
  out <- manifest_path %||% file.path(dirname(paths[[1]]), "MANIFEST.csv")
  readr::write_csv(man, out)
  cli::cli_inform(sprintf("Wrote manifest: %s", out))
  invisible(out)
}

