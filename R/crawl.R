#' @keywords internal
atc_fetch_code <- function(code, rate = 0.5) {
  stopifnot(is_valid_atc_code(code))
  url <- paste0(atc_base_url(), code, "&showdescription=no")
  cli::cli_alert_info("Fetching {url}")
  html <- http_get_html_cached(url, min_delay = rate)

  if (is_leaf_page(html)) {
    ddd <- parse_ddd_table(html)
    codes <- if (!is.null(ddd) && nrow(ddd)) dplyr::distinct(ddd, atc_code, atc_name) else tibble::tibble(atc_code = code, atc_name = NA_character_)
    list(type = "leaf", code = code, children = tibble::tibble(), ddd = ddd %||% tibble::tibble(), codes = codes)
  } else {
    kids <- parse_children(html, code)
    list(type = "parent", code = code, children = kids, ddd = tibble::tibble(), codes = kids)
  }
}

#' Crawl WHO ATC/DDD from one or more root codes
#'
#' @param roots character vector of root ATC codes
#' @param rate minimum seconds between HTTP requests
#' @param progress logical, show progress bar
#' @param max_codes integer limit for development/testing
#' @return list(codes = tibble, ddd = tibble)
#' @export
atc_crawl <- function(roots = atc_roots_default(), rate = 0.5, progress = interactive(), max_codes = Inf) {
  roots <- unique(toupper(roots))
  if (any(!vapply(roots, is_valid_atc_code, logical(1)))) stop("All roots must be uppercase alphanumeric codes.")

  visited <- new.env(parent = emptyenv())
  queue <- roots
  all_codes <- tibble::tibble(atc_code = character(), atc_name = character())
  all_ddd   <- tibble::tibble()

  pb <- NULL
  if (isTRUE(progress)) pb <- cli::cli_progress_bar("Crawling ATC/DDD", total = NA)

  n_processed <- 0L
  while (length(queue) > 0L && n_processed < max_codes) {
    code <- queue[[1]]; queue <- queue[-1]
    if (!is.null(visited[[code]])) next
    visited[[code]] <- TRUE
    n_processed <- n_processed + 1L

    res <- atc_fetch_code(code, rate = rate)

    if (nrow(res$codes)) all_codes <- dplyr::bind_rows(all_codes, res$codes)
    if (nrow(res$ddd)) {
      res$ddd <- dplyr::mutate(res$ddd, source_code = code, .before = 1)
      all_ddd <- dplyr::bind_rows(all_ddd, res$ddd)
    }
    if (nrow(res$children)) queue <- c(queue, res$children$atc_code)

    if (!is.null(pb)) cli::cli_progress_update()
  }
  if (!is.null(pb)) cli::cli_progress_done()

  all_codes <- all_codes |>
    dplyr::mutate(atc_code = toupper(.data$atc_code),
                  atc_name = dplyr::coalesce(.data$atc_name, "")) |>
    dplyr::group_by(.data$atc_code) |>
    dplyr::slice_head(n = 1) |>
    dplyr::ungroup()

  all_ddd <- dplyr::mutate(all_ddd, atc_code = toupper(.data$atc_code))

  list(codes = all_codes, ddd = all_ddd)
}

