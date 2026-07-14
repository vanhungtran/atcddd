# atcddd: WHO ATC/DDD Crawler and Parser
# Version 0.2.0
# Copyright (C) 2025 Lucas VHH TRAN
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the MIT License.

# DDD Computation Functions

# ---- Internal helpers ----

#' Load the bundled WHO DDD data into memory
#'
#' @param data Optional pre-loaded DDD data frame. If \code{NULL}, loads
#'   from the in-memory cache (via \code{\link{atc_load_db}}) or the bundled
#'   CSV file.
#' @return A tibble of DDD definitions with a \code{ddd_numeric} column.
#' @keywords internal
.load_ddd_data <- function(data = NULL) {
  if (!is.null(data)) {
    # Ensure ddd_numeric exists on user-supplied data
    if (!"ddd_numeric" %in% names(data)) {
      data <- data |>
        dplyr::mutate(ddd_numeric = suppressWarnings(as.numeric(.data$ddd)))
    }
    return(data)
  }

  # Try in-memory cache first
  if (!is.null(.atc_search_env$ddd)) {
    return(.atc_search_env$ddd)
  }

  # Fall back to loading the bundled CSV
  ddd_path <- system.file("extdata", "WHO_ATC_DDD_2026-07-14.csv",
                           package = "atcddd")

  if (!file.exists(ddd_path)) {
    cli::cli_abort(paste(
      "Bundled WHO DDD data not found at {.path {ddd_path}}.",
      "Reinstall the package or run {.fun atc_load_db} first."
    ))
  }

  ddd <- readr::read_csv(ddd_path, show_col_types = FALSE, progress = FALSE) |>
    dplyr::mutate(ddd_numeric = suppressWarnings(as.numeric(.data$ddd)))

  # Cache for subsequent calls
  .atc_search_env$ddd <- ddd

  ddd
}

#' Classify a unit into a conversion family
#'
#' @param unit Character unit string (e.g. \code{"mg"}, \code{"MU"}).
#' @return Character string naming the family (\code{"mass"}, \code{"unit"},
#'   \code{"volume"}, \code{"mmol"}, \code{"lsu"}, \code{"tablet"}) or
#'   \code{NA_character_} if unrecognised.
#' @keywords internal
.ddd_unit_family <- function(unit) {
  u <- tolower(unit)

  if (u %in% c("g", "mg", "mcg"))            return("mass")
  if (u %in% c("u", "tu", "mu"))             return("unit")
  if (u == "ml")                              return("volume")
  if (u == "mmol")                            return("mmol")
  if (u == "lsu")                             return("lsu")
  if (u == "tablet")                          return("tablet")

  NA_character_
}

#' Convert a numeric value between compatible units
#'
#' @param value Numeric value to convert.
#' @param from_unit Character; source unit.
#' @param to_unit Character; target unit.
#' @return Converted numeric value. Returns \code{NA} if the units are
#'   incompatible or unrecognised.
#' @keywords internal
.ddd_convert <- function(value, from_unit, to_unit) {
  from <- tolower(from_unit)
  to   <- tolower(to_unit)

  # Same unit — no conversion needed
  if (identical(from, to)) return(value)

  from_family <- .ddd_unit_family(from_unit)
  to_family   <- .ddd_unit_family(to_unit)

  if (is.na(from_family) || is.na(to_family) || !identical(from_family, to_family)) {
    return(NA_real_)
  }

  # Mass: g <-> mg <-> mcg, base unit = mg
  if (from_family == "mass") {
    value_mg <- switch(from,
      g   = value * 1000,
      mg  = value,
      mcg = value / 1000
    )
    result <- switch(to,
      g   = value_mg / 1000,
      mg  = value_mg,
      mcg = value_mg * 1000
    )
    return(result)
  }

  # Units: U <-> TU <-> MU, base unit = U
  if (from_family == "unit") {
    value_u <- switch(from,
      u  = value,
      tu = value * 1000,
      mu = value * 1e6
    )
    result <- switch(to,
      u  = value_u,
      tu = value_u / 1000,
      mu = value_u / 1e6
    )
    return(result)
  }

  # volume / mmol / lsu / tablet: no cross-family conversion needed
  # since the "same family" check above already passed and the
  # "same unit" check at the top ensures they match exactly.
  value
}

