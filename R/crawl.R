# atcddd: WHO ATC/DDD Crawler and Parser
# Version 0.1.0
# Copyright (C) 2025 Lucas VHH TRAN
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the MIT License.

# Internal: template for a shaped, empty DDD tibble (stable schema)
#' @keywords internal
.empty_ddd <- function() {
  tibble::tibble(
    source_code = character(),
    atc_code    = character(),
    atc_name    = character(),
    ddd         = character(),
    uom         = character(),
    adm_r       = character(),
    note        = character()
  )
}

# Internal: ensure tibble has the columns and order of the template
.shape_like <- function(x, template = .empty_ddd()) {
  if (is.null(x) || !nrow(x)) {
    out <- template
  } else {
    missing_cols <- setdiff(names(template), names(x))
    if (length(missing_cols)) {
      for (mc in missing_cols) x[[mc]] <- NA_character_
    }
    out <- dplyr::select(x, dplyr::all_of(names(template)))
  }
  out
}

# Internal: safe HTML fetch that avoids caching xml_document pointers
# Uses fetch_html(url, rate) defined in http.R which handles caching and rate limiting
.fetch_html_safe <- function(url, rate = 0.5) {
  fetch_html(url, rate = rate)
}

# Fetch a single ATC page and parse children/DDD
#' @keywords internal
atc_fetch_code <- function(code, rate = 0.5, quiet = FALSE) {
  stopifnot(is_valid_atc_code(code))
  url <- paste0(atc_base_url(), code, "&showdescription=no")

  html <- .fetch_html_safe(url, rate = rate)

  # Classify page and parse
  if (is_leaf_page(html)) {
    ddd <- tryCatch(
      parse_ddd_table(html),
      error = function(e) {
        NULL
      }
    )

    # Derive codes table from DDD if present, else record the page code at least
    codes <- if (!is.null(ddd) && nrow(ddd) && "atc_code" %in% names(ddd)) {
      dplyr::distinct(ddd, atc_code, atc_name)
    } else {
      tibble::tibble(atc_code = code, atc_name = NA_character_)
    }

    list(
      type     = "leaf",
      code     = code,
      children = tibble::tibble(),    # none on a leaf
      ddd      = ddd %||% tibble::tibble(),
      codes    = codes
    )
  } else {
    kids <- tryCatch(
      parse_children(html, code),
      error = function(e) {
        tibble::tibble()
      }
    )
    list(
      type     = "parent",
      code     = code,
      children = kids,
      ddd      = tibble::tibble(),
      codes    = kids
    )
  }
}

#' Crawl the WHO ATC/DDD Index
#'
#' @description
#' Iteratively traverses ATC codes starting from one or more root codes,
#' respecting rate limits and using the HTTP layer's caching. Returns two
#' tidy tables: `codes` (unique ATC codes with names) and `ddd`
#' (dose definitions and related fields).
#'
#' @param roots Character vector of root ATC codes to start from. Must be
#'   uppercase codes. Default: `atc_roots_default()`.
#' @param rate Numeric; minimum seconds between HTTP requests (default: 0.5).
#' @param progress Logical; show a progress bar (default: `interactive()`).
#' @param max_codes Integer; limit on number of codes to visit (default: `Inf`).
#' @param quiet Logical; reduce informational messages (default: FALSE).
#'
#' @return A list with `codes` and `ddd` tibbles.
#'
#' @seealso [atc_write_csv()], [atc_roots_default()]
#'
#' @examples
#' \dontrun{
#' res <- atc_crawl(roots = "D", rate = 0.8, max_codes = 50)
#' head(res$codes)
#' head(res$ddd)
#' }
#'
#' @export
atc_crawl <- function(roots = atc_roots_default(),
                      rate = 0.5,
                      progress = interactive(),
                      max_codes = Inf,
                      quiet = FALSE) {
  roots <- unique(toupper(roots))
  if (any(!vapply(roots, is_valid_atc_code, logical(1)))) {
    stop("All roots must be uppercase alphanumeric ATC codes.")
  }

  visited <- new.env(parent = emptyenv())
  queue   <- roots

  all_codes <- tibble::tibble(atc_code = character(), atc_name = character())
  all_ddd   <- .empty_ddd()

  pb <- NULL
  if (isTRUE(progress)) pb <- cli::cli_progress_bar("Crawling ATC/DDD", total = NA)

  n_processed <- 0L
  while (length(queue) > 0L && n_processed < max_codes) {
    code <- queue[[1]]
    queue <- queue[-1]

    if (!is.null(visited[[code]])) next
    visited[[code]] <- TRUE
    n_processed <- n_processed + 1L

    res <- tryCatch(
      atc_fetch_code(code, rate = rate, quiet = quiet),
      error = function(e) {
        NULL
      }
    )
    if (is.null(res)) {
      if (!is.null(pb)) cli::cli_progress_update()
      next
    }

    # Accumulate codes (uppercase codes; NA-safe names)
    if (nrow(res$codes)) {
      res$codes <- res$codes |>
        dplyr::mutate(
          dplyr::across(dplyr::any_of("atc_code"), toupper),
          atc_name = dplyr::coalesce(.data$atc_name, "")
        )
      all_codes <- dplyr::bind_rows(all_codes, res$codes)
    }

    # Accumulate DDD rows with shaped schema
    if (nrow(res$ddd)) {
      # Attach source code and shape columns safely
      res$ddd <- dplyr::mutate(res$ddd, source_code = code, .before = 1)
      res$ddd <- .shape_like(res$ddd, template = .empty_ddd())
      # normalize casing if present
      res$ddd <- dplyr::mutate(res$ddd, dplyr::across(dplyr::any_of("atc_code"), toupper))
      all_ddd <- dplyr::bind_rows(all_ddd, res$ddd)
    }

    # Enqueue children, if any
    if (nrow(res$children)) {
      new_codes <- setdiff(toupper(res$children$atc_code), ls(visited, all.names = TRUE))
      if (length(new_codes)) queue <- c(queue, new_codes)
    }

    if (!is.null(pb)) cli::cli_progress_update()
  }
  if (!is.null(pb)) cli::cli_progress_done()

  # Deduplicate and finalize
  all_codes <- all_codes |>
    dplyr::mutate(
      dplyr::across(dplyr::any_of("atc_code"), toupper),
      atc_name = dplyr::coalesce(.data$atc_name, "")
    ) |>
    dplyr::group_by(.data$atc_code) |>
    dplyr::slice_head(n = 1) |>
    dplyr::ungroup()

  all_ddd <- all_ddd |>
    dplyr::mutate(dplyr::across(dplyr::any_of("atc_code"), toupper))

  list(codes = all_codes, ddd = all_ddd)
}
