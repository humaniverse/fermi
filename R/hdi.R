#' Highest Density Interval (approximate) from samples
#'
#' @param x Numeric vector of samples.
#' @param cred_level Credible mass (e.g. 0.89).
#'
#' @return Named numeric vector c(lower = , upper = ).
#' @export
hdi <- function(x, cred_level = 0.89) {
  x <- x[is.finite(x)]
  n <- length(x)
  if (n < 2L) stop("Need at least two samples for HDI.")
  if (cred_level <= 0 || cred_level >= 1) stop("cred_level must be in (0, 1).")

  x_sorted <- sort(x)
  m <- floor(cred_level * n)
  if (m < 1L) stop("cred_level too small for the sample size.")

  n_intervals <- n - m
  low_idx <- seq_len(n_intervals)
  high_idx <- low_idx + m

  interval_widths <- x_sorted[high_idx] - x_sorted[low_idx]
  min_idx <- which.min(interval_widths)

  c(
    lower = x_sorted[low_idx[min_idx]],
    upper = x_sorted[high_idx[min_idx]]
  )
}
