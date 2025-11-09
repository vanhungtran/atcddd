# atcddd: WHO ATC/DDD Crawler and Parser
# Version 0.1.0
# Copyright (C) 2025 Lucas VHH TRAN
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the MIT License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# MIT License for more details.
#
# You should have received a copy of the MIT License
# along with this program. If not, see <https://opensource.org/licenses/MIT>.

#' atcddd: WHO ATC/DDD Crawler and Parser
#'
#' @description
#' Crawl and parse the WHO ATC/DDD index (whocc.no) into tidy tables with
#' robust HTTP (retries, timeouts, user agent), on-disk caching, rate limiting,
#' iterative traversal, resilient parsing, and checksum manifests for reproducibility.
#'
#' This package provides tools for working with the World Health Organization's
#' Anatomical Therapeutic Chemical (ATC) classification system and Defined Daily
#' Dose (DDD) values for medications. It enables researchers and healthcare
#' professionals to systematically retrieve, parse, and analyze pharmaceutical
#' classification data.
#'
#' @section Main Features:
#' \itemize{
#'   \item \strong{Web Crawling}: Automated retrieval from WHO ATC/DDD index
#'   \item \strong{Caching}: Filesystem-based caching to minimize HTTP requests
#'   \item \strong{Rate Limiting}: Respectful crawling with configurable delays
#'   \item \strong{Reproducibility}: SHA256 checksums and manifest generation
#'   \item \strong{Robust Parsing}: Handles malformed HTML and missing data
#' }
#'
#' @section Core Functions:
#' \itemize{
#'   \item \code{\link{atc_crawl}}: Crawl ATC/DDD index from specified roots
#'   \item \code{\link{atc_write_csv}}: Export results to CSV files
#'   \item \code{\link{atc_manifest}}: Generate checksums for reproducibility
#' }
#'
#' @author Lucas VHH TRAN \email{tranhungydhcm@@gmail.com}
#'
#' @seealso
#' \itemize{
#'   \item WHO ATC/DDD Index: \url{https://www.whocc.no/atc_ddd_index/}
#'   \item Package Repository: \url{https://github.com/vanhungtran/atcddd}
#' }
#'
#' @keywords internal
#' @importFrom rlang .data
"_PACKAGE"
