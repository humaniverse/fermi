#' Rank input associations with a Fermi estimate
#'
#' Computes Spearman rank correlations from the paired input and output draws.
#' The result describes associations under the simulated assumptions.
#' Interactions, dependence, and non-monotone relationships can make a rank
#' correlation a poor measure of an input's importance.
#'
#' @param object A result from [bf_fermi_simulate()] with at least two draws.
#' @return A data frame with `component` and signed `spearman` correlation,
#'   ordered by decreasing absolute correlation. Constant inputs or outputs
#'   give `NA` correlations.
#' @examples
#' joint <- data.frame(volume = c(10, 30, 20), price = c(2, 2, 2))
#' sim <- bf_fermi_simulate(joint, function(volume, price) volume * price)
#' bf_sensitivity(sim)
#' @export
bf_sensitivity <- function(object) {
  if (!inherits(object, "bf_fermi")) {
    stop("object must be a bf_fermi simulation.")
  }
  draws <- object$draws
  inputs <- object$inputs
  if (length(draws) < 2L) {
    stop("At least two draws are needed for sensitivity analysis.")
  }
  check_finite_draws(is.finite(draws), "error", "Results")
  check_finite_draws(Reduce(`&`, lapply(inputs, is.finite)), "error", "Inputs")

  output_ranks <- rank(draws)
  constant_output <- all(draws == draws[1])
  spearman <- vapply(inputs, function(x) {
    if (constant_output || all(x == x[1])) {
      return(NA_real_)
    }
    stats::cor(rank(x), output_ranks)
  }, numeric(1))

  ranking <- order(abs(spearman), decreasing = TRUE)
  data.frame(
    component = names(inputs)[ranking],
    spearman = unname(spearman[ranking])
  )
}

#' Compare Fermi estimation scenarios
#'
#' Run [bf_fermi_simulate()] for each set of assumptions, then pass the named
#' results here to compare their medians and equal-tailed credible intervals.
#'
#' @param scenarios A named list of bf_fermi simulations.
#' @param cred_level Credible interval level (default 0.89).
#' @return A data frame with one row per scenario, in the order provided.
#'
#' @examples
#' totals <- function(volume) volume * 2
#' baseline <- bf_fermi_simulate(data.frame(volume = 10:15), totals)
#' higher <- bf_fermi_simulate(data.frame(volume = 15:20), totals)
#' bf_compare_scenarios(list(baseline = baseline, higher = higher))
#'
#' @export
bf_compare_scenarios <- function(scenarios, cred_level = 0.89) {
  if (!is.list(scenarios)) {
    stop("scenarios must be a named list of bf_fermi simulations.")
  }
  validate_names(scenarios, "scenarios")
  summaries <- lapply(scenarios, function(sim) {
    if (!inherits(sim, "bf_fermi")) {
      stop("Each scenario must be a bf_fermi simulation.")
    }
    summary <- posterior_summary(sim, cred_level = cred_level, hdi = FALSE)
    c(
      median = summary$median,
      summary$ci,
      n_draws = summary$n_draws,
      n_dropped = summary$n_dropped
    )
  })
  data.frame(
    scenario = names(scenarios),
    do.call(rbind, unname(summaries)),
    row.names = NULL
  )
}
