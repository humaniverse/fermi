#' Fit a Normal prior to real-valued data
#'
#' @param y Numeric vector (real-valued).
#'
#' @return A bf_prior object with dist = "normal".
#' @export
fit_normal_prior <- function(y) {
  y <- as.numeric(y)
  y <- y[is.finite(y)]
  if (length(y) < 2L) {
    stop("Need at least two observations to fit a Normal prior.")
  }
  mu <- mean(y)
  sigma <- stats::sd(y)
  if (sigma <= 0) {
    stop("Standard deviation must be positive.")
  }

  bf_prior(
    dist = "normal",
    params = list(mean = mu, sd = sigma),
    source = "data",
    metadata = list(n = length(y))
  )
}
