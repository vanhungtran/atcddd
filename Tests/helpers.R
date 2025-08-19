with_cache_off <- function(code) {
  old <- memoise::forget(http_get_html_cached)
  on.exit(memoise::forget(http_get_html_cached), add = TRUE)
  force(code)
}