#' Anatomical group names lookup
#'
#' @return A named character vector: names are Level-1 letters, values are
#'   group descriptions.
#' @keywords internal
.anatomical_group_names <- function() {
  c(A = "Alimentary tract and metabolism",
    B = "Blood and blood forming organs",
    C = "Cardiovascular system",
    D = "Dermatologicals",
    G = "Genito-urinary system and sex hormones",
    H = "Systemic hormonal preparations",
    J = "Antiinfectives for systemic use",
    L = "Antineoplastic and immunomodulating agents",
    M = "Musculo-skeletal system",
    N = "Nervous system",
    P = "Antiparasitic products",
    R = "Respiratory system",
    S = "Sensory organs",
    V = "Various")
}

#' Convert prescription data into Defined Daily Doses (DDDs)
#'
#' @description
#' Converts a data frame of prescription-level drug utilisation data into
#' Defined Daily Doses (DDDs) per drug per prescription. Each row represents
#' one prescription line (one drug for one patient). The function looks up
#' the WHO DDD for each ATC code, accounting for route of administration,
#' then computes the number of DDDs dispensed.
#'
#' @details
#' \strong{DDD Lookup Logic}
#' \enumerate{
#'   \item Try to match \code{atc_code + adm_r} (route-specific DDD).
#'   \item If no route-specific DDD exists, fall back to any non-NA DDD for
#'     that ATC code.
#'   \item If no DDD is found at all, the result is \code{NA} and a warning
#'     is issued listing the codes with missing DDDs.
#' }
#'
#' \strong{Unit Conversion}
#' The function automatically converts between compatible units when the
#' prescription \code{strength_unit} differs from the WHO DDD unit. Supported
#' conversions:
#' \itemize{
#'   \item \strong{Mass}: g, mg, mcg (grams)
#'   \item \strong{Units}: U, TU, MU (units, thousand units, million units)
#'   \item \strong{Volume}: ml (exact match only)
#' }
#' Incompatible unit pairs (e.g. mg vs MU) produce \code{NA} with a warning.
#'
#' @param x A data frame with the following columns:
#'   \describe{
#'     \item{\code{atc_code}}{Character vector of ATC codes (Level 5,
#'       e.g. \code{"N02BE01"}).}
#'     \item{\code{quantity}}{Numeric; the number of units administered
#'       (tablets, ml, etc.).}
#'     \item{\code{strength}}{Numeric; the amount per unit (mg per tablet,
#'       mg per ml, etc.).}
#'     \item{\code{strength_unit}}{Optional character; the unit of
#'       \code{strength}. Defaults to \code{"mg"} if not supplied.}
#'     \item{\code{adm_r}}{Optional character; the route of administration
#'       per row. If absent, the global \code{adm_r} parameter is used.}
#'   }
#'   Any additional columns (e.g. \code{patient_id}, \code{prescription_date})
#'   are preserved in the output.
#' @param adm_r Default administration route for rows without a per-row
#'   \code{adm_r} column. Default \code{"O"} (oral).
#' @param ... Reserved for future extensions. Currently unused.
#'
#' @return A \link[tibble]{tibble} inheriting all columns from \code{x} plus:
#'   \describe{
#'     \item{\code{ddd_value}}{The DDD value looked up from the WHO database,
#'       in the WHO unit (e.g. g, mg).}
#'     \item{\code{ddd_unit}}{The unit of the WHO DDD value.}
#'     \item{\code{total_amount}}{The total amount of drug:
#'       \code{quantity * strength}, expressed in \code{strength_unit}.}
#'     \item{\code{ddd_ratio}}{The number of DDDs:
#'       \code{total_amount / ddd_value}, properly unit-converted.}
#'   }
#'
#' @examples
#' \donttest{
#' prescriptions <- data.frame(
#'   patient_id    = c(1, 1, 2, 3),
#'   atc_code      = c("N02BA01", "C10AA05", "N02BA01", "A10BA02"),
#'   quantity      = c(100, 30, 60, 90),
#'   strength      = c(500, 20, 500, 500),
#'   strength_unit = c("mg", "mg", "mg", "mg"),
#'   adm_r         = c("O", "O", "O", "O")
#' )
#' compute_ddd(prescriptions)
#'
#' # Without strength_unit column (defaults to "mg")
#' df <- data.frame(
#'   atc_code = c("N02BA01", "C10AA05"),
#'   quantity = c(100, 30),
#'   strength = c(500, 20)
#' )
#' compute_ddd(df)
#' }
#'
#' @seealso \code{\link{compute_did}} for DDDs per 1000 inhabitants per day,
#'   \code{\link{ddd_availability}} for DDD coverage summaries,
#'   \code{\link{ddd_route_comparison}} for route-specific DDDs.
#' @export
compute_ddd <- function(x, adm_r = "O", ...) {
  # ---- Input validation ----
  if (!is.data.frame(x)) {
    cli::cli_abort("{.arg x} must be a data frame.")
  }

  required_cols <- c("atc_code", "quantity", "strength")
  missing_cols <- setdiff(required_cols, names(x))
  if (length(missing_cols) > 0) {
    cli::cli_abort(paste(
      "Input data must contain columns:",
      "{.val {required_cols}}."
    ))
  }

  if (!is.numeric(x[["quantity"]])) {
    cli::cli_abort("Column {.field quantity} must be numeric.")
  }
  if (!is.numeric(x[["strength"]])) {
    cli::cli_abort("Column {.field strength} must be numeric.")
  }

  dots <- rlang::list2(...)
  if (length(dots) > 0) {
    cli::cli_warn(paste(
      "Additional arguments to {.fun compute_ddd} are reserved for",
      "future use and will be ignored: {.val {names(dots)}}"
    ))
  }

  # ---- Normalise inputs ----
  x <- x |>
    dplyr::mutate(atc_code = normalize_atc_code(.data$atc_code))

  if (!"strength_unit" %in% names(x)) {
    x <- x |> dplyr::mutate(strength_unit = "mg")
  }

  if (!"adm_r" %in% names(x)) {
    x <- x |> dplyr::mutate(adm_r = adm_r)
  }

  # ---- Load DDD reference data ----
  ddd_data <- .load_ddd_data(NULL)

  # ---- Build DDD lookup tables ----
  # Route-specific DDDs: one row per (atc_code + adm_r)
  route_ddds <- ddd_data |>
    dplyr::filter(!is.na(.data$ddd_numeric), !is.na(.data$uom)) |>
    dplyr::transmute(
      atc_code  = .data$atc_code,
      adm_r_up  = toupper(.data$adm_r),
      ddd_value = .data$ddd_numeric,
      ddd_unit  = .data$uom
    ) |>
    dplyr::distinct(.data$atc_code, .data$adm_r_up, .keep_all = TRUE)

  # Fallback DDDs: first non-NA DDD per ATC code (any route)
  fallback_ddds <- ddd_data |>
    dplyr::filter(!is.na(.data$ddd_numeric), !is.na(.data$uom)) |>
    dplyr::group_by(.data$atc_code) |>
    dplyr::slice_head(n = 1) |>
    dplyr::ungroup() |>
    dplyr::transmute(
      atc_code  = .data$atc_code,
      ddd_value = .data$ddd_numeric,
      ddd_unit  = .data$uom
    )

  # ---- Route-specific DDD lookup (join) ----
  x <- x |> dplyr::mutate(adm_r_up = toupper(.data$adm_r))

  x <- x |>
    dplyr::left_join(route_ddds, by = c("atc_code", "adm_r_up"))

  # ---- Fallback for unmatched rows ----
  unmatched <- is.na(x[["ddd_value"]])
  if (any(unmatched)) {
    # Build a named vector for fast fallback lookup
    fwd <- fallback_ddds[["ddd_value"]]
    names(fwd) <- fallback_ddds[["atc_code"]]
    fun <- fallback_ddds[["ddd_unit"]]
    names(fun) <- fallback_ddds[["atc_code"]]

    codes_missing <- x[["atc_code"]][unmatched]
    x[["ddd_value"]][unmatched] <- fwd[codes_missing]
    x[["ddd_unit"]][unmatched]  <- fun[codes_missing]
  }

  # ---- Warn about ATC codes with no DDD whatsoever ----
  still_missing <- is.na(x[["ddd_value"]])
  if (any(still_missing)) {
    missing_codes <- unique(x[["atc_code"]][still_missing])
    cli::cli_warn(paste(
      "No DDD found for the following ATC code(s):",
      "{.val {missing_codes}}"
    ))
  }

  # ---- Compute total amount ----
  x <- x |>
    dplyr::mutate(total_amount = .data$quantity * .data$strength)

  # ---- Unit conversion and DDD ratio ----
  # Initialise ddd_ratio as NA
  x <- x |> dplyr::mutate(ddd_ratio = NA_real_)

  # Process rows where ddd_value is known
  computable <- !is.na(x[["ddd_value"]]) & !is.na(x[["total_amount"]])
  if (any(computable)) {
    idx <- which(computable)
    ratios <- numeric(length(idx))
    incompat_codes <- character(0)

    for (i in seq_along(idx)) {
      row_idx <- idx[i]
      ta  <- x[["total_amount"]][row_idx]
      su  <- x[["strength_unit"]][row_idx]
      dv  <- x[["ddd_value"]][row_idx]
      du  <- x[["ddd_unit"]][row_idx]

      # Convert total_amount to the DDD unit, then divide
      converted <- .ddd_convert(ta, from_unit = su, to_unit = du)
      if (is.na(converted) && tolower(su) != tolower(du)) {
        incompat_codes <- c(incompat_codes, x[["atc_code"]][row_idx])
        ratios[i] <- NA_real_
      } else if (is.na(converted)) {
        # Both units are NA (or same unknown unit) — direct division
        ratios[i] <- ta / dv
      } else {
        ratios[i] <- converted / dv
      }
    }

    x[["ddd_ratio"]][idx] <- ratios

    if (length(incompat_codes) > 0) {
      cli::cli_warn(paste(
        "Incompatible units for the following ATC code(s);",
        "ddd_ratio set to NA: {.val {unique(incompat_codes)}}"
      ))
    }
  }

  # ---- Clean up and return ----
  x <- x |> dplyr::select(-"adm_r_up")

  # Restore original column order: input columns first, then computed columns
  computed <- c("ddd_value", "ddd_unit", "total_amount", "ddd_ratio")
  x <- x[, c(setdiff(names(x), computed), computed), drop = FALSE]

  tibble::as_tibble(x)
}


