#' Normal prior from expert mean and interval
#'
#' @param mean Expert mean.
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
