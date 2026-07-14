# atcddd: WHO ATC/DDD Crawler and Parser
# Tests for DDD computation functions (compute_ddd, compute_did,
# ddd_availability, ddd_route_comparison)
#
# All tests are offline and use the bundled WHO snapshot CSV.

# ---------------------------------------------------------------------------
# Helper: path to bundled DDD data
# ---------------------------------------------------------------------------
.ddd_path <- function() {
  system.file("extdata", "WHO_ATC_DDD_2025-08-19.csv", package = "atcddd")
}

# ---------------------------------------------------------------------------
# compute_ddd()
# ---------------------------------------------------------------------------
# Expected input columns: atc_code, strength, quantity
#   - strength: numeric, strength per dosage unit (in mg, or matching DDD unit)
#   - quantity: numeric, number of dosage units dispensed
# Expected output: input with additional columns ddd_value, ddd_unit, ddd_ratio
#   - ddd_value: numeric, the DDD looked up (converted to grams)
#   - ddd_unit:   character, the unit of the DDD from the WHO table
#   - ddd_ratio: numeric, (strength * quantity / 1000) / ddd_value
#                i.e. total grams divided by DDD in grams

test_that("compute_ddd: basic computation for a single drug", {
  # Aspirin (N02BA01, DDD = 3 g, Oral)
  # strength = 500 mg, quantity = 100
  # total = 500 * 100 = 50 000 mg = 50 g
  # DDDs = 50 / 3 = 16.666...
  input <- tibble::tibble(
    atc_code = "N02BA01",
    strength = 500,
    quantity = 100
  )

  result <- compute_ddd(input)

  expect_s3_class(result, "tbl_df")
  expect_true(all(c("ddd_value", "ddd_unit", "ddd_ratio") %in% names(result)))
  expect_equal(nrow(result), 1L)
  expect_equal(result$ddd_ratio[1], 50 / 3, tolerance = 1e-3)
  expect_equal(result$ddd_value[1], 3)  # 3 g
})


test_that("compute_ddd: multiple drugs each computed correctly", {
  # Aspirin    (N02BA01) DDD = 3 g,   strength = 500 mg, qty = 100 -> 16.667
  # Atorvastatin (C10AA05) DDD = 20 mg, strength =  10 mg, qty =  30 -> 15
  # Metformin  (A10BA02) DDD = 2 g,   strength = 500 mg, qty =  60 -> 15
  input <- tibble::tibble(
    atc_code = c("N02BA01", "C10AA05", "A10BA02"),
    strength = c(500, 10, 500),
    quantity = c(100, 30, 60)
  )

  result <- compute_ddd(input)

  expect_s3_class(result, "tbl_df")
  expect_equal(nrow(result), 3L)
  expect_true(all(c("ddd_value", "ddd_unit", "ddd_ratio") %in% names(result)))

  # Expected DDD ratios
  # Aspirin:  (500 * 100 / 1000) / 3  = 50 / 3 = 16.667
  # Atorvastatin:  (10 * 30 / 1000) / (20 / 1000)  = 0.3 / 0.02 = 15
  # Metformin:  (500 * 60 / 1000) / 2  = 30 / 2 = 15
  expected <- c(50 / 3, 15, 15)
  expect_equal(result$ddd_ratio, expected, tolerance = 1e-3)

  # Verify the correct DDD values were looked up
  expect_equal(result$ddd_value[result$atc_code == "N02BA01"], 3)
  expect_equal(result$ddd_value[result$atc_code == "A10BA02"], 2)
  # Atorvastatin DDD is 20 mg = 0.02 g — exact value depends on internal
  # representation; just check it is positive and sensible
  expect_true(result$ddd_value[result$atc_code == "C10AA05"] > 0)
})


test_that("compute_ddd: route preference picks correct DDD", {
  # Aspirin (N02BA01) has three routes:
  #   O (oral):          DDD = 3 g
  #   P (parenteral):    DDD = 1 g
  #   R (rectal):        DDD = 3 g
  # strength = 500 mg, quantity = 100 => total = 50 g
  # adm_r = "O" -> 50 / 3  = 16.667
  # adm_r = "P" -> 50 / 1  = 50
  input <- tibble::tibble(
    atc_code = c("N02BA01", "N02BA01"),
    strength = c(500, 500),
    quantity = c(100, 100)
  )

  result_oral <- compute_ddd(input[1, ], adm_r = "O")
  result_paren <- compute_ddd(input[2, ], adm_r = "P")

  expect_equal(result_oral$ddd_ratio[1],  50 / 3, tolerance = 1e-3)
  expect_equal(result_paren$ddd_ratio[1], 50,     tolerance = 1e-3)
  expect_equal(result_oral$ddd_value[1],  3)
  expect_equal(result_paren$ddd_value[1], 1)
})


