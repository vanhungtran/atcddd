# atcddd: WHO ATC/DDD Crawler and Parser
# Version 0.1.0
# Copyright (C) 2025 Lucas VHH TRAN
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the MIT License.

# API Functions for WHO ATC/DDD Data

#' Get ATC Classification Data from WHO Database
#'
#' @description
#' Retrieves ATC (Anatomical Therapeutic Chemical) classification data
#' for a specific code or codes from the WHO Collaborating Centre for
#' Drug Statistics Methodology database.
#'
#' This function provides structured access to the ATC hierarchy and DDD
#' (Defined Daily Dose) information through a clean API-style interface.
#'
#' @param codes Character vector; one or more ATC codes to retrieve.
#'   Can be Level 1 (e.g., "N"), Level 2 (e.g., "N02"), Level 3 (e.g., "N02B"),
#'   Level 4 (e.g., "N02BE"), or Level 5 (e.g., "N02BE01").
#'   If NULL, returns data for all 14 main anatomical groups.
#' @param include_children Logical; if TRUE, also retrieves all child codes
#'   in the hierarchy below the specified codes. Default is FALSE.
#' @param rate_limit Numeric; minimum delay in seconds between requests
#'   to respect WHO server load. Default is 0.5 seconds.
#' @param use_cache Logical; if TRUE, uses filesystem caching to avoid
#'   redundant requests. Default is TRUE.
#'
#' @return A tibble with the following columns:
#' \itemize{
#'   \item \code{atc_code}: The ATC code (e.g., "N02BE01")
#'   \item \code{atc_name}: Name/description of the substance or group
#'   \item \code{level}: Hierarchy level (1-5)
#'   \item \code{ddd}: Defined Daily Dose value (if available)
#'   \item \code{uom}: Unit of measurement for DDD (e.g., "g", "mg")
#'   \item \code{adm_r}: Route of administration (e.g., "O" for oral, "P" for parenteral)
#'   \item \code{note}: Additional notes or comments
#' }
#'
#' @details
#' This function provides a cleaner, API-style interface to the WHO ATC/DDD
#' database compared to the lower-level \code{\link{atc_crawl}} function.
#' It automatically handles:
#' \itemize{
#'   \item Input validation for ATC code format
#'   \item Rate limiting to respect WHO server policies
#'   \item Caching via \pkg{memoise} to minimize redundant requests
#'   \item Error handling with informative messages
#'   \item Consistent tibble output format
#' }
#'
#' Returns \code{NULL} with a message if:
#' \itemize{
#'   \item Invalid ATC codes are provided
#'   \item Network connection fails
#'   \item No data is available for the requested codes
#' }
#'
#' @note
#' Requires an internet connection to access the WHO database.
#' First-time requests may be slower due to network latency;
#' subsequent requests use cached data when \code{use_cache = TRUE}.
#'
#' @section Rate Limiting:
#' To be respectful of WHO server resources, this function enforces
#' a minimum delay between requests. The default is 0.5 seconds,
#' which translates to a maximum of 2 requests per second.
#'
#' @source WHO Collaborating Centre for Drug Statistics Methodology:
#' \url{https://www.whocc.no/atc_ddd_index/}
#'
#' @examples
#' \donttest{
#' # Get data for a specific drug (aspirin)
#' get_atc_data("N02BA01")
#'
#' # Get data for all analgesics (Level 2)
#' get_atc_data("N02")
#'
#' # Get cardiovascular and nervous system main groups
#' get_atc_data(c("C", "N"))
#'
#' # Get all child codes under opioids
#' get_atc_data("N02A", include_children = TRUE)
#'
#' # Get all main anatomical groups
#' get_atc_data()
#' }
#'
#' @seealso
#' \code{\link{atc_crawl}} for lower-level crawling functionality,
#' \code{\link{atc_roots_default}} for main anatomical groups,
#' \code{\link{is_valid_atc_code}} for code validation
#'
#' @importFrom dplyr as_tibble bind_rows filter mutate arrange
#' @importFrom memoise memoise
#'
#' @export
get_atc_data <- function(codes = NULL,
                         include_children = FALSE,
                         rate_limit = 0.5,
                         use_cache = TRUE) {

  # Default to all main anatomical groups
  if (is.null(codes)) {
    codes <- atc_roots_default()
  }
  codes <- normalize_atc_code(unique(codes))

  # Validate input codes
  invalid_codes <- codes[!vapply(codes, is_valid_atc_code, logical(1))]
  if (length(invalid_codes) > 0) {
    message(sprintf(
      "Invalid ATC code format: %s. Expect patterns like 'N', 'N02', 'N02B', 'N02BE', 'N02BE01'.",
      paste(invalid_codes, collapse = ", ")
    ))
    return(NULL)
  }

  # Optionally enable memoised HTTP cache
  if (isTRUE(use_cache)) {
    # http layer already memoises; nothing additional needed here
    invisible(NULL)
  }

  # Crawl once for all requested roots
  res <- tryCatch({
    atc_crawl(roots = codes, rate = rate_limit, progress = FALSE, quiet = TRUE)
  }, error = function(e) {
    message(sprintf("Error fetching ATC data: %s", e$message))
    NULL
  })
  if (is.null(res)) return(NULL)

  codes_tbl <- dplyr::as_tibble(res$codes)
  ddd_tbl   <- dplyr::as_tibble(res$ddd)

  # Limit to specified nodes only when include_children = FALSE
  if (!isTRUE(include_children)) {
    codes_tbl <- dplyr::filter(codes_tbl, .data$atc_code %in% codes)
  }

  # Attach level and join DDD for Level 5 (by code only)
  codes_tbl <- dplyr::mutate(codes_tbl, level = atc_level(.data$atc_code))
  if (nrow(ddd_tbl)) {
    ddd_min <- dplyr::select(ddd_tbl, -dplyr::any_of("source_code"))
    out <- dplyr::left_join(codes_tbl, ddd_min, by = "atc_code")
  } else {
    out <- codes_tbl
  }

  # Reorder and sort
  col_order <- c("atc_code", "atc_name", "level", "ddd", "uom", "adm_r", "note")
  keep <- intersect(col_order, names(out))
  out <- out[, keep]
  out <- dplyr::arrange(out, .data$atc_code)

  if (!nrow(out)) {
    message("No data available for the requested codes.")
    return(NULL)
  }

  out
}


