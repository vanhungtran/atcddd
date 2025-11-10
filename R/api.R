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
  
  # If no codes provided, use all main anatomical groups
  if (is.null(codes)) {
    codes <- atc_roots_default()
  }
  
  # Validate input codes
  invalid_codes <- codes[!sapply(codes, is_valid_atc_code)]
  if (length(invalid_codes) > 0) {
    message(sprintf(
      "Invalid ATC code format: %s. Codes must be uppercase alphanumeric (e.g., 'N02BE01').",
      paste(invalid_codes, collapse = ", ")
    ))
    return(NULL)
  }
  
  # Create fetch function with optional caching
  fetch_atc <- function(code, rate, depth) {
    tryCatch({
      # Use atc_crawl as the underlying engine
      # Note: atc_crawl doesn't have max_depth, it crawls the full tree
      # So we filter by depth after fetching
      result <- atc_crawl(
        roots = code,
        rate = rate,
        quiet = TRUE
      )
      
      if (is.null(result) || nrow(result) == 0) {
        message(sprintf("No data returned for ATC code: %s", code))
        return(NULL)
      }
      
      # Ensure consistent column structure
      result <- dplyr::as_tibble(result)
      
      # Add level information based on code length
      result <- dplyr::mutate(
        result,
        level = dplyr::case_when(
          nchar(.data$atc_code) == 1 ~ 1L,
          nchar(.data$atc_code) == 3 ~ 2L,
          nchar(.data$atc_code) == 4 ~ 3L,
          nchar(.data$atc_code) == 5 ~ 4L,
          nchar(.data$atc_code) == 7 ~ 5L,
          TRUE ~ NA_integer_
        )
      )
      
      # Filter by depth if not crawling full tree
      if (!is.infinite(depth) && depth == 1) {
        result <- dplyr::filter(result, .data$atc_code == code)
      }
      
      # Reorder columns for better readability
      col_order <- c("atc_code", "atc_name", "level", "ddd", "uom", "adm_r", "note")
      existing_cols <- intersect(col_order, names(result))
      result <- result[, existing_cols]
      
      # Sort by atc_code for consistent output
      result <- dplyr::arrange(result, .data$atc_code)
      
      return(result)
      
    }, error = function(e) {
      message(sprintf("Error fetching ATC code %s: %s", code, e$message))
      return(NULL)
    })
  }
  
  # Apply caching if requested
  if (use_cache) {
    fetch_atc <- memoise::memoise(
      fetch_atc,
      cache = atc_cache()
    )
  }
  
  # Determine crawl depth based on include_children
  max_depth <- if (include_children) Inf else 1
  
  # Fetch data for all requested codes
  results_list <- lapply(codes, function(code) {
    Sys.sleep(rate_limit)  # Rate limiting between codes
    fetch_atc(code, rate_limit, max_depth)
  })
  
  # Remove NULL results (failed fetches)
  results_list <- Filter(Negate(is.null), results_list)
  
  if (length(results_list) == 0) {
    message("No data could be retrieved for any of the requested codes.")
    return(NULL)
  }
  
  # Combine all results
  combined_result <- dplyr::bind_rows(results_list)
  
  # Remove duplicates (in case of overlapping hierarchies)
  combined_result <- dplyr::distinct(combined_result, .data$atc_code, .keep_all = TRUE)
  
  # Final sort
  combined_result <- dplyr::arrange(combined_result, .data$atc_code)
  
  return(combined_result)
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
  
  # Get data with all children
  data <- get_atc_data(
    codes = codes,
    include_children = TRUE,
    rate_limit = rate_limit
  )
  
  if (is.null(data)) {
    return(NULL)
  }
  
  # Filter by max_levels
  if (!is.infinite(max_levels)) {
    data <- dplyr::filter(data, .data$level <= max_levels)
  }
  
  # Add parent code information
  data <- dplyr::mutate(
    data,
    parent_code = dplyr::case_when(
      .data$level == 1 ~ NA_character_,
      .data$level == 2 ~ substr(.data$atc_code, 1, 1),
      .data$level == 3 ~ substr(.data$atc_code, 1, 3),
      .data$level == 4 ~ substr(.data$atc_code, 1, 4),
      .data$level == 5 ~ substr(.data$atc_code, 1, 5),
      TRUE ~ NA_character_
    )
  )
  
  # Determine which codes have children
  all_codes <- data$atc_code
  data <- dplyr::mutate(
    data,
    has_children = sapply(.data$atc_code, function(code) {
      any(grepl(paste0("^", code), all_codes) & all_codes != code)
    })
  )
  
  # Select and order columns
  data <- dplyr::select(
    data,
    .data$atc_code, .data$atc_name, .data$level, .data$parent_code, .data$has_children,
    dplyr::everything()
  )
  
  return(data)
}
