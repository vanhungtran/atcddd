# atcddd: WHO ATC/DDD Crawler and Parser
# Version 0.2.0
# Copyright (C) 2025 Lucas VHH TRAN
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the MIT License.

# Drug Name Search and Resolution Functions

# Internal environment for cached database
#' @keywords internal
.atc_search_env <- new.env(parent = emptyenv())

# ---- Built-in drug name synonym table ----
# Maps common clinical/brand names to WHO official names.
# Extend via atc_add_synonym().
#' @keywords internal
.atc_synonyms <- tibble::tibble(
  synonym    = character(),
  atc_code   = character(),
  atc_name   = character()
)

# Pre-populate common synonym mappings
.atc_synonyms_default <- function() {
  tibble::tibble(
    synonym = c(
      "aspirin",
      "acetaminophen",
      "tylenol",
      "advil",
      "motrin",
      "lipitor",
      "glucophage",
      "lasix",
      "inderal",
      "valium",
      "xanax",
      "zoloft",
      "prozac",
      "prilosec",
      "nexium",
      "zocor",
      "crestor",
      "plavix",
      "coumadin",
      "warfarin",
      "levothyroxine",
      "synthroid",
      "epinephrine",
      "adrenaline",
      "noradrenaline",
      "norepinephrine",
      "salbutamol",
      "albuterol",
      "tamoxifen",
      "nolvadex"
    ),
    atc_code = c(
      "N02BA01",  # aspirin → acetylsalicylic acid
      "N02BE01",  # acetaminophen → paracetamol
      "N02BE01",  # tylenol → paracetamol
      "M01AE01",  # advil → ibuprofen
      "M01AE01",  # motrin → ibuprofen
      "C10AA05",  # lipitor → atorvastatin
      "A10BA02",  # glucophage → metformin
      "C03CA01",  # lasix → furosemide
      "C07AA05",  # inderal → propranolol
      "N05BA01",  # valium → diazepam
      "N05BA12",  # xanax → alprazolam
      "N06AB06",  # zoloft → sertraline
      "N06AB03",  # prozac → fluoxetine
      "A02BC01",  # prilosec → omeprazole
      "A02BC05",  # nexium → esomeprazole
      "C10AA01",  # zocor → simvastatin
      "C10AA07",  # crestor → rosuvastatin
      "B01AC04",  # plavix → clopidogrel
      "B01AA03",  # coumadin → warfarin
      "B01AA03",  # warfarin (self)
      "H03AA01",  # levothyroxine (self)
      "H03AA01",  # synthroid → levothyroxine
      "C01CA24",  # epinephrine (self)
      "C01CA24",  # adrenaline → epinephrine
      "C01CA03",  # noradrenaline → norepinephrine
      "C01CA03",  # norepinephrine (self)
      "R03AC02",  # salbutamol (self)
      "R03AC02",  # albuterol → salbutamol
      "L02BA01",  # tamoxifen (self)
      "L02BA01"   # nolvadex → tamoxifen
    ),
    atc_name = c(
      "acetylsalicylic acid",
      "paracetamol",
      "paracetamol",
      "ibuprofen",
      "ibuprofen",
      "atorvastatin",
      "metformin",
      "furosemide",
      "propranolol",
      "diazepam",
      "alprazolam",
      "sertraline",
      "fluoxetine",
      "omeprazole",
      "esomeprazole",
      "simvastatin",
      "rosuvastatin",
      "clopidogrel",
      "warfarin",
      "warfarin",
      "levothyroxine sodium",
      "levothyroxine sodium",
      "epinephrine",
      "epinephrine",
      "norepinephrine",
      "norepinephrine",
      "salbutamol",
      "salbutamol",
      "tamoxifen",
      "tamoxifen"
    )
  )
}