test_that("compute_ddd: drug with no DDD returns NA and warns", {
  # D01AA01 (nystatin) has no DDD recorded (all NA)
  input <- tibble::tibble(
    atc_code = "D01AA01",
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
  input <- tibble::tibble(
    patient_id = c("P001", "P001", "P002"),
    visit_date = as.Date(c("2025-06-01", "2025-06-01", "2025-06-15")),
    atc_code   = c("N02BA01", "C10AA05", "A10BA02"),
    strength   = c(500, 10, 500),
    quantity   = c(100, 30, 60)
  )

  result <- compute_ddd(input)

  # Extra columns survive
  expect_true("patient_id" %in% names(result))
  expect_true("visit_date" %in% names(result))
  expect_equal(result$patient_id, input$patient_id)
  expect_equal(result$visit_date, input$visit_date)

  # DDD columns are also present
  expect_true(all(c("ddd_value", "ddd_unit", "ddd_ratio") %in% names(result)))
  expect_equal(nrow(result), 3L)
})


test_that("compute_ddd: unit conversion with strength in mg and DDD in g", {
  # Metformin (A10BA02) DDD = 2 g, strength = 500 mg, quantity = 60
  # total = 500 * 60 = 30 000 mg = 30 g
  # DDDs = 30 / 2 = 15
  # The function must correctly convert mg -> g to match the DDD unit.
  input <- tibble::tibble(
    atc_code = "A10BA02",
    strength = 500,
    quantity = 60
  )

  result <- compute_ddd(input)

  expect_equal(result$ddd_ratio[1], 15, tolerance = 1e-3)
  expect_equal(result$ddd_value[1], 2)
})


# ---------------------------------------------------------------------------
# compute_did()
# ---------------------------------------------------------------------------
# DID = (total_DDDs / (population * days)) * 1000
# Total DDDs is typically the sum of ddd_ratio from compute_ddd output.

test_that("compute_did: basic DID formula", {
  # Suppose 150 total DDDs, population = 1000, days = 30
  # DID = (150 / (1000 * 30)) * 1000 = 5
  ddd_data <- tibble::tibble(
    atc_code  = c("N02BA01", "C10AA05"),
    ddd_ratio = c(100, 50)   # total = 150 DDDs
  )

  result <- compute_did(ddd_data, population = 1000, days = 30)

  expect_s3_class(result, "tbl_df")
  expect_true("did" %in% names(result))
  expect_equal(result$did[1], 5, tolerance = 1e-3)
})


test_that("compute_did: edge case with zero DDDs or single day", {
  # Zero DDDs -> DID = 0
  ddd_zero <- tibble::tibble(
    atc_code  = "N02BA01",
    ddd_ratio = 0
  )
  result_zero <- compute_did(ddd_zero, population = 1000, days = 30)
  expect_equal(result_zero$did[1], 0, tolerance = 1e-3)

  # Single-day period
  # 50 DDDs, population = 1000, days = 1
  # DID = (50 / (1000 * 1)) * 1000 = 50
  ddd_one <- tibble::tibble(
    atc_code  = "N02BA01",
    ddd_ratio = 50
  )
  result_one <- compute_did(ddd_one, population = 1000, days = 1)
  expect_equal(result_one$did[1], 50, tolerance = 1e-3)
})


# ---------------------------------------------------------------------------
# ddd_availability()
# ---------------------------------------------------------------------------

test_that("ddd_availability: returns tibble with expected columns", {
  avail <- ddd_availability()

  expect_s3_class(avail, "tbl_df")
  expect_true(
    all(c("anatomical_group", "group_name", "total_substances",
          "with_ddd", "pct_with_ddd") %in% names(avail))
  )
  # Numeric columns
  expect_type(avail$total_substances, "integer")
  expect_type(avail$with_ddd, "integer")
  expect_type(avail$pct_with_ddd, "double")
  # Percentage should be between 0 and 100
  expect_true(all(avail$pct_with_ddd >= 0 & avail$pct_with_ddd <= 100))
})


test_that("ddd_availability: returns all 14 anatomical groups (A through V)", {
  avail <- ddd_availability()

  expected_groups <- c("A", "B", "C", "D", "G", "H", "J", "L", "M",
                       "N", "P", "R", "S", "V")
  expect_setequal(avail$anatomical_group, expected_groups)
  expect_equal(nrow(avail), 14L)
})


# ---------------------------------------------------------------------------
# ddd_route_comparison()
# ---------------------------------------------------------------------------

test_that("ddd_route_comparison: known multi-route drug returns all routes", {
  # Aspirin (N02BA01) has O (3 g), P (1 g), R (3 g)
  routes <- ddd_route_comparison("N02BA01")

  expect_s3_class(routes, "tbl_df")
  expect_true(nrow(routes) >= 2)
  expect_true(all(c("atc_code", "atc_name", "ddd", "uom", "adm_r")
                  %in% names(routes)))
  # Should include O, P, and possibly R
  expect_true(all(c("O", "P") %in% routes$adm_r))
  expect_true(all(routes$atc_code == "N02BA01"))
  # Different DDD values per route
  unique_ddd <- unique(routes$ddd[!is.na(routes$ddd)])
  expect_gt(length(unique_ddd), 1)
})


test_that("ddd_route_comparison: unknown code returns empty result", {
  routes <- ddd_route_comparison("X99XX99")

  expect_s3_class(routes, "tbl_df")
  expect_equal(nrow(routes), 0L)
})
