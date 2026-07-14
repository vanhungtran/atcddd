# atcddd: WHO ATC/DDD Crawler and Parser
# Version 0.2.0
# Copyright (C) 2025 Lucas VHH TRAN
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the MIT License.

# Drug Name Extraction from Free-Text Clinical Notes

#' Extract drug names from free-text clinical notes
#'
#' @description
#' Scans unstructured clinical text for drug names and resolves them to WHO
#' ATC codes. Supports exact name matching, synonym (brand/common name)
#' lookup, and optional fuzzy matching for misspellings. Multi-word drug
#' names (e.g. "acetylsalicylic acid", "sodium fluoride") are detected
#' through bigram tokenisation.
#'
#' Inspired by \code{ab_from_text()} from the \pkg{AMR} package, but
#' covering the full WHO ATC/DDD index rather than antimicrobials alone.
#'
#' @param text Character scalar; free-text clinical notes such as
#'   \code{"Patient received 500 mg aspirin PO TID"} or
#'   \code{"On atorvastatin 20 mg daily"}.
#' @param max_results Integer; maximum number of unique drugs to return.
#'   Default is \code{5}.
#' @param fuzzy Logical; if \code{TRUE}, use Levenshtein (edit-distance)
#'   matching for drug names that are not found by exact or synonym lookup.
#'   Default is \code{TRUE}.
#'
#' @return A \link[tibble]{tibble} with up to \code{max_results} rows and
#'   the following columns:
#'   \describe{
#'     \item{\code{drug_name}}{Character; the official drug name from the WHO
#'       ATC database (e.g. \code{"acetylsalicylic acid"}).}
#'     \item{\code{atc_code}}{Character; the resolved ATC code
#'       (e.g. \code{"N02BA01"}).}
#'     \item{\code{match}}{Character; the text span from the input that
#'       triggered the match, preserving original casing
#'       (e.g. \code{"Aspirin"}).}
#'     \item{\code{match_type}}{Character; how the match was made:
#'       \code{"exact"}, \code{"synonym"}, or \code{"fuzzy"}.}
#'     \item{\code{confidence}}{Character; heuristic quality rating:
#'       \code{"high"} (exact or synonym match), \code{"medium"}
#'       (fuzzy, edit distance <= 2), or \code{"low"} (fuzzy,
#'       edit distance 3).}
#'     \item{\code{ddd}}{Character; the WHO Defined Daily Dose value for
#'       the drug (preferring the oral route), or \code{NA} if not
#'       available.}
#'     \item{\code{uom}}{Character; the unit of the DDD value
#'       (e.g. \code{"g"}, \code{"mg"}), or \code{NA} if not available.}
#'   }
#'   Returns a zero-row tibble when no drugs are detected or the input is
#'   empty/NA.
#'
#' @details
#' \strong{Algorithm}
#' \enumerate{
#'   \item \strong{Pre-processing.} The input text is normalised to
#'     lowercase. Punctuation characters (commas, semicolons, periods,
#'     parentheses, etc.) are replaced with spaces so that tokens like
#'     \code{"aspirin,"} become \code{"aspirin"}. Internal hyphens are
#'     preserved (e.g. \code{"co-trimoxazole"}).
#'   \item \strong{Tokenisation.} The cleaned text is split on whitespace
#'     into individual words. Two-word sequences (bigrams) are also
#'     generated so that multi-word drug names are not missed.
#'   \item \strong{Filtering.} Tokens that represent dosing information
#'     (e.g. \code{"500mg"}, \code{"20mg/kg"}), pure numbers, and very
#'     short tokens (<= 2 characters) are excluded from matching. Overly
#'     generic chemical terms (\code{"acid"}, \code{"sodium"},
#'     \code{"chloride"}, etc.) are only allowed as part of a bigram.
#'   \item \strong{Bigram matching (Phase 1).} Each consecutive word pair
#'     that survives filtering is looked up via \code{\link{search_drug}()}
#'     (exact WHO name and synonym check). If \code{fuzzy = TRUE} and no
#'     exact/synonym match is found, \code{\link{fuzzy_match_drug}()} is
#'     tried for the pair. Words consumed by a successful bigram match are
#'     not re-processed as unigrams.
#'   \item \strong{Unigram matching (Phase 2).} Remaining words are matched
#'     individually, first via \code{\link{search_drug}()} and then (if
#'     \code{fuzzy = TRUE}) via \code{\link{fuzzy_match_drug}()}.
#'   \item \strong{De-duplication and ranking.} Results are de-duplicated
#'     by ATC code (keeping the highest-confidence match). The final set
#'     is ranked by confidence (high > medium > low) and truncated to
#'     \code{max_results}.
#' }
#'
#' @section Confidence Heuristic:
#' \describe{
#'   \item{\code{high}}{The token exactly matches a WHO drug name or a
#'     curated synonym. Considered reliable.}
#'   \item{\code{medium}}{The token fuzzy-matches with a Levenshtein
#'     distance of 1 or 2 — likely a minor typo.}
#'   \item{\code{low}}{The token fuzzy-matches with a Levenshtein
#'     distance of 3 — more speculative. Manual verification recommended.}
#' }
#'
#' @examples
#' \donttest{
#' # Simple drug name extraction
#' atc_from_text("Patient was prescribed aspirin 500 mg and metformin")
#'
#' # Brand names resolved via synonym table
#' atc_from_text("On lipitor for cholesterol, also takes tylenol PRN")
#'
#' # Multi-word drug names
#' atc_from_text("Received acetylsalicylic acid 100 mg daily")
#'
#' # Strict mode — no fuzzy matching
#' atc_from_text("acetominophen", fuzzy = FALSE)
#' }
#'
#' @seealso \code{\link{search_drug}} for exact and synonym name search,
#'   \code{\link{fuzzy_match_drug}} for typo-tolerant matching,
#'   \code{\link{resolve_atc}} for single-drug-to-ATC resolution.
#'
#' @export
atc_from_text <- function(text, max_results = 5, fuzzy = TRUE) {
  # ---- Input validation ----
  if (length(text) != 1L) {
    cli::cli_abort("{.arg text} must be a single character string.")
  }
  # Handle NA values (both NA_character_ and plain NA)
  if (is.na(text)) {
    return(.empty_atc_from_text_result())
  }
  if (!is.character(text)) {
    cli::cli_abort("{.arg text} must be a single character string.")
  }

  max_results <- as.integer(max_results)
  if (length(max_results) != 1L || is.na(max_results) || max_results < 1L) {
    cli::cli_abort("{.arg max_results} must be a positive integer.")
  }

  if (!is.logical(fuzzy) || length(fuzzy) != 1L || is.na(fuzzy)) {
    cli::cli_abort("{.arg fuzzy} must be a single logical value.")
  }

  text <- stringr::str_squish(text)
  if (text == "") {
    return(.empty_atc_from_text_result())
  }

  # ---- Load the WHO ATC database once ----
  db <- atc_load_db()
  codes <- db$codes

  # ---- Pre-processing and tokenisation ----
  # Replace sentence-level punctuation with spaces to avoid attached
  # punctuation (e.g. "aspirin," -> "aspirin"), but keep internal hyphens.
  text_clean <- stringr::str_replace_all(
    text,
    stringr::regex("[,;:.!?()\\[\\]{}<>\"'/@#$%^&*+=~`|]+"),
    " "
  )
  text_clean <- stringr::str_squish(text_clean)

  # Lowercase version for matching; original case preserved for 'match' column
  text_lower  <- tolower(text_clean)
  words_lower <- strsplit(text_lower, "\\s+")[[1L]]
  words_orig  <- strsplit(text_clean, "\\s+")[[1L]]

  if (length(words_lower) == 0L) {
    return(.empty_atc_from_text_result())
  }

  # ---- Filter token classes ----
  # Dosing patterns: number + optional decimal + unit
  dosing_re <- paste0(
    "^[0-9]+(\\.[0-9]+)?",
    "(mg|g|mcg|ug|ml|l|iu|mu|tu|%|meq|mmol)",
    "(/(kg|ml|d|l|day|hr))?$"
  )
  is_dosing  <- stringr::str_detect(words_lower, stringr::regex(dosing_re, ignore_case = TRUE))
  is_numeric <- stringr::str_detect(words_lower, "^[0-9]+(\\.[0-9]+)?$")
  is_short   <- nchar(words_lower) <= 2L

  # Overly generic chemical terms — only match as part of a multi-word name
  generic_terms <- c(
    "acid", "sodium", "chloride", "calcium", "potassium", "magnesium",
    "phosphate", "sulfate", "sulphate", "acetate", "nitrate"
  )
  is_generic <- words_lower %in% generic_terms

  # Common English stop words — never match these as drug names
  stop_words <- c(
    "the", "and", "for", "was", "but", "are", "had", "has", "can", "all",
    "any", "per", "not", "his", "her", "our", "out", "how", "who", "she",
    "its", "may", "see", "use", "way", "old", "get", "two", "say", "set",
    "got", "put", "let", "ago", "yet", "new", "own", "too", "now",
    "did", "him", "try", "ask", "ran", "red", "run", "end", "men",
    "also", "than", "then", "just", "very", "even", "well", "back",
    "been", "some", "such", "only", "like", "into", "over", "both",
    "more", "most", "much", "many", "other", "about", "after",
    "before", "since", "while", "still", "often", "ever", "never",
    "always", "without", "between", "through", "during",
    "patient", "takes", "taken", "given", "daily", "times",
    "blood", "level", "levels", "pain", "care", "history",
    "normal", "results", "status", "report", "reports",
    "received", "receives", "prescribed", "prescribes",
    "continue", "continues", "continued",
    "test", "tests", "testing", "cholesterol",
    "should", "match", "matches", "matched", "make", "made",
    "next", "last", "first", "second", "third",
    "best", "better", "worse", "good", "bad",
    "found", "done", "seen", "known", "used"
  )
  is_stopword <- words_lower %in% stop_words

  # Words that should NOT be processed as unigrams
  skip_unigram <- is_dosing | is_numeric | is_short | is_generic | is_stopword

  # For bigrams, skip if either word is dosing/numeric or a stop word.
  # (Generic chemical terms like "acid" ARE allowed in bigrams since they
  #  can be part of legitimate multi-word drug names.)
  skip_bigram <- is_dosing | is_numeric | is_stopword

  # ---- Storage for results ----
  # Named list keyed by ATC code so we can overwrite with higher-confidence
  # matches when the same drug is found more than once.
  results_env <- new.env(parent = emptyenv(), hash = TRUE)

  # Track word positions consumed by successful bigram matches
  consumed <- logical(length(words_lower))

  # Helper: store or update a result (keep best confidence)
  store_result <- function(atc_code, drug_name, match_text, match_type,
                           confidence, ddd, uom) {
    existing <- results_env[[atc_code]]
    if (is.null(existing)) {
      results_env[[atc_code]] <- list(
        drug_name  = drug_name,
        atc_code   = atc_code,
        match      = match_text,
        match_type = match_type,
        confidence = confidence,
        ddd        = ddd %||% NA_character_,
        uom        = uom %||% NA_character_
      )
    } else {
      # Keep the match with higher confidence
      conf_order <- c("high" = 1L, "medium" = 2L, "low" = 3L)
      existing_rank <- conf_order[existing$confidence]
      new_rank      <- conf_order[confidence]
      if (new_rank < existing_rank) {
        results_env[[atc_code]] <- list(
          drug_name  = drug_name,
          atc_code   = atc_code,
          match      = match_text,
          match_type = match_type,
          confidence = confidence,
          ddd        = ddd %||% NA_character_,
          uom        = uom %||% NA_character_
        )
      }
    }
  }

  # ---- Phase 1: Bigram matching ----
  n_words <- length(words_lower)
  if (n_words >= 2L) {
    for (i in seq_len(n_words - 1L)) {
      # Skip if either word is dosing or numeric
      if (skip_bigram[i] || skip_bigram[i + 1L]) next

      bigram      <- paste(words_lower[i], words_lower[i + 1L])
      bigram_orig <- paste(words_orig[i],  words_orig[i + 1L])

      # --- Search with bigram (exact + synonym) ---
      hits <- search_drug(bigram, data = codes, max_results = 1L)

      if (nrow(hits) > 0L && hits$match_type[1L] %in% c("exact", "synonym")) {
        atc      <- hits$atc_code[1L]
        mtype    <- hits$match_type[1L]
        ddd_info <- .lookup_ddd(atc)

        store_result(
          atc_code   = atc,
          drug_name  = hits$atc_name[1L],
          match_text = bigram_orig,
          match_type = mtype,
          confidence = "high",
          ddd        = ddd_info$ddd,
          uom        = ddd_info$uom
        )
        consumed[i]       <- TRUE
        consumed[i + 1L] <- TRUE
        next
      }

      # --- Fuzzy match with bigram (min 4 chars per word) ---
      if (fuzzy && nchar(words_lower[i]) >= 4L && nchar(words_lower[i + 1L]) >= 4L) {
        fuzzy_hits <- fuzzy_match_drug(
          bigram, data = codes, max_distance = 3L, max_results = 1L
        )
        if (nrow(fuzzy_hits) > 0L) {
          atc  <- fuzzy_hits$atc_code[1L]
          dist <- fuzzy_hits$distance[1L]

          confidence <- if (dist <= 2L) "medium" else "low"
          ddd_info   <- .lookup_ddd(atc)

          store_result(
            atc_code   = atc,
            drug_name  = fuzzy_hits$atc_name[1L],
            match_text = bigram_orig,
            match_type = "fuzzy",
            confidence = confidence,
            ddd        = ddd_info$ddd,
            uom        = ddd_info$uom
          )
          consumed[i]       <- TRUE
          consumed[i + 1L] <- TRUE
        }
      }
    }
  }

  # ---- Phase 2: Unigram matching ----
  for (i in seq_len(n_words)) {
    if (consumed[i])        next
    if (skip_unigram[i])    next

    token      <- words_lower[i]
    token_orig <- words_orig[i]

    # --- Search with unigram (exact + synonym) ---
    hits <- search_drug(token, data = codes, max_results = 1L)

    if (nrow(hits) > 0L && hits$match_type[1L] %in% c("exact", "synonym")) {
      atc      <- hits$atc_code[1L]
      mtype    <- hits$match_type[1L]
      ddd_info <- .lookup_ddd(atc)

      store_result(
        atc_code   = atc,
        drug_name  = hits$atc_name[1L],
        match_text = token_orig,
        match_type = mtype,
        confidence = "high",
        ddd        = ddd_info$ddd,
        uom        = ddd_info$uom
      )
      next
    }

    # --- Fuzzy match with unigram (min 4 chars) ---
    if (fuzzy && nchar(token) >= 4L) {
      # Check both codes table and synonym table, keep the closest match
      best_fuzzy <- .best_fuzzy_match(token, codes)
      if (!is.null(best_fuzzy)) {
        ddd_info <- .lookup_ddd(best_fuzzy$atc_code)
        store_result(
          atc_code   = best_fuzzy$atc_code,
          drug_name  = best_fuzzy$atc_name,
          match_text = token_orig,
          match_type = "fuzzy",
          confidence = best_fuzzy$confidence,
          ddd        = ddd_info$ddd,
          uom        = ddd_info$uom
        )
      }
    }
  }

  # ---- Assemble output ----
  if (length(results_env) == 0L) {
    return(.empty_atc_from_text_result())
  }

  # Convert environment to a list of result entries, then bind rows
  result_list <- as.list(results_env)
  out <- dplyr::bind_rows(lapply(result_list, function(entry) {
    tibble::tibble(
      drug_name  = entry$drug_name %||% NA_character_,
      atc_code   = entry$atc_code %||% NA_character_,
      match      = entry$match %||% NA_character_,
      match_type = entry$match_type %||% NA_character_,
      confidence = entry$confidence %||% NA_character_,
      ddd        = entry$ddd %||% NA_character_,
      uom        = entry$uom %||% NA_character_
    )
  }))

  # Rank by confidence (high > medium > low), then by match_type
  # for deterministic ordering within the same confidence tier
  out <- out |>
    dplyr::mutate(
      conf_rank = dplyr::case_match(
        .data$confidence,
        "high"   ~ 1L,
        "medium" ~ 2L,
        "low"    ~ 3L
      ),
      type_rank = dplyr::case_match(
        .data$match_type,
        "exact"   ~ 1L,
        "synonym" ~ 2L,
        "fuzzy"   ~ 3L
      )
    ) |>
    dplyr::arrange(.data$conf_rank, .data$type_rank) |>
    dplyr::select(-"conf_rank", -"type_rank") |>
    utils::head(max_results)

  out
}


