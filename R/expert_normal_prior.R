#' Normal prior from expert mean and interval
#'
#' @param mean Expert mean. It must match the midpoint of the central interval.
#' @param lower Lower bound of central interval.
#' @param upper Upper bound of central interval.
#' @param level Central probability mass in the interval (e.g. 0.9).
#'
#' @return A bf_prior object with dist = "normal".
#'
#' @examples
#' # Delivery time centered on 3 days with a 90% interval of [2.5, 3.5]
#' expert_normal_prior(mean = 3, lower = 2.5, upper = 3.5, level = 0.9)
#'
#' # Revenue per user guess: 90% central interval between $8 and $16
#' expert_normal_prior(mean = 12, lower = 8, upper = 16, level = 0.9)
#'
#' @export
expert_normal_prior <- function(mean, lower, upper, level = 0.9) {
  if (!is_finite_scalar(lower) || !is_finite_scalar(upper) || upper <= lower) {
    stop("lower and upper must be finite numbers with lower < upper.")
  }
  validate_probability(level, "level")

  midpoint <- lower / 2 + upper / 2
  tolerance <- 8 * .Machine$double.eps * max(abs(c(lower, upper)))
  if (!is_finite_scalar(mean) || abs(mean - midpoint) > tolerance) {
    stop("mean must match the midpoint of the central interval.")
  }

  z <- stats::qnorm((1 - level) / 2, lower.tail = FALSE)
  sd <- (upper / 2 - lower / 2) / z
  if (!is_finite_scalar(sd) || sd <= 0) {
    stop("Could not compute a finite positive sd from the central interval.")
  }
  bf_prior(
    dist = "normal",
    params = list(mean = mean, sd = sd),
    source = "expert",
    metadata = list(lower = lower, upper = upper, level = level)
  )
}
