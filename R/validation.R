is_numeric_vector <- function(x) {
  is.numeric(x) && is.null(dim(x))
}

is_finite_scalar <- function(x) {
  is_numeric_vector(x) && length(x) == 1L && is.finite(x)
}

validate_probability <- function(x, name) {
  if (!is_finite_scalar(x) || x <= 0 || x >= 1) {
    stop(name, " must be a finite number in (0, 1).", call. = FALSE)
  }
}

validate_count <- function(x, name, minimum = 0) {
  if (!is_finite_scalar(x) || x < minimum || x != floor(x)) {
    stop(name, " must be an integer >= ", minimum, ".", call. = FALSE)
  }
}

validate_names <- function(x, name) {
  nms <- names(x)
  if (
    length(x) == 0L || is.null(nms) || anyNA(nms) ||
      any(!nzchar(nms)) || anyDuplicated(nms)
  ) {
    stop(name, " must have unique, non-empty names.", call. = FALSE)
  }
}

check_finite_draws <- function(keep, nonfinite, label) {
  dropped <- sum(!keep)
  if (dropped && nonfinite == "error") {
    stop(
      label, " contain ", dropped, " non-finite draw(s). ",
      "Use nonfinite = 'drop' to exclude them.",
      call. = FALSE
    )
  }
  dropped
}

validate_distribution <- function(dist, params) {
  required <- switch(
    dist,
    beta = c("shape1", "shape2"),
    gamma = c("shape", "rate"),
    normal = c("mean", "sd"),
    stop("Unsupported distribution: ", dist, call. = FALSE)
  )
  if (!is.list(params) || !all(required %in% names(params))) {
    stop(
      dist, " params must include ", paste(required, collapse = " and "), ".",
      call. = FALSE
    )
  }
  for (name in required) {
    value <- params[[name]]
    if (!is_finite_scalar(value)) {
      stop(name, " must be a finite number.", call. = FALSE)
    }
    if (name == "sd" && value < 0) {
      stop("sd must be non-negative.", call. = FALSE)
    }
    if (name %in% c("shape1", "shape2", "shape", "rate") && value <= 0) {
      stop(name, " must be positive.", call. = FALSE)
    }
  }
}
