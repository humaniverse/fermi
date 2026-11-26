#' Conjugate Normal-Normal update (known observation sd)
#'
#' @param prior A bf_prior with dist = "normal".
#' @param y Observations.
#' @param obs_sd Known standard deviation of observations.
#'
#' @return A bf_posterior object with dist = "normal".
#' @export
normal_normal_posterior <- function(prior, y, obs_sd) {
  if (!inherits(prior, "bf_prior") || prior$dist != "normal") {
    stop("prior must be a bf_prior with dist = 'normal'.")
  }
  if (!is_finite_scalar(obs_sd) || obs_sd <= 0) {
    stop("obs_sd must be finite and > 0.")
  }
  y <- as.numeric(y)
  y <- y[is.finite(y)]
  n <- length(y)
  if (n == 0L) {
    stop("No valid observations.")
  }

  validate_distribution(prior$dist, prior$params)
  mu0 <- prior$params$mean
  sd0 <- prior$params$sd

  # Scale by the smaller standard deviation to avoid squaring large values.
  data_sd <- obs_sd / sqrt(n)
  smaller <- min(sd0, data_sd)
  if (smaller == 0) {
    params <- if (sd0 == 0) prior$params else list(mean = mean(y), sd = 0)
  } else {
    prior_precision <- (smaller / sd0)^2
    data_precision <- (smaller / data_sd)^2
    precision <- prior_precision + data_precision
    params <- list(
      mean = (prior_precision / precision) * mu0 +
        (data_precision / precision) * mean(y),
      sd = smaller / sqrt(precision)
    )
  }

  bf_posterior(
    dist = "normal",
    params = params,
    prior = prior,
    data = list(y = y, obs_sd = obs_sd)
  )
}
