# Clean up any stale man pages
unlink("man", recursive = TRUE)
dir.create("man")

# Regenerate namespace + docs
devtools::document()

# Rebuild vignettes (after fixing title)
devtools::build_vignettes()

# Run tests from source (should pass)
devtools::test()

# Full check
devtools::check()


usethis::use_github_release()
