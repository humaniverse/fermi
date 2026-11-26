import inspect
import re
from pathlib import Path

import numpy as np
import pandas as pd
import pytest
from matplotlib import pyplot as plt
from scipy.stats import beta

import fermi_estimation as fermi


def test_r_exports_have_python_equivalents():
    namespace = Path(__file__).resolve().parents[2] / "NAMESPACE"
    r_exports = set(re.findall(r"^export\((.+)\)$", namespace.read_text(encoding="utf-8"), re.M))
    python_exports = {name for name in fermi.__all__ if inspect.isfunction(getattr(fermi, name))}
    assert python_exports == r_exports


@pytest.mark.parametrize(
    "dist, params, data, options, draw_observations",
    [
        ("beta", {"shape1": 3, "shape2": 5}, {}, {"trials": 4}, lambda rng, x: rng.binomial(4, x)),
        ("gamma", {"shape": 5, "rate": 5}, {}, {"exposure": 5}, lambda rng, x: rng.poisson(5 * x)),
        ("normal", {"mean": 0, "sd": 1}, {"obs_sd": 3}, {}, lambda rng, x: rng.normal(x, 3)),
        ("normal", {"mean": 0, "sd": 1}, {"obs_sd": 3}, {"obs_sd": 2}, lambda rng, x: rng.normal(x, 2)),
    ],
)
def test_seeded_predictions_draw_parameters_then_observations(dist, params, data, options, draw_observations):
    posterior = fermi.bf_posterior(dist, params, data=data)
    expected_rng = np.random.default_rng(123)
    expected = draw_observations(expected_rng, fermi.bf_draws(posterior, 30, rng=expected_rng))
    actual = fermi.bf_predict(posterior, 30, rng=np.random.default_rng(123), **options)
    np.testing.assert_array_equal(actual, expected)


def test_beta_metadata_matches_the_fitted_distribution():
    q, p = [1e-6, 8e-6], [0.025, 0.9]
    prior = fermi.expert_beta_prior(q, p)
    actual = beta.cdf(q, prior.params["shape1"], prior.params["shape2"])
    np.testing.assert_allclose(prior.metadata["achieved_p"], actual)


def test_joint_draws_keep_pandas_index_and_validate_column_names():
    inputs = pd.DataFrame(
        {"x": pd.array([2, None, 3], dtype="Int64"), "y": [1, 2, 3]},
        index=["first", "missing", "last"],
    )
    sim = fermi.bf_fermi_simulate(inputs, lambda x, y: x / y, nonfinite="drop")
    pd.testing.assert_frame_equal(sim.inputs, inputs.iloc[[0, 2]])
    np.testing.assert_array_equal(sim.draws, [2, 1])
    duplicate_columns = pd.DataFrame([[1, 2]], columns=["x", "x"])
    with pytest.raises(ValueError, match="unique"):
        fermi.bf_fermi_simulate(duplicate_columns, lambda x: x)


def test_plot_uses_provided_axes_and_the_same_seeded_draws_as_its_summary():
    prior = fermi.bf_prior("normal", {"mean": 3, "sd": 1})
    fig, ax = plt.subplots()
    try:
        summary = fermi.plot_posterior(prior, ax=ax, rng=np.random.default_rng(123))
        expected = fermi.posterior_summary(prior, rng=np.random.default_rng(123))
        assert summary == expected
        assert ax.lines[0].get_ydata().max() > 0
        for line, value in zip(ax.lines[1:], [summary.median, *summary.ci.values()], strict=True):
            np.testing.assert_array_equal(line.get_xdata(), [value, value])
        np.testing.assert_array_equal(
            ax.collections[0].get_segments()[0], [[summary.hdi["lower"], 0], [summary.hdi["upper"], 0]]
        )
    finally:
        plt.close(fig)


def test_plot_accepts_constant_draws_and_can_omit_the_hdi():
    fig, ax = plt.subplots()
    try:
        summary = fermi.plot_posterior([3, 3, 3], hdi=False, ax=ax)
        assert summary.median == 3
        assert summary.hdi is None
        assert not ax.collections
        assert np.all(np.isfinite(ax.lines[0].get_ydata()))
    finally:
        plt.close(fig)


def test_documented_python_example(monkeypatch):
    guide = Path(__file__).resolve().parents[2] / "vignettes" / "articles" / "python.Rmd"
    code = re.search(r"^```python\n(.*?)^```$", guide.read_text(encoding="utf-8"), re.M | re.S)
    namespace = {}
    monkeypatch.setattr(plt, "show", lambda: None)
    try:
        exec(compile(code[1], guide, "exec"), namespace)
        assert namespace["summary"].n_draws == 20000
    finally:
        plt.close("all")
