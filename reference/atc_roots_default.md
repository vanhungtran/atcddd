# Default ATC Root Codes

Returns the 14 main anatomical groups (Level 1) of the ATC
classification system. These represent the highest level categories for
pharmaceutical classification.

## Usage

``` r
atc_roots_default()
```

## Value

Character vector of single-letter codes: A through V (excluding E, F, I,
K, O, Q, T, U, W, X, Y, Z)

## ATC Main Groups

- **A**: Alimentary tract and metabolism

- **B**: Blood and blood forming organs

- **C**: Cardiovascular system

- **D**: Dermatologicals

- **G**: Genito-urinary system and sex hormones

- **H**: Systemic hormonal preparations

- **J**: Antiinfectives for systemic use

- **L**: Antineoplastic and immunomodulating agents

- **M**: Musculo-skeletal system

- **N**: Nervous system

- **P**: Antiparasitic products

- **R**: Respiratory system

- **S**: Sensory organs

- **V**: Various

## Examples

``` r
# Get all default root codes
atc_roots_default()
#>  [1] "A" "B" "C" "D" "G" "H" "J" "L" "M" "N" "P" "R" "S" "V"

# Crawl only cardiovascular and nervous system
if (FALSE) { # \dontrun{
res <- atc_crawl(roots = c("C", "N"))
} # }
```
