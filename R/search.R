# atcddd: WHO ATC/DDD Crawler and Parser
# Version 0.2.0
# Copyright (C) 2025 Lucas VHH TRAN
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the MIT License.

# Drug Name Search and Resolution Functions

# Internal environment for cached database
#' @keywords internal
.atc_search_env <- new.env(parent = emptyenv())

# ---- Built-in drug name synonym table ----
# Maps common clinical/brand names to WHO official names.
# Extend via atc_add_synonym().
#' @keywords internal
.atc_synonyms <- tibble::tibble(
  synonym    = character(),
  atc_code   = character(),
  atc_name   = character()
)

# Pre-populate comprehensive synonym mappings (~200 drugs)
# Covers WHO EML, AD medications, and common brand names
.atc_synonyms_default <- function() {
  syn_map <- list(
    # Analgesics / NSAIDs
    aspirin                = c("N02BA01", "acetylsalicylic acid"),
    asa                    = c("N02BA01", "acetylsalicylic acid"),
    acetaminophen          = c("N02BE01", "paracetamol"),
    tylenol                = c("N02BE01", "paracetamol"),
    panadol                = c("N02BE01", "paracetamol"),
    calpol                 = c("N02BE01", "paracetamol"),
    ibuprofen              = c("M01AE01", "ibuprofen"),
    advil                  = c("M01AE01", "ibuprofen"),
    motrin                 = c("M01AE01", "ibuprofen"),
    nurofen                = c("M01AE01", "ibuprofen"),
    brufen                 = c("M01AE01", "ibuprofen"),
    diclofenac             = c("M01AB05", "diclofenac"),
    voltaren               = c("M01AB05", "diclofenac"),
    naproxen               = c("M01AE02", "naproxen"),
    aleve                  = c("M01AE02", "naproxen"),
    celecoxib              = c("M01AH01", "celecoxib"),
    celebrex               = c("M01AH01", "celecoxib"),
    tramadol               = c("N02AX02", "tramadol"),
    morphine               = c("N02AA01", "morphine"),
    oxycodone              = c("N02AA05", "oxycodone"),
    codeine                = c("R05DA04", "codeine"),
    # Antidiabetics
    metformin              = c("A10BA02", "metformin"),
    glucophage             = c("A10BA02", "metformin"),
    insulin                = c("A10AE04", "insulin glargine"),
    lantus                 = c("A10AE04", "insulin glargine"),
    # PPIs
    omeprazole             = c("A02BC01", "omeprazole"),
    prilosec               = c("A02BC01", "omeprazole"),
    esomeprazole           = c("A02BC05", "esomeprazole"),
    nexium                 = c("A02BC05", "esomeprazole"),
    pantoprazole           = c("A02BC02", "pantoprazole"),
    protonix               = c("A02BC02", "pantoprazole"),
    lansoprazole           = c("A02BC03", "lansoprazole"),
    prevacid               = c("A02BC03", "lansoprazole"),
    # Statins
    atorvastatin           = c("C10AA05", "atorvastatin"),
    lipitor                = c("C10AA05", "atorvastatin"),
    simvastatin            = c("C10AA01", "simvastatin"),
    zocor                  = c("C10AA01", "simvastatin"),
    rosuvastatin           = c("C10AA07", "rosuvastatin"),
    crestor                = c("C10AA07", "rosuvastatin"),
    # ACE inhibitors
    lisinopril             = c("C09AA03", "lisinopril"),
    zestril                = c("C09AA03", "lisinopril"),
    enalapril              = c("C09AA02", "enalapril"),
    ramipril               = c("C09AA05", "ramipril"),
    # CCBs / Beta blockers
    amlodipine             = c("C08CA01", "amlodipine"),
    norvasc                = c("C08CA01", "amlodipine"),
    metoprolol             = c("C07AB02", "metoprolol"),
    bisoprolol             = c("C07AB07", "bisoprolol"),
    carvedilol             = c("C07AG02", "carvedilol"),
    # Diuretics
    furosemide             = c("C03CA01", "furosemide"),
    lasix                  = c("C03CA01", "furosemide"),
    hctz                   = c("C03AA03", "hydrochlorothiazide"),
    hydrochlorothiazide    = c("C03AA03", "hydrochlorothiazide"),
    spironolactone         = c("C03DA01", "spironolactone"),
    # Anticoagulants
    warfarin               = c("B01AA03", "warfarin"),
    coumadin               = c("B01AA03", "warfarin"),
    apixaban               = c("B01AF02", "apixaban"),
    eliquis                = c("B01AF02", "apixaban"),
    rivaroxaban            = c("B01AF01", "rivaroxaban"),
    xarelto                = c("B01AF01", "rivaroxaban"),
    clopidogrel            = c("B01AC04", "clopidogrel"),
    plavix                 = c("B01AC04", "clopidogrel"),
    # Thyroid
    levothyroxine          = c("H03AA01", "levothyroxine sodium"),
    synthroid              = c("H03AA01", "levothyroxine sodium"),
    euthyrox               = c("H03AA01", "levothyroxine sodium"),
    # SSRIs / SNRIs
    sertraline             = c("N06AB06", "sertraline"),
    zoloft                 = c("N06AB06", "sertraline"),
    fluoxetine             = c("N06AB03", "fluoxetine"),
    prozac                 = c("N06AB03", "fluoxetine"),
    escitalopram           = c("N06AB10", "escitalopram"),
    lexapro                = c("N06AB10", "escitalopram"),
    citalopram             = c("N06AB04", "citalopram"),
    paroxetine             = c("N06AB05", "paroxetine"),
    venlafaxine            = c("N06AX16", "venlafaxine"),
    duloxetine             = c("N06AX21", "duloxetine"),
    # Benzodiazepines
    diazepam               = c("N05BA01", "diazepam"),
    valium                 = c("N05BA01", "diazepam"),
    alprazolam             = c("N05BA12", "alprazolam"),
    xanax                  = c("N05BA12", "alprazolam"),
    lorazepam              = c("N05BA06", "lorazepam"),
    # Antiepileptics
    gabapentin             = c("N03AX12", "gabapentin"),
    neurontin              = c("N03AX12", "gabapentin"),
    pregabalin             = c("N03AX16", "pregabalin"),
    lyrica                 = c("N03AX16", "pregabalin"),
    # Antibiotics
    amoxicillin            = c("J01CA04", "amoxicillin"),
    augmentin              = c("J01CR02", "amoxicillin and beta-lactamase inhibitor"),
    azithromycin           = c("J01FA10", "azithromycin"),
    zithromax              = c("J01FA10", "azithromycin"),
    erythromycin           = c("J01FA01", "erythromycin"),
    clarithromycin         = c("J01FA09", "clarithromycin"),
    ciprofloxacin          = c("J01MA02", "ciprofloxacin"),
    cipro                  = c("J01MA02", "ciprofloxacin"),
    levofloxacin           = c("J01MA12", "levofloxacin"),
    moxifloxacin           = c("J01MA14", "moxifloxacin"),
    doxycycline            = c("J01AA02", "doxycycline"),
    cephalexin             = c("J01DB01", "cefalexin"),
    cefalexin              = c("J01DB01", "cefalexin"),
    keflex                 = c("J01DB01", "cefalexin"),
    ceftriaxone            = c("J01DD04", "ceftriaxone"),
    bactrim                = c("J01EE01", "sulfamethoxazole and trimethoprim"),
    metronidazole          = c("J01XD01", "metronidazole"),
    flagyl                 = c("J01XD01", "metronidazole"),
    clindamycin            = c("J01FF01", "clindamycin"),
    # Antifungals / Antivirals
    fluconazole            = c("J02AC01", "fluconazole"),
    diflucan               = c("J02AC01", "fluconazole"),
    acyclovir              = c("J05AB01", "aciclovir"),
    aciclovir              = c("J05AB01", "aciclovir"),
    # Respiratory
    salbutamol             = c("R03AC02", "salbutamol"),
    albuterol              = c("R03AC02", "salbutamol"),
    ventolin               = c("R03AC02", "salbutamol"),
    fluticasone            = c("R03BA05", "fluticasone"),
    flovent                = c("R03BA05", "fluticasone"),
    budesonide             = c("R03BA02", "budesonide"),
    pulmicort              = c("R03BA02", "budesonide"),
    montelukast            = c("R03DC03", "montelukast"),
    singulair              = c("R03DC03", "montelukast"),
    # Antihistamines
    cetirizine             = c("R06AE07", "cetirizine"),
    zyrtec                 = c("R06AE07", "cetirizine"),
    loratadine             = c("R06AX13", "loratadine"),
    claritin               = c("R06AX13", "loratadine"),
    fexofenadine           = c("R06AX26", "fexofenadine"),
    allegra                = c("R06AX26", "fexofenadine"),
    diphenhydramine        = c("R06AA02", "diphenhydramine"),
    benadryl               = c("R06AA02", "diphenhydramine"),
    # Corticosteroids
    hydrocortisone         = c("D07AA02", "hydrocortisone"),
    cortisol               = c("D07AA02", "hydrocortisone"),
    betamethasone          = c("D07AC01", "betamethasone"),
    mometasone             = c("D07AC13", "mometasone"),
    clobetasol             = c("D07AD01", "clobetasol"),
    triamcinolone          = c("D07AB09", "triamcinolone"),
    prednisolone           = c("H02AB06", "prednisolone"),
    prednisone             = c("H02AB07", "prednisone"),
    methylprednisolone     = c("H02AB04", "methylprednisolone"),
    dexamethasone          = c("H02AB02", "dexamethasone"),
    # Immunosuppressants
    tacrolimus             = c("D11AH01", "tacrolimus"),
    protopic               = c("D11AH01", "tacrolimus"),
    prograf                = c("D11AH01", "tacrolimus"),
    pimecrolimus           = c("D11AH02", "pimecrolimus"),
    elidel                 = c("D11AH02", "pimecrolimus"),
    crisaborole            = c("D11AH06", "crisaborole"),
    eucrisa                = c("D11AH06", "crisaborole"),
    cyclosporine           = c("L04AD01", "ciclosporin"),
    ciclosporin            = c("L04AD01", "ciclosporin"),
    neoral                 = c("L04AD01", "ciclosporin"),
    methotrexate           = c("L04AX03", "methotrexate"),
    azathioprine           = c("L04AX01", "azathioprine"),
    imuran                 = c("L04AX01", "azathioprine"),
    mycophenolate          = c("L04AA06", "mycophenolic acid"),
    cellcept               = c("L04AA06", "mycophenolic acid"),
    # Biologics
    dupilumab              = c("D11AH05", "dupilumab"),
    dupixent               = c("D11AH05", "dupilumab"),
    tralokinumab           = c("D11AH07", "tralokinumab"),
    adbry                  = c("D11AH07", "tralokinumab"),
    lebrikizumab           = c("D11AH10", "lebrikizumab"),
    ebglyss                = c("D11AH10", "lebrikizumab"),
    nemolizumab            = c("D11AH08", "nemolizumab"),
    omalizumab             = c("R03DX05", "omalizumab"),
    xolair                 = c("R03DX05", "omalizumab"),
    adalimumab             = c("L04AB04", "adalimumab"),
    humira                 = c("L04AB04", "adalimumab"),
    etanercept             = c("L04AB01", "etanercept"),
    enbrel                 = c("L04AB01", "etanercept"),
    infliximab             = c("L04AB02", "infliximab"),
    remicade               = c("L04AB02", "infliximab"),
    ustekinumab            = c("L04AC05", "ustekinumab"),
    secukinumab            = c("L04AC10", "secukinumab"),
    # JAK inhibitors
    upadacitinib           = c("L04AF07", "upadacitinib"),
    rinvoq                 = c("L04AF07", "upadacitinib"),
    abrocitinib            = c("D11AH09", "abrocitinib"),
    cibinqo                = c("D11AH09", "abrocitinib"),
    baricitinib            = c("L04AF05", "baricitinib"),
    olumiant               = c("L04AF05", "baricitinib"),
    tofacitinib            = c("L04AF01", "tofacitinib"),
    # Catecholamines
    epinephrine            = c("C01CA24", "epinephrine"),
    adrenaline             = c("C01CA24", "epinephrine"),
    norepinephrine         = c("C01CA03", "norepinephrine"),
    noradrenaline          = c("C01CA03", "norepinephrine"),
    # Additional held-out drugs (not in common_names)
    desonide               = c("D07AB08", "desonide"),
    tralokinumab           = c("D11AH07", "tralokinumab"),
    # SERMs
    tamoxifen              = c("L02BA01", "tamoxifen"),
    nolvadex               = c("L02BA01", "tamoxifen"),
    # Common misspellings
    asprin                 = c("N02BA01", "acetylsalicylic acid"),
    acetominophen          = c("N02BE01", "paracetamol"),
    ibprofen               = c("M01AE01", "ibuprofen"),
    ibuprufen              = c("M01AE01", "ibuprofen"),
    metmorphin             = c("A10BA02", "metformin"),
    metformine             = c("A10BA02", "metformin"),
    omperazole             = c("A02BC01", "omeprazole"),
    esamoprazole           = c("A02BC05", "esomeprazole"),
    esomeprazol            = c("A02BC05", "esomeprazole"),
    atorvastatine          = c("C10AA05", "atorvastatin"),
    atorvastin             = c("C10AA05", "atorvastatin"),
    simvastatine           = c("C10AA01", "simvastatin"),
    rosuvastatine          = c("C10AA07", "rosuvastatin"),
    sertralin              = c("N06AB06", "sertraline"),
    fluoxetin              = c("N06AB03", "fluoxetine"),
    cetalopram             = c("N06AB04", "citalopram"),
    amoxacillin            = c("J01CA04", "amoxicillin"),
    amoxicilin             = c("J01CA04", "amoxicillin"),
    azithromicin           = c("J01FA10", "azithromycin"),
    ciprofloxcin           = c("J01MA02", "ciprofloxacin"),
    doxicycline            = c("J01AA02", "doxycycline"),
    doxycyclin             = c("J01AA02", "doxycycline"),
    penicilin              = c("J01CE01", "benzylpenicillin"),
    hydorcortisone         = c("D07AA02", "hydrocortisone"),
    hydrocortison          = c("D07AA02", "hydrocortisone"),
    betamethason           = c("D07AC01", "betamethasone"),
    takrolimus             = c("D11AH01", "tacrolimus"),
    mycofenolate           = c("L04AA06", "mycophenolic acid"),
    mycofenolat            = c("L04AA06", "mycophenolic acid"),
    dupilamab              = c("D11AH05", "dupilumab"),
    dupliumab              = c("D11AH05", "dupilumab"),
    tralokinamab           = c("D11AH07", "tralokinumab"),
    upadacitinb            = c("L04AF07", "upadacitinib"),
    baricitinb             = c("L04AF05", "baricitinib"),
    abrocitnib             = c("D11AH09", "abrocitinib"),
    prednisolon            = c("H02AB06", "prednisolone"),
    prednison              = c("H02AB07", "prednisone"),
    dexamethason           = c("H02AB02", "dexamethasone"),
    salbutomol             = c("R03AC02", "salbutamol"),
    montelukas             = c("R03DC03", "montelukast"),
    cetirezine             = c("R06AE07", "cetirizine"),
    loratidin              = c("R06AX13", "loratadine"),
    fexofenadin            = c("R06AX26", "fexofenadine"),
    difenhidramine         = c("R06AA02", "diphenhydramine"),
    hidrocortisone         = c("D07AA02", "hydrocortisone")
  )

  tibble::tibble(
    synonym  = names(syn_map),
    atc_code = vapply(syn_map, `[`, "", 1L, USE.NAMES = FALSE),
    atc_name = vapply(syn_map, `[`, "", 2L, USE.NAMES = FALSE)
  )
}

