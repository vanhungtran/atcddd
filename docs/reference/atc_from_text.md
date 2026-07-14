# Extract drug names from free-text clinical notes

Scans unstructured clinical text for drug names and resolves them to WHO
ATC codes. Supports exact name matching, synonym (brand/common name)
lookup, and optional fuzzy matching for misspellings. Multi-word drug
names (e.g. "acetylsalicylic acid", "sodium fluoride") are detected
through bigram tokenisation.

Inspired by `ab_from_text()` from the AMR package, but covering the full
WHO ATC/DDD index rather than antimicrobials alone.

## Usage

``` r
atc_from_text(text, max_results = 5, fuzzy = TRUE)
```

## Arguments

- text:

  Character scalar; free-text clinical notes such as
  `"Patient received 500 mg aspirin PO TID"` or
  `"On atorvastatin 20 mg daily"`.

- max_results:

  Integer; maximum number of unique drugs to return. Default is `5`.

- fuzzy:

  Logical; if `TRUE`, use Levenshtein (edit-distance) matching for drug
  names that are not found by exact or synonym lookup. Default is
  `TRUE`.

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) with up
to `max_results` rows and the following columns:

- `drug_name`:

  Character; the official drug name from the WHO ATC database (e.g.
  `"acetylsalicylic acid"`).

- `atc_code`:

  Character; the resolved ATC code (e.g. `"N02BA01"`).

- `match`:

  Character; the text span from the input that triggered the match,
  preserving original casing (e.g. `"Aspirin"`).

- `match_type`:

  Character; how the match was made: `"exact"`, `"synonym"`, or
  `"fuzzy"`.

- `confidence`:

  Character; heuristic quality rating: `"high"` (exact or synonym
  match), `"medium"` (fuzzy, edit distance \<= 2), or `"low"` (fuzzy,
  edit distance 3).

- `ddd`:

  Character; the WHO Defined Daily Dose value for the drug (preferring
  the oral route), or `NA` if not available.

- `uom`:

  Character; the unit of the DDD value (e.g. `"g"`, `"mg"`), or `NA` if
  not available.

Returns a zero-row tibble when no drugs are detected or the input is
empty/NA.

## Details

**Algorithm**

1.  **Pre-processing.** The input text is normalised to lowercase.
    Punctuation characters (commas, semicolons, periods, parentheses,
    etc.) are replaced with spaces so that tokens like `"aspirin,"`
    become `"aspirin"`. Internal hyphens are preserved (e.g.
    `"co-trimoxazole"`).

2.  **Tokenisation.** The cleaned text is split on whitespace into
    individual words. Two-word sequences (bigrams) are also generated so
    that multi-word drug names are not missed.

3.  **Filtering.** Tokens that represent dosing information (e.g.
    `"500mg"`, `"20mg/kg"`), pure numbers, and very short tokens (\<= 2
    characters) are excluded from matching. Overly generic chemical
    terms (`"acid"`, `"sodium"`, `"chloride"`, etc.) are only allowed as
    part of a bigram.

4.  **Bigram matching (Phase 1).** Each consecutive word pair that
    survives filtering is looked up via
    [`search_drug()`](https://vanhungtran.github.io/atcddd/reference/search_drug.md)
    (exact WHO name and synonym check). If `fuzzy = TRUE` and no
    exact/synonym match is found,
    [`fuzzy_match_drug()`](https://vanhungtran.github.io/atcddd/reference/fuzzy_match_drug.md)
    is tried for the pair. Words consumed by a successful bigram match
    are not re-processed as unigrams.

5.  **Unigram matching (Phase 2).** Remaining words are matched
    individually, first via
    [`search_drug()`](https://vanhungtran.github.io/atcddd/reference/search_drug.md)
    and then (if `fuzzy = TRUE`) via
    [`fuzzy_match_drug()`](https://vanhungtran.github.io/atcddd/reference/fuzzy_match_drug.md).

6.  **De-duplication and ranking.** Results are de-duplicated by ATC
    code (keeping the highest-confidence match). The final set is ranked
    by confidence (high \> medium \> low) and truncated to
    `max_results`.

## Confidence Heuristic

- `high`:

  The token exactly matches a WHO drug name or a curated synonym.
  Considered reliable.

- `medium`:

  The token fuzzy-matches with a Levenshtein distance of 1 or 2 — likely
  a minor typo.

- `low`:

  The token fuzzy-matches with a Levenshtein distance of 3 — more
  speculative. Manual verification recommended.

## See also

[`search_drug`](https://vanhungtran.github.io/atcddd/reference/search_drug.md)
for exact and synonym name search,
[`fuzzy_match_drug`](https://vanhungtran.github.io/atcddd/reference/fuzzy_match_drug.md)
for typo-tolerant matching,
[`resolve_atc`](https://vanhungtran.github.io/atcddd/reference/resolve_atc.md)
for single-drug-to-ATC resolution.

## Examples

``` r
# \donttest{
# Simple drug name extraction
atc_from_text("Patient was prescribed aspirin 500 mg and metformin")
#> # A tibble: 2 × 7
#>   drug_name            atc_code match     match_type confidence ddd   uom  
#>   <chr>                <chr>    <chr>     <chr>      <chr>      <chr> <chr>
#> 1 metformin            A10BA02  metformin exact      high       2     g    
#> 2 acetylsalicylic acid N02BA01  aspirin   synonym    high       3     g    

# Brand names resolved via synonym table
atc_from_text("On lipitor for cholesterol, also takes tylenol PRN")
#> # A tibble: 2 × 7
#>   drug_name    atc_code match   match_type confidence ddd   uom  
#>   <chr>        <chr>    <chr>   <chr>      <chr>      <chr> <chr>
#> 1 atorvastatin C10AA05  lipitor synonym    high       20    mg   
#> 2 paracetamol  N02BE01  tylenol synonym    high       3     g    

# Multi-word drug names
atc_from_text("Received acetylsalicylic acid 100 mg daily")
#> # A tibble: 1 × 7
#>   drug_name            atc_code match          match_type confidence ddd   uom  
#>   <chr>                <chr>    <chr>          <chr>      <chr>      <chr> <chr>
#> 1 acetylsalicylic acid A01AD05  acetylsalicyl… exact      high       NA    NA   

# Strict mode — no fuzzy matching
atc_from_text("acetominophen", fuzzy = FALSE)
#> # A tibble: 0 × 7
#> # ℹ 7 variables: drug_name <chr>, atc_code <chr>, match <chr>,
#> #   match_type <chr>, confidence <chr>, ddd <chr>, uom <chr>
# }
```
