#' Fit a Normal prior to real-valued data
#'
#' @param y Numeric vector (real-valued).
#'
#' @return A bf_prior object with dist = "normal".
#'
#' @examples
#' # Fit to observed cycle times (days)
#' cycle_times <- c(4.5, 5.2, 4.8, 5.0, 4.9, 5.4)
#' fit_normal_prior(cycle_times)
#'
#' # Fit to centered measurement errors
#' measurement_error <- c(-0.2, 0.1, 0.0, 0.3, -0.1, 0.2)
#' fit_normal_prior(measurement_error)
#'
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
