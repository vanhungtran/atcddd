# atcddd: WHO ATC/DDD Crawler and Parser
# Version 0.2.0
# Copyright (C) 2025 Lucas VHH TRAN
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the MIT License.

# Offline ATC Hierarchy Lookup Functions

#' Get direct children of an ATC code in the hierarchy
#'
#' @description
#' Returns all ATC codes that are immediate children of the given parent
#' code. This works offline using any data frame of ATC codes (such as the
#' cached WHO data) — no internet connection is required.
#'
#' The parent-child relationship follows the natural ATC hierarchy:
#' \itemize{
#'   \item Children of Level 1 `"N"` are Level 2 codes starting with `N`
#'     (e.g. `"N01"`, `"N02"`, …)
#'   \item Children of Level 4 `"N02BE"` are Level 5 substances
#'     (e.g. `"N02BE01"`, `"N02BE51"`, …)
#' }
#'
#' @param code Character scalar; the ATC parent code.
#' @param data Data frame containing at least an `atc_code` column
#'   (e.g. from the output of [atc_crawl()] or the cached CSVs).
#' @return Character vector of child ATC codes, or `character(0)` if
#'   the code is a leaf or not found.
#'
#' @examples
#' \donttest{
#' # First download the WHO data, then load it
#' atc_download(roots = "N")
#' db <- atc_load_db()
#'
#' # Direct children of analgesics (N02)
#' atc_children("N02", db$codes)
#'
#' # Direct children of the nervous system group
#' atc_children("N", db$codes)
#' }
#'
#' @seealso [atc_descendants()], [atc_parent()], [atc_level()]
#' @export
atc_children <- function(code, data) {
  code <- normalize_atc_code(code)
  stopifnot(
    is_scalar_character(code),
    is_valid_atc_code(code),
    is.data.frame(data),
    "atc_code" %in% names(data)
  )

  parent_level <- atc_level(code)
  if (is.na(parent_level)) return(character(0))

  # Level N children = codes that are (a) exactly one level deeper,
  # (b) whose parent equals `code`
  child_codes <- data[["atc_code"]]
  child_levels <- atc_level(child_codes)
  child_parents <- atc_parent(child_codes)

  unique(child_codes[
    child_levels == (parent_level + 1L) &
    child_parents == code &
    !is.na(child_parents)
  ])
}

#' Get all descendants of an ATC code through the hierarchy
#'
#' @description
#' Returns all ATC codes below the given code in the hierarchy — that is,
#' all children, grandchildren, great-grandchildren, and so on down to
#' Level 5 substances. This works offline against any data frame of ATC
#' codes.
#'
#' @param code Character scalar; the root ATC code.
#' @param data Data frame containing at least an `atc_code` column.
#' @param max_level Integer; maximum hierarchy depth to descend.
#'   Default is 5 (complete tree).
#' @return Character vector of all descendant ATC codes (excluding `code`
#'   itself), or `character(0)` if the code is a leaf or not found.
#'
#' @examples
#' \donttest{
#' # First download the WHO data, then load it
#' atc_download(roots = c("C", "N"))
#' db <- atc_load_db()
#'
#' # All codes under the cardiovascular group
#' atc_descendants("C", db$codes)
#'
#' # All codes under the nervous system group, stopping at Level 4
#' atc_descendants("N", db$codes, max_level = 4)
#' }
#'
#' @seealso [atc_children()], [atc_parent()]
#' @export
atc_descendants <- function(code, data, max_level = 5L) {
  code <- normalize_atc_code(code)
  stopifnot(
    is_scalar_character(code),
    is_valid_atc_code(code),
    is.data.frame(data),
    "atc_code" %in% names(data)
  )

  parent_level <- atc_level(code)
  if (is.na(parent_level)) return(character(0))

  all_codes  <- data[["atc_code"]]
  all_levels <- atc_level(all_codes)
  all_parents <- atc_parent(all_codes)

  # Collect all codes that (a) are deeper than `code`,
  # (b) have `code` somewhere in their ancestry chain
  deeper <- all_levels > parent_level & !is.na(all_levels)

  if (!any(deeper)) return(character(0))

  # For each candidate, walk up the parent chain; keep if `code` appears
  candidates <- all_codes[deeper]
  candidate_parents <- all_parents[deeper]

  keep <- logical(length(candidates))
  for (i in seq_along(candidates)) {
    cur <- candidate_parents[i]
    while (!is.na(cur) && cur != "") {
      if (cur == code) { keep[i] <- TRUE; break }
      # Find the parent of cur in the data
      idx <- match(cur, all_codes)
      if (is.na(idx)) break
      cur <- all_parents[idx]
    }
  }

  result <- unique(candidates[keep])

  # Apply max_level filter
  if (!is.infinite(max_level)) {
    result <- result[atc_level(result) <= max_level]
  }

  sort(result)
}
