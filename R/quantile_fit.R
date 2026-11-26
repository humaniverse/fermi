validate_quantile_targets <- function(q, p, lower, upper, tol) {
  if (
    !is_numeric_vector(q) || length(q) != 2L ||
      any(!is.finite(q) | q <= lower | q >= upper) || q[1] >= q[2]
  ) {
    stop(
      "q must contain two increasing finite quantiles in (",
      lower, ", ", upper, ").",
      call. = FALSE
    )
  }
  if (
    !is_numeric_vector(p) || length(p) != 2L ||
      any(!is.finite(p) | p <= 0 | p >= 1) || p[1] >= p[2]
  ) {
    stop("p must contain two increasing probabilities in (0, 1).", call. = FALSE)
  }
  if (!is_finite_scalar(tol) || tol < 0 || tol > 1) {
    stop("tol must be a finite probability error between 0 and 1.", call. = FALSE)
  }
}

quantile_fit_metadata <- function(q, p, achieved_q, achieved_p, tol) {
  max_p_error <- max(abs(achieved_p - p))
  if (!is.finite(max_p_error) || max_p_error > tol) {
    warning(
      "Quantile match is imprecise. Maximum absolute probability error: ",
      signif(max_p_error, 3), " (tolerance: ", tol, ").",
      call. = FALSE
    )
  }
  list(
    q = q,
    p = p,
    achieved_q = achieved_q,
    achieved_p = achieved_p,
    max_p_error = max_p_error,
    tol = tol
  )
}
