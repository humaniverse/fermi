# Simulate a Fermi estimate

Simulate a Fermi estimate

## Usage

``` r
bf_fermi_simulate(
  components,
  fun,
  n_draws = 10000,
  use = c("posterior", "prior"),
  nonfinite = c("error", "drop")
)
```

## Arguments

- components:

  A named list of bf_prior and/or bf_posterior objects, sampled
  independently, or a numeric data frame with one joint draw per row.
  Joint draws are used in the supplied order, preserving dependence.

- fun:

  A vectorised function whose arguments correspond to
  `names(components)`. It must return one numeric value per input row.

- n_draws:

  Number of Monte Carlo draws. For a data frame, this defaults to its
  number of rows and must match it if supplied.

- use:

  For lists, "posterior" (default) uses posterior parameters when
  available. "prior" uses the priors attached to any posterior objects.

- nonfinite:

  "error" (default) rejects non-finite inputs or outputs. "drop"
  excludes affected rows from both inputs and output.

## Value

A bf_fermi object with `draws`, their corresponding `inputs`, the
supplied `fun`, and `n_dropped` (the number of excluded rows).

## Examples

``` r
joint <- data.frame(demand = c(100, 200, 300), capacity = c(80, 150, 250))
bf_fermi_simulate(joint, function(demand, capacity) demand - capacity)
#> $draws
#> [1] 20 50 50
#> 
#> $inputs
#>   demand capacity
#> 1    100       80
#> 2    200      150
#> 3    300      250
#> 
#> $fun
#> function (demand, capacity) 
#> demand - capacity
#> <environment: 0x6428422c9318>
#> 
#> $n_dropped
#> [1] 0
#> 
#> attr(,"class")
#> [1] "bf_fermi"
```
