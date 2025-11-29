#' Fit a Beta prior to data
#'
#' @param y Numeric vector with values strictly between 0 and 1.
#' @param method "mm" (method of moments) or "mle" (maximum likelihood).
#'
#' @return A bf_prior object with dist = "beta".
#' @export
fit_beta_prior <- function(y, method = c("mm", "mle")) {
  method <- match.arg(method)
  y <- as.numeric(y)
  if (any(y <= 0 | y >= 1, na.rm = TRUE)) {
    stop("All observations must be in (0, 1) to fit a Beta distribution.")
  }
  y <- y[is.finite(y)]
  if (length(y) < 2L) stop("Need at least two observations to fit a Beta prior.")

  if (method == "mm") {
    m <- mean(y)
    v <- stats::var(y)
    if (v <= 0) stop("Variance must be positive to use method of moments.")
    common <- m * (1 - m) / v - 1
    if (common <= 0) {
      stop("Sample variance too large relative to mean; Beta MoM fails. Try method = 'mle'.")
    }
    alpha <- m * common
    beta  <- (1 - m) * common
  } else { # MLE via optim
    neg_loglik <- function(par) {
      a <- exp(par[1])
      b <- exp(par[2])
      -sum(stats::dbeta(y, a, b, log = TRUE))
    }
    fit <- stats::optim(
      par = c(0, 0),
      fn = neg_loglik,
      method = "BFGS"
    )
    if (fit$convergence != 0) warning("MLE for Beta prior did not fully converge.")
    alpha <- exp(fit$par[1])
    beta  <- exp(fit$par[2])
  }

  bf_prior(
    dist = "beta",
    params = list(shape1 = alpha, shape2 = beta),
    source = "data",
    metadata = list(method = method, n = length(y))
  )
}
