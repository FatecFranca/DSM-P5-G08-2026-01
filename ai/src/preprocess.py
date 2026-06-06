"""Preprocessamento compartilhado entre treino e inferencia."""
from __future__ import annotations

from typing import Any

import numpy as np

FEATURE_COLS = [
    "Age",
    "BMI",
    "Daily_Steps",
    "Hours_of_Sleep",
    "Exercise_Hours_per_Week",
    "Heart_Rate",
    "Calories_Intake",
    "Alcohol_Consumption_per_Week",
    "Gender_enc",
    "Smoker_enc",
    "Diabetic_enc",
    "Heart_Disease_enc",
]

TARGET_MAP = {"Em_Risco": 0, "Sedentario": 1, "Moderado": 2, "Saudavel_Ativo": 3}
PROFILE_LABELS = {v: k for k, v in TARGET_MAP.items()}

# Limites em escala bruta (questionario / API). BMI e refinado no treino a partir do CSV.
DEFAULT_RAW_BOUNDS: dict[str, tuple[float, float]] = {
    "Age": (18.0, 75.0),
    "BMI": (12.0, 52.0),
    "Daily_Steps": (1000.0, 15000.0),
    "Hours_of_Sleep": (3.0, 10.0),
    "Exercise_Hours_per_Week": (0.0, 10.0),
    "Heart_Rate": (50.0, 110.0),
    "Calories_Intake": (1200.0, 4000.0),
    "Alcohol_Consumption_per_Week": (0.0, 10.0),
}


def compute_bmi_bounds(df) -> tuple[float, float]:
    bmi = df["Weight_kg"] / ((df["Height_cm"] / 100) ** 2)
    return float(bmi.min()), float(bmi.max())


def build_raw_bounds(df) -> dict[str, tuple[float, float]]:
    bmi_min, bmi_max = compute_bmi_bounds(df)
    bounds = dict(DEFAULT_RAW_BOUNDS)
    bounds["BMI"] = (bmi_min, bmi_max)
    return bounds


def _clip01(value: float) -> float:
    return float(np.clip(value, 0.0, 1.0))


def normalize_raw(value: float, min_v: float, max_v: float) -> float:
    if max_v <= min_v:
        return 0.5
    return _clip01((value - min_v) / (max_v - min_v))


def yes_no_enc(value: str) -> int:
    return 1 if value == "Yes" else 0


def gender_enc(value: str) -> int:
    return 1 if value == "Male" else 0


def build_features_from_api(body: Any, raw_bounds: dict[str, tuple[float, float]]) -> dict[str, float]:
    bmi = body.bmi if getattr(body, "bmi", None) is not None else body.weightKg / ((body.heightCm / 100) ** 2)

    return {
        "Age": normalize_raw(body.age, *raw_bounds["Age"]),
        "BMI": normalize_raw(bmi, *raw_bounds["BMI"]),
        "Daily_Steps": normalize_raw(body.dailySteps, *raw_bounds["Daily_Steps"]),
        "Hours_of_Sleep": normalize_raw(body.hoursOfSleep, *raw_bounds["Hours_of_Sleep"]),
        "Exercise_Hours_per_Week": normalize_raw(body.exerciseHoursPerWeek, *raw_bounds["Exercise_Hours_per_Week"]),
        "Heart_Rate": normalize_raw(body.heartRate, *raw_bounds["Heart_Rate"]),
        "Calories_Intake": normalize_raw(body.caloriesIntake, *raw_bounds["Calories_Intake"]),
        "Alcohol_Consumption_per_Week": normalize_raw(body.alcoholPerWeek, *raw_bounds["Alcohol_Consumption_per_Week"]),
        "Gender_enc": float(gender_enc(body.gender)),
        "Smoker_enc": float(yes_no_enc(body.smoker)),
        "Diabetic_enc": float(yes_no_enc(body.diabetic)),
        "Heart_Disease_enc": float(yes_no_enc(body.heartDisease)),
    }


def features_to_vector(features: dict[str, float]) -> np.ndarray:
    return np.array([[features[col] for col in FEATURE_COLS]], dtype=float)
