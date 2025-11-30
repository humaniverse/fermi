#' Normal prior from expert mean and interval
#'
#' @param mean Expert mean.
#' @param lower Lower bound of central interval.
#' @param upper Upper bound of central interval.
#' @param level Central probability mass in the interval (e.g. 0.9).
#'
#' @return A bf_prior object with dist = "normal".
#' @export
expert_normal_prior <- function(mean, lower, upper, level = 0.9) {
  if (upper <= lower) {
    stop("upper must be greater than lower.")
  }
  if (level <= 0 || level >= 1) {
    stop("level must be in (0, 1).")
  }

  z <- stats::qnorm((1 + level) / 2)
  sd <- (upper - lower) / (2 * z)

  bf_prior(
    dist = "normal",
    params = list(mean = mean, sd = sd),
    source = "expert",
    metadata = list(lower = lower, upper = upper, level = level)
  )
}
