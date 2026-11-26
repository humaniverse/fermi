test_that("simulations preserve the R class and data frame row names", {
  joint <- data.frame(x = c(4, Inf, 3, 2), y = c(1, 4, 2, 3))
  rownames(joint) <- c("first", "invalid", "third", "last")
  simulated <- bf_fermi_simulate(joint, function(x, y) x + y, nonfinite = "drop")
  expect_s3_class(simulated, "bf_fermi")
  expect_identical(simulated$inputs, joint[c(1, 3, 4), ])
})

test_that("R lists with duplicated component names are rejected", {
  prior <- bf_prior("normal", list(mean = 1, sd = 0))
  expect_error(bf_fermi_simulate(list(x = prior, x = prior), identity), "unique")
})