#' Compute DDDs per 1000 inhabitants per day (DID)
#'
#' @description
#' Computes the standard WHO drug utilisation metric: the number of Defined
#' Daily Doses per 1000 inhabitants per day. This normalises drug consumption
#' across different population sizes and observation periods, enabling fair
#' comparisons between populations or time periods.
#'
#' @details
#' The DID formula is:
#' \deqn{DID = \frac{\sum(ddd\_ratio)}{population \times days} \times 1000}
#'
#' @param ddd_data A data frame containing at least a \code{ddd_ratio}
#'   column, typically the output of \code{\link{compute_ddd}}.
#' @param population Integer; the study population size.
#' @param days Integer; the number of days in the study period.
#'
#' @return A \link[tibble]{tibble} with columns:
#'   \describe{
#'     \item{\code{total_ddd}}{Sum of all \code{ddd_ratio} values.}
#'     \item{\code{did}}{DDDs per 1000 inhabitants per day.}
#'     \item{\code{population}}{Study population size.}
#'     \item{\code{days}}{Number of days in the study period.}
#'   }
#'
#' @examples
#' \donttest{
#' prescriptions <- data.frame(
#'   atc_code      = c("N02BA01", "C10AA05", "A10BA02"),
#'   quantity      = c(100, 30, 90),
#'   strength      = c(500, 20, 500),
#'   strength_unit = c("mg", "mg", "mg")
#' )
#' ddd_result <- compute_ddd(prescriptions)
#' compute_did(ddd_result, population = 10000, days = 30)
#' }
#'
#' @seealso \code{\link{compute_ddd}} for computing DDD ratios,
#'   \code{\link{ddd_availability}} for DDD coverage summaries.
#' @export
compute_did <- function(ddd_data, population, days) {
  # ---- Input validation ----
  if (!is.data.frame(ddd_data)) {
    cli::cli_abort("{.arg ddd_data} must be a data frame.")
  }
  if (!"ddd_ratio" %in% names(ddd_data)) {
    cli::cli_abort("{.arg ddd_data} must contain a column named {.field ddd_ratio}.")
  }

  assert_positive_numeric(population, "population")
  assert_positive_numeric(days, "days")

  population <- as.numeric(population)
  days       <- as.numeric(days)

  # ---- Compute DID ----
  total_ddd <- sum(ddd_data[["ddd_ratio"]], na.rm = TRUE)
  did_value <- (total_ddd / (population * days)) * 1000

  tibble::tibble(
    total_ddd  = total_ddd,
    did        = did_value,
    population = population,
    days       = days
  )
}