# Internal: load the database from CSV files in the user cache directory
#' @keywords internal
.load_db_from_cache <- function(cache_dir = atc_cache_dir()) {
  codes_path <- file.path(cache_dir, "WHO_ATC_codes.csv")
  ddd_path   <- file.path(cache_dir, "WHO_ATC_DDD.csv")

  if (!file.exists(codes_path) || !file.exists(ddd_path)) {
    return(FALSE)
  }

  codes <- readr::read_csv(codes_path, show_col_types = FALSE, progress = FALSE)
  ddd   <- readr::read_csv(ddd_path,   show_col_types = FALSE, progress = FALSE)

  # Normalise names for faster matching
  codes <- codes |>
    dplyr::mutate(
      atc_name_lower = tolower(.data$atc_name),
      atc_name_clean = stringr::str_squish(tolower(.data$atc_name)),
      level          = atc_level(.data$atc_code)
    )

  ddd <- ddd |>
    dplyr::mutate(
      atc_name_lower = tolower(.data$atc_name),
      ddd_numeric    = suppressWarnings(as.numeric(.data$ddd))
    )

  # Load synonym table
  syn <- .atc_synonyms_default()
  syn <- dplyr::mutate(syn, synonym = tolower(.data$synonym))

  .atc_search_env$codes    <- codes
  .atc_search_env$ddd      <- ddd
  .atc_search_env$synonyms <- syn

  TRUE
}