#' Load the bundled WHO ATC database into memory
#'
#' @description
#' Loads the bundled WHO ATC/DDD CSV files into an in-memory cache, making
#' subsequent [search_drug()], [fuzzy_match_drug()], and [resolve_atc()]
#' calls fast and offline-capable.
#'
#' Call this once at the start of your session (or let search functions
#' call it automatically on first use). Set `refresh = TRUE` to force
#' a reload.
#'
#' @param refresh Logical; if `TRUE`, reloads the database even if already
#'   cached. Default is `FALSE`.
#'
#' @return Invisibly returns a list with `codes` and `ddd` tibbles.
#'
#' @examples
#' atc_load_db()
#'
#' # Force reload
#' atc_load_db(refresh = TRUE)
#'
#' @seealso [search_drug()], [fuzzy_match_drug()], [resolve_atc()]
#' @export
atc_load_db <- function(refresh = FALSE) {
  if (!isTRUE(refresh) && !is.null(.atc_search_env$codes)) {
    return(invisible(list(
      codes    = .atc_search_env$codes,
      ddd      = .atc_search_env$ddd,
      synonyms = .atc_search_env$synonyms
    )))
  }

  codes_path <- system.file("extdata", "WHO_ATC_codes_2026-07-14.csv",
                            package = "atcddd")
  ddd_path   <- system.file("extdata", "WHO_ATC_DDD_2026-07-14.csv",
                            package = "atcddd")

  if (!file.exists(codes_path) || !file.exists(ddd_path)) {
    stop(
      "Bundled WHO data files not found. Reinstall the package or place ",
      "the CSV files in inst/extdata/."
    )
  }

  codes <- readr::read_csv(codes_path, show_col_types = FALSE, progress = FALSE)
  ddd   <- readr::read_csv(ddd_path,   show_col_types = FALSE, progress = FALSE)

  # Normalise names for faster matching
  codes <- codes |>
    dplyr::mutate(
      atc_name_lower = tolower(.data$atc_name),
      atc_name_clean = stringr::str_squish(tolower(.data$atc_name)),
      level          = atc_level(.data$atc_code)
    )

  ddd <- ddd |>
    dplyr::mutate(
      atc_name_lower = tolower(.data$atc_name),
      ddd_numeric    = suppressWarnings(as.numeric(.data$ddd))
    )

  # Load synonym table
  syn <- .atc_synonyms_default()
  syn <- dplyr::mutate(syn, synonym = tolower(.data$synonym))

  .atc_search_env$codes    <- codes
  .atc_search_env$ddd      <- ddd
  .atc_search_env$synonyms <- syn

  invisible(list(codes = codes, ddd = ddd))
}

