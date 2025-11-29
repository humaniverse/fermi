#' Fermi-style simulation from a combination of priors/posteriors
#'
#' @param components Named list of bf_prior and/or bf_posterior objects.
#' @param fun A function whose arguments correspond to names(components).
#' @param n_draws Number of Monte Carlo draws.
#' @param use Character. "posterior" (default) uses posterior params if available,
#'   otherwise prior; "prior" forces use of priors only.
#'
#' @return A list with draws for the derived quantity and input draws.
#' @export
bf_fermi_simulate <- function(components, fun, n_draws = 10000,
                              use = c("posterior", "prior")) {
  use <- match.arg(use)
  if (is.null(names(components)) || any(names(components) == "")) {
    stop("components must be a *named* list.")
  }
  if (!is.function(fun)) stop("fun must be a function.")

  draws_list <- list()
  for (nm in names(components)) {
    comp <- components[[nm]]
    if (inherits(comp, "bf_posterior") && use == "posterior") {
      draws_list[[nm]] <- bf_draws(comp, n_draws)
    } else if (inherits(comp, "bf_prior")) {
      draws_list[[nm]] <- bf_draws(comp, n_draws)
    } else if (inherits(comp, "bf_posterior") && use == "prior") {
      if (is.null(comp$prior)) {
        stop("Requested use = 'prior' but posterior has no attached prior for component '", nm, "'.")
      }
      draws_list[[nm]] <- bf_draws(comp$prior, n_draws)
    } else {
      stop("Each component must be bf_prior or bf_posterior.")
    }
  }

  # Convert to data.frame so the function can use vectorised operations
  df <- as.data.frame(draws_list, stringsAsFactors = FALSE)

  # Call fun in a vectorised way: fun must accept vectors
  result_draws <- do.call(fun, df)

  if (!is.numeric(result_draws) || length(result_draws) != n_draws) {
    stop("fun must return a numeric vector of length n_draws.")
  }

  structure(
    list(
      draws = result_draws,
      inputs = df,
      fun = fun
    ),
    class = "bf_fermi"
  )
}
