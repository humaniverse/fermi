#' Highest Density Interval (approximate) from samples
#'
#' @param x Numeric vector of samples.
#' @param cred_level Credible mass (e.g. 0.89).
#' @param nonfinite "error" (default) rejects non-finite draws. "drop" excludes
#'   them and warns with the number excluded.
#'
#' @return Named numeric vector c(lower = , upper = ).
#' @export
hdi <- function(x, cred_level = 0.89, nonfinite = c("error", "drop")) {
  validate_probability(cred_level, "cred_level")
  if (!is_numeric_vector(x)) {
    stop("x must be a numeric vector.")
  }
  keep <- is.finite(x)
  dropped <- check_finite_draws(keep, match.arg(nonfinite), "Samples")
  x <- x[keep]
  n <- length(x)
  if (n < 2L) {
    stop("Need at least two samples for HDI.")
  }
  if (dropped) {
    warning("Excluded ", dropped, " non-finite draw(s).", call. = FALSE)
  }

  x_sorted <- sort(x)
  m <- floor(cred_level * n)
  if (m < 1L) {
    stop("cred_level too small for the sample size.")
  }

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
