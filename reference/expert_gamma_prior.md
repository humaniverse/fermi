# Gamma prior from expert quantiles

Uses a Normal approximation for concentrated Gamma distributions when it
matches the requested probabilities, and a root finder otherwise.

## Usage

``` r
expert_gamma_prior(
  q,
  p = c(0.1, 0.9),
  shape_switch = 20,
  mode = c("auto", "normal", "uniroot"),
  tol = 1e-06
)
```

## Arguments

- q:

  Two increasing positive target quantiles, e.g. c(q10, q90).

- p:

  Two increasing cumulative probabilities for q, in (0, 1).

- shape_switch:

  Minimum implied shape for considering the Normal approximation in auto
  mode (default 20). Use `Inf` to always refine.

- mode:

  One of "auto", "normal", "uniroot":

  - "auto": try the approximation and refine if needed

  - "normal": always use the Normal approximation

  - "uniroot": always use the root finder

- tol:

  Maximum tolerated absolute probability error at either target. A
  larger error in the final fit triggers a warning.

## Value

A bf_prior with dist = "gamma". Its metadata includes the requested and
achieved quantiles and probabilities, maximum probability error, and the
fitting method used.

## Examples

``` r
expert_gamma_prior(q = c(400, 900), p = c(0.1, 0.9))
#> fermi prior
#>   Distribution: gamma 
#>   Source      : expert 
#>   Parameters  :
#> $shape
#> [1] 10.35401
#> 
#> $rate
#> [1] 0.01625796
#> 
#>   Quantile calibration:
#>  quantile requested_probability achieved_probability
#>       400                   0.1                  0.1
#>       900                   0.9                  0.9
expert_gamma_prior(q = c(0.2, 1), p = c(0.1, 0.9))
#> fermi prior
#>   Distribution: gamma 
#>   Source      : expert 
#>   Parameters  :
#> $shape
#> [1] 2.886175
#> 
#> $rate
#> [1] 5.163781
#> 
#>   Quantile calibration:
#>  quantile requested_probability achieved_probability
#>       0.2                   0.1                  0.1
#>       1.0                   0.9                  0.9
```
