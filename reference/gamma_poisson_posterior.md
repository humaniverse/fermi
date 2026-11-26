# Conjugate Gamma-Poisson update for a rate

Conjugate Gamma-Poisson update for a rate

## Usage

``` r
gamma_poisson_posterior(prior, y, exposure = NULL)
```

## Arguments

- prior:

  A bf_prior with dist = "gamma".

- y:

  Integer counts (vector or scalar).

- exposure:

  Optional vector of finite positive exposures for each observation
  (defaults to 1 per observation).

## Value

A bf_posterior object with dist = "gamma".
