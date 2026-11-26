from collections.abc import Mapping

import numpy as np
import pandas as pd
from scipy.stats import rankdata

from ._models import Posterior, Prior, SimulationResult
from ._posterior import bf_draws
from ._summary import posterior_summary
from ._validation import count, dropped_draws, generator, numeric_vector, option, validate_names


def _numeric_columns(frame):
    return {
        name: numeric_vector(column, "Joint draw columns must be numeric vectors.")
        for name, column in frame.items()
    }


def bf_fermi_simulate(
    components, fun, n_draws=None, use="posterior", nonfinite="error", *, rng=None
) -> SimulationResult:
    """Combine named prior/posterior draws or rows of supplied joint draws.

    `fun` receives NumPy arrays as keyword arguments and returns one value per
    input row. Omit `n_draws` to use 10,000 draws or the supplied row count.
    """
    use = option(use, "use", ("posterior", "prior"))
    nonfinite = option(nonfinite, "nonfinite", ("error", "drop"))
    if not isinstance(components, (Mapping, pd.DataFrame)):
        raise ValueError("components must be a named mapping or a numeric DataFrame.")
    validate_names(components, "components")
    if not callable(fun):
        raise ValueError("fun must be a function.")

    if isinstance(components, pd.DataFrame):
        inputs = components.copy()
        columns = _numeric_columns(inputs)
        n_draws = count(len(inputs) if n_draws is None else n_draws, "n_draws", minimum=1)
        if n_draws != len(inputs):
            raise ValueError("n_draws must match the number of rows in the joint draws.")
    else:
        n_draws = count(10000 if n_draws is None else n_draws, "n_draws", minimum=1)
        rng = generator(rng)
        columns = {}
        for name, component in components.items():
            if not isinstance(component, (Prior, Posterior)):
                raise ValueError(f"Component '{name}' must be a bf_prior or bf_posterior.")
            if isinstance(component, Posterior) and use == "prior":
                component = component.prior
                if component is None:
                    raise ValueError(f"Posterior for component '{name}' has no attached prior.")
            columns[name] = bf_draws(component, n_draws, rng=rng)
        inputs = pd.DataFrame(columns)

    keep_inputs = np.logical_and.reduce([np.isfinite(column) for column in columns.values()])
    n_dropped = dropped_draws(keep_inputs, nonfinite, "Inputs")
    if not np.any(keep_inputs):
        raise ValueError("No finite input draws remain.")
    inputs = inputs.iloc[keep_inputs]
    with np.errstate(divide="ignore", invalid="ignore", over="ignore"):
        result = fun(**{name: column[keep_inputs] for name, column in columns.items()})
    message = "fun must return a numeric vector with one value per input row."
    draws = numeric_vector(result, message)
    if draws.size != len(inputs):
        raise ValueError(message)

    keep_results = np.isfinite(draws)
    n_dropped += dropped_draws(keep_results, nonfinite, "Results")
    if not np.any(keep_results):
        raise ValueError("No finite result draws remain.")
    return SimulationResult(draws[keep_results], inputs.iloc[keep_results], fun, n_dropped)


def bf_sensitivity(object) -> pd.DataFrame:
    """Rank input components by absolute Spearman correlation with the output."""
    if not isinstance(object, SimulationResult):
        raise ValueError("object must be a bf_fermi simulation.")
    draws = object.draws
    if draws.size < 2:
        raise ValueError("At least two draws are needed for sensitivity analysis.")
    columns = _numeric_columns(object.inputs)
    dropped_draws(np.isfinite(draws), "error", "Results")
    finite_inputs = np.logical_and.reduce([np.isfinite(column) for column in columns.values()])
    dropped_draws(finite_inputs, "error", "Inputs")
    output_ranks = rankdata(draws)
    constant_output = np.all(draws == draws[0])
    correlations = {}
    for name, column in columns.items():
        if constant_output or np.all(column == column[0]):
            correlations[name] = np.nan
        else:
            correlations[name] = np.corrcoef(rankdata(column), output_ranks)[0, 1]
    order = sorted(
        correlations,
        key=lambda name: np.inf if np.isnan(correlations[name]) else -abs(correlations[name]),
    )
    return pd.DataFrame({"component": order, "spearman": [correlations[name] for name in order]})


def bf_compare_scenarios(scenarios, cred_level=0.89) -> pd.DataFrame:
    """Summarize named simulations in input order with intervals and draw counts."""
    if not isinstance(scenarios, Mapping):
        raise ValueError("scenarios must have unique, non-empty names.")
    validate_names(scenarios, "scenarios")
    rows = []
    for name, simulation in scenarios.items():
        if not isinstance(simulation, SimulationResult):
            raise ValueError("Each scenario must be a bf_fermi simulation.")
        summary = posterior_summary(simulation, cred_level=cred_level, hdi=False)
        rows.append({
            "scenario": name,
            "median": summary.median,
            **summary.ci,
            "n_draws": summary.n_draws,
            "n_dropped": summary.n_dropped,
        })
    return pd.DataFrame(rows)
