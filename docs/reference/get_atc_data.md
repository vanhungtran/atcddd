# Get ATC Classification Data from WHO Database

Retrieves ATC (Anatomical Therapeutic Chemical) classification data for
a specific code or codes from the WHO Collaborating Centre for Drug
Statistics Methodology database.

This function provides structured access to the ATC hierarchy and DDD
(Defined Daily Dose) information through a clean API-style interface.

## Usage

``` r
get_atc_data(
  codes = NULL,
  include_children = FALSE,
  rate_limit = 0.5,
  use_cache = TRUE
)
```

## Source

WHO Collaborating Centre for Drug Statistics Methodology:
<https://www.whocc.no/atc_ddd_index/>

## Arguments

- codes:

  Character vector; one or more ATC codes to retrieve. Can be Level 1
  (e.g., "N"), Level 2 (e.g., "N02"), Level 3 (e.g., "N02B"), Level 4
  (e.g., "N02BE"), or Level 5 (e.g., "N02BE01"). If NULL, returns data
  for all 14 main anatomical groups.

- include_children:

  Logical; if TRUE, also retrieves all child codes in the hierarchy
  below the specified codes. Default is FALSE.

- rate_limit:

  Numeric; minimum delay in seconds between requests to respect WHO
  server load. Default is 0.5 seconds.

- use_cache:

  Logical; if TRUE, uses filesystem caching to avoid redundant requests.
  Default is TRUE.

## Value

A tibble with the following columns:

- `atc_code`: The ATC code (e.g., "N02BE01")

- `atc_name`: Name/description of the substance or group

- `level`: Hierarchy level (1-5)

- `ddd`: Defined Daily Dose value (if available)

- `uom`: Unit of measurement for DDD (e.g., "g", "mg")

- `adm_r`: Route of administration (e.g., "O" for oral, "P" for
  parenteral)

- `note`: Additional notes or comments

## Details

This function provides a cleaner, API-style interface to the WHO ATC/DDD
database compared to the lower-level
[`atc_crawl`](https://vanhungtran.github.io/atcddd/reference/atc_crawl.md)
function. It automatically handles:

- Input validation for ATC code format

- Rate limiting to respect WHO server policies

- Caching via memoise to minimize redundant requests

- Error handling with informative messages

- Consistent tibble output format

Returns `NULL` with a message if:

- Invalid ATC codes are provided

- Network connection fails

- No data is available for the requested codes

## Note

Requires an internet connection to access the WHO database. First-time
requests may be slower due to network latency; subsequent requests use
cached data when `use_cache = TRUE`.

## Rate Limiting

To be respectful of WHO server resources, this function enforces a
minimum delay between requests. The default is 0.5 seconds, which
translates to a maximum of 2 requests per second.

## See also

[`atc_crawl`](https://vanhungtran.github.io/atcddd/reference/atc_crawl.md)
for lower-level crawling functionality,
[`atc_roots_default`](https://vanhungtran.github.io/atcddd/reference/atc_roots_default.md)
for main anatomical groups,
[`is_valid_atc_code`](https://vanhungtran.github.io/atcddd/reference/is_valid_atc_code.md)
for code validation

## Examples

``` r
# \donttest{
# Get data for a specific drug (aspirin)
get_atc_data("N02BA01")
#> # A tibble: 3 × 6
#>   atc_code level ddd   uom   adm_r note                                
#>   <chr>    <int> <chr> <chr> <chr> <chr>                               
#> 1 N02BA01      5 3     g     O     NA                                  
#> 2 N02BA01      5 1     g     P     Expressed as lysine acetylsalisylate
#> 3 N02BA01      5 3     g     R     NA                                  

# Get data for all analgesics (Level 2)
get_atc_data("N02")
#> No data available for the requested codes.
#> NULL

# Get cardiovascular and nervous system main groups
get_atc_data(c("C", "N"))
#> No data available for the requested codes.
#> NULL

# Get all child codes under opioids
get_atc_data("N02A", include_children = TRUE)
#> # A tibble: 91 × 6
#>    atc_code level ddd   uom   adm_r note 
#>    <chr>    <int> <chr> <chr> <chr> <chr>
#>  1 N02AA        4 NA    NA    NA    NA   
#>  2 N02AA01      5 0.1   g     O     NA   
#>  3 N02AA01      5 30    mg    P     NA   
#>  4 N02AA01      5 30    mg    R     NA   
#>  5 N02AA02      5 NA    NA    NA    NA   
#>  6 N02AA03      5 20    mg    O     NA   
#>  7 N02AA03      5 4     mg    P     NA   
#>  8 N02AA03      5 4     mg    R     NA   
#>  9 N02AA04      5 30    mg    O     NA   
#> 10 N02AA04      5 30    mg    P     NA   
#> # ℹ 81 more rows

# Get all main anatomical groups
get_atc_data()
#> No data available for the requested codes.
#> NULL
# }
```