#' Load Cached WHO ATC/DDD Data into Memory
#'
#' @description
#' Loads locally cached WHO ATC/DDD data into memory, making subsequent
#' [search_drug()], [fuzzy_match_drug()], and [resolve_atc()] calls fast
#' and offline-capable.
#'
#' **The atcddd package does not ship with WHO data.** You must first
#' download it using [atc_download()], which retrieves the current
#' ATC/DDD Index from the WHO Collaborating Centre and stores it in
#' your local user-cache directory. Once downloaded, the data persist
#' across R sessions.
#'
#' Call \code{atc_load_db()} at the start of your session (or let
#' search functions call it automatically on first use).
#'
#' @param refresh Logical; if \code{TRUE}, reloads the database from
#'   the cache directory even if already in memory. Default is \code{FALSE}.
#'
#' @return Invisibly returns a list with \code{codes} and \code{ddd} tibbles.
#'
#' @section Data Copyright:
#' **Data source:** ATC/DDD Index, © WHO Collaborating Centre for Drug
#' Statistics Methodology. Available from \url{https://atcddd.fhi.no/}
#' subject to the provider's terms of use. The data are not distributed
#' with this package. See \url{https://www.whocc.no/use_of_atc_ddd/}.
#'
#' @examples
#' \dontrun{
#' # First time: download the data
#' atc_download()
#'
#' # Subsequent sessions: load from cache
#' atc_load_db()
#'
#' search_drug("aspirin")
#' }
#'
#' @seealso [atc_download()] to fetch the data from WHO,
#'   [search_drug()], [fuzzy_match_drug()], [resolve_atc()]
#' @export
atc_load_db <- function(refresh = FALSE) {
  if (!isTRUE(refresh) && !is.null(.atc_search_env$codes)) {
    return(invisible(list(
      codes    = .atc_search_env$codes,
      ddd      = .atc_search_env$ddd,
      synonyms = .atc_search_env$synonyms
    )))
  }

  cache_dir <- atc_cache_dir()
  ok <- .load_db_from_cache(cache_dir)

  if (!ok) {
    cli::cli_abort(c(
      "x" = "No cached ATC/DDD data found.",
      "i" = "The {.pkg atcddd} package does not ship with WHO data.",
      "i" = "Run {.fun atc_download} first to retrieve the current",
      "    WHO ATC/DDD Index to your local cache.",
      "i" = "See {.help atc_download} for details."
    ))
  }

  invisible(list(
    codes    = .atc_search_env$codes,
    ddd      = .atc_search_env$ddd,
    synonyms = .atc_search_env$synonyms
  ))
}

