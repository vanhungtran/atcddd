
<!-- README.md is generated from README.Rmd. Please edit that file -->

# Tutorial for R package atcddd

## Lucas TRAN

## 10/09/2025

## Introduction

*atcddd*

## Package installation

The code of *atcddd* is freely available at
<https://github.com/vanhungtran/atcddd>.

The following commands can be used to install this R package, and an R
version \>= 4.2.3 is required.

    library(devtools)
    install_github("vanhungtran/atcddd")

## Example

    #The DNAm betas matrix

    #>res
    #>$codes
    #># A tibble: 500 × 2
    #>   atc_code atc_name                          
    #>   <chr>    <chr>                             
    #> 1 D01      ANTIFUNGALS FOR DERMATOLOGICAL USE
    #> 2 D01A     ANTIFUNGALS FOR TOPICAL USE       
    #> 3 D01AA    Antibiotics                       
    #> 4 D01AA01  nystatin                          
    #> 5 D01AA02  natamycin                         
    #> 6 D01AA03  hachimycin                        
    #> 7 D01AA04  pecilocin                         
    #> 8 D01AA06  mepartricin                       
    #> 9 D01AA07  pyrrolnitrin                      
    #>10 D01AA08  griseofulvin                      
    #># ℹ 490 more rows
    #># ℹ Use `print(n = ...)` to see more rows

    #>$ddd
    #># A tibble: 392 × 7
    #>   source_code atc_code atc_name                                        ddd   uom   adm_r note 
    #>   <chr>       <chr>    <chr>                                           <chr> <chr> <chr> <chr>
    #> 1 D01AA       D01AA01  nystatin                                        NA    NA    NA    NA   
    #> 2 D01AA       D01AA02  natamycin                                       NA    NA    NA    NA   
    #> 3 D01AA       D01AA03  hachimycin                                      NA    NA    NA    NA   
    #> 4 D01AA       D01AA04  pecilocin                                       NA    NA    NA    NA   
    #> 5 D01AA       D01AA06  mepartricin                                     NA    NA    NA    NA   
    #> 6 D01AA       D01AA07  pyrrolnitrin                                    NA    NA    NA    NA   
    #> 7 D01AA       D01AA08  griseofulvin                                    NA    NA    NA    NA   
    #> 8 D01AA       D01AA20  antibiotics in combination with corticosteroids NA    NA    NA    NA   
    #> 9 D01AC       D01AC01  clotrimazole                                    NA    NA    NA    NA   
    #>10 D01AC       D01AC02  miconazole                                      NA    NA    NA    NA   
    #># ℹ 382 more rows
    #># ℹ Use `print(n = ...)` to see more rows

## Reference
