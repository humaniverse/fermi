# Plot posterior or Fermi distribution

Plot posterior or Fermi distribution

## Usage

``` r
plot_posterior(
  object,
  cred_level = 0.89,
  hdi = TRUE,
  ...,
  nonfinite = c("error", "drop")
)
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

- nonfinite:

  "error" (default) rejects non-finite draws. "drop" excludes them and
  reports the count in the returned summary.

## Value

The posterior summary, invisibly.
