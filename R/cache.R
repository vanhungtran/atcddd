#' @keywords internal
.atc_env <- new.env(parent = emptyenv())

#' @keywords internal
`%||%` <- function(x, y) if (is.null(x)) y else x

#' @keywords internal
atc_base_url <- function() "https://www.whocc.no/atc_ddd_index/?code="

#' @keywords internal
atc_user_agent <- function() "atcddd R package (+https://vanhungtran.github.io/atcddd; contact: tranhungydhcm@gmail.com)"

#' @keywords internal
atc_cache_dir <- function() {
  dir <- rappdirs::user_cache_dir("atcddd")
  if (!dir.exists(dir)) dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  dir
}

#' @keywords internal
atc_cache <- function() {
  cache <- .atc_env$cache
  if (is.null(cache)) {
    cache <- memoise::cache_filesystem(atc_cache_dir())
    .atc_env$cache <- cache
  }
  cache
}

#' Default ATC roots
#' @export
atc_roots_default <- function() c("A","B","C","D","G","H","J","L","M","N","P","R","S","V")

#' @keywords internal
is_valid_atc_code <- function(x) is.character(x) && length(x) == 1 && grepl("^[A-Z0-9]+$", x)