#' Zero-row tibble template for atc_from_text() return value
#' @keywords internal
.empty_atc_from_text_result <- function() {
  tibble::tibble(
    drug_name  = character(),
    atc_code   = character(),
    match      = character(),
    match_type = character(),
    confidence = character(),
    ddd        = character(),
    uom        = character()
  )
}

#' Find the best fuzzy match for a token across codes and synonyms
#'
#' Checks both the WHO codes table and the synonym table for the closest
#' fuzzy match (Levenshtein distance <= 3). Returns a list with atc_code,
#' atc_name, and confidence, or NULL if no acceptable match is found.
#' @param token Character; lowercased token to match.
#' @param codes Data frame; the WHO ATC codes table.
#' @return A list with elements atc_code, atc_name, confidence, or NULL.
#' @keywords internal
.best_fuzzy_match <- function(token, codes) {
  # Try codes table first
  hits <- fuzzy_match_drug(token, data = codes,
                           max_distance = 3L, max_results = 1L)
  codes_dist <- if (nrow(hits) > 0L) hits$distance[1L] else Inf
  codes_atc  <- if (nrow(hits) > 0L) hits$atc_code[1L] else NA_character_
  codes_name <- if (nrow(hits) > 0L) hits$atc_name[1L] else NA_character_

  # Try synonym table
  syn_dist <- Inf
  syn_atc  <- NA_character_
  syn_name <- NA_character_

  if (!is.null(.atc_search_env$synonyms) &&
      nrow(.atc_search_env$synonyms) > 0L) {
    syn_dists <- utils::adist(
      token, .atc_search_env$synonyms[["synonym"]],
      partial = FALSE, ignore.case = TRUE
    )[1L, ]
    best <- which.min(syn_dists)
    if (length(best) > 0L && syn_dists[best] <= 3L) {
      syn_dist <- syn_dists[best[1L]]
      syn_atc  <- .atc_search_env$synonyms[["atc_code"]][best[1L]]
      syn_name <- .atc_search_env$synonyms[["atc_name"]][best[1L]]
    }
  }

  # Pick the better match (lower distance wins)
  best_dist <- min(codes_dist, syn_dist)
  if (is.infinite(best_dist)) return(NULL)

  if (codes_dist <= syn_dist && !is.na(codes_atc)) {
    confidence <- if (codes_dist <= 2L) "medium" else "low"
    list(atc_code = codes_atc, atc_name = codes_name, confidence = confidence)
  } else if (!is.na(syn_atc)) {
    confidence <- if (syn_dist <= 2L) "medium" else "low"
    list(atc_code = syn_atc, atc_name = syn_name, confidence = confidence)
  } else if (!is.na(codes_atc)) {
    confidence <- if (codes_dist <= 2L) "medium" else "low"
    list(atc_code = codes_atc, atc_name = codes_name, confidence = confidence)
  } else {
    NULL
  }
}
