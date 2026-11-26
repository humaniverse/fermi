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

  Non-negative integer number of successes.

- trials:

  Positive integer number of trials.

## Value

A bf_posterior object with dist = "beta".
