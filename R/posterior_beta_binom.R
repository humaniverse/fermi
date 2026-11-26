#' Conjugate Beta-Binomial update
#'
#' @param prior A bf_prior with dist = "beta".
#' @param successes Non-negative integer number of successes.
#' @param trials Positive integer number of trials.
#'
#' @return A bf_posterior object with dist = "beta".
#' @export
beta_binom_posterior <- function(prior, successes, trials) {
  if (!inherits(prior, "bf_prior") || prior$dist != "beta") {
    stop("prior must be a bf_prior with dist = 'beta'.")
  }
  validate_count(successes, "successes")
  validate_count(trials, "trials", minimum = 1)
  if (successes > trials) {
    stop("successes cannot exceed trials.")
  }

  validate_distribution(prior$dist, prior$params)
  a0 <- prior$params$shape1
  b0 <- prior$params$shape2

  a_post <- a0 + successes
  b_post <- b0 + (trials - successes)

  bf_posterior(
    dist = "beta",
    params = list(shape1 = a_post, shape2 = b_post),
    prior = prior,
    data = list(successes = successes, trials = trials)
  )
}
