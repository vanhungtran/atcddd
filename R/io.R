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

#' Download the WHO ATC/DDD Index to Your Local Cache
#'
#' @description
#' Retrieves the current ATC/DDD Index from the WHO Collaborating Centre,
#' stores it in your local user-cache directory, and loads it into memory
#' for offline use. This is the **required first step** before using
#' [search_drug()], [fuzzy_match_drug()], [resolve_atc()], or
#' [compute_ddd()] — the package ships with no data; you must explicitly
#' download it.
#'
#' Downloaded data are stored as CSV files in the directory returned by
#' \code{rappdirs::user_cache_dir("atcddd")} and are reused across
#' sessions. Call \code{atc_download(refresh = TRUE)} to fetch a fresh
#' copy when the WHO site publishes an update (typically twice yearly).
#'
#' @param roots Character vector of root ATC codes to start crawling from.
#'   Default: all 14 main anatomical groups.
#' @param rate Numeric; minimum seconds between HTTP requests (default: 0.5).
#' @param refresh Logical; if \code{TRUE}, re-download even if cached data
#'   already exist. Default is \code{FALSE}.
#' @param quiet Logical; suppress progress messages (default: \code{FALSE}).
#' @param ... Additional arguments passed to [atc_crawl()].
#'
#' @return Invisibly returns a list with \code{codes} and \code{ddd} tibbles.
#'   As a side effect, CSV files are written to the user cache and the
#'   in-memory search database is populated.
#'
#' @section Data Copyright:
#' **Data source:** ATC/DDD Index, © WHO Collaborating Centre for Drug
#' Statistics Methodology. Available from \url{https://atcddd.fhi.no/}
#' subject to the provider's terms of use. Downloaded data retain the
#' original copyright and terms of the WHO Collaborating Centre. See
#' \url{https://www.whocc.no/use_of_atc_ddd/} for details.
#'
#' @examples
#' \dontrun{
#' # First-time setup — download the full WHO ATC/DDD Index
#' atc_download()
#'
#' # Download a single anatomical group for quicker testing
#' atc_download(roots = "D")
#'
#' # Refresh your local copy (e.g. after a WHO update)
#' atc_download(refresh = TRUE)
#' }
#'
#' @export
atc_download <- function(roots = atc_roots_default(),
                         rate = 0.5,
                         refresh = FALSE,
                         quiet = FALSE,
                         ...) {
  cache_dir <- atc_cache_dir()
  f_codes   <- file.path(cache_dir, "WHO_ATC_codes.csv")
  f_ddd     <- file.path(cache_dir, "WHO_ATC_DDD.csv")

  if (!isTRUE(refresh) && file.exists(f_codes) && file.exists(f_ddd)) {
    if (!quiet) {
      cli::cli_inform(c(
        "i" = "ATC/DDD data already cached in {.path {cache_dir}}.",
        "i" = "Use {.code atc_download(refresh = TRUE)} to re-download."
      ))
    }
    db <- atc_load_db()
    return(invisible(db))
  }

  if (!quiet) {
    cli::cli_inform(c(
      "v" = "Downloading WHO ATC/DDD Index to {.path {cache_dir}}.",
      "i" = "This may take a few minutes for all 14 anatomical groups."
    ))
  }

  res <- atc_crawl(roots = roots, rate = rate, quiet = quiet, ...)

  # Persist to cache
  readr::write_csv(res$codes, f_codes)
  readr::write_csv(res$ddd,   f_ddd)

  # Load into in-memory search database
  .load_db_from_cache(cache_dir)

  if (!quiet) {
    cli::cli_alert_success(paste(
      "Downloaded {nrow(res$codes)} ATC codes and",
      "{nrow(res$ddd)} DDD entries."
    ))
  }

  invisible(res)
}

