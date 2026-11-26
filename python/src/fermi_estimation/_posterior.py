import numpy as np

from ._models import Posterior, Prior, bf_posterior
from ._validation import count, finite_scalar, generator, numeric_vector, validate_distribution


def bf_draws(object, n=4000, *, rng=None) -> np.ndarray:
    """Draw a one-dimensional sample from a prior or posterior."""
    if not isinstance(object, (Prior, Posterior)):
        raise ValueError("object must be a bf_prior or bf_posterior.")
    n = count(n, "n")
    dist, params = object.dist, object.params
    validate_distribution(dist, params)
    rng = generator(rng)
    if dist == "beta":
        return rng.beta(params["shape1"], params["shape2"], size=n)
    if dist == "gamma":
        with np.errstate(over="ignore"):
            return rng.standard_gamma(params["shape"], size=n) / params["rate"]
    if params["sd"] == 0:
        return np.full(n, params["mean"], dtype=float)
    with np.errstate(over="ignore"):
        return rng.normal(params["mean"], params["sd"], size=n)


def _prior_params(prior, dist):
    if not isinstance(prior, Prior) or prior.dist != dist:
        raise ValueError(f"prior must be a bf_prior with dist = '{dist}'.")
    validate_distribution(dist, prior.params)
    return prior.params


def beta_binom_posterior(prior, successes, trials) -> Posterior:
    """Update a Beta prior with Binomial successes and trials."""
    params = _prior_params(prior, "beta")
    successes = count(successes, "successes")
    trials = count(trials, "trials", minimum=1)
    if successes > trials:
        raise ValueError("successes cannot exceed trials.")
    return bf_posterior(
        "beta",
        {"shape1": params["shape1"] + successes, "shape2": params["shape2"] + (trials - successes)},
        prior,
        {"successes": successes, "trials": trials},
    )


def gamma_poisson_posterior(prior, y, exposure=None) -> Posterior:
    """Update a shape–rate Gamma prior with Poisson counts and exposures."""
    params = _prior_params(prior, "gamma")
    counts_error = "Counts y must be finite non-negative integers."
    y = numeric_vector(y, counts_error, allow_scalar=True).astype(float)
    if np.any(~np.isfinite(y) | (y < 0) | (y != np.floor(y))):
        raise ValueError(counts_error)
    if exposure is None:
        exposure = np.ones(y.size)
    else:
        exposure_error = "Exposures must be finite and > 0."
        exposure = numeric_vector(exposure, exposure_error, allow_scalar=True).astype(float)
        if np.any(~np.isfinite(exposure) | (exposure <= 0)):
            raise ValueError(exposure_error)
        if y.size != exposure.size:
            raise ValueError("y and exposure must have same length.")
    with np.errstate(over="ignore"):
        shape = float(params["shape"] + np.sum(y))
        rate = float(params["rate"] + np.sum(exposure))
    return bf_posterior("gamma", {"shape": shape, "rate": rate}, prior, {"y": y, "exposure": exposure})


def normal_normal_posterior(prior, y, obs_sd) -> Posterior:
    """Update a Normal prior for the mean of observations with known deviation."""
    params = _prior_params(prior, "normal")
    if not finite_scalar(obs_sd) or obs_sd <= 0:
        raise ValueError("obs_sd must be finite and > 0.")
    y = numeric_vector(y, "y must be a numeric vector.", allow_scalar=True).astype(float)
    y = y[np.isfinite(y)]
    if not y.size:
        raise ValueError("No valid observations.")

    prior_sd = params["sd"]
    data_sd = float(obs_sd / np.sqrt(y.size))
    if prior_sd > 0:
        with np.errstate(over="ignore", invalid="ignore"):
            data_mean = np.mean(y)
        if not np.isfinite(data_mean):
            scale = np.max(np.abs(y))
            data_mean = np.mean(y / scale) * scale
        smaller = min(prior_sd, data_sd)
        if smaller == 0:
            params = {"mean": float(data_mean), "sd": 0.0}
        else:
            prior_precision = (smaller / prior_sd) ** 2
            data_precision = (smaller / data_sd) ** 2
            precision = prior_precision + data_precision
            mean = (
                (prior_precision / precision) * params["mean"]
                + (data_precision / precision) * data_mean
            )
            params = {"mean": float(mean), "sd": float(smaller / np.sqrt(precision))}
    return bf_posterior("normal", params, prior, {"y": y, "obs_sd": obs_sd})


def bf_predict(
    object, n=4000, trials=None, exposure=None, obs_sd=None, *, rng=None
) -> np.ndarray:
    """Generate observations from a Beta, Gamma, or Normal posterior."""
    if not isinstance(object, Posterior):
        raise ValueError("object must be a bf_posterior.")
    n = count(n, "n", minimum=1)
    dist = object.dist
    validate_distribution(dist, object.params)
    likelihood = {"beta": "trials", "gamma": "exposure", "normal": "obs_sd"}[dist]
    given = {"trials": trials, "exposure": exposure, "obs_sd": obs_sd}
    if any(name != likelihood and value is not None for name, value in given.items()):
        raise ValueError(f"Only {likelihood} applies to a {dist} posterior.")

    rng = generator(rng)
    if dist == "beta":
        trials = count(1 if trials is None else trials, "trials")
        draws = rng.binomial(trials, bf_draws(object, n, rng=rng))
    elif dist == "gamma":
        exposure = 1 if exposure is None else exposure
        if not finite_scalar(exposure) or exposure <= 0:
            raise ValueError("exposure must be finite and > 0.")
        with np.errstate(over="ignore"):
            poisson_means = bf_draws(object, n, rng=rng) * exposure
        if not np.all(np.isfinite(poisson_means)):
            raise ValueError("Non-finite Poisson means in prediction. Check the rate and exposure.")
        draws = rng.poisson(poisson_means)
    else:
        obs_sd = object.data.get("obs_sd") if obs_sd is None else obs_sd
        if not finite_scalar(obs_sd) or obs_sd <= 0:
            raise ValueError(
                "obs_sd must be supplied as a finite positive number or stored in the posterior."
            )
        with np.errstate(over="ignore"):
            draws = rng.normal(bf_draws(object, n, rng=rng), obs_sd)
    if not np.all(np.isfinite(draws)):
        raise ValueError("Prediction produced non-finite draws. Check the model parameters.")
    return draws
