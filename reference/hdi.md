# Highest Density Interval (approximate) from samples

Highest Density Interval (approximate) from samples

## Usage

``` r
hdi(x, cred_level = 0.89, nonfinite = c("error", "drop"))
```

## Arguments

- x:

  Numeric vector of samples.

- cred_level:

  Credible mass (e.g. 0.89).

- nonfinite:

  "error" (default) rejects non-finite draws. "drop" excludes them and
  warns with the number excluded.

## Value

Named numeric vector c(lower = , upper = ).
