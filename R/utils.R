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

#' Normalize an ATC code to canonical form
#'
#' @description
#' Trims whitespace and converts to uppercase. This is the canonicalisation
#' step applied internally before validation, level detection, and parent
#' derivation.
#'
#' @param x Character vector of ATC codes.
#' @return Character vector of trimmed, uppercase codes.
#'
#' @examples
#' normalize_atc_code(" n02be01 ")
#' normalize_atc_code(c("n02BE01", "C10aa05"))
#'
#' @seealso [is_valid_atc_code()], [atc_level()]
#' @export
normalize_atc_code <- function(x) {
  toupper(stringr::str_trim(x))
}

#' Determine the ATC hierarchy level of a code
#'
#' @description
#' Returns the hierarchy level (1–5) for each ATC code based on its
#' character pattern. The five levels of the WHO ATC classification are:
#'
#' \itemize{
#'   \item Level 1 — Anatomical main group (1 letter, e.g. `"N"`)
#'   \item Level 2 — Therapeutic subgroup (1 letter + 2 digits, e.g. `"N02"`)
#'   \item Level 3 — Pharmacological subgroup (4 chars, e.g. `"N02B"`)
#'   \item Level 4 — Chemical subgroup (5 chars, e.g. `"N02BE"`)
#'   \item Level 5 — Chemical substance (7 chars, e.g. `"N02BE01"`)
#' }
#'
#' @param code Character vector of ATC codes.
#' @return Integer vector of the same length, with values 1–5, or `NA` for
#'   codes that do not match any recognised ATC pattern.
#'
#' @examples
#' atc_level("N")          # 1
#' atc_level("N02")        # 2
#' atc_level("N02BE01")    # 5
#' atc_level(c("C", "C10", "C10AA", "C10AA05"))
#' atc_level("garbage")    # NA
#'
#' @seealso [atc_parent()], [is_valid_atc_code()]
#' @export
atc_level <- function(code) {
  code <- normalize_atc_code(code)
  lvl <- rep(NA_integer_, length(code))
  lvl[grepl("^[A-Z]$", code)] <- 1L
  lvl[grepl("^[A-Z][0-9]{2}$", code)] <- 2L
  lvl[grepl("^[A-Z][0-9]{2}[A-Z]$", code)] <- 3L
  lvl[grepl("^[A-Z][0-9]{2}[A-Z]{2}$", code)] <- 4L
  lvl[grepl("^[A-Z][0-9]{2}[A-Z]{2}[0-9]{2}$", code)] <- 5L
  lvl
}

#' Get the parent ATC code one level up in the hierarchy
#'
#' @description
#' Given an ATC code, returns the code of its immediate parent in the
#' five-level hierarchy. Level-1 codes (single letters) have no parent.
#'
#' @param code Character vector of ATC codes.
#' @return Character vector of parent codes. Returns `NA` for Level-1 codes
#'   and for codes that do not match a recognised ATC pattern.
#'
#' @examples
#' atc_parent("N02BE01")   # "N02BE"
#' atc_parent("N02BE")     # "N02B"
#' atc_parent("N02B")      # "N02"
#' atc_parent("N02")       # "N"
#' atc_parent("N")         # NA (Level 1 has no parent)
#'
#' @seealso [atc_level()], [atc_children()]
#' @export
atc_parent <- function(code) {
  code <- normalize_atc_code(code)
  lvl <- atc_level(code)
  out <- rep(NA_character_, length(code))
  out[lvl == 2L] <- substr(code[lvl == 2L], 1, 1)
  out[lvl == 3L] <- substr(code[lvl == 3L], 1, 3)
  out[lvl == 4L] <- substr(code[lvl == 4L], 1, 4)
  out[lvl == 5L] <- substr(code[lvl == 5L], 1, 5)
  out
}
