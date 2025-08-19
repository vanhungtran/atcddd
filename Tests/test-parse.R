test_that("is_valid_atc_code works", {
  expect_true(is_valid_atc_code("A"))
  expect_true(is_valid_atc_code("L01"))
  expect_false(is_valid_atc_code("a"))
  expect_false(is_valid_atc_code(""))
})