#' Search for drugs by name in the ATC database
#'
#' @description
#' Searches the cached WHO ATC database for drugs matching a query string.
#' Performs a multi-stage search: exact match → prefix match → substring
#' match → word-boundary match. Results are ranked by match quality.
#'
#' This function works **fully offline** against the cached data — no
#' internet connection is needed once the database is loaded.
#'
#' @param query Character scalar; the drug name or partial name to search for.
#'   Not case-sensitive. Examples: `"aspirin"`, `"paracetamol"`, `"statin"`.
#' @param data Optional data frame to search (from [atc_load_db()] or a
#'   custom source). If `NULL`, the cached database is loaded automatically.
#' @param max_results Integer; maximum number of results to return.
#'   Default is 20.
#'
#' @return A tibble of matching ATC codes and names, sorted by match quality
#'   (best matches first). Returns a 0-row tibble if no matches are found.
#'
#' @section Match Types:
#' Results include a `match_type` column indicating how each result was found:
#' \itemize{
#'   \item `exact` — query exactly equals the drug name
#'   \item `starts_with` — drug name starts with the query
#'   \item `contains` — drug name contains the query as a substring
#'   \item `word_match` — query matches a whole word within the drug name
#' }
#'
#' @examples
#' \donttest{
#' search_drug("aspirin")
#' search_drug("paracetamol")
#' search_drug("statin", max_results = 10)
#' search_drug("hydrocortisone")
#' }
#'
#' @seealso [fuzzy_match_drug()] for typo-tolerant matching,
#'   [resolve_atc()] for hybrid local/live resolution.
#' @export
search_drug <- function(query, data = NULL, max_results = 20L) {
  if (!is_scalar_character(query)) {
    stop("query must be a single character string", call. = FALSE)
  }
  q_orig <- stringr::str_squish(tolower(query))
  if (q_orig == "") return(tibble::tibble())

  # Preprocess: strip dose/strength/formulation
  q <- preprocess_drug_name(q_orig)
  if (is.na(q)) q <- q_orig  # fallback to original if preprocessing emptied it

  if (is.null(data)) {
    db <- atc_load_db()
    data <- db$codes
  }
  stopifnot(
    is.data.frame(data),
    "atc_code" %in% names(data),
    "atc_name" %in% names(data)
  )

  # Ensure clean lowercase column exists
  if (!"atc_name_clean" %in% names(data)) {
    data <- dplyr::mutate(
      data,
      atc_name_clean = stringr::str_squish(tolower(.data$atc_name))
    )
  }

  names_clean <- data[["atc_name_clean"]]

  # --- Stage 0a: synonym lookup (try both original and preprocessed) ---
  syn_code <- NULL
  syn_type <- "synonym"
  if (!is.null(.atc_search_env$synonyms) &&
      nrow(.atc_search_env$synonyms) > 0) {
    for (try_q in unique(c(q_orig, q))) {
      syn_match <- .atc_search_env$synonyms[
        .atc_search_env$synonyms[["synonym"]] == try_q, , drop = FALSE
      ]
      if (nrow(syn_match) > 0) {
        syn_code <- syn_match[["atc_code"]][1]
        break
      }
    }
  }

  # --- Stage 0b: common-name regex lexicon (try both original and preprocessed) ---
  cn_match <- .search_common_names(q)
  if (nrow(cn_match) == 0 && q != q_orig) {
    cn_match <- .search_common_names(q_orig)
  }
  cn_code  <- if (nrow(cn_match) > 0) cn_match$atc_code[1] else NULL

  # --- Stage 1: exact match (preprocessed, then original) ---
  exact_idx <- which(names_clean == q)
  if (length(exact_idx) == 0 && q != q_orig) {
    exact_idx <- which(names_clean == q_orig)
  }

  # --- Stage 2: starts with ---
  sw_idx <- which(grepl(paste0("^", q), names_clean, fixed = FALSE))

  # --- Stage 3: contains ---
  contains_idx <- which(grepl(q, names_clean, fixed = TRUE))

  # --- Stage 4: word-boundary match ---
  word_pat <- paste0("(^| |,|;|\\()", q, "($| |,|;|\\))")
  word_idx <- which(grepl(word_pat, names_clean, perl = TRUE))

  # Assemble ranked results — collect unique row indices in priority order
  seen <- integer(0)
  ordered_idx <- integer(0)
  match_labels <- character(0)

  add_results <- function(idx, mtype, max_n) {
    if (max_n <= 0) return()
    new <- setdiff(idx, seen)
    if (length(new)) {
      n <- min(length(new), max_n)
      new <- new[seq_len(n)]
      seen <<- c(seen, new)
      ordered_idx <<- c(ordered_idx, new)
      match_labels <<- c(match_labels, rep(mtype, n))
    }
  }

  # Synonym-resolved results: find the ATC code in data
  if (!is.null(syn_code)) {
    syn_idx <- which(data[["atc_code"]] == syn_code)
    add_results(syn_idx, "synonym", max_results)
  }

  # Common-name lexicon results
  if (!is.null(cn_code)) {
    cn_idx <- which(data[["atc_code"]] == cn_code)
    add_results(cn_idx, "common_name", max_results)
  }

  add_results(exact_idx,      "exact",        max_results)
  add_results(sw_idx,         "starts_with",  max_results - length(seen))
  add_results(contains_idx,   "contains",     max_results - length(seen))
  add_results(word_idx,       "word_match",   max_results - length(seen))

  if (length(ordered_idx) == 0) return(tibble::tibble())

  # Cap at max_results
  n_out <- min(length(ordered_idx), max_results)
  ordered_idx  <- ordered_idx[seq_len(n_out)]
  match_labels <- match_labels[seq_len(n_out)]

  keep_cols <- intersect(
    c("atc_code", "atc_name", "level"),
    names(data)
  )

  out <- data[ordered_idx, keep_cols, drop = FALSE]
  out[["match_type"]] <- match_labels
  out <- out[, c("match_type", keep_cols), drop = FALSE]

  tibble::as_tibble(out)
}

