#' Beta prior from expert quantiles
#'
#' @param q Numeric vector of length 2: target quantiles.
#' @param p Numeric vector of length 2: cumulative probabilities for q (e.g. c(0.1, 0.9)).
#' @param start Optional starting values for log(shape1), log(shape2).
#'
#' @return A bf_prior object with dist = "beta".
#' @export
expert_beta_prior <- function(q, p = c(0.1, 0.9), start = c(0, 0)) {
  if (length(q) != 2L || length(p) != 2L) {
    stop("q and p must both be length 2.")
  }
  if (any(q <= 0 | q >= 1)) stop("Beta quantiles must lie in (0, 1).")
  if (any(p <= 0 | p >= 1)) stop("Probabilities p must lie in (0, 1).")

  obj <- function(par) {
    a <- exp(par[1])
    b <- exp(par[2])
    qb <- stats::qbeta(p, a, b)
    sum((qb - q)^2)
  }

  fit <- stats::optim(par = start, fn = obj, method = "BFGS")
  if (fit$convergence != 0) warning("Optimization for expert Beta prior did not fully converge.")
  alpha <- exp(fit$par[1])
  beta  <- exp(fit$par[2])

  bf_prior(
    dist = "beta",
    params = list(shape1 = alpha, shape2 = beta),
    source = "expert",
    metadata = list(q = q, p = p)
  )
}
