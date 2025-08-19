test_that("atc_crawl returns expected structure on a short run (network)", {
  skip_network_tests()

  res <- atc_crawl(roots = "D", rate = 0.8, progress = FALSE, max_codes = 5, quiet = TRUE)

  expect_type(res, "list")
  expect_true(all(c("codes","ddd") %in% names(res)))
  expect_s3_class(res$codes, "tbl_df")
  expect_s3_class(res$ddd, "tbl_df")

  # Basic columns and types
  expect_true(all(c("atc_code","atc_name") %in% names(res$codes)))
  if (nrow(res$ddd)) {
    expect_true(all(c("source_code","atc_code") %in% names(res$ddd)))
  }
})
