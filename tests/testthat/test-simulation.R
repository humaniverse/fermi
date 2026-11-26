test_that("independent simulations can use a posterior or its attached prior", {
  prior <- bf_prior("normal", list(mean = 2, sd = 0))
  post <- bf_posterior("normal", list(mean = 4, sd = 0), prior = prior)
  components <- list(x = post, y = prior)
  sum_draws <- function(x, y) x + y

  simulated <- bf_fermi_simulate(components, sum_draws, n_draws = 4)
  expect_s3_class(simulated, "bf_fermi")
  expect_equal(simulated$draws, rep(6, 4))
  expect_equal(simulated$inputs$x, rep(4, 4))
  expect_equal(simulated$n_dropped, 0L)
  expect_equal(
    bf_fermi_simulate(components, sum_draws, n_draws = 4, use = "prior")$draws,
    rep(4, 4)
  )
  post$prior <- NULL
  expect_error(
    bf_fermi_simulate(list(x = post), identity, use = "prior"),
    "no attached prior"
  )
})

test_that("joint draws preserve the supplied row order and relationships", {
  joint <- data.frame(x = c(4, 1, 3, 2), y = c(1, 4, 2, 3))
  sim <- bf_fermi_simulate(joint, function(x, y) x + y)
  expect_identical(sim$inputs, joint)
  expect_equal(sim$draws, rep(5, 4))
  expect_error(
    bf_fermi_simulate(joint, function(x, y) x + y, n_draws = 3),
    "must match the number of rows"
  )
  expect_error(
    bf_fermi_simulate(data.frame(x = c("a", "b")), identity),
    "numeric vectors"
  )
})

test_that("invalid draw counts, component names, and output shapes are rejected", {
  prior <- bf_prior("normal", list(mean = 1, sd = 0))
  expect_error(bf_fermi_simulate(list(x = prior, x = prior), identity), "unique")
  expect_error(bf_fermi_simulate(list(prior), identity), "non-empty")
  expect_error(bf_fermi_simulate(list(x = prior), identity, n_draws = 1.5), "integer")
  expect_error(bf_fermi_simulate(list(x = prior), identity, n_draws = 0), "integer")
  expect_error(bf_fermi_simulate(data.frame(x = numeric()), identity), "n_draws")
  expect_error(
    bf_fermi_simulate(data.frame(x = 1:3), function(x) matrix(x)),
    "numeric vector"
  )
  expect_error(
    bf_fermi_simulate(data.frame(x = 1:3), function(x) mean(x)),
    "one value per input row"
  )
})

test_that("excluded non-finite rows are counted and remain aligned", {
  joint <- data.frame(x = c(1, Inf, 3, 4, NA, 6), y = c(10, 20, 0, 40, 50, 60))
  ratio <- function(x, y) {
    stopifnot(all(is.finite(x)))
    x / y
  }
  expect_error(bf_fermi_simulate(joint, ratio), "Inputs contain 2 non-finite")
  expect_error(
    bf_fermi_simulate(joint[c(1, 3, 4, 6), ], ratio),
    "Results contain 1 non-finite"
  )
  sim <- bf_fermi_simulate(joint, ratio, nonfinite = "drop")
  expect_equal(sim$draws, rep(0.1, 3))
  expect_identical(sim$inputs, joint[c(1, 4, 6), ])
  expect_equal(sim$n_dropped, 3)
  expect_equal(posterior_summary(sim)$n_draws, 3)
  expect_output(print(posterior_summary(sim)), "Excluded draws: 3")
  expect_error(
    bf_fermi_simulate(data.frame(x = Inf), identity, nonfinite = "drop"),
    "No finite input draws"
  )
  expect_error(
    bf_fermi_simulate(data.frame(x = 0), function(x) 1 / x, nonfinite = "drop"),
    "No finite result draws"
  )
})
