#' Simulate a Fermi estimate
#'
#' @param components A named list of bf_prior and/or bf_posterior objects,
#'   sampled independently, or a numeric data frame with one joint draw per row.
#'   Joint draws are used in the supplied order, preserving dependence.
#' @param fun A vectorised function whose arguments correspond to
#'   `names(components)`. It must return one numeric value per input row.
#' @param n_draws Number of Monte Carlo draws. For a data frame, this defaults
#'   to its number of rows and must match it if supplied.
#' @param use For lists, "posterior" (default) uses posterior parameters when
#'   available. "prior" uses the priors attached to any posterior objects.
#' @param nonfinite "error" (default) rejects non-finite inputs or outputs.
#'   "drop" excludes affected rows from both inputs and output.
#'
#' @return A bf_fermi object with `draws`, their corresponding `inputs`, the
#'   supplied `fun`, and `n_dropped` (the number of excluded rows).
#'
#' @examples
#' joint <- data.frame(demand = c(100, 200, 300), capacity = c(80, 150, 250))
#' bf_fermi_simulate(joint, function(demand, capacity) demand - capacity)
#'
#' @export
bf_fermi_simulate <- function(
  components,
  fun,
  n_draws = 10000,
  use = c("posterior", "prior"),
  nonfinite = c("error", "drop")
) {
  use <- match.arg(use)
  nonfinite <- match.arg(nonfinite)
  if (!is.list(components)) {
    stop("components must be a named list or a numeric data frame.")
  }
  validate_names(components, "components")
  if (!is.function(fun)) {
    stop("fun must be a function.")
  }

  if (is.data.frame(components)) {
    inputs <- as.data.frame(components)
    if (!all(vapply(inputs, is_numeric_vector, logical(1)))) {
      stop("Joint draw columns must be numeric vectors.")
    }
    if (missing(n_draws)) {
      n_draws <- nrow(inputs)
    }
    validate_count(n_draws, "n_draws", minimum = 1)
    if (n_draws != nrow(inputs)) {
      stop("n_draws must match the number of rows in the joint draws.")
    }
  } else {
    validate_count(n_draws, "n_draws", minimum = 1)
    draws_list <- lapply(names(components), function(name) {
      comp <- components[[name]]
      if (!inherits(comp, c("bf_prior", "bf_posterior"))) {
        stop("Component '", name, "' must be a bf_prior or bf_posterior.")
      }
      if (inherits(comp, "bf_posterior") && use == "prior") {
        comp <- comp$prior
        if (is.null(comp)) {
          stop("Posterior for component '", name, "' has no attached prior.")
        }
      }
      bf_draws(comp, n_draws)
    })
    names(draws_list) <- names(components)
    inputs <- as.data.frame(draws_list, optional = TRUE)
  }

  keep <- Reduce(`&`, lapply(inputs, is.finite))
  n_dropped <- check_finite_draws(keep, nonfinite, "Inputs")
  if (!any(keep)) {
    stop("No finite input draws remain.")
  }
  inputs <- inputs[keep, , drop = FALSE]

  # A plain list passes only the component columns as named arguments.
  result_draws <- do.call(fun, as.list(inputs))
  if (!is_numeric_vector(result_draws) || length(result_draws) != nrow(inputs)) {
    stop("fun must return a numeric vector with one value per input row.")
  }
  keep <- is.finite(result_draws)
  n_dropped <- n_dropped + check_finite_draws(keep, nonfinite, "Results")
  if (!any(keep)) {
    stop("No finite result draws remain.")
  }

  structure(
    list(
      draws = result_draws[keep],
      inputs = inputs[keep, , drop = FALSE],
      fun = fun,
      n_dropped = n_dropped
    ),
    class = "bf_fermi"
  )
}
