test_that("summaries handle simulations saved before exclusion counts existed", {
  saved <- structure(list(draws = c(1:3, Inf)), class = "bf_fermi")
  expect_error(posterior_summary(saved), "non-finite")
  expect_equal(posterior_summary(saved, nonfinite = "drop")$n_dropped, 1L)
  saved$draws <- 1:3
  expect_equal(posterior_summary(saved)$n_dropped, 0L)
})

test_that("plots return the same summary invisibly and summaries print exclusions", {
  draws <- c(1:9, Inf)
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off())
  plotted <- withVisible(plot_posterior(draws, nonfinite = "drop"))
  expect_false(plotted$visible)
  expect_s3_class(plotted$value, "bf_summary")
  expect_equal(plotted$value, posterior_summary(draws, nonfinite = "drop"))
  expect_output(print(plotted$value), "Excluded draws: 1")
})
