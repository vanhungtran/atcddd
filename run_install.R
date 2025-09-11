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


usethis::use_git_remote("origin", "https://github.com/vanhungtran/atcddd.git", overwrite = TRUE)
gert::git_push(remote = "origin", set_upstream = TRUE)


if (!("git2r" %in% installed.packages()[,"Package"])) {
  install.packages("git2r")
}






# Load the library
library(git2r)

# Set the path to your repository (change this to your repo path)
repo_path <- here::here()
repo <- repository(repo_path)

# Stage files (add all changes)
add(repo, "*")

# Commit changes with a message
commit(repo,paste0( "New update - ", date()))







usethis::use_git_remote("origin", "https://github.com/vanhungtran/atcddd.git", overwrite = TRUE)
gert::git_push(remote = "origin", set_upstream = TRUE)
