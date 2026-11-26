parity_callbacks <- list(
  add = function(x, y) x + y,
  identity = identity,
  matrix = function(x) matrix(x),
  mean = function(x) mean(x),
  ratio = function(x, y) {
    stopifnot(all(is.finite(x)))
    x / y
  },
  reciprocal = function(x) 1 / x,
  flow = function(reverse, constant, weaker, flow) flow,
  zeros = function(x) rep(0, length(x))
)

parity_decode <- function(value, saved) {
  if (!is.list(value)) {
    return(value)
  }
  if (is.null(names(value))) {
    if (!length(value)) {
      return(numeric())
    }
    return(unlist(lapply(value, parity_decode, saved = saved), use.names = FALSE))
  }
  if (identical(names(value), "number")) {
    return(switch(value$number, inf = Inf, nan = NaN, stop("Unknown number")))
  }
  if (identical(names(value), "ref")) {
    return(get(value$ref, saved, inherits = FALSE))
  }
  if (identical(names(value), "callback")) {
    return(parity_callbacks[[value$callback]])
  }
  if (identical(names(value), "frame")) {
    return(as.data.frame(parity_decode(value$frame, saved), optional = TRUE))
  }
  lapply(value, parity_decode, saved = saved)
}

parity_field <- function(result, path) {
  if (path == ".") {
    return(result)
  }
  Reduce(function(x, key) x[[key]], strsplit(path, ".", fixed = TRUE)[[1]], init = result)
}

parity_equal <- function(actual, expected) {
  if (is.list(expected)) {
    expect_identical(names(actual), names(expected))
    for (key in names(expected)) {
      parity_equal(actual[[key]], expected[[key]])
    }
  } else if (is.numeric(expected)) {
    expect_true(is.numeric(actual))
    expect_identical(is.na(actual), is.na(expected))
    expect_equal(actual[!is.na(actual)], expected[!is.na(expected)], tolerance = 0)
  } else {
    expect_equal(actual, expected)
  }
}

parity_near <- function(actual, expected, atol = 0, rtol = 0) {
  expect_true(is.numeric(actual))
  expect_identical(is.na(actual), is.na(expected))
  keep <- !is.na(expected)
  expect_true(all(abs(actual[keep] - expected[keep]) <= atol + rtol * abs(expected[keep])))
}

parity_sample <- function(draws, expected) {
  expect_true(is.numeric(draws) && is.null(dim(draws)))
  expect_length(draws, expected$size)
  expect_true(all(is.finite(draws)))
  if (!is.null(expected$min_exclusive)) {
    expect_true(all(draws > expected$min_exclusive))
  }
  if (!is.null(expected$max_exclusive)) {
    expect_true(all(draws < expected$max_exclusive))
  }
  if (isTRUE(expected$integer)) {
    expect_true(all(draws == floor(draws)))
  }
  if (!is.null(expected$mean)) {
    parity_near(mean(draws), expected$mean[[1]], atol = expected$mean[[2]])
  }
  if (!is.null(expected$variance)) {
    parity_near(stats::var(draws), expected$variance[[1]], atol = expected$variance[[2]])
  }
}

run_parity_case <- function(case) {
  set.seed(1234)
  saved <- new.env(parent = emptyenv())
  if (any(vapply(case$calls, function(step) step$fn == "plot_posterior", logical(1)))) {
    grDevices::pdf(NULL)
    on.exit(grDevices::dev.off())
  }
  for (step in case$calls) {
    fun <- getExportedValue("fermi", step$fn)
    args <- parity_decode(step$args, saved)
    recorded <- character()
    result <- tryCatch(
      withCallingHandlers(
        do.call(fun, args),
        warning = function(condition) {
          recorded <<- c(recorded, conditionMessage(condition))
          invokeRestart("muffleWarning")
        }
      ),
      error = identity
    )
    if (is.null(step$warning)) {
      expect_equal(recorded, character())
    } else {
      expect_length(recorded, 1)
      expect_match(recorded, step$warning, fixed = TRUE)
    }
    if (!is.null(step$error)) {
      expect_s3_class(result, "error")
      expect_match(conditionMessage(result), step$error, fixed = TRUE)
      next
    }
    if (inherits(result, "error")) {
      stop(result)
    }
    if (!is.null(step$save)) {
      assign(step$save, result, saved)
    }
    for (key in names(step$equals)) {
      parity_equal(parity_field(result, key), parity_decode(step$equals[[key]], saved))
    }
    for (key in names(step$near)) {
      spec <- step$near[[key]]
      parity_near(
        parity_field(result, key),
        parity_decode(spec$value, saved),
        atol = if (is.null(spec$atol)) 0 else spec$atol,
        rtol = if (is.null(spec$rtol)) 0 else spec$rtol
      )
    }
    if (!is.null(step$sample)) {
      parity_sample(result, step$sample)
    }
  }
}

fixture_files <- list.files(test_path("fixtures", "parity"), pattern = "[.]json$", full.names = TRUE)
stopifnot(length(fixture_files) == 4L)
for (file in fixture_files) {
  for (case in jsonlite::read_json(file)) {
    test_that(paste("shared parity:", case$id), {
      run_parity_case(case)
    })
  }
}