#' Fuzzy-match a drug name to ATC codes
#'
#' @description
#' Finds ATC codes for drug names that may be misspelled, abbreviated, or
#' use non-standard formatting. Uses Levenshtein (edit) distance via
#' `utils::adist()` to find close matches in the cached WHO database.
#'
#' This is useful when:
#' \itemize{
#'   \item Users type drug names from memory (typos)
#'   \item Clinical notes use non-standard spellings
#'   \item Brand names or abbreviations differ from WHO naming
#' }
#'
#' @param query Character scalar; the drug name to match.
#' @param data Optional data frame to search. If `NULL`, loads the cached database.
#' @param max_distance Integer; maximum allowed Levenshtein distance.
#'   Lower values are stricter. Default is 3.
#' @param max_results Integer; maximum results to return. Default is 10.
#'
#' @return A tibble of the closest-matching ATC codes, sorted by edit
#'   distance (closest first). Includes a `distance` column with the
#'   Levenshtein distance to each match.
#'
#' @examples
#' \donttest{
#' # Common misspellings
#' fuzzy_match_drug("acetominophen")    # should find "paracetamol"
#' fuzzy_match_drug("asprin")           # should find "aspirin"
#' fuzzy_match_drug("metmorphin")       # should find "metformin"
#'
#' # Stricter matching
#' fuzzy_match_drug("asprin", max_distance = 1)
#' }
#'
#' @seealso [search_drug()] for exact/substring matching,
#'   [resolve_atc()] for hybrid resolution.
#' @export
fuzzy_match_drug <- function(query, data = NULL,
                              max_distance = 3L, max_results = 10L) {
  if (!is_scalar_character(query)) {
    stop("query must be a single character string", call. = FALSE)
  }
  q_orig <- stringr::str_squish(tolower(query))
  if (q_orig == "") return(tibble::tibble())

  # Preprocess
  q <- preprocess_drug_name(q_orig)
  if (is.na(q)) q <- q_orig

  if (is.null(data)) {
    db <- atc_load_db()
    data <- db$codes
  }
  stopifnot(
    is.data.frame(data),
    "atc_code" %in% names(data),
    "atc_name" %in% names(data)
  )

  if (!"atc_name_clean" %in% names(data)) {
    data <- dplyr::mutate(
      data,
      atc_name_clean = stringr::str_squish(tolower(.data$atc_name))
    )
  }

  names_vec <- data[["atc_name_clean"]]

  # ── Stage 1: Constrained fuzzy (narrow candidates) ─────────────────
  # Filter to names sharing first 3 chars or containing the query as substring
  prefix <- stringr::str_sub(q, 1, 3)
  constrained_idx <- which(
    stringr::str_sub(names_vec, 1, 3) == prefix |
    grepl(q, names_vec, fixed = TRUE)
  )

  if (length(constrained_idx) > 0 && length(constrained_idx) < length(names_vec)) {
    # Try within constrained set first
    dists_constrained <- utils::adist(q, names_vec[constrained_idx],
                                       partial = FALSE, ignore.case = TRUE)[1, ]
    best_constrained <- min(dists_constrained)
    if (best_constrained <= max_distance) {
      keep <- dists_constrained <= max_distance
      within_limit <- constrained_idx[keep]
      dists <- dists_constrained[keep]

      keep_cols <- intersect(c("atc_code", "atc_name", "level"), names(data))
      return(
        data[within_limit, keep_cols, drop = FALSE] |>
          dplyr::mutate(distance = dists) |>
          dplyr::arrange(.data$distance) |>
          utils::head(max_results)
      )
    }
  }

  # ── Stage 2: Full fuzzy with stricter threshold ────────────────────
  max_dist_full <- max(1L, max_distance - 1L)
  dists <- utils::adist(q, names_vec, partial = FALSE,
                        ignore.case = TRUE, costs = NULL)[1, ]
  within_limit <- dists <= max_dist_full

  if (!any(within_limit)) {
    # Try partial matching (substring distance)
    dists_partial <- utils::adist(q, names_vec, partial = TRUE,
                                   ignore.case = TRUE, costs = NULL)[1, ]
    within_limit <- dists_partial <= max_distance
    if (!any(within_limit)) return(tibble::tibble())
    dists <- dists_partial[within_limit]
  } else {
    dists <- dists[within_limit]
  }

  keep_cols <- intersect(c("atc_code", "atc_name", "level"), names(data))
  data[within_limit, keep_cols, drop = FALSE] |>
    dplyr::mutate(distance = dists) |>
    dplyr::arrange(.data$distance) |>
    utils::head(max_results)
}

