import inspect
import json
import warnings
from collections.abc import Mapping
from pathlib import Path

import numpy as np
import pandas as pd
import pytest
from matplotlib import pyplot as plt

import fermi_estimation as fermi


def ratio(x, y):
    assert np.all(np.isfinite(x))
    return x / y


CALLBACKS = {
    "add": lambda x, y: x + y,
    "identity": lambda x: x,
    "matrix": lambda x: x[:, None],
    "mean": lambda x: np.mean(x),
    "ratio": ratio,
    "reciprocal": lambda x: 1 / x,
    "flow": lambda reverse, constant, weaker, flow: flow,
    "zeros": lambda x: np.zeros_like(x),
}
NUMBERS = {"inf": np.inf, "nan": np.nan}
FIXTURES = Path(__file__).resolve().parents[2] / "tests" / "testthat" / "fixtures" / "parity"
FIXTURE_FILES = sorted(FIXTURES.glob("*.json"))
assert len(FIXTURE_FILES) == 4


def decode(value, saved):
    if isinstance(value, list):
        return [decode(element, saved) for element in value]
    if not isinstance(value, dict):
        return value
    if value.keys() == {"number"}:
        return NUMBERS[value["number"]]
    if value.keys() == {"ref"}:
        return saved[value["ref"]]
    if value.keys() == {"callback"}:
        return CALLBACKS[value["callback"]]
    if value.keys() == {"frame"}:
        return pd.DataFrame(decode(value["frame"], saved))
    return {key: decode(element, saved) for key, element in value.items()}


def field(result, path):
    if path != ".":
        for key in path.split("."):
            if isinstance(result, (Mapping, pd.DataFrame)):
                result = result[key]
            else:
                result = getattr(result, key)
    return result


def assert_equal(actual, expected):
    if isinstance(expected, dict):
        assert actual.keys() == expected.keys()
        for key, wanted in expected.items():
            assert_equal(actual[key], wanted)
    elif isinstance(expected, list):
        assert np.shape(actual) == np.shape(expected)
        np.testing.assert_array_equal(actual, expected)
    else:
        assert actual == expected


def assert_near(actual, expected, *, atol=0, rtol=0):
    assert np.shape(actual) == np.shape(expected)
    np.testing.assert_allclose(actual, expected, atol=atol, rtol=rtol)


def assert_sample(draws, expected):
    assert isinstance(draws, np.ndarray)
    assert draws.shape == (expected["size"],)
    assert np.all(np.isfinite(draws))
    if "min_exclusive" in expected:
        assert np.all(draws > expected["min_exclusive"])
    if "max_exclusive" in expected:
        assert np.all(draws < expected["max_exclusive"])
    if expected.get("integer"):
        assert np.all(draws == np.floor(draws))
    if "mean" in expected:
        mean, tolerance = expected["mean"]
        assert_near(np.mean(draws), mean, atol=tolerance)
    if "variance" in expected:
        variance, tolerance = expected["variance"]
        assert_near(np.var(draws, ddof=1), variance, atol=tolerance)


def run_step(step, saved, rng):
    assert step["fn"] in fermi.__all__
    func = getattr(fermi, step["fn"])
    args = decode(step["args"], saved)
    if "rng" in inspect.signature(func).parameters:
        args["rng"] = rng

    with warnings.catch_warnings(record=True) as recorded:
        warnings.simplefilter("always")
        if "error" in step:
            with pytest.raises(ValueError) as error:
                func(**args)
            assert step["error"] in str(error.value)
            result = None
        else:
            result = func(**args)
    if "warning" in step:
        assert len(recorded) == 1
        assert step["warning"] in str(recorded[0].message)
    else:
        assert not recorded, [str(warning.message) for warning in recorded]

    if "save" in step:
        saved[step["save"]] = result
    for key, wanted in step.get("equals", {}).items():
        assert_equal(field(result, key), decode(wanted, saved))
    for key, spec in step.get("near", {}).items():
        assert_near(
            field(result, key),
            decode(spec["value"], saved),
            atol=spec.get("atol", 0),
            rtol=spec.get("rtol", 0),
        )
    if "sample" in step:
        assert_sample(result, step["sample"])


@pytest.mark.parametrize(
    "case",
    [
        pytest.param(case, id=f"{path.stem}: {case['id']}")
        for path in FIXTURE_FILES
        for case in json.loads(path.read_text(encoding="utf-8"))
    ],
)
def test_shared_parity_case(case):
    saved = {}
    rng = np.random.default_rng(1234)
    try:
        for step in case["calls"]:
            run_step(step, saved, rng)
    finally:
        plt.close("all")
