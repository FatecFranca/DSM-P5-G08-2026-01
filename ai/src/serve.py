"""API FastAPI para inferencia dos modelos treinados."""
from __future__ import annotations

from functools import lru_cache
from pathlib import Path
from typing import Literal

import joblib
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

from preprocess import (
    FEATURE_COLS,
    PROFILE_LABELS,
    build_features_from_api,
    features_to_vector,
)

ROOT = Path(__file__).resolve().parents[1]
MODELS_DIR = ROOT / "models"
MODEL_VERSION = "ml-v1.0"

PROFILE_SCORES = {"Em_Risco": 25, "Sedentario": 45, "Moderado": 65, "Saudavel_Ativo": 90}
CLUSTER_LABELS = {
    0: "Grupo Ativo e Regulado",
    1: "Grupo Sedentario",
    2: "Grupo Moderado Misto",
    3: "Grupo de Atencao Clinica",
}

app = FastAPI(title="Vitalis ML Service", version=MODEL_VERSION)


class PredictInput(BaseModel):
    age: int
    gender: Literal["Male", "Female"]
    heightCm: float
    weightKg: float
    bmi: float | None = None
    dailySteps: int
    caloriesIntake: int
    hoursOfSleep: float
    heartRate: int = 80
    exerciseHoursPerWeek: float
    smoker: Literal["Yes", "No"]
    alcoholPerWeek: int
    diabetic: Literal["Yes", "No"]
    heartDisease: Literal["Yes", "No"]


@lru_cache(maxsize=1)
def load_artifacts():
    required = ["classifier.pkl", "kmeans.pkl", "raw_bounds.pkl"]
    for name in required:
        if not (MODELS_DIR / name).exists():
            raise FileNotFoundError(f"Modelo ausente: {MODELS_DIR / name}. Execute train.py.")
    return (
        joblib.load(MODELS_DIR / "classifier.pkl"),
        joblib.load(MODELS_DIR / "kmeans.pkl"),
        joblib.load(MODELS_DIR / "raw_bounds.pkl"),
    )


@app.get("/health")
def health():
    models_ready = (MODELS_DIR / "classifier.pkl").exists()
    return {
        "status": "ok" if models_ready else "missing_models",
        "service": "vitalis-ml",
        "modelVersion": MODEL_VERSION,
        "modelsReady": models_ready,
    }


@app.post("/predict")
def predict(body: PredictInput):
    try:
        classifier, kmeans, raw_bounds = load_artifacts()
    except FileNotFoundError as exc:
        raise HTTPException(status_code=503, detail=str(exc)) from exc

    features = build_features_from_api(body, raw_bounds)
    X = features_to_vector(features)

    profile_enc = int(classifier.predict(X)[0])
    cluster_id = int(kmeans.predict(X)[0])
    profile = PROFILE_LABELS[profile_enc]
    proba = classifier.predict_proba(X)[0]

    return {
        "profile": profile,
        "profileScore": PROFILE_SCORES[profile],
        "clusterId": cluster_id,
        "clusterLabel": CLUSTER_LABELS.get(cluster_id, f"Cluster {cluster_id}"),
        "explanation": [f"Classificacao gerada pelo modelo Logistic Regression ({MODEL_VERSION})."],
        "confidence": float(max(proba)),
        "modelVersion": MODEL_VERSION,
    }
