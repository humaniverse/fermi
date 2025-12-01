# Conjugate Beta-Binomial update

Conjugate Beta-Binomial update

## Usage

``` r
beta_binom_posterior(prior, successes, trials)
```

## Arguments

- prior:

  A bf_prior with dist = "beta".

- successes:

  Number of successes.

- trials:

  Number of trials.

## Value

A bf_posterior object with dist = "beta".
