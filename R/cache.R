# atcddd: WHO ATC/DDD Crawler and Parser
# Version 0.1.0
# Copyright (C) 2025 Lucas VHH TRAN
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the MIT License.

# Caching and Configuration Utilities

#' @keywords internal
.atc_env <- new.env(parent = emptyenv())

#' @keywords internal
`%||%` <- function(x, y) if (is.null(x)) y else x

#' Get base URL for WHO ATC/DDD index
#' @keywords internal
#' @return Character; the base URL
atc_base_url <- function() "https://www.whocc.no/atc_ddd_index/?code="

#' Get user agent string for HTTP requests
#' @keywords internal
#' @return Character; user agent identification
atc_user_agent <- function() {
  "atcddd R package (+https://vanhungtran.github.io/atcddd; contact: tranhungydhcm@gmail.com)"
}

#' Get or create cache directory
#' @keywords internal
#' @return Character; path to cache directory
atc_cache_dir <- function() {
  dir <- rappdirs::user_cache_dir("atcddd")
  if (!dir.exists(dir)) {
    dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  }
  dir
}

#' Get or initialize filesystem cache
#' @keywords internal
#' @return A memoise cache object
atc_cache <- function() {
  cache <- .atc_env$cache
  if (is.null(cache)) {
    cache <- memoise::cache_filesystem(atc_cache_dir())
    .atc_env$cache <- cache
  }
  cache
}

#' Default ATC Root Codes
#'
#' @description
#' Returns the 14 main anatomical groups (Level 1) of the ATC classification system.
#' These represent the highest level categories for pharmaceutical classification.
#'
#' @return Character vector of single-letter codes: A through V (excluding E, F, I, K, O, Q, T, U, W, X, Y, Z)
#'
#' @section ATC Main Groups:
#' \itemize{
#'   \item \strong{A}: Alimentary tract and metabolism
#'   \item \strong{B}: Blood and blood forming organs
#'   \item \strong{C}: Cardiovascular system
#'   \item \strong{D}: Dermatologicals
#'   \item \strong{G}: Genito-urinary system and sex hormones
#'   \item \strong{H}: Systemic hormonal preparations
#'   \item \strong{J}: Antiinfectives for systemic use
#'   \item \strong{L}: Antineoplastic and immunomodulating agents
#'   \item \strong{M}: Musculo-skeletal system
#'   \item \strong{N}: Nervous system
#'   \item \strong{P}: Antiparasitic products
#'   \item \strong{R}: Respiratory system
#'   \item \strong{S}: Sensory organs
#'   \item \strong{V}: Various
#' }
#'
#' @examples
#' # Get all default root codes
#' atc_roots_default()
#'
#' # Crawl only cardiovascular and nervous system
#' \dontrun{
#' res <- atc_crawl(roots = c("C", "N"))
#' }
#'
#' @export
atc_roots_default <- function() {
  c("A", "B", "C", "D", "G", "H", "J", "L", "M", "N", "P", "R", "S", "V")
}

#' Validate ATC Code Format
#'
#' @description
#' Checks if a string is a valid ATC code format (uppercase alphanumeric).
#'
#' @param x Character; a potential ATC code
#' @return Logical; TRUE if valid, FALSE otherwise
#'
#' @keywords internal
is_valid_atc_code <- function(x) {
  is.character(x) && length(x) == 1L && grepl("^[A-Z0-9]+$", x)
}

