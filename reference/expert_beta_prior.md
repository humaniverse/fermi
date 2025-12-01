# Beta prior from expert quantiles (robust version)

Beta prior from expert quantiles (robust version)

## Usage

``` r
expert_beta_prior(
  q,
  p = c(0.1, 0.9),
  start = NULL,
  method = "BFGS",
  maxit = 2000,
  tol = 1e-10
)
```

## Arguments

- q:

  Numeric vector of length 2: target quantiles in (0, 1).

- p:

  Numeric vector of length 2: cumulative probabilities for q.

- start:

  Optional starting values for log(shape1), log(shape2).

- method:

  Optimisation method passed to optim().

- maxit:

  Maximum iterations for optim().

- tol:

  Tolerance on squared error between target and achieved quantiles below
  which we don't complain even if optim() reports non-convergence.

## Value

A bf_prior object with dist = "beta".

## Examples

``` r
# 10% and 90% quantiles at 2% and 8%: e.g., piano ownership fraction
expert_beta_prior(q = c(0.02, 0.08), p = c(0.1, 0.9))
#> fermi prior
#>   Distribution: beta 
#>   Source      : expert 
#>   Parameters  :
#> $shape1
#> [1] 3.623535
#> 
#> $shape2
#> [1] 72.7708
#> 

# Asymmetric beliefs: 25% chance below 3%, 75% chance below 10%
expert_beta_prior(q = c(0.03, 0.10), p = c(0.25, 0.75))
#> fermi prior
#>   Distribution: beta 
#>   Source      : expert 
#>   Parameters  :
#> $shape1
#> [1] 1.458965
#> 
#> $shape2
#> [1] 18.76397
#> 
```
