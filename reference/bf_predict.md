# Draw from a conjugate posterior predictive distribution

Draws a parameter from the posterior for each replicate and then samples
a future observation from the corresponding likelihood. The result
captures uncertainty in both the parameter and the future observation.

## Usage

``` r
bf_predict(object, n = 4000, trials = NULL, exposure = NULL, obs_sd = NULL)
```

## Arguments

- object:

  A bf_posterior from a Beta-Binomial, Gamma-Poisson, or Normal-Normal
  model.

- n:

  Positive integer number of predictive draws.

- trials:

  Future trial count for a Beta posterior (default 1).

- exposure:

  Future exposure for a Gamma posterior (default 1).

- obs_sd:

  Future observation standard deviation for a Normal posterior. By
  default uses the value stored by
  [`normal_normal_posterior()`](https://humaniverse.github.io/fermi/reference/normal_normal_posterior.md).

## Value

A numeric vector of predictive draws.

## Examples

``` r
prior <- bf_prior("gamma", list(shape = 2, rate = 1))
post <- gamma_poisson_posterior(prior, c(3, 4, 2))
future <- bf_predict(post, exposure = 30)
mean(future > 100)
#> [1] 0.2365
```
