# Helper: skip network-dependent tests on CRAN/CI or when NO_INTERNET is set
skip_network_tests <- function() {
  testthat::skip_on_cran()
  testthat::skip_on_ci()
  if (nzchar(Sys.getenv("NO_INTERNET"))) testthat::skip("Skipping network tests (NO_INTERNET set).")
}

# Small HTML fixtures to unit-test parsers without hitting the network
fake_parent_html <- function(parent_code = "D") {
  sprintf('
    <html><body>
      <a href="/atc_ddd_index/?code=%s01">Child One</a>
      <a href="/atc_ddd_index/?code=%s02">Child Two</a>
      <a href="/atc_ddd_index/?code=%s">Self (should be ignored)</a>
      <a href="/atc_ddd_index/?code=X99">Other Branch (ignored)</a>
    </body></html>
  ', parent_code, parent_code, parent_code)
}

fake_leaf_html <- function() {
  # Table repeats ATC code/name only in first row; others blank -> should fill down
  '
  <html><body>
    <table>
      <thead>
        <tr><th>ATC code</th><th>Name</th><th>DDD</th><th>U</th><th>Adm.R</th><th>Note</th></tr>
      </thead>
      <tbody>
        <tr><td>D01AA01</td><td>Nystatin</td><td>1</td><td>g</td><td>O</td><td></td></tr>
        <tr><td></td><td></td><td>0.5</td><td>g</td><td>P</td><td>Alt route</td></tr>
        <tr><td>D01AA02</td><td>Levorin</td><td>2</td><td>g</td><td>O</td><td></td></tr>
      </tbody>
    </table>
  </body></html>
  '
}
