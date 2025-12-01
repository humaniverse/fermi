# Gamma prior from expert quantiles (hybrid)

Uses a normal approximation for "large, bell-shaped" Gammas and a
uniroot-based solver for more skewed or small-scale cases.

## Usage

``` r
expert_gamma_prior(
  q,
  p = c(0.1, 0.9),
  shape_switch = 20,
  mode = c("auto", "normal", "uniroot")
)
```

## Arguments

- q:

  Numeric, length 2: target quantiles (\> 0), e.g. c(q10, q90).

- p:

  Numeric, length 2: corresponding probabilities in (0, 1).

- shape_switch:

  Threshold on the implied shape above which we trust the normal
  approximation (default 20).

- mode:

  One of "auto", "normal", "uniroot":

  - "auto": hybrid behaviour (recommended)

  - "normal": always use normal approximation

  - "uniroot": always use the uniroot solver

## Value

A bf_prior object with dist = "gamma".

## Examples

``` r
# Reliability: time-to-failure in hours with 10% at 400 and 90% at 900
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

# Low-rate process: 10% at 0.2 events/day, 90% at 1 event/day
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
```
