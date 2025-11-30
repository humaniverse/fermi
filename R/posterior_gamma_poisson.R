#' Conjugate Gamma-Poisson update for a rate
#'
#' @param prior A bf_prior with dist = "gamma".
#' @param y Integer counts (vector or scalar).
#' @param exposure Optional vector of exposures for each observation (defaults to 1 per observation).
#'
#' @return A bf_posterior object with dist = "gamma".
#' @export
gamma_poisson_posterior <- function(prior, y, exposure = NULL) {
  if (!inherits(prior, "bf_prior") || prior$dist != "gamma") {
    stop("prior must be a bf_prior with dist = 'gamma'.")
  }
  y <- as.numeric(y)
  if (any(y < 0 | y != round(y))) {
    stop("Counts y must be non-negative integers.")
  }
  if (is.null(exposure)) {
    exposure <- rep(1, length(y))
  } else {
    exposure <- as.numeric(exposure)
    if (any(exposure <= 0)) {
      stop("Exposures must be > 0.")
    }
    if (length(exposure) != length(y)) {
      stop("y and exposure must have same length.")
    }
  }

  shape0 <- prior$params$shape
  rate0 <- prior$params$rate

  shape_post <- shape0 + sum(y)
  rate_post <- rate0 + sum(exposure)

  bf_posterior(
    dist = "gamma",
    params = list(shape = shape_post, rate = rate_post),
    prior = prior,
    data = list(y = y, exposure = exposure)
  )
}
