#' Draw from a conjugate posterior predictive distribution
#'
#' Draws a parameter from the posterior for each replicate and then samples a
#' future observation from the corresponding likelihood. The result captures
#' uncertainty in both the parameter and the future observation.
#'
#' @param object A bf_posterior from a Beta-Binomial, Gamma-Poisson, or
#'   Normal-Normal model.
#' @param n Positive integer number of predictive draws.
#' @param trials Future trial count for a Beta posterior (default 1).
#' @param exposure Future exposure for a Gamma posterior (default 1).
#' @param obs_sd Future observation standard deviation for a Normal posterior.
#'   By default uses the value stored by [normal_normal_posterior()].
#' @return A numeric vector of predictive draws.
#'
#' @examples
#' prior <- bf_prior("gamma", list(shape = 2, rate = 1))
#' post <- gamma_poisson_posterior(prior, c(3, 4, 2))
#' future <- bf_predict(post, exposure = 30)
#' mean(future > 100)
#'
#' @export
bf_predict <- function(
  object,
  n = 4000,
  trials = NULL,
  exposure = NULL,
  obs_sd = NULL
) {
  if (!inherits(object, "bf_posterior")) {
    stop("object must be a bf_posterior.")
  }
  validate_count(n, "n", minimum = 1)
  dist <- object$dist
  likelihood_arg <- switch(
    dist,
    beta = "trials",
    gamma = "exposure",
    normal = "obs_sd",
    stop("Unsupported distribution: ", dist)
  )
  given <- list(trials = trials, exposure = exposure, obs_sd = obs_sd)
  supplied <- names(given)[!vapply(given, is.null, logical(1))]
  if (any(!supplied %in% likelihood_arg)) {
    stop("Only ", likelihood_arg, " applies to a ", dist, " posterior.")
  }

  if (dist == "beta") {
    if (is.null(trials)) {
      trials <- 1
    }
    validate_count(trials, "trials")
    draws <- stats::rbinom(n, size = trials, prob = bf_draws(object, n))
  } else if (dist == "gamma") {
    if (is.null(exposure)) {
      exposure <- 1
    }
    if (!is_finite_scalar(exposure) || exposure <= 0) {
      stop("exposure must be finite and > 0.")
    }
    lambda <- bf_draws(object, n) * exposure
    if (any(!is.finite(lambda))) {
      stop("Non-finite Poisson means in prediction. Check the rate and exposure.")
    }
    draws <- stats::rpois(n, lambda = lambda)
  } else {
    if (is.null(obs_sd)) {
      obs_sd <- object$data$obs_sd
    }
    if (!is_finite_scalar(obs_sd) || obs_sd <= 0) {
      stop("obs_sd must be supplied as a finite positive number or stored in the posterior.")
    }
    draws <- stats::rnorm(n, mean = bf_draws(object, n), sd = obs_sd)
  }
  if (any(!is.finite(draws))) {
    stop("Prediction produced non-finite draws. Check the model parameters.")
  }
  draws
}
