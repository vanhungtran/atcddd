test_that("parse_children extracts and filters child codes correctly", {
  html <- xml2::read_html(fake_parent_html("D01A"))
  kids <- parse_children(html, "D01A")

  expect_s3_class(kids, "tbl_df")
  expect_true(all(c("atc_code","atc_name") %in% names(kids)))
  expect_true(all(stringr::str_starts(kids$atc_code, "D01A")))
  expect_setequal(kids$atc_code, c("D01A01","D01A02"))
})

test_that("parse_ddd_table reads and fills DDD rows", {
  html <- xml2::read_html(fake_leaf_html())
  ddd <- parse_ddd_table(html)

  expect_s3_class(ddd, "tbl_df")
  # Expected columns (some may be absent on odd pages; parser keeps what exists)
  expect_true(all(c("atc_code","atc_name","ddd","uom","adm_r","note") %in% names(ddd)))
  # Fill-down should make atc_code present on all rows
  expect_false(any(is.na(ddd$atc_code)))
  # First two rows should share same code/name after fill-down
  expect_equal(ddd$atc_code[1], ddd$atc_code[2])
  expect_equal(ddd$atc_name[1], ddd$atc_name[2])
})
