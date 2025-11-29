#' Gamma prior from expert quantiles
#'
#' @param q Numeric vector of length 2: target quantiles (> 0).
#' @param p Numeric vector of length 2: cumulative probabilities for q.
#' @param start Optional starting values for log(shape), log(rate).
#'
#' @return A bf_prior object with dist = "gamma".
#' @export
expert_gamma_prior <- function(q, p = c(0.1, 0.9), start = c(0, 0)) {
  if (length(q) != 2L || length(p) != 2L) {
    stop("q and p must both be length 2.")
  }
  if (any(q <= 0)) stop("Gamma quantiles must be > 0.")
  if (any(p <= 0 | p >= 1)) stop("Probabilities p must lie in (0, 1).")

  obj <- function(par) {
    shape <- exp(par[1])
    rate  <- exp(par[2])
    qg <- stats::qgamma(p, shape = shape, rate = rate)
    sum((qg - q)^2)
  }

  fit <- stats::optim(par = start, fn = obj, method = "BFGS")
  if (fit$convergence != 0) warning("Optimization for expert Gamma prior did not fully converge.")
  shape <- exp(fit$par[1])
  rate  <- exp(fit$par[2])

  bf_prior(
    dist = "gamma",
    params = list(shape = shape, rate = rate),
    source = "expert",
    metadata = list(q = q, p = p)
  )
}
