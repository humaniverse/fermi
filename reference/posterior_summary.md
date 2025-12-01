# Summarise a posterior or Fermi distribution

Summarise a posterior or Fermi distribution

## Usage

``` r
posterior_summary(object, cred_level = 0.89, hdi = TRUE)
```

## Arguments

- object:

  A bf_posterior, bf_fermi, or numeric vector of draws.

- cred_level:

  Credible interval level (default 0.89).

- hdi:

  Logical: include HDI?

## Value

A list with median, ci, and (optionally) hdi.
