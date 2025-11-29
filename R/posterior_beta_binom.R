#' Conjugate Beta-Binomial update
#'
#' @param prior A bf_prior with dist = "beta".
#' @param successes Number of successes.
#' @param trials Number of trials.
#'
#' @return A bf_posterior object with dist = "beta".
#' @export
beta_binom_posterior <- function(prior, successes, trials) {
  if (!inherits(prior, "bf_prior") || prior$dist != "beta") {
    stop("prior must be a bf_prior with dist = 'beta'.")
  }
  if (successes < 0 || trials <= 0 || successes > trials) {
    stop("Invalid successes/trials combination.")
  }

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
