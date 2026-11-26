#' Draw samples from a prior or posterior distribution
#'
#' @param object A bf_prior or bf_posterior.
#' @param n Non-negative integer number of draws.
#'
#' @return Numeric vector of draws.
#' @export
bf_draws <- function(object, n = 4000) {
  if (!inherits(object, c("bf_prior", "bf_posterior"))) {
    stop("object must be a bf_prior or bf_posterior.")
  }
  validate_count(n, "n")
  dist <- object$dist
  p <- object$params
  validate_distribution(dist, p)

  switch(
    dist,
    beta = stats::rbeta(n, shape1 = p$shape1, shape2 = p$shape2),
    gamma = stats::rgamma(n, shape = p$shape, rate = p$rate),
    normal = stats::rnorm(n, mean = p$mean, sd = p$sd),
    stop("Unsupported distribution: ", dist)
  )
}
