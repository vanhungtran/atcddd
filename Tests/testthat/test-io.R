test_that("atc_write_csv writes outputs and manifest computes checksums", {
  tmp <- tempdir()
  res <- list(
    codes = tibble::tibble(
      atc_code = c("D01AA01","D01AA02"),
      atc_name = c("Nystatin","Levorin")
    ),
    ddd = tibble::tibble(
      source_code = c("D01AA01","D01AA01","D01AA02"),
      atc_code = c("D01AA01","D01AA01","D01AA02"),
      atc_name = c("Nystatin","Nystatin","Levorin"),
      ddd = c("1","0.5","2"), uom = c("g","g","g"),
      adm_r = c("O","P","O"), note = c(NA, "Alt route", NA)
    )
  )

  paths <- atc_write_csv(res, dir = tmp, stamp = FALSE)
  expect_true(all(file.exists(paths)))

  man <- atc_manifest(paths)
  expect_s3_class(man, "tbl_df")
  expect_equal(nrow(man), 2)
  expect_true(all(c("file","size","sha256") %in% names(man)))

  out <- atc_write_manifest(paths)
  expect_true(file.exists(out))
})
