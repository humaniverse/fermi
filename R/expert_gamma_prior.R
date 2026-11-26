#' Gamma prior from expert quantiles
#'
#' Uses a Normal approximation for concentrated Gamma distributions when it
#' matches the requested probabilities, and a root finder otherwise.
#'
#' @param q Two increasing positive target quantiles, e.g. c(q10, q90).
#' @param p Two increasing cumulative probabilities for q, in (0, 1).
#' @param shape_switch Minimum implied shape for considering the Normal
#'   approximation in auto mode (default 20). Use `Inf` to always refine.
#' @param mode One of "auto", "normal", "uniroot":
#'   - "auto": try the approximation and refine if needed
#'   - "normal": always use the Normal approximation
#'   - "uniroot": always use the root finder
#' @param tol Maximum tolerated absolute probability error at either target.
#'   A larger error in the final fit triggers a warning.
#'
#' @return A bf_prior with dist = "gamma". Its metadata includes the requested
#'   and achieved quantiles and probabilities, maximum probability error, and
#'   the fitting method used.
#'
#' @examples
#' expert_gamma_prior(q = c(400, 900), p = c(0.1, 0.9))
#' expert_gamma_prior(q = c(0.2, 1), p = c(0.1, 0.9))
#'
#' @export
expert_gamma_prior <- function(
  q,
  p = c(0.1, 0.9),
  shape_switch = 20,
  mode = c("auto", "normal", "uniroot"),
  tol = 1e-6
) {
  mode <- match.arg(mode)
  validate_quantile_targets(q, p, lower = 0, upper = Inf, tol = tol)
  if (
    !is_numeric_vector(shape_switch) || length(shape_switch) != 1L ||
      is.na(shape_switch) || shape_switch < 0
  ) {
    stop("shape_switch must be non-negative.")
  }

  guess <- .gamma_from_quantiles_normal(q, p)
  guess_values <- unlist(guess, use.names = FALSE)
  use_normal <- mode == "normal"
  if (
    mode == "auto" && all(is.finite(guess_values) & guess_values > 0) &&
      guess$shape >= shape_switch
  ) {
    approx_p <- stats::pgamma(q, shape = guess$shape, rate = guess$rate)
    use_normal <- isTRUE(max(abs(approx_p - p)) <= tol)
  }
  method_used <- "normal"
  params <- guess
  if (!use_normal) {
    params <- .gamma_from_quantiles_uniroot(q, p, shape_init = guess$shape)
    method_used <- "uniroot"
  }

  validate_distribution("gamma", params)
  achieved_q <- stats::qgamma(p, shape = params$shape, rate = params$rate)
  achieved_p <- stats::pgamma(q, shape = params$shape, rate = params$rate)
  metadata <- quantile_fit_metadata(q, p, achieved_q, achieved_p, tol)
  bf_prior(
    dist = "gamma",
    params = params,
    source = "expert",
    metadata = c(metadata, list(
      method = method_used,
      shape0 = guess$shape,
      rate0 = guess$rate,
      err_q = sum((achieved_q - q)^2)
    ))
  )
}

.gamma_from_quantiles_normal <- function(q, p) {
  m <- mean(q)
  z <- stats::qnorm(p)
  relative_sd <- ((q[2] - q[1]) / m) / (z[2] - z[1])
  shape <- 1 / relative_sd^2
  list(shape = shape, rate = shape / m)
}

.gamma_from_quantiles_uniroot <- function(q, p, shape_init) {
  # The ratio of the unit-rate quantiles depends only on the shape.
  log_ratio <- function(lower, upper) {
    relative_difference <- (upper - lower) / lower
    if (is.finite(relative_difference)) {
      return(log1p(relative_difference))
    }
    log(upper) - log(lower)
  }
  log_target_ratio <- log_ratio(q[1], q[2])
  f_log_shape <- function(log_shape) {
    shape <- exp(log_shape)
    q1_ref <- stats::qgamma(p[1], shape = shape, rate = 1)
    if (q1_ref == 0) {
      return(Inf)
    }
    q2_ref <- stats::qgamma(p[2], shape = shape, rate = 1)
    log_ratio(q1_ref, q2_ref) - log_target_ratio
  }

  center <- if (is.finite(shape_init) && shape_init > 0) log(shape_init) else 0
  bounds <- center + c(-5, 5)
  root <- stats::uniroot(
    f_log_shape,
    interval = bounds,
    extendInt = "downX",
    tol = 1e-10,
    check.conv = TRUE
  )
  shape <- exp(root$root)
  rate <- stats::qgamma(p[1], shape = shape, rate = 1) / q[1]
  list(shape = shape, rate = rate)
}
