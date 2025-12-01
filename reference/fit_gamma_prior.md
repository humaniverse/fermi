# Fit a Gamma prior to positive data

Fit a Gamma prior to positive data

## Usage

``` r
fit_gamma_prior(y, method = c("mm", "mle"))
```

## Arguments

- y:

  Numeric vector with values \> 0.

- method:

  "mm" or "mle".

## Value

A bf_prior object with dist = "gamma".

## Examples

``` r
# Method of moments: task durations in hours
handling_time <- c(0.8, 1.1, 0.9, 1.3, 1.0, 1.2)
fit_gamma_prior(handling_time, method = "mm")
#> fermi prior
#>   Distribution: gamma 
#>   Source      : data 
#>   Parameters  :
#> $shape
#> [1] 31.5
#> 
#> $rate
#> [1] 30
#> 

# MLE: daily throughput figures (jobs completed)
throughput <- c(95, 110, 102, 130, 120, 115)
fit_gamma_prior(throughput, method = "mle")
#> Warning: NaNs produced
#> Warning: NaNs produced
#> Warning: NaNs produced
#> Warning: NaNs produced
#> Warning: NaNs produced
#> Warning: NaNs produced
#> fermi prior
#>   Distribution: gamma 
#>   Source      : data 
#>   Parameters  :
#> $shape
#> [1] 94.7823
#> 
#> $rate
#> [1] 0.8462748
#> 
```
