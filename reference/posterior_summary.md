# Summarise a posterior or Fermi distribution

Summarise a posterior or Fermi distribution

## Usage

``` r
posterior_summary(
  object,
  cred_level = 0.89,
  hdi = TRUE,
  nonfinite = c("error", "drop")
)
```

## Arguments

- object:

  A bf_prior, bf_posterior, bf_fermi, or numeric vector of draws.

- cred_level:

  Credible interval level (default 0.89).

- hdi:

  Logical: include HDI?

- nonfinite:

  "error" (default) rejects non-finite draws. "drop" excludes them and
  includes them in the reported count of dropped draws.

## Value

A list with median, ci, and (optionally) hdi, plus counts of retained
(`n_draws`) and excluded (`n_dropped`) draws.
