# Create a fermi prior object

Create a fermi prior object

## Usage

``` r
bf_prior(dist, params, source = c("data", "expert"), metadata = list())
```

## Arguments

- dist:

  Character. One of "beta", "gamma", "normal".

- params:

  Named list of finite distribution parameters. Beta uses positive
  `shape1` and `shape2`, Gamma uses positive `shape` and `rate`, and
  Normal uses `mean` and non-negative `sd`.

- source:

  Character. "data" or "expert".

- metadata:

  Optional list with any extra info (e.g. description).

## Value

An object of class "bf_prior".
