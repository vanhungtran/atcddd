# Contributing to atcddd

Thank you for considering contributing to `atcddd`! We welcome
contributions from the R and health data science community.

## How to Contribute

### 1. Report Bugs

Open an issue on [GitHub
Issues](https://github.com/vanhungtran/atcddd/issues):

- Use a clear, descriptive title
- Include a minimal reproducible example
- Describe expected vs. actual behavior
- Note your R version, operating system, and package version
  (`packageVersion("atcddd")`)

### 2. Suggest Features

Propose enhancements via GitHub Issues:

- Explain the use case and why it would benefit others
- Provide example workflows if possible
- Tag with “enhancement” label

### 3. Submit Pull Requests

1.  Fork the repository
2.  Create a feature branch (`git checkout -b feature/amazing-feature`)
3.  Make your changes with tests
4.  Run
    [`devtools::test()`](https://devtools.r-lib.org/reference/test.html)
    to ensure all tests pass
5.  Run
    [`devtools::document()`](https://devtools.r-lib.org/reference/document.html)
    to regenerate documentation
6.  Commit and push, then submit a PR with a clear description

### 4. Improve Documentation

- Fix typos or clarify examples
- Add vignettes for advanced use cases
- Improve function documentation

## Development Guidelines

### Code Style

- Follow the [tidyverse style guide](https://style.tidyverse.org/)
- Use `snake_case` for function and variable names
- Prefix internal functions with `.` (dot)

### Testing

- All new functionality must include testthat tests
- Tests must not require network access (use bundled data)
- Run
  [`devtools::test()`](https://devtools.r-lib.org/reference/test.html)
  before submitting

### Documentation

- All exported functions must have complete roxygen2 documentation
- Include `@examples` with `\donttest{}` for API-dependent examples
- Regenerate docs with
  [`devtools::document()`](https://devtools.r-lib.org/reference/document.html)

### Package Dependencies

- Minimize dependencies — prefer base R where practical
- Only use packages listed in DESCRIPTION Imports
- Suggest heavy packages (like ggplot2) in Suggests, not Imports

## Code of Conduct

Please note that this project follows a [Contributor Code of
Conduct](https://vanhungtran.github.io/atcddd/CODE_OF_CONDUCT.md). By
participating, you agree to abide by its terms.
