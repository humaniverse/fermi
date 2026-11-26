#' Summarise a posterior or Fermi distribution
#'
#' @param object A bf_prior, bf_posterior, bf_fermi, or numeric vector of draws.
#' @param cred_level Credible interval level (default 0.89).
#' @param hdi Logical: include HDI?
#' @param nonfinite "error" (default) rejects non-finite draws. "drop" excludes
#'   them and includes them in the reported count of dropped draws.
#'
#' @return A list with median, ci, and (optionally) hdi, plus counts of retained
#'   (`n_draws`) and excluded (`n_dropped`) draws.
#' @export
posterior_summary <- function(
  object,
  cred_level = 0.89,
  hdi = TRUE,
  nonfinite = c("error", "drop")
) {
  samples <- summary_draws(object, match.arg(nonfinite))
  summarise_draws(samples, cred_level, hdi)
}

summary_draws <- function(object, nonfinite) {
  n_dropped <- 0L
  draws <- if (
    inherits(object, "bf_posterior") ||
      inherits(object, "bf_prior")
  ) {
    bf_draws(object)
  } else if (inherits(object, "bf_fermi")) {
    # Simulations created before non-finite draw validation have no count.
    if (!is.null(object$n_dropped)) {
      n_dropped <- object$n_dropped
    }
    object$draws
  } else if (is_numeric_vector(object)) {
    object
  } else {
    stop("object must be a bf_prior, bf_posterior, bf_fermi or numeric vector.")
  }

  keep <- is.finite(draws)
  n_dropped <- n_dropped + check_finite_draws(keep, nonfinite, "Samples")
  draws <- draws[keep]
  if (length(draws) < 2L) {
    stop("At least two finite draws are needed.")
  }

  list(draws = draws, n_dropped = n_dropped)
}

summarise_draws <- function(samples, cred_level, hdi) {
  validate_probability(cred_level, "cred_level")
  draws <- samples$draws
  med <- stats::median(draws)
  alpha <- (1 - cred_level) / 2
  ci <- stats::quantile(draws, probs = c(alpha, 1 - alpha), names = FALSE)

  out <- list(
    median = med,
    ci = c(lower = ci[1], upper = ci[2]),
    cred_level = cred_level,
    n_draws = length(draws),
    n_dropped = samples$n_dropped
  )

  if (hdi) {
    out$hdi <- hdi(draws, cred_level = cred_level)
  }

  class(out) <- c("bf_summary", class(out))
  out
}

#' @export
print.bf_summary <- function(x, ...) {
  cat("Posterior summary\n")
  cat("  Credible level: ", x$cred_level * 100, " %\n", sep = "")
  cat("  Median        : ", x$median, "\n", sep = "")
  cat(
    "  CI            : [",
    x$ci["lower"],
    ", ",
    x$ci["upper"],
    "]\n",
    sep = ""
  )
  if (!is.null(x$hdi)) {
    cat(
      "  HDI           : [",
      x$hdi["lower"],
      ", ",
      x$hdi["upper"],
      "]\n",
      sep = ""
    )
  }
  if (isTRUE(x$n_dropped > 0)) {
    cat("  Excluded draws:", x$n_dropped, "\n")
  }
  invisible(x)
}
