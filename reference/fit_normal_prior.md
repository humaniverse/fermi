# Fit a Normal prior to real-valued data

Fit a Normal prior to real-valued data

## Usage

``` r
fit_normal_prior(y)
```

## Arguments

- y:

  Numeric vector (real-valued).

## Value

A bf_prior object with dist = "normal".

## Examples

``` r
# Fit to observed cycle times (days)
cycle_times <- c(4.5, 5.2, 4.8, 5.0, 4.9, 5.4)
fit_normal_prior(cycle_times)
#> fermi prior
#>   Distribution: normal 
#>   Source      : data 
#>   Parameters  :
#> $mean
#> [1] 4.966667
#> 
#> $sd
#> [1] 0.3141125
#> 

# Fit to centered measurement errors
measurement_error <- c(-0.2, 0.1, 0.0, 0.3, -0.1, 0.2)
fit_normal_prior(measurement_error)
#> fermi prior
#>   Distribution: normal 
#>   Source      : data 
#>   Parameters  :
#> $mean
#> [1] 0.05
#> 
#> $sd
#> [1] 0.1870829
#> 
```
