# atcddd: WHO ATC/DDD Crawler and Parser
# Version 0.1.0
# Copyright (C) 2025 Lucas VHH TRAN
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the MIT License.

# Utility Functions and Global Variable Declarations

# Suppress R CMD check notes for NSE (Non-Standard Evaluation) variables
# These variables are used in dplyr/tidyr contexts
utils::globalVariables(c(
  # Variables used in crawl.R
  "atc_code",
  "atc_name",
  "ddd",
  "uom",
  "adm_r",
  "note",
  "source_code",
  
  # Variables used in api.R
  "level",
  "parent_code",
  "has_children",
  
  # Variables used in parse.R and other modules
  ".data"
))

#' @keywords internal
is_scalar_character <- function(x) {
  is.character(x) && length(x) == 1L && !is.na(x)
}

#' @keywords internal
is_valid_url <- function(x) {
  is_scalar_character(x) && grepl("^https?://", x)
}

#' @keywords internal
assert_positive_numeric <- function(x, name = deparse(substitute(x))) {
  if (!is.numeric(x) || length(x) != 1L || is.na(x) || x <= 0) {
    stop(sprintf("%s must be a positive numeric value", name), call. = FALSE)
  }
  invisible(TRUE)
}

#' @keywords internal
assert_character_vector <- function(x, name = deparse(substitute(x))) {
  if (!is.character(x) || length(x) == 0L) {
    stop(sprintf("%s must be a non-empty character vector", name), call. = FALSE)
  }
  invisible(TRUE)
}

#' @keywords internal
normalize_atc_code <- function(x) {
  toupper(stringr::str_trim(x))
}
