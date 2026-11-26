# Beta prior from expert quantiles

Fits the CDF on the log-odds scale so small target quantiles can be
calibrated accurately.

## Usage

``` r
expert_beta_prior(
  q,
  p = c(0.1, 0.9),
  start = NULL,
  method = "BFGS",
  maxit = 2000,
  tol = 1e-06
)
```

## Arguments

- q:

  Two increasing target quantiles in (0, 1).

- p:

  Two increasing cumulative probabilities for q, in (0, 1).

- start:

  Optional starting values for log(shape1), log(shape2).

- method:

  Optimisation method passed to optim().

- maxit:

  Maximum iterations for optim().

- tol:

  Maximum tolerated absolute probability error at either target. A
  larger error triggers a warning regardless of the optimizer status.

## Value

A bf_prior with dist = "beta". Its metadata includes the requested and
achieved quantiles and probabilities, maximum probability error, and
optimizer convergence code.

## Examples

``` r
expert_beta_prior(q = c(0.02, 0.08), p = c(0.1, 0.9))
#> fermi prior
#>   Distribution: beta 
#>   Source      : expert 
#>   Parameters  :
#> $shape1
#> [1] 3.623528
#> 
#> $shape2
#> [1] 72.77062
#> 
#>   Quantile calibration:
#>  quantile requested_probability achieved_probability
#>      0.02                   0.1                  0.1
#>      0.08                   0.9                  0.9
expert_beta_prior(q = c(1e-6, 8e-6), p = c(0.025, 0.9))
#> fermi prior
#>   Distribution: beta 
#>   Source      : expert 
#>   Parameters  :
#> $shape1
#> [1] 3.175159
#> 
#> $shape2
#> [1] 695559.8
#> 
#>   Quantile calibration:
#>  quantile requested_probability achieved_probability
#>     1e-06                 0.025                0.025
#>     8e-06                 0.900                0.900
```