#' Get ATC Hierarchy Tree
#'
#' @description
#' Retrieves the complete hierarchical structure for specified ATC codes,
#' including all parent and child relationships. Useful for understanding
#' the classification structure and building tree visualizations.
#'
#' @param codes Character vector; one or more ATC codes to build tree from.
#'   If NULL, builds tree for all main anatomical groups (may be slow).
#' @param max_levels Integer; maximum depth to traverse. Default is 5 (complete hierarchy).
#' @param rate_limit Numeric; minimum delay in seconds between requests. Default is 0.5.
#'
#' @return A tibble with hierarchical structure including:
#' \itemize{
#'   \item \code{atc_code}: The ATC code
#'   \item \code{atc_name}: Name/description
#'   \item \code{level}: Hierarchy level (1-5)
#'   \item \code{parent_code}: Parent code in hierarchy (NA for Level 1)
#'   \item \code{has_children}: Logical indicating if code has sub-classifications
#' }
#'
#' @examples
#' \donttest{
#' # Get hierarchy tree for opioids
#' get_atc_hierarchy("N02A")
#'
#' # Get complete nervous system tree (may take time)
#' get_atc_hierarchy("N", max_levels = 5)
#' }
#'
#' @export
get_atc_hierarchy <- function(codes = NULL,
                               max_levels = 5,
                               rate_limit = 0.5) {

  data <- get_atc_data(
    codes = codes,
    include_children = TRUE,
    rate_limit = rate_limit
  )
  if (is.null(data)) return(NULL)

  # Ensure level present
  if (!"level" %in% names(data)) {
    data <- dplyr::mutate(data, level = atc_level(.data$atc_code))
  }

  # Filter by max_levels
  if (!is.infinite(max_levels)) {
    data <- dplyr::filter(data, .data$level <= max_levels)
  }

  # Parent and has_children
  data <- dplyr::mutate(data, parent_code = atc_parent(.data$atc_code))
  all_codes <- data$atc_code
  data <- dplyr::mutate(
    data,
    has_children = vapply(
      .data$atc_code,
      function(code) any(grepl(paste0("^", code), all_codes) & all_codes != code),
      logical(1)
    )
  )

  dplyr::select(
    data,
    dplyr::any_of(c("atc_code", "atc_name", "level", "parent_code", "has_children")),
    dplyr::everything()
  )
}
