# Fermi-style simulation from a combination of priors/posteriors

Fermi-style simulation from a combination of priors/posteriors

## Usage

``` r
bf_fermi_simulate(
  components,
  fun,
  n_draws = 10000,
  use = c("posterior", "prior")
)
```

## Arguments

- components:

  Named list of bf_prior and/or bf_posterior objects.

- fun:

  A function whose arguments correspond to names(components).

- n_draws:

  Number of Monte Carlo draws.

- use:

  Character. "posterior" (default) uses posterior params if available,
  otherwise prior; "prior" forces use of priors only.

## Value

A list with draws for the derived quantity and input draws.
