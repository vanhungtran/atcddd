# atcddd: WHO ATC/DDD Crawler and Parser
# Version 0.3.0
# Copyright (C) 2025 Lucas VHH TRAN
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the MIT License.

# Common-Name Regex Lexicon — brand, generic, and abbreviation mapping

#' Preprocess a Drug Name for Matching
#'
#' Strips dose, strength, route, and formulation information from drug name
#' strings, leaving only the active ingredient or brand name core. This
#' dramatically improves match rates against WHO nomenclature.
#'
#' @param x Character vector of drug name strings.
#' @return Character vector of cleaned drug name cores.
#'
#' @examples
#' preprocess_drug_name("aspirin 500mg tablet")      # "aspirin"
#' preprocess_drug_name("metformin 1000mg")           # "metformin"
#' preprocess_drug_name("betamethasone valerate 0.1% cream")  # "betamethasone valerate"
#' preprocess_drug_name("dupilumab 300mg/2mL injection")       # "dupilumab"
#'
#' @export
preprocess_drug_name <- function(x) {
  x <- tolower(stringr::str_squish(x))

  # Replace (don't remove) — uses space to preserve word boundaries
  # Strength-with-slash: "300mg/2mL"
  x <- stringr::str_replace_all(x,
    "\\d+(\\.\\d+)?\\s*(mg|mcg|ug|g|ml|l|U|IU|mmol|mEq)\\s*/\\s*\\d+(\\.\\d+)?\\s*(ml|mL|g|mg|mcg|dose|kg|day|hr)", " ")
  # Standalone strength: "500mg", "100 mcg", "1%"
  x <- stringr::str_replace_all(x,
    "\\b\\d+(\\.\\d+)?\\s*(mg|mcg|ug|g|ml|%|U|IU|mmol|mEq)\\b", " ")
  # Standalone numbers
  x <- stringr::str_replace_all(x, "\\b\\d+(\\.\\d+)?\\b", " ")
  # Stray % signs
  x <- stringr::str_replace_all(x, "%", " ")
  # Formulation descriptors
  x <- stringr::str_replace_all(x,
    "\\b(tablets|tablet|capsules|capsule|cream|ointment|gel|foam|lotion|shampoo|injection|injectable|inhaler|inhalation|solution|suspension|syrup|elixir|drops|spray|powder|suppository|patch|implant|device|kit|pack|vial|ampule|prefilled|syringe|pen|cartridge)\\b", " ")
  # Route descriptors
  x <- stringr::str_replace_all(x,
    "\\b(oral|topical|ophthalmic|otic|nasal|inhaled|intravenous|intramuscular|subcutaneous|sublingual|buccal|transdermal|rectal|vaginal|parenteral|IV|IM|SC|SL|PO|PR|PV)\\b", " ")
  # Frequency
  x <- stringr::str_replace_all(x,
    "\\b(once daily|twice daily|three times daily|four times daily|as needed|PRN|BID|TID|QID|QD|QHS|QAM|QPM|Q4H|Q6H|Q8H|Q12H|weekly|monthly)\\b", " ")
  # Parentheticals
  x <- stringr::str_replace_all(x, "\\([^)]*\\)", " ")
  # Separators
  x <- stringr::str_replace_all(x, "[+;/]", " ")

  # Collapse
  x <- stringr::str_squish(x)
  x[x == ""] <- NA_character_
  x
}

#' Load the Common-Name Regex Lexicon
#'
#' Loads a curated table of regex patterns mapping common drug names,
#' brand names, and abbreviations to ATC codes. This lexicon is bundled
#' with the package and provides immediate matching for ~100 commonly
#' prescribed drugs without requiring WHO name alignment.
#'
#' The lexicon is shipped as \code{inst/extdata/atc_common_names.csv}.
#' Users can extend it via \code{atc_add_synonym()} for session-level
#' additions or by contributing new patterns.
#'
#' @param refresh Logical; if \code{TRUE}, reloads the lexicon even if
#'   already cached. Default is \code{FALSE}.
#'
#' @return Invisibly returns a tibble with columns \code{pattern},
#'   \code{atc_code}, \code{active_ingredient}, and \code{category}.
#'
#' @section Data Copyright:
#' The common-name patterns are hand-curated from public-domain drug
#' databases and are covered by the package's MIT License. ATC codes
#' referenced are factual data points, not distributed WHO datasets.
#'
#' @examples
#' atc_load_common_names()
#'
#' @seealso [atc_load_db()], [search_drug()], [resolve_atc()]
#' @export
atc_load_common_names <- function(refresh = FALSE) {
  if (!isTRUE(refresh) && !is.null(.atc_search_env$common_names)) {
    return(invisible(.atc_search_env$common_names))
  }

  path <- system.file("extdata", "atc_common_names.csv", package = "atcddd")

  if (!file.exists(path)) {
    cli::cli_warn(c(
      "!" = "Common-name lexicon not found at {.path {path}}.",
      "i" = "Reinstall the package or place atc_common_names.csv in inst/extdata/."
    ))
    .atc_search_env$common_names <- tibble::tibble(
      pattern = character(), atc_code = character(),
      active_ingredient = character(), category = character()
    )
    return(invisible(.atc_search_env$common_names))
  }

  cn <- readr::read_csv(path, show_col_types = FALSE, progress = FALSE)

  # Validate ATC codes
  valid <- is_valid_atc_code(cn$atc_code)
  if (!all(valid)) {
    cli::cli_warn(c(
      "!" = "{sum(!valid)} invalid ATC code(s) in common_names.csv",
      "i" = "Codes: {.val {cn$atc_code[!valid]}}"
    ))
    cn <- cn[valid, ]
  }

  .atc_search_env$common_names <- cn
  invisible(cn)
}

#' Search the Common-Name Regex Lexicon
#'
#' Matches a preprocessed drug name against the bundled common-name regex
#' lexicon. This is a fast, offline lookup that runs before WHO-name search
#' in the resolution pipeline.
#'
#' @param query Character scalar; preprocessed drug name to search.
#' @param data Optional lexicon data frame. If \code{NULL}, loads the
#'   bundled lexicon.
#' @return A tibble with columns \code{active_ingredient}, \code{atc_code},
#'   \code{match_type} (always \code{"common_name"}), and \code{category}.
#'   Returns a 0-row tibble if no match is found.
#'
#' @keywords internal
.search_common_names <- function(query, data = NULL) {
  if (is.null(data)) {
    if (is.null(.atc_search_env$common_names)) {
      atc_load_common_names()
    }
    data <- .atc_search_env$common_names
  }

  if (is.null(data) || nrow(data) == 0L) {
    return(tibble::tibble(
      active_ingredient = character(), atc_code = character(),
      match_type = character(), category = character()
    ))
  }

  q <- tolower(stringr::str_squish(query))
  if (q == "" || is.na(q)) {
    return(tibble::tibble(
      active_ingredient = character(), atc_code = character(),
      match_type = character(), category = character()
    ))
  }

  # Try each pattern — first exact match wins (patterns are ordered by importance)
  for (i in seq_len(nrow(data))) {
    if (grepl(data$pattern[i], q, ignore.case = TRUE, perl = TRUE)) {
      return(tibble::tibble(
        active_ingredient = data$active_ingredient[i],
        atc_code          = data$atc_code[i],
        match_type        = "common_name",
        category          = data$category[i]
      ))
    }
  }

  tibble::tibble(
    active_ingredient = character(), atc_code = character(),
    match_type = character(), category = character()
  )
}
