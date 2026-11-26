test_that("summaries compute credible intervals and track exclusions", {
  draws <- c(1:9, Inf, NaN, NA)
  expect_error(posterior_summary(draws), "3 non-finite")
  summary <- posterior_summary(draws, cred_level = 0.5, nonfinite = "drop")
  expect_s3_class(summary, "bf_summary")
  expect_equal(summary$median, 5)
  expect_equal(summary$ci, c(lower = 3, upper = 7))
  expect_equal(summary$hdi, c(lower = 1, upper = 5))
  expect_equal(summary$n_draws, 9)
  expect_equal(summary$n_dropped, 3)
  expect_null(posterior_summary(1:9, hdi = FALSE)$hdi)
  expect_error(posterior_summary(1:9, cred_level = NA_real_), "cred_level")
  expect_error(hdi(draws), "non-finite")
  expect_warning(hdi(draws, nonfinite = "drop"), "Excluded 3")
})

test_that("summaries handle simulations saved before exclusion counts existed", {
  saved <- structure(list(draws = c(1:3, Inf)), class = "bf_fermi")
  expect_error(posterior_summary(saved), "non-finite")
  expect_equal(posterior_summary(saved, nonfinite = "drop")$n_dropped, 1L)
  saved$draws <- 1:3
  expect_equal(posterior_summary(saved)$n_dropped, 0L)
})

test_that("plots return the same exclusion counts as summaries", {
  draws <- c(1:9, Inf)
  expect_error(plot_posterior(draws), "non-finite")
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off())
  expect_equal(
    plot_posterior(draws, nonfinite = "drop"),
    posterior_summary(draws, nonfinite = "drop")
  )
})

test_that("sensitivity ranks signed associations by absolute magnitude", {
  joint <- data.frame(
    reverse = 5:1, constant = 3, weaker = c(2, 4, 3, 1, 5), flow = 1:5
  )
  sim <- bf_fermi_simulate(joint, function(reverse, constant, weaker, flow) flow)
  out <- bf_sensitivity(sim)
  expect_equal(out$component, c("reverse", "flow", "weaker", "constant"))
  expect_equal(out$spearman, c(-1, 1, cor(joint$weaker, joint$flow), NA))
  sim$draws[] <- 0
  expect_true(all(is.na(bf_sensitivity(sim)$spearman)))
})

test_that("scenario comparisons retain labels and report draw counts and intervals", {
  base <- bf_fermi_simulate(data.frame(x = 1:5), identity)
  higher <- bf_fermi_simulate(
    data.frame(x = c(2:6, Inf)), identity, nonfinite = "drop"
  )
  comparison <- bf_compare_scenarios(list(base = base, higher = higher), 0.5)
  expect_equal(comparison, data.frame(
    scenario = c("base", "higher"),
    median = c(3, 4),
    lower = c(2, 3),
    upper = c(4, 5),
    n_draws = c(5, 5),
    n_dropped = c(0, 1)
  ))
  expect_error(bf_compare_scenarios(list(base)), "names")
  expect_error(bf_compare_scenarios(list(base = 1:5)), "bf_fermi")
})
