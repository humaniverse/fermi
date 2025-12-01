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

  Named list of parameters (e.g. list(shape1 = , shape2 = )).

- source:

  Character. "data" or "expert".

- metadata:

  Optional list with any extra info (e.g. description).

## Value

An object of class "bf_prior".
