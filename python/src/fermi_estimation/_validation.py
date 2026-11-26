from collections.abc import Mapping
from math import isfinite
from numbers import Integral, Real

import numpy as np
import pandas as pd


DISTRIBUTIONS = {
    "beta": ("shape1", "shape2"),
    "gamma": ("shape", "rate"),
    "normal": ("mean", "sd"),
}


def option(value, name, choices):
    if isinstance(value, str) and value:
        matches = [choice for choice in choices if choice.startswith(value)]
        if value in matches:
            return value
        if len(matches) == 1:
            return matches[0]
    raise ValueError(f"{name} must be one of {', '.join(choices)}.")


def real_scalar(value):
    return isinstance(value, Real) and not isinstance(value, bool)


def finite_scalar(value):
    if not real_scalar(value):
        return False
    try:
        return isfinite(value)
    except OverflowError:
        return False


def probability(value, name):
    if not finite_scalar(value) or not 0 < value < 1:
        raise ValueError(f"{name} must be a finite number in (0, 1).")


def count(value, name, minimum=0):
    if (
        not finite_scalar(value)
        or value < minimum
        or (not isinstance(value, Integral) and value != np.floor(value))
    ):
        raise ValueError(f"{name} must be an integer >= {minimum}.")
    return int(value)


def numeric_vector(value, message, *, allow_scalar=False):
    if isinstance(value, pd.Series) and pd.api.types.is_extension_array_dtype(value.dtype):
        if value.dtype.kind not in "iuf":
            raise ValueError(message)
        vector = value.to_numpy(dtype=float, na_value=np.nan)
    else:
        try:
            vector = np.asarray(value)
        except (TypeError, ValueError) as exc:
            raise ValueError(message) from exc
    if allow_scalar and vector.ndim == 0:
        vector = vector.reshape(1)
    if vector.ndim != 1 or vector.dtype.kind not in "iuf":
        raise ValueError(message)
    return vector


def validate_names(names, label):
    names = list(names)
    if (
        not names
        or any(not isinstance(name, str) or not name for name in names)
        or len(set(names)) != len(names)
    ):
        raise ValueError(f"{label} must have unique, non-empty names.")


def dropped_draws(keep, nonfinite, label):
    dropped = int(np.count_nonzero(~keep))
    if dropped and nonfinite == "error":
        raise ValueError(
            f"{label} contain {dropped} non-finite draw(s). Use nonfinite = 'drop' to exclude them."
        )
    return dropped


def validate_distribution(dist, params):
    if not isinstance(dist, str) or dist not in DISTRIBUTIONS:
        raise ValueError(f"Unsupported distribution: {dist}")
    required = DISTRIBUTIONS[dist]
    if not isinstance(params, Mapping) or any(name not in params for name in required):
        raise ValueError(f"{dist} params must include {' and '.join(required)}.")
    for name in required:
        value = params[name]
        if not finite_scalar(value):
            raise ValueError(f"{name} must be a finite number.")
        if name == "sd" and value < 0:
            raise ValueError("sd must be non-negative.")
        if dist != "normal" and value <= 0:
            raise ValueError(f"{name} must be positive.")


def generator(rng):
    if rng is None:
        return np.random.default_rng()
    if not isinstance(rng, np.random.Generator):
        raise TypeError("rng must be a numpy.random.Generator.")
    return rng
