#' Summarise a posterior or Fermi distribution
#'
#' @param object A bf_posterior, bf_fermi, or numeric vector of draws.
#' @param cred_level Credible interval level (default 0.89).
#' @param hdi Logical: include HDI?
#'
#' @return A list with median, ci, and (optionally) hdi.
#' @export
posterior_summary <- function(object, cred_level = 0.89, hdi = TRUE) {
  if (cred_level <= 0 || cred_level >= 1) {
    stop("cred_level must be in (0, 1).")
  }

  draws <- if (
    inherits(object, "bf_posterior") ||
      inherits(object, "bf_prior")
  ) {
    bf_draws(object)
  } else if (inherits(object, "bf_fermi")) {
    object$draws
  } else if (is.numeric(object)) {
    object
  } else {
    stop("Unsupported object type for posterior_summary.")
  }

  draws <- draws[is.finite(draws)]
  if (length(draws) < 2L) {
    stop("Not enough draws for summary.")
  }

  med <- stats::median(draws)
  alpha <- (1 - cred_level) / 2
  ci <- stats::quantile(draws, probs = c(alpha, 1 - alpha), names = FALSE)

  out <- list(
    median = med,
    ci = c(lower = ci[1], upper = ci[2]),
    cred_level = cred_level
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
  cat("  Credible level:", x$cred_level * 100, "%\n")
  cat("  Median        :", x$median, "\n")
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
  invisible(x)
}
