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
  if (obs_sd <= 0) stop("obs_sd must be > 0.")
  y <- as.numeric(y)
  y <- y[is.finite(y)]
  n <- length(y)
  if (n == 0L) stop("No valid observations.")

  mu0 <- prior$params$mean
  sd0 <- prior$params$sd

  tau0_sq <- sd0^2
  tau_sq  <- obs_sd^2

  ybar <- mean(y)

  prec0 <- 1 / tau0_sq
  prec  <- 1 / tau_sq

  prec_post <- prec0 + n * prec
  var_post  <- 1 / prec_post
  mu_post   <- var_post * (prec0 * mu0 + n * prec * ybar)

  bf_posterior(
    dist = "normal",
    params = list(mean = mu_post, sd = sqrt(var_post)),
    prior = prior,
    data = list(y = y, obs_sd = obs_sd)
  )
}
