#' Beta prior from expert quantiles
#'
#' Fits the CDF on the log-odds scale so small target quantiles can be
#' calibrated accurately.
#'
#' @param q Two increasing target quantiles in (0, 1).
#' @param p Two increasing cumulative probabilities for q, in (0, 1).
#' @param start Optional starting values for log(shape1), log(shape2).
#' @param method Optimisation method passed to optim().
#' @param maxit Maximum iterations for optim().
#' @param tol Maximum tolerated absolute probability error at either target.
#'   A larger error triggers a warning regardless of the optimizer status.
#'
#' @return A bf_prior with dist = "beta". Its metadata includes the requested
#'   and achieved quantiles and probabilities, maximum probability error, and
#'   optimizer convergence code.
#'
#' @examples
#' expert_beta_prior(q = c(0.02, 0.08), p = c(0.1, 0.9))
#' expert_beta_prior(q = c(1e-6, 8e-6), p = c(0.025, 0.9))
#'
#' @export
expert_beta_prior <- function(
  q,
  p = c(0.1, 0.9),
  start = NULL,
  method = "BFGS",
  maxit = 2000,
  tol = 1e-6
) {
  validate_quantile_targets(q, p, lower = 0, upper = 1, tol = tol)
  validate_count(maxit, "maxit")

  automatic_start <- is.null(start)
  if (automatic_start) {
    # Approximate logit(X) with a Normal and use the implied Beta moments.
    z <- stats::qnorm(p)
    logit_q <- stats::qlogis(q)
    logit_sd <- diff(logit_q) / diff(z)
    midpoint <- stats::plogis(logit_q[1] - z[1] * logit_sd)
    concentration <- 1 / (midpoint * (1 - midpoint) * logit_sd^2) - 1
    shape <- c(midpoint, 1 - midpoint) * concentration
    start <- c(0, 0)
    if (all(is.finite(shape) & shape > 0)) {
      start <- log(shape)
    }
  } else if (
    !is_numeric_vector(start) || length(start) != 2L ||
      any(!is.finite(start) | !is.finite(exp(start)) | exp(start) == 0)
  ) {
    stop("start must contain two finite log shape values.")
  }

  target <- stats::qlogis(p)
  obj <- function(par) {
    shape <- exp(par)
    if (any(!is.finite(shape) | shape == 0)) {
      return(1e100)
    }
    # Optimizer trial points can take the CDF beyond floating-point limits.
    log_odds <- suppressWarnings(
      stats::pbeta(q, shape[1], shape[2], log.p = TRUE) -
        stats::pbeta(q, shape[1], shape[2], lower.tail = FALSE, log.p = TRUE)
    )
    loss <- sum((log_odds - target)^2)
    if (is.finite(loss)) loss else 1e100
  }

  fit_from <- function(start) {
    fit <- stats::optim(
      par = start,
      fn = obj,
      method = method,
      control = list(maxit = maxit, reltol = 1e-13, ndeps = rep(1e-5, 2L))
    )
    shape <- exp(fit$par)
    achieved_p <- stats::pbeta(q, shape[1], shape[2])
    list(
      shape = shape,
      achieved_p = achieved_p,
      error = max(abs(achieved_p - p)),
      convergence = fit$convergence
    )
  }
  fit <- fit_from(start)
  if (automatic_start && !isTRUE(fit$error <= tol) && any(start != 0)) {
    fallback <- fit_from(c(0, 0))
    if (!is.finite(fit$error) || isTRUE(fallback$error < fit$error)) {
      fit <- fallback
    }
  }

  alpha <- fit$shape[1]
  beta <- fit$shape[2]
  achieved_q <- stats::qbeta(p, alpha, beta)
  metadata <- quantile_fit_metadata(q, p, achieved_q, fit$achieved_p, tol)
  bf_prior(
    dist = "beta",
    params = list(shape1 = alpha, shape2 = beta),
    source = "expert",
    metadata = c(metadata, list(
      err = sum((achieved_q - q)^2),
      convergence = fit$convergence
    ))
  )
}
