# Fit a Beta prior to data

Fit a Beta prior to data

## Usage

``` r
fit_beta_prior(y, method = c("mm", "mle"))
```

## Arguments

- y:

  Numeric vector with values strictly between 0 and 1.

- method:

  "mm" (method of moments) or "mle" (maximum likelihood).

## Value

A bf_prior object with dist = "beta".

## Examples

``` r
# Method of moments: proportions from small pilots
click_rates <- c(0.04, 0.05, 0.06, 0.07, 0.05, 0.08)
fit_beta_prior(click_rates, method = "mm")
#> fermi prior
#>   Distribution: beta 
#>   Source      : data 
#>   Parameters  :
#> $shape1
#> [1] 14.73066
#> 
#> $shape2
#> [1] 237.795
#> 

# MLE: conversion rates expressed as successes / trials
conv <- c(5/120, 8/150, 10/170, 12/160, 7/140)
fit_beta_prior(conv, method = "mle")
#> fermi prior
#>   Distribution: beta 
#>   Source      : data 
#>   Parameters  :
#> $shape1
#> [1] 24.84978
#> 
#> $shape2
#> [1] 420.7564
#> 
```