#' Search for drugs by name in the ATC database
#'
#' @description
#' Searches the bundled WHO ATC database for drugs matching a query string.
#' Performs a multi-stage search: exact match → prefix match → substring
#' match → word-boundary match. Results are ranked by match quality.
#'
#' This function works **fully offline** against the bundled data — no
#' internet connection is needed once the database is loaded.
#'
#' @param query Character scalar; the drug name or partial name to search for.
#'   Not case-sensitive. Examples: `"aspirin"`, `"paracetamol"`, `"statin"`.
#' @param data Optional data frame to search (from [atc_load_db()] or a
#'   custom source). If `NULL`, the bundled database is loaded automatically.
#' @param max_results Integer; maximum number of results to return.
#'   Default is 20.
#'
#' @return A tibble of matching ATC codes and names, sorted by match quality
#'   (best matches first). Returns a 0-row tibble if no matches are found.
#'
#' @section Match Types:
#' Results include a `match_type` column indicating how each result was found:
#' \itemize{
#'   \item `exact` — query exactly equals the drug name
#'   \item `starts_with` — drug name starts with the query
#'   \item `contains` — drug name contains the query as a substring
#'   \item `word_match` — query matches a whole word within the drug name
#' }
#'
#' @examples
#' \donttest{
#' search_drug("aspirin")
#' search_drug("paracetamol")
#' search_drug("statin", max_results = 10)
#' search_drug("hydrocortisone")
#' }
#'
#' @seealso [fuzzy_match_drug()] for typo-tolerant matching,
#'   [resolve_atc()] for hybrid local/live resolution.
#' @export
search_drug <- function(query, data = NULL, max_results = 20L) {
  if (!is_scalar_character(query)) {
    stop("query must be a single character string", call. = FALSE)
  }
  q <- stringr::str_squish(tolower(query))
  if (q == "") return(tibble::tibble())

  if (is.null(data)) {
    db <- atc_load_db()
    data <- db$codes
  }
  stopifnot(
    is.data.frame(data),
    "atc_code" %in% names(data),
    "atc_name" %in% names(data)
  )

  # Ensure clean lowercase column exists
  if (!"atc_name_clean" %in% names(data)) {
    data <- dplyr::mutate(
      data,
      atc_name_clean = stringr::str_squish(tolower(.data$atc_name))
    )
  }

  names_clean <- data[["atc_name_clean"]]

  # --- Stage 0: synonym lookup ---
  syn_code <- NULL
  if (!is.null(.atc_search_env$synonyms) &&
      nrow(.atc_search_env$synonyms) > 0) {
    syn_match <- .atc_search_env$synonyms[
      .atc_search_env$synonyms[["synonym"]] == q, , drop = FALSE
    ]
    if (nrow(syn_match) > 0) {
      syn_code <- syn_match[["atc_code"]][1]
    }
  }

  # --- Stage 1: exact match ---
  exact_idx <- which(names_clean == q)

  # --- Stage 2: starts with ---
  sw_idx <- which(grepl(paste0("^", q), names_clean, fixed = FALSE))

  # --- Stage 3: contains ---
  contains_idx <- which(grepl(q, names_clean, fixed = TRUE))

  # --- Stage 4: word-boundary match ---
  word_pat <- paste0("(^| |,|;|\\()", q, "($| |,|;|\\))")
  word_idx <- which(grepl(word_pat, names_clean, perl = TRUE))

  # Assemble ranked results — collect unique row indices in priority order
  seen <- integer(0)
  ordered_idx <- integer(0)
  match_labels <- character(0)

  add_results <- function(idx, mtype, max_n) {
    new <- setdiff(idx, seen)
    if (length(new)) {
      n <- min(length(new), max_n)
      new <- new[seq_len(n)]
      seen <<- c(seen, new)
      ordered_idx <<- c(ordered_idx, new)
      match_labels <<- c(match_labels, rep(mtype, n))
    }
  }

  # Synonym-resolved results: find the ATC code in data
  if (!is.null(syn_code)) {
    syn_idx <- which(data[["atc_code"]] == syn_code)
    add_results(syn_idx, "synonym", max_results)
  }

  add_results(exact_idx,      "exact",        max_results)
  add_results(sw_idx,         "starts_with",  max_results - length(seen))
  add_results(contains_idx,   "contains",     max_results - length(seen))
  add_results(word_idx,       "word_match",   max_results - length(seen))

  if (length(ordered_idx) == 0) return(tibble::tibble())

  # Cap at max_results
  n_out <- min(length(ordered_idx), max_results)
  ordered_idx  <- ordered_idx[seq_len(n_out)]
  match_labels <- match_labels[seq_len(n_out)]

  keep_cols <- intersect(
    c("atc_code", "atc_name", "level"),
    names(data)
  )

  # Extract matching rows directly by index
  out <- data[ordered_idx, keep_cols, drop = FALSE]
  out[["match_type"]] <- match_labels
  out <- out[, c("match_type", keep_cols), drop = FALSE]

  tibble::as_tibble(out)
}

#' Fuzzy-match a drug name to ATC codes
#'
#' @description
#' Finds ATC codes for drug names that may be misspelled, abbreviated, or
#' use non-standard formatting. Uses Levenshtein (edit) distance via
#' `utils::adist()` to find close matches in the bundled WHO database.
#'
#' This is useful when:
#' \itemize{
#'   \item Users type drug names from memory (typos)
#'   \item Clinical notes use non-standard spellings
#'   \item Brand names or abbreviations differ from WHO naming
#' }
#'
#' @param query Character scalar; the drug name to match.
#' @param data Optional data frame to search. If `NULL`, loads the bundled database.
#' @param max_distance Integer; maximum allowed Levenshtein distance.
#'   Lower values are stricter. Default is 3.
#' @param max_results Integer; maximum results to return. Default is 10.
#'
#' @return A tibble of the closest-matching ATC codes, sorted by edit
#'   distance (closest first). Includes a `distance` column with the
#'   Levenshtein distance to each match.
#'
#' @examples
#' \donttest{
#' # Common misspellings
#' fuzzy_match_drug("acetominophen")    # should find "paracetamol"
#' fuzzy_match_drug("asprin")           # should find "aspirin"
#' fuzzy_match_drug("metmorphin")       # should find "metformin"
#'
#' # Stricter matching
#' fuzzy_match_drug("asprin", max_distance = 1)
#' }
#'
#' @seealso [search_drug()] for exact/substring matching,
#'   [resolve_atc()] for hybrid resolution.
#' @export
fuzzy_match_drug <- function(query, data = NULL,
                              max_distance = 3L, max_results = 10L) {
  if (!is_scalar_character(query)) {
    stop("query must be a single character string", call. = FALSE)
  }
  q <- stringr::str_squish(tolower(query))
  if (q == "") return(tibble::tibble())

  if (is.null(data)) {
    db <- atc_load_db()
    data <- db$codes
  }
  stopifnot(
    is.data.frame(data),
    "atc_code" %in% names(data),
    "atc_name" %in% names(data)
  )

  if (!"atc_name_clean" %in% names(data)) {
    data <- dplyr::mutate(
      data,
      atc_name_clean = stringr::str_squish(tolower(.data$atc_name))
    )
  }

  # Compute Levenshtein distances
  names_vec <- data[["atc_name_clean"]]
  dists <- utils::adist(q, names_vec, partial = FALSE,
                        ignore.case = TRUE, costs = NULL)[1, ]

  within_limit <- dists <= max_distance

  if (!any(within_limit)) {
    # No close match — try partial matching (substring distance)
    dists_partial <- utils::adist(q, names_vec, partial = TRUE,
                                   ignore.case = TRUE, costs = NULL)[1, ]
    within_limit <- dists_partial <= max_distance
    if (!any(within_limit)) return(tibble::tibble())
    dists <- dists_partial
  }

  keep_cols <- intersect(
    c("atc_code", "atc_name", "level"),
    names(data)
  )

  data[within_limit, keep_cols, drop = FALSE] |>
    dplyr::mutate(distance = dists[within_limit]) |>
    dplyr::arrange(.data$distance) |>
    utils::head(max_results)
}

