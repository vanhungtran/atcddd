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
#' Crawl, parse, search, and compute with the World Health Organization's
#' Anatomical Therapeutic Chemical (ATC) classification system and Defined
#' Daily Dose (DDD) Index. This package provides a complete toolkit for
#' pharmacoepidemiology, drug utilisation research, and clinical data
#' science.
#'
#' **The package ships with no WHO data.** Use [atc_download()] to retrieve
#' the current ATC/DDD Index from the WHO Collaborating Centre. Data are
#' cached locally for offline use across sessions.
#'
#' @section Main Features:
#' \itemize{
#'   \item \strong{Data Download}: [atc_download()] retrieves the WHO index
#'     to your local user-cache directory for persistent offline use.
#'   \item \strong{Web Crawling}: [atc_crawl()] for low-level iterative
#'     traversal of the ATC hierarchy with configurable rate limiting.
#'   \item \strong{Drug Name Search}: [search_drug()], [fuzzy_match_drug()],
#'     and [resolve_atc()] for offline drug-name-to-ATC-code resolution
#'     with brand-name synonyms and typo-tolerant matching.
#'   \item \strong{Clinical Text Extraction}: [atc_from_text()] extracts
#'     drug names from free-text clinical notes.
#'   \item \strong{DDD Computation}: [compute_ddd()] and [compute_did()]
#'     convert prescription data into Defined Daily Doses and DDDs per
#'     1000 inhabitants per day.
#'   \item \strong{Hierarchy Navigation}: [atc_children()],
#'     [atc_descendants()], [atc_parent()], and [atc_level()] for
#'     exploring the five-level ATC classification tree.
#'   \item \strong{Reproducibility}: [atc_manifest()] generates SHA256
#'     checksums for downloaded data files.
#' }
#'
#' @section Getting Started:
#' \preformatted{
#' library(atcddd)
#'
#' # Step 1: Download the WHO ATC/DDD Index (required, one-time)
#' atc_download()
#'
#' # Step 2: Search, resolve, compute — all offline from here
#' resolve_atc("aspirin")
#' search_drug("statin")
#' atc_children("N02", atc_load_db()$codes)
#' }
#'
#' @section Data Copyright:
#' **Data source:** ATC/DDD Index, © WHO Collaborating Centre for Drug
#' Statistics Methodology. Available from \url{https://atcddd.fhi.no/}
#' subject to the provider's terms of use. The data are not distributed
#' with this package. Downloaded data retain the original copyright.
#' See \url{https://www.whocc.no/use_of_atc_ddd/} for details.
#'
#' @author Lucas VHH TRAN \email{tranhungydhcm@@gmail.com}
#'
#' @seealso
#' \itemize{
#'   \item WHO ATC/DDD Index: \url{https://www.whocc.no/atc_ddd_index/}
#'   \item Package Repository: \url{https://github.com/vanhungtran/atcddd}
#'   \item \code{\link{atc_download}} to acquire the data
#'   \item \code{\link{atc_load_db}} to load cached data
#' }
#'
#' @keywords internal
#' @importFrom rlang .data
"_PACKAGE"
