#' Gamma prior from expert quantiles (hybrid)
#'
#' Uses a normal approximation for "large, bell-shaped" Gammas and a
#' uniroot-based solver for more skewed or small-scale cases.
#'
#' @param q Numeric, length 2: target quantiles (> 0), e.g. c(q10, q90).
#' @param p Numeric, length 2: corresponding probabilities in (0, 1).
#' @param shape_switch Threshold on the implied shape above which we trust
#'   the normal approximation (default 20).
#' @param mode One of "auto", "normal", "uniroot":
#'   - "auto": hybrid behaviour (recommended)
#'   - "normal": always use normal approximation
#'   - "uniroot": always use the uniroot solver
#'
#' @return A bf_prior object with dist = "gamma".
#' @export
expert_gamma_prior <- function(q,
                               p = c(0.1, 0.9),
                               shape_switch = 20,
                               mode = c("auto", "normal", "uniroot")) {
  mode <- match.arg(mode)

  if (length(q) != 2L || length(p) != 2L) {
    stop("q and p must both be length 2.")
  }
  if (any(q <= 0)) stop("Gamma quantiles must be > 0.")
  if (any(p <= 0 | p >= 1)) stop("Probabilities p must lie in (0, 1).")
  if (!(q[2] > q[1])) stop("Require q[2] > q[1].")
  if (!(p[2] > p[1])) stop("Require p[2] > p[1].")

  # 1. Normal-approximation guess for shape/rate
  guess <- .gamma_from_quantiles_normal(q, p)
  shape0 <- guess$shape
  rate0  <- guess$rate

  # 2. Decide which method to use
  use_normal  <- (mode == "normal") ||
                 (mode == "auto" && shape0 >= shape_switch)
  use_uniroot <- (mode == "uniroot") ||
                 (mode == "auto" && shape0 < shape_switch)

  if (use_normal && !use_uniroot) {
    shape <- shape0
    rate  <- rate0
    method_used <- "normal"
  } else if (use_uniroot && !use_normal) {
    sol <- .gamma_from_quantiles_uniroot(q, p, shape_init = shape0)
    shape <- sol$shape
    rate  <- sol$rate
    method_used <- "uniroot"
  } else {
    # should not happen, but just in case:
    sol <- .gamma_from_quantiles_uniroot(q, p, shape_init = shape0)
    shape <- sol$shape
    rate  <- sol$rate
    method_used <- "uniroot"
  }

  # 3. Diagnostics: how close are we to the requested quantiles?
  achieved_q <- stats::qgamma(p, shape = shape, rate = rate)
  err_q <- sum((achieved_q - q)^2)

  if (err_q > max(1e-6 * mean(q)^2, 1e-6)) {
    warning(
      "expert_gamma_prior: quantile match may be imprecise. ",
      "Squared error on q: ", signif(err_q, 3),
      " (method = ", method_used, ", shape ~= ", signif(shape, 3), ")"
    )
  }

  bf_prior(
    dist   = "gamma",
    params = list(shape = shape, rate = rate),
    source = "expert",
    metadata = list(
      q = q,
      p = p,
      method = method_used,
      shape0 = shape0,
      rate0  = rate0,
      err_q  = err_q
    )
  )
}

# Normal-approximation -> Gamma(shape, rate) via method of moments
.gamma_from_quantiles_normal <- function(q, p) {
  # q: length-2 vector of quantiles
  # p: length-2 vector of cumulative probs

  m <- mean(q)
  z <- stats::qnorm(p)
  sd_approx <- (q[2] - q[1]) / (z[2] - z[1])
  if (!is.finite(sd_approx) || sd_approx <= 0) {
    stop("Failed to get a sensible sd_approx from quantiles.")
  }

  v <- sd_approx^2
  shape <- m^2 / v
  rate  <- m / v

  list(shape = shape, rate = rate)
}

# Exact-ish shape/rate via 1D root-finding, using Gamma scaling
.gamma_from_quantiles_uniroot <- function(q, p, shape_init = NULL) {
  target_ratio <- q[2] / q[1]

  # function of log(shape) whose root we want:
  # log( Q(p2; shape,1)/Q(p1; shape,1) ) - log(target_ratio ) = 0
  f_log_shape <- function(log_shape) {
    shape <- exp(log_shape)
    q1_ref <- stats::qgamma(p[1], shape = shape, rate = 1)
    q2_ref <- stats::qgamma(p[2], shape = shape, rate = 1)
    log(q2_ref / q1_ref) - log(target_ratio)
  }

  # bracket the root in log(shape)
  if (is.null(shape_init) || !is.finite(shape_init) || shape_init <= 0) {
    low  <- -5
    high <-  5
  } else {
    low  <- log(shape_init) - 5
    high <- log(shape_init) + 5
  }

  f_low  <- f_log_shape(low)
  f_high <- f_log_shape(high)

  iter <- 0
  while (f_low * f_high > 0 && iter < 10) {
    low  <- low  - 2
    high <- high + 2
    f_low  <- f_log_shape(low)
    f_high <- f_log_shape(high)
    iter <- iter + 1
  }

  if (f_low * f_high > 0) {
    stop("Failed to bracket a root for Gamma shape; check q and p.")
  }

  root <- stats::uniroot(
    f_log_shape,
    lower = low,
    upper = high,
    tol   = 1e-10
  )

  shape <- exp(root$root)

  # Now fix rate so that Q(p[1]; shape, rate) = q[1]
  q1_ref <- stats::qgamma(p[1], shape = shape, rate = 1)
  rate   <- q1_ref / q[1]

  list(shape = shape, rate = rate)
}
