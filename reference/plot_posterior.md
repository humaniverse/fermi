# Plot posterior or Fermi distribution

Plot posterior or Fermi distribution

## Usage

``` r
plot_posterior(object, cred_level = 0.89, hdi = TRUE, ...)
```

## Arguments

- object:

  A bf_posterior, bf_fermi, bf_prior, or numeric vector of draws.

- cred_level:

  Credible interval level (default 0.89).

- hdi:

  Logical: annotate HDI?

- ...:

  Passed to underlying plotting function.
