# atcddd: WHO ATC/DDD Crawler and Parser
# Version 0.1.0
# Copyright (C) 2025 Lucas VHH TRAN
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the MIT License.

# Input/Output Functions

#' Write ATC Codes and DDD Tables to CSV Files
#'
#' @description
#' Exports the results from \code{\link{atc_crawl}} to two separate CSV files:
#' one for ATC codes and names, and one for DDD (Defined Daily Dose) data.
#' Files can optionally include a date stamp for version tracking.
#'
#' @param x List; output from \code{\link{atc_crawl}} containing \code{codes}
#'   and \code{ddd} tibbles.
#' @param dir Character; output directory path (default: current directory).
#'   Directory will be created if it doesn't exist.
#' @param stamp Logical; whether to include date stamp in filenames
#'   (default: TRUE). Format: \code{_YYYY-MM-DD}.
#'
#' @return Character vector of file paths (invisible). Use this for
#'   subsequent operations like manifest generation.
#'
#' @section Output Files:
#' \itemize{
#'   \item \code{WHO_ATC_codes[_YYYY-MM-DD].csv}: Contains atc_code and atc_name
#'   \item \code{WHO_ATC_DDD[_YYYY-MM-DD].csv}: Contains DDD specifications
#' }
#'
#' @examples
#' \dontrun{
#' # Basic usage
#' res <- atc_crawl(roots = "D", max_codes = 50)
#' paths <- atc_write_csv(res)
#'
#' # Custom directory without date stamp
#' atc_write_csv(res, dir = "output/atc_data", stamp = FALSE)
#'
#' # With manifest generation
#' paths <- atc_write_csv(res, dir = "data")
#' atc_write_manifest(paths)
#' }
#'
#' @seealso
#' \code{\link{atc_crawl}} for data collection,
#' \code{\link{atc_write_manifest}} for checksum generation
#'
#' @export
atc_write_csv <- function(x, dir = ".", stamp = TRUE) {
  # Input validation
  if (!is.list(x)) {
    stop("x must be a list (output from atc_crawl)", call. = FALSE)
  }
  if (!all(c("codes", "ddd") %in% names(x))) {
    stop("x must contain 'codes' and 'ddd' components", call. = FALSE)
  }
  if (!is.character(dir) || length(dir) != 1L) {
    stop("dir must be a single character string", call. = FALSE)
  }
  if (!is.logical(stamp) || length(stamp) != 1L) {
    stop("stamp must be a single logical value", call. = FALSE)
  }
  
  # Create directory if needed
  if (!dir.exists(dir)) {
    dir.create(dir, recursive = TRUE, showWarnings = FALSE)
    cli::cli_inform("Created directory: {.path {dir}}")
  }
  
  # Generate filenames
  date_suffix <- if (stamp) paste0("_", format(Sys.Date(), "%Y-%m-%d")) else ""
  f_codes <- file.path(dir, paste0("WHO_ATC_codes", date_suffix, ".csv"))
  f_ddd   <- file.path(dir, paste0("WHO_ATC_DDD", date_suffix, ".csv"))
  
  # Write files
  cli::cli_inform("Writing {.file {basename(f_codes)}} ({nrow(x$codes)} rows)")
  cli::cli_inform("Writing {.file {basename(f_ddd)}} ({nrow(x$ddd)} rows)")
  
  readr::write_csv(x$codes, f_codes)
  readr::write_csv(x$ddd, f_ddd)
  
  cli::cli_alert_success("Successfully wrote {length(c(f_codes, f_ddd))} files to {.path {dir}}")
  
  invisible(c(f_codes, f_ddd))
}