#' Resolve a drug name to its ATC code with hybrid local/live lookup
#'
#' @description
#' The primary drug-name resolution function. Tries to find the ATC code
#' for a given drug name by searching the bundled local database first,
#' then optionally falling back to a live WHO crawl if the drug is not
#' found locally.
#'
#' This is the function you reach for when you have a drug name and need
#' its ATC code — the #1 workflow in pharmacoepidemiology.
#'
#' @param query Character scalar; the drug name to resolve.
#'   Case-insensitive. Examples: `"aspirin"`, `"atorvastatin"`.
#' @param source Character; resolution strategy:
#'   \itemize{
#'     \item `"local"` — bundled database only (offline, fast)
#'     \item `"live"` — WHO website only (always up-to-date, requires internet)
#'     \item `"hybrid"` — try local first, fall back to live (default)
#'   }
#' @param data Optional data frame for local search. If `NULL`, auto-loads
#'   the bundled database.
#' @param fuzzy Logical; if `TRUE` and the exact lookup fails, fall back
#'   to fuzzy matching before trying live resolution. Default is `TRUE`.
#' @param rate_limit Numeric; delay between live WHO requests (seconds).
#'   Only used when `source` is `"live"` or `"hybrid"`. Default is 0.5.
#'
#' @return A tibble with columns:
#' \itemize{
#'   \item `query` — the original query
#'   \item `atc_code` — the resolved ATC code
#'   \item `atc_name` — the drug name from the database
#'   \item `source` — `"local"` or `"live"` indicating where the match came from
#'   \item `match_type` — how the match was found (`"exact"`, `"fuzzy"`, `"live"`)
#' }
#' Returns a 0-row tibble if the drug cannot be resolved.
#'
#' @section Resolution Order (hybrid mode):
#' 1. Exact name match in local database
#' 2. Fuzzy match in local database (if `fuzzy = TRUE`)
#' 3. Live WHO crawl as last resort
#'
#' @examples
#' \donttest{
#' # Offline — fast, no internet needed
#' resolve_atc("aspirin", source = "local")
#'
#' # Live — always current
#' resolve_atc("aspirin", source = "live")
#'
#' # Hybrid (default) — local first, live fallback
#' resolve_atc("atorvastatin")
#'
#' # Batch resolution
#' meds <- c("aspirin", "metformin", "atorvastatin")
#' resolve_batch(meds)
#' }
#'
#' @seealso [resolve_batch()] for vectorised resolution,
#'   [search_drug()] for exploratory search.
#' @export
resolve_atc <- function(query,
                        source     = c("hybrid", "local", "live"),
                        data       = NULL,
                        fuzzy      = TRUE,
                        rate_limit = 0.5) {
  source <- match.arg(source)
  if (!is_scalar_character(query)) {
    stop("query must be a single character string", call. = FALSE)
  }

  empty_result <- function(q, src, mtype) {
    tibble::tibble(
      query      = q,
      atc_code   = NA_character_,
      atc_name   = NA_character_,
      ddd        = NA_character_,
      uom        = NA_character_,
      adm_r      = NA_character_,
      source     = src,
      match_type = mtype
    )[0, ]
  }

  # --- Try local ---
  if (source %in% c("local", "hybrid")) {
    # Search (includes synonym resolution)
    hits <- search_drug(query, data = data, max_results = 1L)

    if (nrow(hits) > 0) {
      mtype <- hits$match_type[1]
      ddd_info <- .lookup_ddd(hits$atc_code[1], data = data)
      return(tibble::tibble(
        query      = query,
        atc_code   = hits$atc_code[1],
        atc_name   = hits$atc_name[1],
        ddd        = ddd_info$ddd,
        uom        = ddd_info$uom,
        adm_r      = ddd_info$adm_r,
        source     = "local",
        match_type = mtype
      ))
    }

    # Fuzzy fallback (only if the query bears some resemblance)
    if (isTRUE(fuzzy) && nchar(query) >= 3) {
      fuzzy_res <- fuzzy_match_drug(query, data = data,
                                     max_distance = 3L, max_results = 1L)
      if (nrow(fuzzy_res) > 0 && fuzzy_res$distance[1] <= 3L) {
        ddd_info <- .lookup_ddd(fuzzy_res$atc_code[1], data = data)
        return(tibble::tibble(
          query      = query,
          atc_code   = fuzzy_res$atc_code[1],
          atc_name   = fuzzy_res$atc_name[1],
          ddd        = ddd_info$ddd,
          uom        = ddd_info$uom,
          adm_r      = ddd_info$adm_r,
          source     = "local",
          match_type = "fuzzy"
        ))
      }
    }

    if (source == "local") return(empty_result(query, "local", NA_character_))
  }

  # --- Try live ---
  if (source %in% c("live", "hybrid")) {
    live_res <- tryCatch(
      get_atc_data(query, rate_limit = rate_limit, use_cache = TRUE),
      error = function(e) NULL
    )

    if (!is.null(live_res) && nrow(live_res) > 0) {
      ddd_info <- if ("ddd" %in% names(live_res)) {
        list(
          ddd   = as.character(live_res$ddd[1]),
          uom   = as.character(live_res$uom[1]),
          adm_r = as.character(live_res$adm_r[1])
        )
      } else { list(ddd = NA_character_, uom = NA_character_, adm_r = NA_character_) }

      return(tibble::tibble(
        query      = query,
        atc_code   = live_res$atc_code[1],
        atc_name   = live_res$atc_name[1],
        ddd        = ddd_info$ddd,
        uom        = ddd_info$uom,
        adm_r      = ddd_info$adm_r,
        source     = "live",
        match_type = "live"
      ))
    }
  }

  empty_result(query, source, NA_character_)
}

