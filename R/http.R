#' @keywords internal
last_request_time <- function() .atc_env$last_request_time %||% 0

#' @keywords internal
set_last_request_time <- function(t) { .atc_env$last_request_time <- t; invisible(t) }

#' Fetch HTML with retries and rate limit
#' @keywords internal
# Fetch raw bytes and cache those; reparse per call
http_get_raw <- function(url, min_delay = 0.5, timeout = 30, max_tries = 5) {
  now <- as.numeric(Sys.time())
  dt <- now - (get0("last_request_time", envir = .atc_env, ifnotfound = 0))
  if (!is.null(min_delay) && dt < min_delay) Sys.sleep(min_delay - dt)

  req <- httr2::request(url) |>
    httr2::req_user_agent(atc_user_agent()) |>
    httr2::req_timeout(timeout) |>
    httr2::req_retry(max_tries = max_tries)

  resp <- httr2::req_perform(req)
  assign("last_request_time", as.numeric(Sys.time()), envir = .atc_env)

  status <- httr2::resp_status(resp)
  if (status >= 400) stop(sprintf("HTTP error %s at %s", status, url))
  httr2::resp_body_raw(resp)  # raw vector
}

http_get_raw_cached <- memoise::memoise(http_get_raw, cache = atc_cache())

fetch_html <- function(url, rate = 0.5) {
  raw <- http_get_raw_cached(url, min_delay = rate)
  xml2::read_html(raw)  # create a fresh xml_document each time
}
