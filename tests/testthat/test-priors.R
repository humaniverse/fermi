test_that("Beta elicitation calibrates rare asymmetric targets", {
  q <- c(1e-6, 8e-6)
  p <- c(0.025, 0.9)
  expect_warning(prior <- expert_beta_prior(q, p), NA)
  expect_equal(prior$metadata$p, p)
  expect_equal(prior$metadata$q, q)
  expect_lt(max(abs(do.call(stats::pbeta, c(list(q = q), prior$params)) - p)), 1e-6)
  expect_equal(prior$metadata$achieved_p, do.call(stats::pbeta, c(list(q = q), prior$params)))
  expect_output(print(prior), "achieved_probability")
})

test_that("Beta elicitation reports a poor fit even when optim returns zero", {
  expect_warning(
    prior <- expert_beta_prior(c(0.02, 0.08), start = c(0, 0), maxit = 0),
    "Maximum absolute probability error"
  )
  expect_equal(prior$metadata$convergence, 0L)
  expect_gt(prior$metadata$max_p_error, prior$metadata$tol)
})

test_that("Gamma elicitations refine an imprecise approximation in auto mode", {
  q <- c(2.5e6, 3.5e6)
  p <- c(0.1, 0.9)
  expect_warning(
    approximate <- expert_gamma_prior(q, p, mode = "normal"),
    "Maximum absolute probability error"
  )
  expect_warning(prior <- expert_gamma_prior(q, p), NA)
  expect_identical(prior$metadata$method, "uniroot")
  expect_lt(prior$metadata$max_p_error, 1e-6)
  expect_equal(prior$metadata$achieved_q, q, tolerance = 1e-6)
  expect_gt(approximate$metadata$max_p_error, prior$metadata$max_p_error)
  expect_warning(skewed <- expert_gamma_prior(c(0.2, 1)), NA)
  expect_lt(skewed$metadata$max_p_error, 1e-6)
})

test_that("invalid quantile targets and inconsistent Normal intervals are rejected", {
  expect_error(expert_beta_prior(c(0.2, 0.1)), "increasing")
  expect_error(expert_beta_prior(c(0.2, 0.4), c(0.9, 0.1)), "probabilities")
  expect_error(expert_gamma_prior(c(1, Inf)), "finite quantiles")
  expect_error(expert_gamma_prior(c(1, 2), c(NA, 0.9)), "probabilities")
  expect_error(expert_normal_prior(2.4, 2, 3.2, 0.8), "midpoint")
  expect_error(expert_normal_prior(2.6, 2, 3.2, Inf), "level")

  prior <- expert_normal_prior(2.6, 2, 3.2, 0.8)
  expect_equal(
    do.call(stats::qnorm, c(list(p = c(0.1, 0.9)), prior$params)),
    c(2, 3.2)
  )
})

test_that("data priors fit and draw on their expected supports", {
  for (method in c("mm", "mle")) {
    beta <- fit_beta_prior(c(0.08, 0.12, 0.22, 0.3), method)
    gamma <- fit_gamma_prior(c(2, 4, 5, 6), method)
    expect_identical(beta$source, "data")
    expect_identical(gamma$metadata$method, method)
    draws <- bf_draws(beta, 30)
    expect_true(all(draws > 0 & draws < 1))
    expect_true(all(bf_draws(gamma, 30) > 0))
  }
  normal <- fit_normal_prior(c(-1, 0, 1))
  expect_equal(normal$params, list(mean = 0, sd = 1))
  expect_length(bf_draws(normal, 30), 30)
})

test_that("constructors and drawing validate distribution parameters and counts", {
  expect_error(bf_prior("beta", list(shape1 = 1)), "shape2")
  expect_error(bf_prior("normal", list(mean = NA, sd = 1)), "mean")
  expect_error(bf_posterior("gamma", list(shape = 1, rate = Inf)), "rate")
  expect_error(bf_posterior("beta", list(shape1 = 0, shape2 = 1)), "positive")
  prior <- bf_prior("normal", list(mean = 1, sd = 0))
  expect_equal(bf_draws(prior, 3), rep(1, 3))
  expect_equal(bf_draws(prior, 0), numeric())
  expect_error(bf_draws(prior, 1.5), "integer")
})
