# Conjugate Normal-Normal update (known observation sd)

Conjugate Normal-Normal update (known observation sd)

## Usage

``` r
normal_normal_posterior(prior, y, obs_sd)
```

## Arguments

- prior:

  A bf_prior with dist = "normal".

- y:

  Observations.

- obs_sd:

  Known standard deviation of observations.

## Value

A bf_posterior object with dist = "normal".
