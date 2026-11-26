import warnings

import numpy as np
from scipy import optimize, special, stats

from ._models import Prior, bf_prior
from ._validation import count, finite_scalar, generator, numeric_vector, option, probability, real_scalar


def _quantile_targets(q, p, upper, tol):
    quantile_error = f"q must contain two increasing finite quantiles in (0, {upper})."
    probability_error = "p must contain two increasing probabilities in (0, 1)."
    q = numeric_vector(q, quantile_error).astype(float)
    p = numeric_vector(p, probability_error).astype(float)
    if q.size != 2 or not np.all(np.isfinite(q)) or not 0 < q[0] < q[1] < upper:
        raise ValueError(quantile_error)
    if p.size != 2 or not 0 < p[0] < p[1] < 1:
        raise ValueError(probability_error)
    if not finite_scalar(tol) or not 0 <= tol <= 1:
        raise ValueError("tol must be a finite probability error between 0 and 1.")
    return q, p


def _calibration(q, p, achieved_q, achieved_p, tol):
    error = float(np.max(np.abs(achieved_p - p)))
    if not np.isfinite(error) or error > tol:
        warnings.warn(
            f"Quantile match is imprecise. Maximum absolute probability error: "
            f"{error:.3g} (tolerance: {tol}).",
            stacklevel=3,
        )
    return {
        "q": q,
        "p": p,
        "achieved_q": achieved_q,
        "achieved_p": achieved_p,
        "max_p_error": error,
        "tol": tol,
    }


def _exp(log_params):
    with np.errstate(over="ignore", under="ignore"):
        return np.exp(log_params)


