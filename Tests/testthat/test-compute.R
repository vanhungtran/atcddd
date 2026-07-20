# atcddd: WHO ATC/DDD Crawler and Parser
# Tests for DDD computation functions (compute_ddd, compute_did,
# ddd_availability, ddd_route_comparison)
#
# All tests use synthetic test fixtures (inst/extdata/synthetic_ddd.csv).
# No real WHO data is distributed with this package.

# ---------------------------------------------------------------------------
# Helper: load synthetic DDD data into the search environment
# ---------------------------------------------------------------------------
.load_synthetic_ddd <- function() {
  # Bypass atc_load_db (which requires cached WHO data) and load
  # synthetic fixtures directly into the in-memory environment.
  ddd_path <- system.file("extdata", "synthetic_ddd.csv", package = "atcddd")
  codes_path <- system.file("extdata", "synthetic_codes.csv", package = "atcddd")

  if (!file.exists(ddd_path) || !file.exists(codes_path)) {
    skip("Synthetic test fixtures not found")
  }

  ddd <- readr::read_csv(ddd_path, show_col_types = FALSE, progress = FALSE) |>
    dplyr::mutate(ddd_numeric = suppressWarnings(as.numeric(.data$ddd)))

  codes <- readr::read_csv(codes_path, show_col_types = FALSE, progress = FALSE) |>
    dplyr::mutate(
      atc_name_lower = tolower(.data$atc_name),
      atc_name_clean = stringr::str_squish(tolower(.data$atc_name)),
      level          = atc_level(.data$atc_code)
    )

  # Inject into the package's search environment
  atcddd:::.atc_search_env$codes <- codes
  atcddd:::.atc_search_env$ddd   <- ddd

  invisible(list(codes = codes, ddd = ddd))
}

# ---------------------------------------------------------------------------
# compute_ddd()
# ---------------------------------------------------------------------------

test_that("compute_ddd: basic computation for a single drug (synthetic data)", {
  .load_synthetic_ddd()

  # testolone (X01AA01, DDD = 1 g, Oral)
  # strength = 500 mg, quantity = 100
  # total = 500 * 100 = 50 000 mg = 50 g
  # DDDs = 50 / 1 = 50
  input <- tibble::tibble(
    atc_code = "X01AA01",
    strength = 500,
    quantity = 100
  )

  result <- compute_ddd(input)

  expect_s3_class(result, "tbl_df")
  expect_true(all(c("ddd_value", "ddd_unit", "ddd_ratio") %in% names(result)))
  expect_equal(nrow(result), 1L)
  expect_equal(result$ddd_ratio[1], 50, tolerance = 1e-3)
  expect_equal(result$ddd_value[1], 1)  # 1 g
})


test_that("compute_ddd: multiple drugs each computed correctly", {
  .load_synthetic_ddd()

  # testolone  (X01AA01) DDD = 1 g,   strength = 500 mg, qty = 100 -> 50
  # fictimab   (X01AA02) DDD = 10 mg, strength =  10 mg, qty =  30 -> 30
  # placebomab (X01AB01) DDD = 20 mg, strength =  20 mg, qty =  60 -> 60
  input <- tibble::tibble(
    atc_code = c("X01AA01", "X01AA02", "X01AB01"),
    strength = c(500, 10, 20),
    quantity = c(100, 30, 60)
  )

  result <- compute_ddd(input)

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 3L)
  expect_true(all(c("ddd_value", "ddd_unit", "ddd_ratio") %in% names(result)))

  # testolone:  (500 * 100 / 1000) / 1  = 50
  # fictimab:   (10 * 30 / 1000) / (10 / 1000) = 0.3 / 0.01 = 30
  # placebomab: (20 * 60 / 1000) / (20 / 1000) = 1.2 / 0.02 = 60
  expected <- c(50, 30, 60)
  expect_equal(result$ddd_ratio, expected, tolerance = 1e-3)
})


test_that("compute_ddd: route preference picks correct DDD", {
  .load_synthetic_ddd()

  # testolone (X01AA01) has two routes:
  #   O (oral):      DDD = 1 g
  #   P (parenteral): DDD = 0.5 g
  # strength = 500 mg, quantity = 100 => total = 50 g
  # adm_r = "O" -> 50 / 1   = 50
  # adm_r = "P" -> 50 / 0.5 = 100
  input <- tibble::tibble(
    atc_code = c("X01AA01", "X01AA01"),
    strength = c(500, 500),
    quantity = c(100, 100)
  )

  result_oral <- compute_ddd(input[1, ], adm_r = "O")
  result_paren <- compute_ddd(input[2, ], adm_r = "P")

  expect_equal(result_oral$ddd_ratio[1],  50,  tolerance = 1e-3)
  expect_equal(result_paren$ddd_ratio[1], 100, tolerance = 1e-3)
  expect_equal(result_oral$ddd_value[1],  1)
  expect_equal(result_paren$ddd_value[1], 0.5)
})


