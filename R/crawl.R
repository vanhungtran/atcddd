# atcddd: WHO ATC/DDD Crawler and Parser
# Version 0.1.0
# Copyright (C) 2025 Lucas VHH TRAN
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the MIT License.

#' Crawl the WHO ATC/DDD Index
#'
#' @description
#' Iteratively traverses ATC codes starting from one or more root codes,
#' respecting rate limits and using the HTTP layer's caching. Returns two
#' tidy tables: \code{codes} (unique ATC codes with names) and \code{ddd} 
#' (dose definitions and related fields).
#'
#' This function implements a breadth-first traversal of the ATC hierarchy,
#' automatically discovering child codes and handling both parent nodes
#' (with child links) and leaf nodes (with DDD tables).
#'
#' @param roots Character vector of root ATC codes to start from.
#'   Default: anatomical main groups A-V (see \code{\link{atc_roots_default}}).
#'   Must be uppercase alphanumeric codes.
#' @param rate Numeric; minimum seconds between HTTP requests (default: 0.5).
#'   Increase this value for more conservative crawling.
#' @param progress Logical; show a progress bar (default: \code{interactive()}).
#'   Set to \code{FALSE} for batch processing or scripting.
#' @param max_codes Integer; limit on number of codes to visit (default: Inf).
#'   Useful for testing or partial crawls. Set to a finite value to limit scope.
#' @param quiet Logical; reduce informational messages (default: FALSE).
#'
#' @return A list with two components:
#' \describe{
#'   \item{codes}{A tibble with columns:
#'     \itemize{
#'       \item \code{atc_code}: Character; the ATC code (uppercase)
#'       \item \code{atc_name}: Character; the WHO description/name
#'     }
#'   }
#'   \item{ddd}{A tibble with columns:
#'     \itemize{
#'       \item \code{source_code}: Character; the parent code where this DDD was found
#'       \item \code{atc_code}: Character; the specific drug's ATC code
#'       \item \code{atc_name}: Character; drug name
#'       \item \code{ddd}: Character; defined daily dose value
#'       \item \code{uom}: Character; unit of measure
#'       \item \code{adm_r}: Character; administration route
#'       \item \code{note}: Character; additional notes
#'     }
#'   }
#' }
#'
#' @section Caching:
#' Results are cached at the HTTP level using the \code{memoise} package.
#' The cache is stored in the user's cache directory (see \code{rappdirs::user_cache_dir}).
#' To clear the cache, delete the cache directory or restart R.
#'
#' @section Rate Limiting:
#' The function respects the \code{rate} parameter by enforcing a minimum delay
#' between consecutive HTTP requests. This helps prevent overloading the WHO server.
#'
#' @examples
#' \dontrun{
#' # Crawl a single anatomical group (Dermatologicals)
#' res_d <- atc_crawl(roots = "D", rate = 0.8, max_codes = 50)
#' head(res_d$codes)
#' head(res_d$ddd)
#'
#' # Crawl multiple groups
#' res_multi <- atc_crawl(roots = c("A", "B"), rate = 1.0)
#'
#' # Full crawl (may take several minutes)
#' res_all <- atc_crawl(progress = TRUE)
#' nrow(res_all$codes)  # Total unique codes
#' nrow(res_all$ddd)    # Total DDD entries
#' }
#'
#' @seealso
#' \code{\link{atc_write_csv}} for exporting results,
#' \code{\link{atc_roots_default}} for default root codes
#'
#' @export

# Internal: template for a shaped, empty DDD tibble (stable schema)
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
# Requires either:
#   - fetch_html(url, rate) defined in http.R (preferred), or
#   - http_get_raw_cached(url, min_delay) + xml2::read_html
# Fallback to http_get_html_cached (not recommended across sessions).
.fetch_html_safe <- function(url, rate = 0.5) {
  if (exists("fetch_html", mode = "function")) {
    return(fetch_html(url, rate = rate))
  }
  if (exists("http_get_raw_cached", mode = "function")) {
    raw <- http_get_raw_cached(url, min_delay = rate)
    return(xml2::read_html(raw))
  }
  # Fallback (works within-session but fragile if cached across sessions)
  if (exists("http_get_html_cached", mode = "function")) {
    return(http_get_html_cached(url, min_delay = rate))
  }
  stop("No suitable HTML fetch function found. Provide fetch_html() or http_get_raw_cached().")
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

# Crawl WHO ATC/DDD from one or more root codes
# Iterative, rate-limited, cached (via HTTP layer), robust to partial failures.
# Returns two tidy tibbles: codes (unique codes with names) and ddd (rows with DDD/UOM/route/notes).
#' @param roots character vector of root ATC codes (default: anatomical main groups)
#' @param rate minimum seconds between HTTP requests
#' @param progress logical; show a progress bar
#' @param max_codes integer; limit for development/testing (default Inf)
#' @param quiet logical; reduce info messages
#' @return list(codes = tibble, ddd = tibble)
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
