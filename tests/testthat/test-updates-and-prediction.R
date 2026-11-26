test_that("the conjugate updates match their analytic parameters", {
  beta <- bf_prior("beta", list(shape1 = 2, shape2 = 3))
  gamma <- bf_prior("gamma", list(shape = 2, rate = 3))
  normal <- bf_prior("normal", list(mean = 2, sd = 3))

  updated <- beta_binom_posterior(beta, successes = 2, trials = 5)
  expect_equal(updated$params, list(shape1 = 4, shape2 = 6))
  expect_identical(updated$prior, beta)
  expect_equal(
    gamma_poisson_posterior(gamma, c(1, 2), c(0.5, 2))$params,
    list(shape = 5, rate = 5.5)
  )
  updated <- normal_normal_posterior(normal, c(3, 5), obs_sd = 2)
  expect_equal(updated$params, list(mean = 40 / 11, sd = sqrt(18 / 11)))
})

test_that("conjugate updates reject invalid likelihood inputs", {
  beta <- bf_prior("beta", list(shape1 = 1, shape2 = 1))
  gamma <- bf_prior("gamma", list(shape = 1, rate = 1))
  normal <- bf_prior("normal", list(mean = 0, sd = 1))

  expect_error(beta_binom_posterior(beta, 1.5, 10), "successes must be an integer")
  expect_error(beta_binom_posterior(beta, 1, Inf), "trials must be an integer")
  expect_error(beta_binom_posterior(beta, 6, 5), "cannot exceed")
  expect_error(gamma_poisson_posterior(gamma, NA_real_), "Counts")
  expect_error(gamma_poisson_posterior(gamma, 2, Inf), "finite")
  expect_error(gamma_poisson_posterior(gamma, c(1, 2), 0.5), "same length")
  expect_error(normal_normal_posterior(normal, 1, Inf), "finite")
})

test_that("Normal updates handle point priors and extreme scales", {
  point <- bf_prior("normal", list(mean = 2, sd = 0))
  expect_equal(normal_normal_posterior(point, 4, 1)$params, point$params)

  diffuse <- bf_prior("normal", list(mean = 2, sd = 1e200))
  expect_equal(
    normal_normal_posterior(diffuse, 4, 1e200)$params,
    list(mean = 3, sd = 1e200 / sqrt(2))
  )
})

test_that("predictive draws propagate parameter and observation uncertainty", {
  gamma <- bf_prior("gamma", list(shape = 2, rate = 3))
  post <- gamma_poisson_posterior(gamma, c(1, 2))
  set.seed(123)
  expected <- stats::rpois(30, lambda = bf_draws(post, 30) * 5)
  set.seed(123)
  expect_equal(bf_predict(post, n = 30, exposure = 5), expected)

  beta <- bf_prior("beta", list(shape1 = 2, shape2 = 3))
  post <- beta_binom_posterior(beta, 1, 3)
  set.seed(123)
  expected <- stats::rbinom(30, size = 4, prob = bf_draws(post, 30))
  set.seed(123)
  expect_equal(bf_predict(post, n = 30, trials = 4), expected)

  normal <- bf_prior("normal", list(mean = 0, sd = 1))
  post <- normal_normal_posterior(normal, c(1, 3), obs_sd = 3)
  set.seed(123)
  expected <- stats::rnorm(30, mean = bf_draws(post, 30), sd = 3)
  set.seed(123)
  expect_equal(bf_predict(post, n = 30), expected)
  set.seed(123)
  expected <- stats::rnorm(30, mean = bf_draws(post, 30), sd = 2)
  set.seed(123)
  expect_equal(bf_predict(post, n = 30, obs_sd = 2), expected)
})

test_that("prediction validates future observation parameters", {
  gamma <- bf_posterior("gamma", list(shape = 2, rate = 3))
  beta <- bf_posterior("beta", list(shape1 = 2, shape2 = 3))
  normal <- bf_posterior("normal", list(mean = 0, sd = 1))
  expect_error(bf_predict(gamma, exposure = Inf), "finite")
  expect_error(bf_predict(gamma, trials = 5), "Only exposure")
  expect_error(bf_predict(beta, trials = 2.5), "integer")
  expect_error(bf_predict(normal), "obs_sd")
  expect_error(bf_predict(normal, n = 1.5, obs_sd = 1), "n must be an integer")
  expect_equal(bf_predict(beta, n = 3, trials = 0), rep(0, 3))
})
