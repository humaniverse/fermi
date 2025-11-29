#' Draw samples from a prior or posterior distribution
#'
#' @param object A bf_prior or bf_posterior.
#' @param n Number of draws.
#'
#' @return Numeric vector of draws.
#' @export
bf_draws <- function(object, n = 4000) {
  if (inherits(object, "bf_prior")) {
    dist <- object$dist
    p <- object$params
  } else if (inherits(object, "bf_posterior")) {
    dist <- object$dist
    p <- object$params
  } else {
    stop("object must be a bf_prior or bf_posterior.")
  }

  switch(
    dist,
    beta = stats::rbeta(n, shape1 = p$shape1, shape2 = p$shape2),
    gamma = stats::rgamma(n, shape = p$shape, rate = p$rate),
    normal = stats::rnorm(n, mean = p$mean, sd = p$sd),
    stop("Unsupported distribution: ", dist)
  )
}