#' Summary of DDD coverage by anatomical group
#'
#' @description
#' Returns a summary table showing which ATC groups have DDD values assigned
#' in the WHO DDD Index. The report is grouped by anatomical main group
#' (Level 1 of the ATC hierarchy).
#'
#' @param data Optional pre-loaded DDD data frame (from
#'   \code{\link{atc_load_db}} or a custom source). If \code{NULL}, the
#'   bundled database is loaded automatically.
#'
#' @return A \link[tibble]{tibble} with columns:
#'   \describe{
#'     \item{\code{anatomical_group}}{Level 1 letter (e.g. \code{"A"},
#'       \code{"B"}, ...).}
#'     \item{\code{group_name}}{The anatomical group description (e.g.
#'       \code{"Alimentary tract and metabolism"}).}
#'     \item{\code{total_substances}}{Number of unique ATC Level-5 substances
#'       in that group.}
#'     \item{\code{with_ddd}}{Number of substances with an assigned DDD.}
#'     \item{\code{pct_with_ddd}}{Percentage of substances with an assigned
#'       DDD.}
#'   }
#'
#' @examples
#' \donttest{
#' ddd_availability()
#' }
#'
#' @seealso \code{\link{compute_ddd}} for DDD computation,
#'   \code{\link{compute_did}} for DID calculation.
#' @export
ddd_availability <- function(data = NULL) {
  # ---- Load data ----
  ddd_data <- .load_ddd_data(data)

  # ---- Compute group-level summary ----
  # Extract anatomical group (Level 1) from the ATC code first character
  ddd_data <- ddd_data |>
    dplyr::mutate(
      anatomical_group = substr(.data$atc_code, 1, 1)
    )

  # Summarise per group
  summary <- ddd_data |>
    dplyr::group_by(.data$anatomical_group) |>
    dplyr::summarise(
      total_substances = dplyr::n_distinct(.data$atc_code),
      with_ddd = dplyr::n_distinct(
        .data$atc_code[!is.na(.data$ddd_numeric)]
      ),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      pct_with_ddd = round(
        .data$with_ddd / .data$total_substances * 100, 1
      )
    )

  # ---- Attach group names ----
  grp_names <- .anatomical_group_names()
  summary <- summary |>
    dplyr::mutate(
      group_name = grp_names[.data$anatomical_group]
    )

  # Reorder columns
  summary <- summary |>
    dplyr::select(
      "anatomical_group",
      "group_name",
      "total_substances",
      "with_ddd",
      "pct_with_ddd"
    )

  summary
}


