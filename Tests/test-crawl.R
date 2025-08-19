test_that("atc_crawl returns expected structure", {
  skip_on_cran()
  skip_on_ci()  # flip if you record fixtures with httptest2

  res <- atc_crawl(roots = "D", rate = 0.8, progress = FALSE, max_codes = 5)
  expect_type(res, "list")
  expect_true(all(c("codes","ddd") %in% names(res)))
  expect_s3_class(res$codes, "tbl_df")
  expect_s3_class(res$ddd, "tbl_df")
})