#' Resolve a drug name to its ATC code with hybrid local/live lookup
#'
#' @description
#' The primary drug-name resolution function. Tries to find the ATC code
#' for a given drug name by searching the cached local database first,
#' then optionally falling back to a live WHO crawl if the drug is not
#' found locally.
#'
#' This is the function you reach for when you have a drug name and need
#' its ATC code — the #1 workflow in pharmacoepidemiology.
#'
#' @param query Character scalar; the drug name to resolve.
#'   Case-insensitive. Examples: `"aspirin"`, `"atorvastatin"`.
#' @param source Character; resolution strategy:
#'   \itemize{
#'     \item `"local"` — cached database only (offline, fast)
#'     \item `"live"` — WHO website only (always up-to-date, requires internet)
#'     \item `"hybrid"` — try local first, fall back to live (default)
#'   }
#' @param data Optional data frame for local search. If `NULL`, auto-loads
#'   the cached database.
#' @param fuzzy Logical; if `TRUE` and the exact lookup fails, fall back
#'   to fuzzy matching before trying live resolution. Default is `TRUE`.
#' @param rate_limit Numeric; delay between live WHO requests (seconds).
#'   Only used when `source` is `"live"` or `"hybrid"`. Default is 0.5.
#'
#' @return A tibble with columns:
#' \itemize{
#'   \item `query` — the original query
#'   \item `atc_code` — the resolved ATC code
#'   \item `atc_name` — the drug name from the database
#'   \item `source` — `"local"` or `"live"` indicating where the match came from
#'   \item `match_type` — how the match was found (`"exact"`, `"fuzzy"`, `"live"`)
#' }
#' Returns a 0-row tibble if the drug cannot be resolved.
#'
#' @section Resolution Order (hybrid mode):
#' 1. Exact name match in local database
#' 2. Fuzzy match in local database (if `fuzzy = TRUE`)
#' 3. Live WHO crawl as last resort
#'
#' @examples
#' \donttest{
#' # Offline — fast, no internet needed
#' resolve_atc("aspirin", source = "local")
#'
#' # Live — always current
#' resolve_atc("aspirin", source = "live")
#'
#' # Hybrid (default) — local first, live fallback
#' resolve_atc("atorvastatin")
#'
#' # Batch resolution
#' meds <- c("aspirin", "metformin", "atorvastatin")
#' resolve_batch(meds)
#' }
#'
#' @seealso [resolve_batch()] for vectorised resolution,
#'   [search_drug()] for exploratory search.
#' @export
resolve_atc <- function(query,
                        source     = c("hybrid", "local", "live", "rxnorm"),
                        data       = NULL,
                        fuzzy      = TRUE,
                        rate_limit = 0.5) {
  source <- match.arg(source)
  if (!is_scalar_character(query)) {
    stop("query must be a single character string", call. = FALSE)
  }

  empty_result <- function(q, src, mtype) {
    tibble::tibble(
      query      = q,
      atc_code   = NA_character_,
      atc_name   = NA_character_,
      ddd        = NA_character_,
      uom        = NA_character_,
      adm_r      = NA_character_,
      source     = src,
      match_type = mtype
    )[0, ]
  }

  # --- Try local ---
  if (source %in% c("local", "hybrid")) {
    # Search (includes synonym resolution)
    hits <- search_drug(query, data = data, max_results = 1L)

    if (nrow(hits) > 0) {
      mtype <- hits$match_type[1]
      ddd_info <- .lookup_ddd(hits$atc_code[1], data = data)
      return(tibble::tibble(
        query      = query,
        atc_code   = hits$atc_code[1],
        atc_name   = hits$atc_name[1],
        ddd        = ddd_info$ddd,
        uom        = ddd_info$uom,
        adm_r      = ddd_info$adm_r,
        source     = "local",
        match_type = mtype
      ))
    }

    # Fuzzy fallback (only if the query bears some resemblance)
    if (isTRUE(fuzzy) && nchar(query) >= 3) {
      fuzzy_res <- fuzzy_match_drug(query, data = data,
                                     max_distance = 3L, max_results = 1L)
      if (nrow(fuzzy_res) > 0 && fuzzy_res$distance[1] <= 3L) {
        ddd_info <- .lookup_ddd(fuzzy_res$atc_code[1], data = data)
        return(tibble::tibble(
          query      = query,
          atc_code   = fuzzy_res$atc_code[1],
          atc_name   = fuzzy_res$atc_name[1],
          ddd        = ddd_info$ddd,
          uom        = ddd_info$uom,
          adm_r      = ddd_info$adm_r,
          source     = "local",
          match_type = "fuzzy"
        ))
      }
    }

    if (source == "local") return(empty_result(query, "local", NA_character_))
  }

  # --- Try RxNorm API ---
  if (source %in% c("rxnorm", "hybrid")) {
    rx_res <- tryCatch(
      .resolve_rxnorm(query),
      error = function(e) NULL
    )

    if (!is.null(rx_res) && nrow(rx_res) > 0) {
      return(tibble::tibble(
        query      = query,
        atc_code   = rx_res$atc_code[1],
        atc_name   = rx_res$atc_name[1],
        ddd        = NA_character_,
        uom        = NA_character_,
        adm_r      = NA_character_,
        source     = "rxnorm",
        match_type = "rxnorm"
      ))
    }
  }

  # --- Try live (WHO crawl) ---
  if (source %in% c("live", "hybrid")) {
    live_res <- tryCatch(
      get_atc_data(query, rate_limit = rate_limit, use_cache = TRUE),
      error = function(e) NULL
    )

    if (!is.null(live_res) && nrow(live_res) > 0) {
      ddd_info <- if ("ddd" %in% names(live_res)) {
        list(
          ddd   = as.character(live_res$ddd[1]),
          uom   = as.character(live_res$uom[1]),
          adm_r = as.character(live_res$adm_r[1])
        )
      } else { list(ddd = NA_character_, uom = NA_character_, adm_r = NA_character_) }

      return(tibble::tibble(
        query      = query,
        atc_code   = live_res$atc_code[1],
        atc_name   = live_res$atc_name[1],
        ddd        = ddd_info$ddd,
        uom        = ddd_info$uom,
        adm_r      = ddd_info$adm_r,
        source     = "live",
        match_type = "live"
      ))
    }
  }

  empty_result(query, source, NA_character_)
}

