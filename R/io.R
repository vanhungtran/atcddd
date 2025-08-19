#' Write codes and DDD tables to CSV files
#' @param x list with 'codes' and 'ddd'
#' @param dir output directory
#' @param stamp logical date-stamped filenames
#' @return character vector of file paths (invisible)
#' @export
atc_write_csv <- function(x, dir = ".", stamp = TRUE) {
  stopifnot(is.list(x), "codes" %in% names(x), "ddd" %in% names(x))
  if (!dir.exists(dir)) dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  date <- if (stamp) paste0("_", format(Sys.Date(), "%Y-%m-%d")) else ""
  f_codes <- file.path(dir, paste0("WHO_ATC_codes", date, ".csv"))
  f_ddd   <- file.path(dir, paste0("WHO_ATC_DDD",   date, ".csv"))
  cli::cli_inform(sprintf("Writing %s and %s", f_codes, f_ddd))
  readr::write_csv(x$codes, f_codes)
  readr::write_csv(x$ddd,   f_ddd)
  invisible(c(f_codes, f_ddd))
}