#' Compare DDD values for a drug across administration routes
#'
#' @description
#' Displays the Defined Daily Dose (DDD) values for a single drug across all
#' available administration routes in the WHO DDD Index. This is useful for
#' understanding how DDDs differ by route of administration.
#'
#' @param atc_code A single ATC code (character string, e.g.
#'   \code{"N02BE01"} for paracetamol).
#' @param data Optional pre-loaded DDD data frame. If \code{NULL}, the
#'   bundled database is loaded automatically.
#'
#' @return A \link[tibble]{tibble} with columns:
#'   \describe{
#'     \item{\code{atc_code}}{The ATC code.}
#'     \item{\code{atc_name}}{The drug name.}
#'     \item{\code{ddd}}{The DDD value.}
#'     \item{\code{uom}}{The unit of the DDD value.}
#'     \item{\code{adm_r}}{The administration route.}
#'     \item{\code{note}}{Additional notes.}
#'   }
#'   If no DDD entries are found, a message is printed and a 0-row tibble is
#'   returned invisibly.
#'
#' @examples
#' \donttest{
#' # Paracetamol — compare oral, parenteral, rectal DDDs
#' ddd_route_comparison("N02BE01")
#'
#' # Estradiol — multiple routes with differing DDDs
#' ddd_route_comparison("G03CA03")
#' }
#'
#' @seealso \code{\link{compute_ddd}} for DDD computation.
#' @export
ddd_route_comparison <- function(atc_code, data = NULL) {
  # ---- Input validation ----
  if (!is_scalar_character(atc_code)) {
    cli::cli_abort("{.arg atc_code} must be a single character string.")
  }

  target_code <- normalize_atc_code(atc_code)

  if (!atc_level(target_code) %in% c(4L, 5L)) {
    cli::cli_abort(paste(
      "{.arg atc_code} must be a Level 4 or Level 5 ATC code.",
      "Got {.val {target_code}} (Level {atc_level(target_code)})."
    ))
  }

  # ---- Load data ----
  ddd_data <- .load_ddd_data(data)

  # ---- Filter for the requested code ----
  result <- ddd_data |>
    dplyr::filter(.data$atc_code == target_code) |>
    dplyr::select(
      "atc_code",
      "atc_name",
      "ddd",
      "uom",
      "adm_r",
      "note"
    )

  if (nrow(result) == 0) {
    cli::cli_inform("No DDD entries found for ATC code {.val {atc_code}}.")
    return(tibble::tibble())
  }

  # Sort by adm_r for readability (NA routes last)
  result <- result |>
    dplyr::arrange(!is.na(.data$adm_r), .data$adm_r)

  tibble::as_tibble(result)
}
