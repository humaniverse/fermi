#' Plot posterior or Fermi distribution
#'
#' @param object A bf_posterior, bf_fermi, bf_prior, or numeric vector of draws.
#' @param cred_level Credible interval level (default 0.89).
#' @param hdi Logical: annotate HDI?
#' @param ... Passed to underlying plotting function.
#' @param nonfinite "error" (default) rejects non-finite draws. "drop" excludes
#'   them and reports the count in the returned summary.
#' @return The posterior summary, invisibly.
#'
#' @importFrom graphics abline plot segments
#' @importFrom rlang .data
#' @export
plot_posterior <- function(
  object,
  cred_level = 0.89,
  hdi = TRUE,
  ...,
  nonfinite = c("error", "drop")
) {
  samples <- summary_draws(object, match.arg(nonfinite))
  draws <- samples$draws
  summary <- summarise_draws(samples, cred_level, hdi)

  if (requireNamespace("ggplot2", quietly = TRUE)) {
    df <- data.frame(x = draws)
    g <- ggplot2::ggplot(df, ggplot2::aes(x = .data$x)) +
      ggplot2::geom_density() +
      ggplot2::labs(
        x = "Value",
        y = "Density",
        title = "Posterior distribution",
        subtitle = paste0(
          "Median and ",
          cred_level * 100,
          "% credible interval"
        )
      )

    g <- g +
      ggplot2::geom_vline(xintercept = summary$median, linetype = "dashed") +
      ggplot2::geom_vline(xintercept = summary$ci, linetype = "dotted")

    if (!is.null(summary$hdi)) {
      g <- g +
        ggplot2::annotate(
          "segment",
          x = summary$hdi["lower"],
          xend = summary$hdi["upper"],
          y = 0,
          yend = 0,
          linewidth = 1.1
        )
    }
    print(g)
  } else {
    # Base R fallback
    dens <- stats::density(draws)
    plot(
      dens,
      main = "Posterior distribution",
      xlab = "Value",
      ylab = "Density",
      ...
    )
    abline(v = summary$median, lty = 2)
    abline(v = summary$ci, lty = 3)
    if (!is.null(summary$hdi)) {
      segments(summary$hdi["lower"], 0, summary$hdi["upper"], 0, lwd = 2)
    }
  }

  invisible(summary)
}
