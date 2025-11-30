#' Create a bayesfermi prior object
#'
#' @param dist Character. One of "beta", "gamma", "normal".
#' @param params Named list of parameters (e.g. list(shape1 = , shape2 = )).
#' @param source Character. "data" or "expert".
#' @param metadata Optional list with any extra info (e.g. description).
#'
#' @return An object of class "bf_prior".
#' @export
bf_prior <- function(
  dist,
  params,
  source = c("data", "expert"),
  metadata = list()
) {
  source <- match.arg(source)
  dist <- match.arg(dist, c("beta", "gamma", "normal"))
  stopifnot(is.list(params))
  structure(
    list(
      dist = dist,
      params = params,
      source = source,
      metadata = metadata
    ),
    class = "bf_prior"
  )
}

#' Create a bayesfermi posterior object
#'
#' @param dist Character. One of "beta", "gamma", "normal".
#' @param params Named list of posterior parameters.
#' @param prior A bf_prior object (optional but recommended).
#' @param data A list describing the data used for the update.
#'
#' @return An object of class "bf_posterior".
#' @export
bf_posterior <- function(dist, params, prior = NULL, data = list()) {
  dist <- match.arg(dist, c("beta", "gamma", "normal"))
  structure(
    list(
      dist = dist,
      params = params,
      prior = prior,
      data = data
    ),
    class = "bf_posterior"
  )
}

#' @export
print.bf_prior <- function(x, ...) {
  cat("bayesfermi prior\n")
  cat("  Distribution:", x$dist, "\n")
  cat("  Source      :", x$source, "\n")
  cat("  Parameters  :\n")
  print(x$params)
  invisible(x)
}

#' @export
print.bf_posterior <- function(x, ...) {
  cat("bayesfermi posterior\n")
  cat("  Distribution:", x$dist, "\n")
  cat("  Parameters  :\n")
  print(x$params)
  if (!is.null(x$prior)) {
    cat("  Derived from prior (", x$prior$source, ")\n", sep = "")
  }
  invisible(x)
}
