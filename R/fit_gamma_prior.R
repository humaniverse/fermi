#' Fit a Gamma prior to positive data
#'
#' @param y Numeric vector with values > 0.
#' @param method "mm" or "mle".
#'
#' @return A bf_prior object with dist = "gamma".
#' @export
fit_gamma_prior <- function(y, method = c("mm", "mle")) {
  method <- match.arg(method)
  y <- as.numeric(y)
  y <- y[is.finite(y)]
  if (any(y <= 0)) {
    stop("All observations must be > 0 to fit a Gamma distribution.")
  }
  if (length(y) < 2L) {
    stop("Need at least two observations to fit a Gamma prior.")
  }

  if (method == "mm") {
    m <- mean(y)
    v <- stats::var(y)
    if (v <= 0) {
      stop("Variance must be positive to use method of moments.")
    }
    shape <- m^2 / v
    rate <- m / v
  } else {
    # MLE via optim
    neg_loglik <- function(par) {
      shape <- exp(par[1])
      rate <- exp(par[2])
      -sum(stats::dgamma(y, shape = shape, rate = rate, log = TRUE))
    }
    fit <- stats::optim(
      par = c(0, 0),
      fn = neg_loglik,
      method = "BFGS"
    )
    if (fit$convergence != 0) {
      warning("MLE for Gamma prior did not fully converge.")
    }
    shape <- exp(fit$par[1])
    rate <- exp(fit$par[2])
  }

  bf_prior(
    dist = "gamma",
    params = list(shape = shape, rate = rate),
    source = "data",
    metadata = list(method = method, n = length(y))
  )
}
