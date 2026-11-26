# Rank input associations with a Fermi estimate

Computes Spearman rank correlations from the paired input and output
draws. The result describes associations under the simulated
assumptions. Interactions, dependence, and non-monotone relationships
can make a rank correlation a poor measure of an input's importance.

## Usage

``` r
bf_sensitivity(object)
```

## Arguments

- object:

  A result from
  [`bf_fermi_simulate()`](https://humaniverse.github.io/fermi/reference/bf_fermi_simulate.md)
  with at least two draws.

## Value

A data frame with `component` and signed `spearman` correlation, ordered
by decreasing absolute correlation. Constant inputs or outputs give `NA`
correlations.

## Examples

``` r
joint <- data.frame(volume = c(10, 30, 20), price = c(2, 2, 2))
sim <- bf_fermi_simulate(joint, function(volume, price) volume * price)
bf_sensitivity(sim)
#>   component spearman
#> 1    volume        1
#> 2     price       NA
```