test_that("compute_ddd: drug with no DDD returns NA and warns", {
  .load_synthetic_ddd()

  # X99XX99 does not exist in synthetic fixtures
  input <- tibble::tibble(
    atc_code = "X99XX99",
    strength = 100,
    quantity = 1
  )

  expect_warning(
    result <- compute_ddd(input),
    regexp = "No DDD"
  )

  expect_s3_class(result, "tbl_df")
  expect_true(is.na(result$ddd_value[1]) || is.na(result$ddd_ratio[1]))
})


test_that("compute_ddd: extra columns are preserved in output", {
  .load_synthetic_ddd()

  input <- tibble::tibble(
    patient_id = c("P001", "P001", "P002"),
    visit_date = as.Date(c("2025-06-01", "2025-06-01", "2025-06-15")),
    atc_code   = c("X01AA01", "X01AA02", "X01AB01"),
    strength   = c(500, 10, 20),
    quantity   = c(100, 30, 60)
  )

  result <- compute_ddd(input)

  expect_true("patient_id" %in% names(result))
  expect_true("visit_date" %in% names(result))
  expect_equal(result$patient_id, input$patient_id)
  expect_equal(result$visit_date, input$visit_date)
  expect_true(all(c("ddd_value", "ddd_unit", "ddd_ratio") %in% names(result)))
  expect_equal(nrow(result), 3L)
})


test_that("compute_ddd: unit conversion with strength in mg and DDD in g", {
  .load_synthetic_ddd()

  # testolone (X01AA01) DDD = 1 g, strength = 500 mg, quantity = 60
  # total = 500 * 60 = 30 000 mg = 30 g
  # DDDs = 30 / 1 = 30
  input <- tibble::tibble(
    atc_code = "X01AA01",
    strength = 500,
    quantity = 60
  )

  result <- compute_ddd(input)

  expect_equal(result$ddd_ratio[1], 30, tolerance = 1e-3)
  expect_equal(result$ddd_value[1], 1)
})


# ---------------------------------------------------------------------------
# compute_did()
# ---------------------------------------------------------------------------

test_that("compute_did: basic DID formula", {
  ddd_data <- tibble::tibble(
    atc_code  = c("X01AA01", "X01AA02"),
    ddd_ratio = c(100, 50)
  )

  result <- compute_did(ddd_data, population = 1000, days = 30)

  expect_s3_class(result, "tbl_df")
  expect_true("did" %in% names(result))
  expect_equal(result$did[1], 5, tolerance = 1e-3)
})


test_that("compute_did: edge case with zero DDDs or single day", {
  ddd_zero <- tibble::tibble(
    atc_code  = "X01AA01",
    ddd_ratio = 0
  )
  result_zero <- compute_did(ddd_zero, population = 1000, days = 30)
  expect_equal(result_zero$did[1], 0, tolerance = 1e-3)

  ddd_one <- tibble::tibble(
    atc_code  = "X01AA01",
    ddd_ratio = 50
  )
  result_one <- compute_did(ddd_one, population = 1000, days = 1)
  expect_equal(result_one$did[1], 50, tolerance = 1e-3)
})


# ---------------------------------------------------------------------------
# ddd_availability()
# ---------------------------------------------------------------------------

test_that("ddd_availability: returns tibble with expected columns", {
  .load_synthetic_ddd()

  avail <- ddd_availability()

  expect_s3_class(avail, "tbl_df")
  expect_true(
    all(c("anatomical_group", "group_name", "total_substances",
          "with_ddd", "pct_with_ddd") %in% names(avail))
  )
  expect_type(avail$total_substances, "integer")
  expect_type(avail$with_ddd, "integer")
  expect_type(avail$pct_with_ddd, "double")
  expect_true(all(avail$pct_with_ddd >= 0 & avail$pct_with_ddd <= 100))
})


test_that("ddd_availability: synthetic data covers expected groups", {
  .load_synthetic_ddd()

  avail <- ddd_availability()

  # Synthetic fixture uses X prefix; expect at least group X
  expect_true("X" %in% avail$anatomical_group)
})


# ---------------------------------------------------------------------------
# ddd_route_comparison()
# ---------------------------------------------------------------------------

test_that("ddd_route_comparison: known multi-route drug returns all routes", {
  .load_synthetic_ddd()

  # testolone (X01AA01) has O (1 g) and P (0.5 g)
  routes <- ddd_route_comparison("X01AA01")

  expect_s3_class(routes, "tbl_df")
  expect_true(nrow(routes) >= 2)
  expect_true(all(c("atc_code", "atc_name", "ddd", "uom", "adm_r")
                  %in% names(routes)))
  expect_true(all(c("O", "P") %in% routes$adm_r))
  expect_true(all(routes$atc_code == "X01AA01"))
})


test_that("ddd_route_comparison: unknown code returns empty result", {
  .load_synthetic_ddd()

  routes <- ddd_route_comparison("X99XX99")

  expect_s3_class(routes, "tbl_df")
  expect_equal(nrow(routes), 0L)
})
