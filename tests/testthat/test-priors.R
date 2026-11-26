test_that("R prints the fitted calibration probabilities", {
  q <- c(1e-6, 8e-6)
  p <- c(0.025, 0.9)
  prior <- expert_beta_prior(q, p)
  expect_s3_class(prior, "bf_prior")
  expect_equal(prior$metadata$achieved_p, do.call(stats::pbeta, c(list(q = q), prior$params)))
  expect_output(print(prior), "achieved_probability")
})