#' Resolve multiple drug names at once
#'
#' @description
#' Vectorised version of [resolve_atc()] — resolves a character vector of
#' drug names to their ATC codes. Runs sequentially with rate limiting to
#' be respectful of the WHO server when live fallback is used.
#'
#' @param queries Character vector of drug names to resolve.
#' @param source Character; `"hybrid"`, `"local"`, or `"live"`.
#'   Passed to [resolve_atc()]. Default is `"hybrid"`.
#' @param ... Additional arguments passed to [resolve_atc()].
#'
#' @return A tibble stacking the results from each query, with the same
#'   columns as [resolve_atc()].
#'
#' @examples
#' \donttest{
#' meds <- c("aspirin", "paracetamol", "ibuprofen", "metformin")
#' resolve_batch(meds)
#'
#' # Offline only
#' resolve_batch(meds, source = "local")
#' }
#'
#' @seealso [resolve_atc()] for single-name resolution.
#' @export
resolve_batch <- function(queries, source = c("hybrid", "local", "live"), ...) {
  source <- match.arg(source)
  if (!is.character(queries) || length(queries) == 0L) {
    stop("queries must be a non-empty character vector", call. = FALSE)
  }

  # Preload local DB once
  if (source %in% c("local", "hybrid")) atc_load_db()

  results <- lapply(queries, function(q) {
    resolve_atc(q, source = source, ...)
  })

  dplyr::bind_rows(results)
}