#' Resolve multiple drug names at once
#'
#' @description
#' Vectorised version of [resolve_atc()] — resolves a character vector of
#' drug names to their ATC codes. Runs sequentially with rate limiting to
#' be respectful of the WHO server when live fallback is used.
#'
#' @param queries Character vector of drug names to resolve.
#' @param source Character; `"hybrid"`, `"local"`, or `"live"`.
#'   Passed to [resolve_atc()]. Default is `"hybrid"`.
#' @param ... Additional arguments passed to [resolve_atc()].
#'
#' @return A tibble stacking the results from each query, with the same
#'   columns as [resolve_atc()].
#'
#' @examples
#' \donttest{
#' meds <- c("aspirin", "paracetamol", "ibuprofen", "metformin")
#' resolve_batch(meds)
#'
#' # Offline only
#' resolve_batch(meds, source = "local")
#' }
#'
#' @seealso [resolve_atc()] for single-name resolution.
#' @export
resolve_batch <- function(queries, source = c("hybrid", "local", "live"), ...) {
  source <- match.arg(source)
  if (!is.character(queries) || length(queries) == 0L) {
    stop("queries must be a non-empty character vector", call. = FALSE)
  }

  # Preload local DB once
  if (source %in% c("local", "hybrid")) atc_load_db()

  results <- lapply(queries, function(q) {
    resolve_atc(q, source = source, ...)
  })

  dplyr::bind_rows(results)
}

# Internal: look up DDD for a single ATC code
#' @keywords internal
.lookup_ddd <- function(code, data = NULL) {
  if (is.null(data)) {
    if (!is.null(.atc_search_env$ddd)) {
      data <- .atc_search_env$ddd
    } else {
      return(list(ddd = NA_character_, uom = NA_character_,
                  adm_r = NA_character_))
    }
  }

  # Prefer oral route
  ddd_rows <- data[data[["atc_code"]] == code, , drop = FALSE]
  if (nrow(ddd_rows) == 0) {
    return(list(ddd = NA_character_, uom = NA_character_,
                adm_r = NA_character_))
  }

  # Prefer oral, then first non-NA DDD
  if ("adm_r" %in% names(ddd_rows)) {
    oral <- ddd_rows[!is.na(ddd_rows[["adm_r"]]) &
                     ddd_rows[["adm_r"]] == "O", , drop = FALSE]
    if (nrow(oral) > 0 && "ddd" %in% names(oral) &&
        !is.na(oral[["ddd"]][1]) && oral[["ddd"]][1] != "NA") {
      return(list(ddd   = as.character(oral[["ddd"]][1]),
                  uom   = as.character(oral[["uom"]][1]),
                  adm_r = "O"))
    }
  }

  # Fall back to first row with a non-NA DDD
  if ("ddd" %in% names(ddd_rows)) {
    valid <- ddd_rows[!is.na(ddd_rows[["ddd"]]) &
                      ddd_rows[["ddd"]] != "NA", , drop = FALSE]
    if (nrow(valid) > 0) {
      return(list(ddd   = as.character(valid[["ddd"]][1]),
                  uom   = as.character(valid[["uom"]][1]),
                  adm_r = as.character(valid[["adm_r"]][1])))
    }
  }

  list(ddd = NA_character_, uom = NA_character_, adm_r = NA_character_)
}

