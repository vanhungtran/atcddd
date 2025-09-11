#' @keywords internal
parse_children <- function(html, parent_code) {
  stopifnot(is_valid_atc_code(parent_code))
  links <- rvest::html_elements(html, "a[href*='atc_ddd_index/?code='], a[href*='?code=']")
  hrefs <- rvest::html_attr(links, "href")
  texts <- rvest::html_text2(links)
  codes <- stringr::str_match(hrefs, "[?&]code=([A-Za-z0-9]+)")[,2]
  keep <- !is.na(codes) & codes != parent_code & stringr::str_starts(codes, parent_code)
  tibble::tibble(
    atc_code = toupper(codes[keep]),
    atc_name = stringr::str_squish(texts[keep])
  ) |>
    dplyr::distinct()
}

#' @keywords internal
is_leaf_page <- function(html) {
  any(stringr::str_detect(
    tolower(rvest::html_text2(rvest::html_elements(html, "table"))),
    "atc.*code"
  ))
}

#' @keywords internal
parse_ddd_table <- function(html) {
  tables <- rvest::html_elements(html, "table")
  if (length(tables) == 0L) return(NULL)

  target <- NULL
  for (tb in tables) {
    df_try <- rvest::html_table(tb, header = TRUE, fill = TRUE, trim = TRUE)
    nms <- tolower(names(df_try))
    if (any(stringr::str_detect(nms, "atc.*code")) && any(stringr::str_detect(nms, "name"))) {
      target <- df_try; break
    }
  }
  if (is.null(target)) target <- rvest::html_table(tables[[1]], header = TRUE, fill = TRUE, trim = TRUE)

  df <- tibble::as_tibble(target)
  names(df) <- tolower(stringr::str_trim(names(df)))

  col_map <- c(
    "atc code" = "atc_code",
    "atc_code" = "atc_code",
    "code" = "atc_code",
    "name" = "atc_name",
    "ddd" = "ddd",
    "u"   = "uom",
    "unit" = "uom",
    "adm.r" = "adm_r",
    "adm r" = "adm_r",
    "route" = "adm_r",
    "note" = "note",
    "notes" = "note"
  )
  names(df) <- purrr::map_chr(names(df), ~ col_map[[.x]] %||% .x)

  keep <- intersect(c("atc_code","atc_name","ddd","uom","adm_r","note"), names(df))
  df <- dplyr::select(df, dplyr::all_of(keep))

  df <- df |>
    dplyr::mutate(dplyr::across(dplyr::everything(),
                                ~ dplyr::na_if(stringr::str_squish(as.character(.)), "")))

  # FILL: use tidyselect with all_of() (no .data pronoun here)
  fill_cols <- intersect(c("atc_code","atc_name"), names(df))
  if (length(fill_cols)) {
    df <- tidyr::fill(df, dplyr::all_of(fill_cols), .direction = "down")
  }

  # FILTER: .data is OK in dplyr verbs; guard for existence
  if ("atc_code" %in% names(df)) {
    df <- dplyr::filter(df, !is.na(.data$atc_code))
  }

  df
}
