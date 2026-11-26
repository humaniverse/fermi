# Create a fermi posterior object

Create a fermi posterior object

## Usage

``` r
bf_posterior(dist, params, prior = NULL, data = list())
```

## Arguments

- dist:

  Character. One of "beta", "gamma", "normal".

- params:

  Named list of posterior parameters, as in
  [`bf_prior()`](https://humaniverse.github.io/fermi/reference/bf_prior.md).

- prior:

  A bf_prior object (optional but recommended).

- data:

  A list describing the data used for the update.

## Value

An object of class "bf_posterior".