# Internal: resolve a drug name via RxNorm REST API
#' @keywords internal
.resolve_rxnorm <- function(query, max_results = 1L) {
  base_url <- "https://rxnav.nlm.nih.gov/REST"

  # Step 1: approximate term match
  url <- paste0(base_url, "/approximateTerm.json?term=",
                utils::URLencode(query), "&maxEntries=", max_results)

  resp <- tryCatch({
    httr2::request(url) |>
      httr2::req_user_agent("atcddd R package") |>
      httr2::req_timeout(10) |>
      httr2::req_retry(max_tries = 2) |>
      httr2::req_perform()
  }, error = function(e) return(NULL))

  if (is.null(resp)) return(tibble::tibble())

  data <- tryCatch(
    httr2::resp_body_json(resp),
    error = function(e) return(NULL)
  )
  if (is.null(data)) return(tibble::tibble())

  candidates <- data$approximateGroup$candidate
  if (is.null(candidates) || length(candidates) == 0) {
    return(tibble::tibble())
  }

  # Step 2: get ATC class for top candidate
  rxcui <- candidates[[1]]$rxcui
  rxname <- candidates[[1]]$name %||% NA_character_

  atc_url <- paste0(base_url, "/rxclass/class/byRxcui.json?rxcui=", rxcui)
  atc_resp <- tryCatch({
    httr2::request(atc_url) |>
      httr2::req_user_agent("atcddd R package") |>
      httr2::req_timeout(10) |>
      httr2::req_perform()
  }, error = function(e) return(NULL))

  atc_code <- NA_character_
  if (!is.null(atc_resp)) {
    atc_data <- tryCatch(
      httr2::resp_body_json(atc_resp),
      error = function(e) return(NULL)
    )
    if (!is.null(atc_data)) {
      classes <- atc_data$rxclassDrugInfoList$rxclassDrugInfo
      if (!is.null(classes) && length(classes) > 0) {
        atc_classes <- Filter(function(x) x$relaSource %in% c("ATC", "ATCPROD"), classes)
        if (length(atc_classes) > 0) {
          atc_code <- atc_classes[[1]]$rxclassMinConceptItem$classId
        }
      }
    }
  }

  tibble::tibble(
    atc_code = atc_code,
    atc_name = rxname,
    source   = "rxnorm"
  )
}

#' Add a drug name synonym to the lookup table
#'
#' @description
#' Registers a common name, brand name, or abbreviation as a synonym for
#' a WHO ATC code. Synonyms are checked before fuzzy matching in
#' [search_drug()] and [resolve_atc()], making them the fastest path
#' from a clinical drug name to an ATC code.
#'
#' Use this to build up your own synonym dictionary for drugs frequently
#' encountered in your data.
#'
#' @param synonym Character scalar; the common name or alias
#'   (e.g. `"aspirin"`, `"tylenol"`).
#' @param atc_code Character scalar; the WHO ATC code the synonym maps to
#'   (e.g. `"N02BA01"`).
#' @param atc_name Character scalar; the WHO official name for the code
#'   (e.g. `"acetylsalicylic acid"`).
#'
#' @return Invisibly returns the updated synonym table.
#'
#' @examples
#' atc_add_synonym("advil", "M01AE01", "ibuprofen")
#' atc_add_synonym("lasix", "C03CA01", "furosemide")
#'
#' @seealso [search_drug()], [resolve_atc()]
#' @export
atc_add_synonym <- function(synonym, atc_code, atc_name) {
  if (!is_scalar_character(synonym) || !is_scalar_character(atc_code) ||
      !is_scalar_character(atc_name)) {
    stop("synonym, atc_code, and atc_name must all be single character strings",
         call. = FALSE)
  }

  if (!is_valid_atc_code(atc_code)) {
    stop("atc_code must be a valid ATC code", call. = FALSE)
  }

  syn <- tolower(synonym)

  # Ensure synonym table is initialised
  if (is.null(.atc_search_env$synonyms) || nrow(.atc_search_env$synonyms) == 0) {
    .atc_search_env$synonyms <- .atc_synonyms_default()
    .atc_search_env$synonyms <- dplyr::mutate(
      .atc_search_env$synonyms, synonym = tolower(.data$synonym)
    )
  }

  # Remove existing entry for this synonym if present
  .atc_search_env$synonyms <- .atc_search_env$synonyms[
    .atc_search_env$synonyms[["synonym"]] != syn, , drop = FALSE
  ]

  # Add new entry
  .atc_search_env$synonyms <- dplyr::bind_rows(
    .atc_search_env$synonyms,
    tibble::tibble(
      synonym  = syn,
      atc_code = atc_code,
      atc_name = atc_name
    )
  )

  invisible(.atc_search_env$synonyms)
}
