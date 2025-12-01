# Normal prior from expert mean and interval

Normal prior from expert mean and interval

## Usage

``` r
expert_normal_prior(mean, lower, upper, level = 0.9)
```

## Arguments

- mean:

  Expert mean.

- lower:

  Lower bound of central interval.

- upper:

  Upper bound of central interval.

- level:

  Central probability mass in the interval (e.g. 0.9).

## Value

A bf_prior object with dist = "normal".

## Examples

``` r
# Delivery time centered on 3 days with a 90% interval of [2.5, 3.5]
expert_normal_prior(mean = 3, lower = 2.5, upper = 3.5, level = 0.9)
#> fermi prior
#>   Distribution: normal 
#>   Source      : expert 
#>   Parameters  :
#> $mean
#> [1] 3
#> 
#> $sd
#> [1] 0.3039784
#> 

# Revenue per user guess: 90% central interval between $8 and $16
expert_normal_prior(mean = 12, lower = 8, upper = 16, level = 0.9)
#> fermi prior
#>   Distribution: normal 
#>   Source      : expert 
#>   Parameters  :
#> $mean
#> [1] 12
#> 
#> $sd
#> [1] 2.431827
#> 
```
