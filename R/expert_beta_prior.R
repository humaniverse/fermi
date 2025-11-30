#' Beta prior from expert quantiles (robust version)
#'
#' @param q Numeric vector of length 2: target quantiles in (0, 1).
#' @param p Numeric vector of length 2: cumulative probabilities for q.
#' @param start Optional starting values for log(shape1), log(shape2).
#' @param method Optimisation method passed to optim().
#' @param maxit Maximum iterations for optim().
#' @param tol Tolerance on squared error between target and achieved quantiles
#'   below which we don't complain even if optim() reports non-convergence.
#'
#' @return A bf_prior object with dist = "beta".
#'
#' @examples
#' # 10% and 90% quantiles at 2% and 8%: e.g., piano ownership fraction
#' expert_beta_prior(q = c(0.02, 0.08), p = c(0.1, 0.9))
#'
#' # Asymmetric beliefs: 25% chance below 3%, 75% chance below 10%
#' expert_beta_prior(q = c(0.03, 0.10), p = c(0.25, 0.75))
#'
#' @export
expert_beta_prior <- function(
  q,
  p = c(0.1, 0.9),
  start = NULL,
  method = "BFGS",
  maxit = 2000,
  tol = 1e-10
) {
  if (length(q) != 2L || length(p) != 2L) {
    stop("q and p must both be length 2.")
  }
  if (any(q <= 0 | q >= 1)) {
    stop("Beta quantiles must lie in (0, 1).")
  }
  if (any(p <= 0 | p >= 1)) {
    stop("Probabilities p must lie in (0, 1).")
  }

  # If no start given and p is symmetric around 0.5, use a MoM-based guess
  if (is.null(start)) {
    if (abs(p[1] + p[2] - 1) < 1e-8) {
      m <- mean(q)
      z <- stats::qnorm(p[2]) # e.g. qnorm(0.9)
      sd_approx <- (q[2] - q[1]) / (2 * z)
      v <- sd_approx^2
      common <- m * (1 - m) / v - 1

      if (is.finite(common) && common > 0) {
        a0 <- m * common
        b0 <- (1 - m) * common
        start <- log(c(a0, b0))
      } else {
        # fall back if MoM breaks
        start <- c(0, 0)
      }
    } else {
      # non-symmetric probs: fall back to (1,1)
      start <- c(0, 0)
    }
  }

  obj <- function(par) {
    a <- exp(par[1])
    b <- exp(par[2])
    qb <- stats::qbeta(p, a, b)
    sum((qb - q)^2)
  }

  fit <- stats::optim(
    par = start,
    fn = obj,
    method = method,
    control = list(maxit = maxit)
  )

  alpha <- exp(fit$par[1])
  beta <- exp(fit$par[2])

  # Check how well we actually match the target quantiles
  achieved <- stats::qbeta(p, alpha, beta)
  err <- sum((achieved - q)^2)

  if (fit$convergence != 0 && err > tol) {
    warning(
      "Optimization for expert Beta prior did not fully converge. ",
      "Final squared error on target quantiles: ",
      signif(err, 3)
    )
  }

  bf_prior(
    dist = "beta",
    params = list(shape1 = alpha, shape2 = beta),
    source = "expert",
    metadata = list(q = q, p = p, err = err)
  )
}