def _anneal(loss, start, maxit, rng):
    current = best = start
    current_loss = best_loss = loss(start)
    for step in range(1, maxit):
        cooling = np.log(((step - 1) // 10) * 10 + np.e)
        candidate = current + rng.standard_normal(2) / cooling
        candidate_loss = loss(candidate)
        difference = candidate_loss - current_loss
        if difference <= 0 or rng.random() < np.exp(-difference * cooling / 10):
            current, current_loss = candidate, candidate_loss
            if candidate_loss <= best_loss:
                best, best_loss = candidate, candidate_loss
    return best


def expert_beta_prior(
    q, p=(0.1, 0.9), start=None, method="BFGS", maxit=2000, tol=1e-6, *, rng=None
) -> Prior:
    """Calibrate a Beta prior to two quantiles using their target probabilities.

    Supply `start` in log-shape units. The RNG is used with simulated annealing.
    """
    q, p = _quantile_targets(q, p, 1, tol)
    maxit = count(maxit, "maxit")
    method = option(
        method, "method", ("BFGS", "Nelder-Mead", "CG", "L-BFGS-B", "SANN", "Brent")
    )
    if method == "Brent":
        raise ValueError("method 'Brent' is only available for one-dimensional optimization.")

    automatic_start = start is None
    if automatic_start:
        z = special.ndtri(p)
        logit_q = special.logit(q)
        logit_sd = (logit_q[1] - logit_q[0]) / (z[1] - z[0])
        midpoint = special.expit(logit_q[0] - z[0] * logit_sd)
        with np.errstate(divide="ignore", invalid="ignore", over="ignore"):
            concentration = 1 / (midpoint * (1 - midpoint) * logit_sd**2) - 1
            shape = np.array([midpoint, 1 - midpoint]) * concentration
        start = np.log(shape) if np.all(np.isfinite(shape) & (shape > 0)) else np.zeros(2)
    else:
        message = "start must contain two finite log shape values."
        start = numeric_vector(start, message)
        shape = _exp(start)
        if start.size != 2 or not np.all(np.isfinite(shape) & (shape > 0)):
            raise ValueError(message)

    target = special.logit(p)

    def loss(log_shapes):
        a, b = _exp(log_shapes)
        if not np.isfinite(a) or not np.isfinite(b) or min(a, b) == 0:
            return 1e100
        # Evaluate the two tails independently to retain precision near 0 and 1.
        with np.errstate(divide="ignore", invalid="ignore"):
            log_odds = np.log(special.betainc(a, b, q)) - np.log(special.betaincc(a, b, q))
        error = np.sum((log_odds - target) ** 2)
        return float(error) if np.isfinite(error) else 1e100

    local_rng = generator(rng) if method == "SANN" else None

    def fit_from(initial):
        fitted, convergence = initial, 0
        if maxit and method == "SANN":
            fitted = _anneal(loss, initial, maxit, local_rng)
        elif maxit:
            if method == "Nelder-Mead":
                options = {"maxfev": maxit, "xatol": 1e-10, "fatol": 1e-13}
                jac = None
            else:
                options = {"maxiter": maxit, "gtol": 1e-9, "finite_diff_rel_step": 1e-5}
                if method == "L-BFGS-B":
                    options["ftol"] = 1e-13
                jac = "3-point"
            fit = optimize.minimize(loss, initial, method=method, jac=jac, options=options)
            fitted, convergence = fit.x, int(fit.status)
        a, b = _exp(fitted)
        achieved = special.betainc(a, b, q)
        return (a, b), convergence, achieved, np.max(np.abs(achieved - p))

    params, convergence, achieved_p, error = fit_from(start)
    if automatic_start and (not np.isfinite(error) or error > tol) and np.any(start != 0):
        fallback = fit_from(np.zeros(2))
        if not np.isfinite(error) or fallback[3] < error:
            params, convergence, achieved_p, _ = fallback
    a, b = params
    achieved_q = special.betaincinv(a, b, p)
    metadata = _calibration(q, p, achieved_q, achieved_p, tol)
    metadata.update(err=float(np.sum((achieved_q - q) ** 2)), convergence=convergence)
    return bf_prior("beta", {"shape1": float(a), "shape2": float(b)}, "expert", metadata)


def _gamma_root(q, p, initial_shape):
    def log_ratio(lower, upper):
        with np.errstate(divide="ignore", over="ignore"):
            relative_difference = (upper - lower) / lower
        if np.isfinite(relative_difference):
            return np.log1p(relative_difference)
        return np.log(upper) - np.log(lower)

    target = log_ratio(*q)

    def objective(log_shape):
        lower, upper = special.gammaincinv(np.exp(log_shape), p)
        return log_ratio(lower, upper) - target if lower > 0 else np.inf

    center = float(np.log(initial_shape)) if np.isfinite(initial_shape) and initial_shape > 0 else 0
    lower, upper = center - 5, center + 5
    for _ in range(100):
        if objective(lower) < 0:
            lower -= 2
        elif objective(upper) > 0:
            upper += 2
        else:
            break
    else:
        raise ValueError("Failed to bracket a root for Gamma shape. Check q and p.")
    shape = np.exp(optimize.brentq(objective, lower, upper, xtol=1e-10))
    return shape, special.gammaincinv(shape, p[0]) / q[0]


def expert_gamma_prior(q, p=(0.1, 0.9), shape_switch=20, mode="auto", tol=1e-6) -> Prior:
    """Calibrate a shape–rate Gamma prior to two quantiles.

    Auto mode uses the Normal approximation when its probability error is within tolerance.
    """
    mode = option(mode, "mode", ("auto", "normal", "uniroot"))
    q, p = _quantile_targets(q, p, np.inf, tol)
    if not real_scalar(shape_switch) or not shape_switch >= 0:
        raise ValueError("shape_switch must be non-negative.")
    mean = q[0] + (q[1] - q[0]) / 2
    z = special.ndtri(p)
    with np.errstate(divide="ignore", over="ignore", under="ignore"):
        relative_sd = ((q[1] - q[0]) / mean) / (z[1] - z[0])
        shape0 = 1 / relative_sd**2
        rate0 = shape0 / mean
    shape, rate = shape0, rate0
    method = "normal"
    use_normal = mode == "normal"
    with np.errstate(over="ignore"):
        if mode == "auto" and shape0 >= shape_switch and 0 < rate0 < np.inf and np.isfinite(shape0):
            use_normal = np.max(np.abs(special.gammainc(shape0, q * rate0) - p)) <= tol
        if not use_normal:
            shape, rate = _gamma_root(q, p, shape0)
            method = "uniroot"
        params = {"shape": float(shape), "rate": float(rate)}
        prior = bf_prior("gamma", params, "expert")
        achieved_q = special.gammaincinv(shape, p) / rate
        achieved_p = special.gammainc(shape, q * rate)
        error = float(np.sum((achieved_q - q) ** 2))
    prior.metadata = _calibration(q, p, achieved_q, achieved_p, tol)
    prior.metadata.update(method=method, shape0=float(shape0), rate0=float(rate0), err_q=error)
    return prior


def expert_normal_prior(mean, lower, upper, level=0.9) -> Prior:
    """Construct a Normal prior from a mean and a symmetric central interval."""
    if not finite_scalar(lower) or not finite_scalar(upper) or upper <= lower:
        raise ValueError("lower and upper must be finite numbers with lower < upper.")
    probability(level, "level")
    midpoint = lower / 2 + upper / 2
    tolerance = 8 * np.finfo(float).eps * max(abs(lower), abs(upper))
    if not finite_scalar(mean) or abs(mean - midpoint) > tolerance:
        raise ValueError("mean must match the midpoint of the central interval.")
    z = stats.norm.isf((1 - level) / 2)
    sd = (upper / 2 - lower / 2) / z
    if not finite_scalar(sd) or sd <= 0:
        raise ValueError("Could not compute a finite positive sd from the central interval.")
    return bf_prior(
        "normal", {"mean": float(mean), "sd": float(sd)}, "expert",
        {"lower": lower, "upper": upper, "level": level},
    )


def _observations(y):
    return numeric_vector(y, "y must be a numeric vector.", allow_scalar=True).astype(float)


def _sample_moments(y):
    mean, variance = np.mean(y), np.var(y, ddof=1)
    if variance <= 0:
        raise ValueError("Variance must be positive to use method of moments.")
    return mean, variance


def _maximum_likelihood(log_likelihood, label):
    def loss(log_params):
        params = _exp(log_params)
        if not np.all(np.isfinite(params) & (params > 0)):
            return 1e100
        with np.errstate(divide="ignore", invalid="ignore", over="ignore"):
            value = -log_likelihood(*params)
        return float(value) if np.isfinite(value) else 1e100

    fit = optimize.minimize(loss, np.zeros(2), method="BFGS", jac="3-point")
    if not fit.success:
        warnings.warn(f"MLE for {label} prior did not fully converge.", stacklevel=3)
    return _exp(fit.x)


def fit_beta_prior(y, method="mm") -> Prior:
    """Fit a Beta prior to at least two proportions strictly between 0 and 1."""
    method = option(method, "method", ("mm", "mle"))
    y = _observations(y)
    if np.any((y <= 0) | (y >= 1)):
        raise ValueError("All observations must be in (0, 1) to fit a Beta distribution.")
    y = y[np.isfinite(y)]
    if y.size < 2:
        raise ValueError("Need at least two observations to fit a Beta prior.")
    if method == "mm":
        mean, variance = _sample_moments(y)
        concentration = mean * (1 - mean) / variance - 1
        if concentration <= 0:
            raise ValueError("Sample variance too large relative to mean. Try method = 'mle'.")
        a, b = mean * concentration, (1 - mean) * concentration
    else:
        a, b = _maximum_likelihood(lambda a, b: np.sum(stats.beta.logpdf(y, a, b)), "Beta")
    return bf_prior(
        "beta", {"shape1": float(a), "shape2": float(b)}, metadata={"method": method, "n": y.size}
    )


def fit_gamma_prior(y, method="mm") -> Prior:
    """Fit a shape–rate Gamma prior to at least two positive observations."""
    method = option(method, "method", ("mm", "mle"))
    y = _observations(y)
    y = y[np.isfinite(y)]
    if np.any(y <= 0):
        raise ValueError("All observations must be > 0 to fit a Gamma distribution.")
    if y.size < 2:
        raise ValueError("Need at least two observations to fit a Gamma prior.")
    if method == "mm":
        mean, variance = _sample_moments(y)
        shape, rate = mean**2 / variance, mean / variance
    else:
        shape, rate = _maximum_likelihood(
            lambda shape, rate: np.sum(stats.gamma.logpdf(y, shape, scale=1 / rate)), "Gamma"
        )
    return bf_prior(
        "gamma", {"shape": float(shape), "rate": float(rate)}, metadata={"method": method, "n": y.size}
    )


def fit_normal_prior(y) -> Prior:
    """Fit a Normal prior using the sample mean and sample standard deviation."""
    y = _observations(y)
    y = y[np.isfinite(y)]
    if y.size < 2:
        raise ValueError("Need at least two observations to fit a Normal prior.")
    mean, sd = np.mean(y), np.std(y, ddof=1)
    if sd <= 0:
        raise ValueError("Standard deviation must be positive.")
    return bf_prior("normal", {"mean": float(mean), "sd": float(sd)}, metadata={"n": y.size})
