# Compare Fermi estimation scenarios

Run
[`bf_fermi_simulate()`](https://humaniverse.github.io/fermi/reference/bf_fermi_simulate.md)
for each set of assumptions, then pass the named results here to compare
their medians and equal-tailed credible intervals.

## Usage

``` r
bf_compare_scenarios(scenarios, cred_level = 0.89)
```

## Arguments

- scenarios:

  A named list of bf_fermi simulations.

- cred_level:

  Credible interval level (default 0.89).

## Value

A data frame with one row per scenario, in the order provided.

## Examples

``` r
totals <- function(volume) volume * 2
baseline <- bf_fermi_simulate(data.frame(volume = 10:15), totals)
higher <- bf_fermi_simulate(data.frame(volume = 15:20), totals)
bf_compare_scenarios(list(baseline = baseline, higher = higher))
#>   scenario median lower upper n_draws n_dropped
#> 1 baseline     25 20.55 29.45       6         0
#> 2   higher     35 30.55 39.45       6         0
```
