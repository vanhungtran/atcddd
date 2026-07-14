# Get all descendants of an ATC code through the hierarchy

Returns all ATC codes below the given code in the hierarchy — that is,
all children, grandchildren, great-grandchildren, and so on down to
Level 5 substances. This works offline against any data frame of ATC
codes.

## Usage

``` r
atc_descendants(code, data, max_level = 5L)
```

## Arguments

- code:

  Character scalar; the root ATC code.

- data:

  Data frame containing at least an `atc_code` column.

- max_level:

  Integer; maximum hierarchy depth to descend. Default is 5 (complete
  tree).

## Value

Character vector of all descendant ATC codes (excluding `code` itself),
or `character(0)` if the code is a leaf or not found.

## See also

[`atc_children()`](https://vanhungtran.github.io/atcddd/reference/atc_children.md),
[`atc_parent()`](https://vanhungtran.github.io/atcddd/reference/atc_parent.md)

## Examples

``` r
# \donttest{
codes <- readr::read_csv(
  system.file("extdata", "WHO_ATC_codes_2026-07-14.csv",
              package = "atcddd"),
  show_col_types = FALSE
)

# All substances under the statin chemical class
atc_descendants("C10AA", codes)
#> [1] "C10AA01" "C10AA02" "C10AA03" "C10AA04" "C10AA05" "C10AA06" "C10AA07"
#> [8] "C10AA08"

# All codes under the cardiovascular group, stopping at Level 4
atc_descendants("C", codes, max_level = 4)
#>   [1] "C01"   "C01A"  "C01AA" "C01AB" "C01AC" "C01AX" "C01B"  "C01BA" "C01BB"
#>  [10] "C01BC" "C01BD" "C01BG" "C01C"  "C01CA" "C01CE" "C01CX" "C01D"  "C01DA"
#>  [19] "C01DB" "C01DX" "C01E"  "C01EA" "C01EB" "C01EX" "C02"   "C02A"  "C02AA"
#>  [28] "C02AB" "C02AC" "C02B"  "C02BA" "C02BB" "C02BC" "C02C"  "C02CA" "C02CC"
#>  [37] "C02D"  "C02DA" "C02DB" "C02DC" "C02DD" "C02DG" "C02K"  "C02KA" "C02KB"
#>  [46] "C02KC" "C02KD" "C02KN" "C02KX" "C02L"  "C02LA" "C02LB" "C02LC" "C02LE"
#>  [55] "C02LF" "C02LG" "C02LK" "C02LL" "C02LN" "C02LX" "C02N"  "C03"   "C03A" 
#>  [64] "C03AA" "C03AB" "C03AH" "C03AX" "C03B"  "C03BA" "C03BB" "C03BC" "C03BD"
#>  [73] "C03BK" "C03BX" "C03C"  "C03CA" "C03CB" "C03CC" "C03CD" "C03CX" "C03D" 
#>  [82] "C03DA" "C03DB" "C03E"  "C03EA" "C03EB" "C03X"  "C03XA" "C04"   "C04A" 
#>  [91] "C04AA" "C04AB" "C04AC" "C04AD" "C04AE" "C04AF" "C04AX" "C05"   "C05A" 
#> [100] "C05AA" "C05AB" "C05AD" "C05AE" "C05AX" "C05B"  "C05BA" "C05BB" "C05BX"
#> [109] "C05C"  "C05CA" "C05CX" "C05X"  "C05XX" "C07"   "C07A"  "C07AA" "C07AB"
#> [118] "C07AG" "C07B"  "C07BA" "C07BB" "C07BG" "C07C"  "C07CA" "C07CB" "C07CG"
#> [127] "C07D"  "C07DA" "C07DB" "C07E"  "C07EA" "C07EB" "C07F"  "C07FB" "C07FX"
#> [136] "C08"   "C08C"  "C08CA" "C08CX" "C08D"  "C08DA" "C08DB" "C08E"  "C08EA"
#> [145] "C08EX" "C08G"  "C08GA" "C09"   "C09A"  "C09AA" "C09B"  "C09BA" "C09BB"
#> [154] "C09BX" "C09C"  "C09CA" "C09D"  "C09DA" "C09DB" "C09DX" "C09X"  "C09XA"
#> [163] "C09XX" "C10"   "C10A"  "C10AA" "C10AB" "C10AC" "C10AD" "C10AX" "C10B" 
#> [172] "C10BA" "C10BX"
# }
```
