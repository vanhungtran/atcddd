#' @keywords internal
last_request_time <- function() .atc_env$last_request_time %||% 0

#' @keywords internal
set_last_request_time <- function(t) { .atc_env$last_request_time <- t; invisible(t) }

#' Fetch HTML with retries and rate limit
#' @keywords internal
http_get_html <- function(url, min_delay = 0.5, timeout = 30, max_tries = 5) {
  now <- as.numeric(Sys.time())
  dt <- now - last_request_time()
  if (!is.null(min_delay) && dt < min_delay) Sys.sleep(min_delay - dt)

  req <- httr2::request(url) |>
    httr2::req_user_agent(atc_user_agent()) |>
    httr2::req_timeout(timeout) |>
    httr2::req_retry(max_tries = max_tries)

  resp <- httr2::req_perform(req)
  set_last_request_time(as.numeric(Sys.time()))

  status <- httr2::resp_status(resp)
  if (status >= 400) stop(sprintf("HTTP error %s at %s", status, url))

  httr2::resp_body_html(resp)
}

#' @keywords internal
http_get_html_cached <- memoise::memoise(http_get_html, cache = atc_cache())

