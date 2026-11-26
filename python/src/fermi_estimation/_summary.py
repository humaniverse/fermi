import warnings

import numpy as np
from scipy import stats

from ._models import Posterior, PosteriorSummary, Prior, SimulationResult
from ._posterior import bf_draws
from ._validation import dropped_draws, numeric_vector, option, probability


def _shortest_interval(ordered, cred_level):
    window = int(np.floor(cred_level * ordered.size))
    if window < 1:
        raise ValueError("cred_level too small for the sample size.")
    with np.errstate(over="ignore"):
        start = np.argmin(ordered[window:] - ordered[:-window])
    return {"lower": float(ordered[start]), "upper": float(ordered[start + window])}


def hdi(x, cred_level=0.89, nonfinite="error") -> dict[str, float]:
    """Estimate the shortest interval containing the requested sample mass."""
    probability(cred_level, "cred_level")
    x = numeric_vector(x, "x must be a numeric vector.", allow_scalar=True)
    nonfinite = option(nonfinite, "nonfinite", ("error", "drop"))
    keep = np.isfinite(x)
    dropped = dropped_draws(keep, nonfinite, "Samples")
    x = x[keep]
    if x.size < 2:
        raise ValueError("Need at least two samples for HDI.")
    if dropped:
        warnings.warn(f"Excluded {dropped} non-finite draw(s).", stacklevel=2)
    return _shortest_interval(np.sort(x.astype(float)), cred_level)


def _summary_draws(object, nonfinite, rng):
    nonfinite = option(nonfinite, "nonfinite", ("error", "drop"))
    n_dropped = 0
    if isinstance(object, (Prior, Posterior)):
        draws = bf_draws(object, rng=rng)
    elif isinstance(object, SimulationResult):
        draws = object.draws
        n_dropped = object.n_dropped
    else:
        message = "object must be a bf_prior, bf_posterior, bf_fermi or numeric vector."
        draws = numeric_vector(object, message, allow_scalar=True)
    keep = np.isfinite(draws)
    n_dropped += dropped_draws(keep, nonfinite, "Samples")
    draws = draws[keep]
    if draws.size < 2:
        raise ValueError("At least two finite draws are needed.")
    return draws, n_dropped


def _summarize(draws, n_dropped, cred_level, include_hdi):
    probability(cred_level, "cred_level")
    ordered = np.sort(draws.astype(float))
    tail = (1 - cred_level) / 2
    # R's type-7 sample quantiles use linear interpolation between adjacent values.
    positions = (ordered.size - 1) * np.array([tail, 0.5, 1 - tail])
    lower = positions.astype(int)
    upper = np.ceil(positions).astype(int)
    fraction = positions - lower
    left, median, right = (1 - fraction) * ordered[lower] + fraction * ordered[upper]
    return PosteriorSummary(
        median=float(median),
        ci={"lower": float(left), "upper": float(right)},
        cred_level=float(cred_level),
        n_draws=ordered.size,
        n_dropped=n_dropped,
        hdi=_shortest_interval(ordered, cred_level) if include_hdi else None,
    )


def posterior_summary(object, cred_level=0.89, hdi=True, nonfinite="error", *, rng=None) -> PosteriorSummary:
    """Summarize prior, posterior, simulation, or numeric draws."""
    draws, n_dropped = _summary_draws(object, nonfinite, rng)
    return _summarize(draws, n_dropped, cred_level, hdi)


def _density(draws):
    lower, upper = float(np.min(draws)), float(np.max(draws))
    scale = max(abs(lower), abs(upper)) or 1.0
    if lower == upper:
        bandwidth = 0.9 * draws.size ** -0.2
        x = np.linspace(-3 * bandwidth, 3 * bandwidth, 512)
        return lower + x * scale, stats.norm.pdf(x, scale=bandwidth) / scale
    # Center the scaled draws before calculating the KDE bandwidth.
    scaled = draws / scale - lower / scale
    sd = np.std(scaled, ddof=1)
    iqr = np.diff(np.quantile(scaled, (0.25, 0.75)))[0]
    spread = min(sd, iqr / 1.34) or sd
    bandwidth = 0.9 * spread * draws.size ** -0.2
    estimate = stats.gaussian_kde(scaled, bw_method=bandwidth / sd)
    x = np.linspace(scaled.min(), scaled.max(), 512)
    return (x + lower / scale) * scale, estimate(x) / scale


def plot_posterior(
    object, cred_level=0.89, hdi=True, *, nonfinite="error", ax=None, rng=None, **kwargs
) -> PosteriorSummary:
    """Plot a density and interval markers on an Axes and return its summary.

    Additional keyword arguments style the density line. Use `plt.show()` to
    display the figure in a script.
    """
    draws, n_dropped = _summary_draws(object, nonfinite, rng)
    summary = _summarize(draws, n_dropped, cred_level, hdi)
    if ax is None:
        from matplotlib import pyplot as plt

        ax = plt.gca()
    x, density = _density(draws)
    ax.plot(x, density, **kwargs)
    ax.axvline(summary.median, linestyle="--")
    for bound in summary.ci.values():
        ax.axvline(bound, linestyle=":")
    if summary.hdi is not None:
        ax.hlines(0, summary.hdi["lower"], summary.hdi["upper"], linewidth=2)
    ax.set(
        xlabel="Value",
        ylabel="Density",
        title=f"Posterior distribution\nMedian and {cred_level * 100:.6g}% credible interval",
    )
    return summary