# Internal: look up DDD for a single ATC code
#' @keywords internal
.lookup_ddd <- function(code, data = NULL) {
  if (is.null(data)) {
    if (!is.null(.atc_search_env$ddd)) {
      data <- .atc_search_env$ddd
    } else {
      return(list(ddd = NA_character_, uom = NA_character_,
                  adm_r = NA_character_))
    }
  }

  # Prefer oral route
  ddd_rows <- data[data[["atc_code"]] == code, , drop = FALSE]
  if (nrow(ddd_rows) == 0) {
    return(list(ddd = NA_character_, uom = NA_character_,
                adm_r = NA_character_))
  }

  # Prefer oral, then first non-NA DDD
  if ("adm_r" %in% names(ddd_rows)) {
    oral <- ddd_rows[!is.na(ddd_rows[["adm_r"]]) &
                     ddd_rows[["adm_r"]] == "O", , drop = FALSE]
    if (nrow(oral) > 0 && "ddd" %in% names(oral) &&
        !is.na(oral[["ddd"]][1]) && oral[["ddd"]][1] != "NA") {
      return(list(ddd   = as.character(oral[["ddd"]][1]),
                  uom   = as.character(oral[["uom"]][1]),
                  adm_r = "O"))
    }
  }

  # Fall back to first row with a non-NA DDD
  if ("ddd" %in% names(ddd_rows)) {
    valid <- ddd_rows[!is.na(ddd_rows[["ddd"]]) &
                      ddd_rows[["ddd"]] != "NA", , drop = FALSE]
    if (nrow(valid) > 0) {
      return(list(ddd   = as.character(valid[["ddd"]][1]),
                  uom   = as.character(valid[["uom"]][1]),
                  adm_r = as.character(valid[["adm_r"]][1])))
    }
  }

  list(ddd = NA_character_, uom = NA_character_, adm_r = NA_character_)
}

#' Add a drug name synonym to the lookup table
#'
#' @description
#' Registers a common name, brand name, or abbreviation as a synonym for
#' a WHO ATC code. Synonyms are checked before fuzzy matching in
#' [search_drug()] and [resolve_atc()], making them the fastest path
#' from a clinical drug name to an ATC code.
#'
#' Use this to build up your own synonym dictionary for drugs frequently
#' encountered in your data.
#'
#' @param synonym Character scalar; the common name or alias
#'   (e.g. `"aspirin"`, `"tylenol"`).
#' @param atc_code Character scalar; the WHO ATC code the synonym maps to
#'   (e.g. `"N02BA01"`).
#' @param atc_name Character scalar; the WHO official name for the code
#'   (e.g. `"acetylsalicylic acid"`).
#'
#' @return Invisibly returns the updated synonym table.
#'
#' @examples
#' atc_add_synonym("advil", "M01AE01", "ibuprofen")
#' atc_add_synonym("lasix", "C03CA01", "furosemide")
#'
#' @seealso [search_drug()], [resolve_atc()]
#' @export
atc_add_synonym <- function(synonym, atc_code, atc_name) {
  if (!is_scalar_character(synonym) || !is_scalar_character(atc_code) ||
      !is_scalar_character(atc_name)) {
    stop("synonym, atc_code, and atc_name must all be single character strings",
         call. = FALSE)
  }

  if (!is_valid_atc_code(atc_code)) {
    stop("atc_code must be a valid ATC code", call. = FALSE)
  }

  syn <- tolower(synonym)

  # Ensure synonym table is initialised
  if (is.null(.atc_search_env$synonyms) || nrow(.atc_search_env$synonyms) == 0) {
    .atc_search_env$synonyms <- .atc_synonyms_default()
    .atc_search_env$synonyms <- dplyr::mutate(
      .atc_search_env$synonyms, synonym = tolower(.data$synonym)
    )
  }

  # Remove existing entry for this synonym if present
  .atc_search_env$synonyms <- .atc_search_env$synonyms[
    .atc_search_env$synonyms[["synonym"]] != syn, , drop = FALSE
  ]

  # Add new entry
  .atc_search_env$synonyms <- dplyr::bind_rows(
    .atc_search_env$synonyms,
    tibble::tibble(
      synonym  = syn,
      atc_code = atc_code,
      atc_name = atc_name
    )
  )

  invisible(.atc_search_env$synonyms)
}
