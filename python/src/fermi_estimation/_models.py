from collections.abc import Callable, Mapping
from dataclasses import dataclass, field
from typing import Any

import numpy as np
import pandas as pd

from ._validation import DISTRIBUTIONS, option, validate_distribution


@dataclass(eq=False)
class Prior:
    """A distribution, its parameters, and how the prior was obtained."""

    dist: str
    params: dict[str, float]
    source: str = "data"
    metadata: dict[str, Any] = field(default_factory=dict)

    def __post_init__(self):
        self.dist = option(self.dist, "dist", DISTRIBUTIONS)
        self.source = option(self.source, "source", ("data", "expert"))
        validate_distribution(self.dist, self.params)
        self.params = dict(self.params)


@dataclass(eq=False)
class Posterior:
    """An updated distribution with its optional prior and observation data."""

    dist: str
    params: dict[str, float]
    prior: Prior | None = None
    data: dict[str, Any] = field(default_factory=dict)

    def __post_init__(self):
        self.dist = option(self.dist, "dist", DISTRIBUTIONS)
        validate_distribution(self.dist, self.params)
        self.params = dict(self.params)


@dataclass(eq=False)
class SimulationResult:
    """Derived draws, row-aligned inputs, the model, and the exclusion count."""

    draws: np.ndarray
    inputs: pd.DataFrame
    fun: Callable
    n_dropped: int = 0


@dataclass
class PosteriorSummary:
    """A median, equal-tailed interval, optional HDI, and draw counts."""

    median: float
    ci: dict[str, float]
    cred_level: float
    n_draws: int
    n_dropped: int = 0
    hdi: dict[str, float] | None = None

    def __str__(self):
        lines = [
            "Posterior summary",
            f"  Credible level: {self.cred_level * 100:.6g}%",
            f"  Median: {self.median:.6g}",
            f"  CI: [{self.ci['lower']:.6g}, {self.ci['upper']:.6g}]",
        ]
        if self.hdi is not None:
            lines.append(f"  HDI: [{self.hdi['lower']:.6g}, {self.hdi['upper']:.6g}]")
        if self.n_dropped:
            lines.append(f"  Excluded draws: {self.n_dropped}")
        return "\n".join(lines)


def bf_prior(
    dist: str,
    params: Mapping[str, float],
    source: str = "data",
    metadata: Mapping[str, Any] | None = None,
) -> Prior:
    """Create a Beta, Gamma (shape and rate), or Normal prior."""
    return Prior(dist, params, source, {} if metadata is None else dict(metadata))


def bf_posterior(
    dist: str,
    params: Mapping[str, float],
    prior: Prior | None = None,
    data: Mapping[str, Any] | None = None,
) -> Posterior:
    """Create a posterior and optionally retain its prior and observed data."""
    return Posterior(dist, params, prior, {} if data is None else dict(data))
