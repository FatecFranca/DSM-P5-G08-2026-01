"""API FastAPI para inferencia dos modelos treinados."""
from pathlib import Path
from typing import Literal

import joblib
import numpy as np
from fastapi import FastAPI
from pydantic import BaseModel, Field

ROOT = Path(__file__).resolve().parents[1]
MODELS_DIR = ROOT / "models"

PROFILE_LABELS = {0: "Em_Risco", 1: "Sedentario", 2: "Moderado", 3: "Saudavel_Ativo"}
PROFILE_SCORES = {"Em_Risco": 25, "Sedentario": 45, "Moderado": 65, "Saudavel_Ativo": 90}
CLUSTER_LABELS = {
    0: "Grupo Ativo e Regulado",
    1: "Grupo Sedentario",
    2: "Grupo Moderado Misto",
    3: "Grupo de Atencao Clinica",
}

app = FastAPI(title="Vitalis ML Service")


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


def load_models():
    return (
        joblib.load(MODELS_DIR / "classifier.pkl"),
        joblib.load(MODELS_DIR / "kmeans.pkl"),
        joblib.load(MODELS_DIR / "feature_cols.pkl"),
    )


@app.get("/health")
def health():
    return {"status": "ok", "service": "vitalis-ml"}


@app.post("/predict")
def predict(body: PredictInput):
    classifier, kmeans, feature_cols = load_models()

    bmi = body.bmi or body.weightKg / ((body.heightCm / 100) ** 2)
    gender_enc = 1 if body.gender == "Male" else 0
    yes_no = lambda v: 1 if v == "Yes" else 0

    # Valores brutos - normalizar com scaler salvo no treino futuro
    row = {
        "Age": body.age,
        "BMI": bmi,
        "Daily_Steps": body.dailySteps,
        "Hours_of_Sleep": body.hoursOfSleep,
        "Exercise_Hours_per_Week": body.exerciseHoursPerWeek,
        "Heart_Rate": body.heartRate,
        "Calories_Intake": body.caloriesIntake,
        "Alcohol_Consumption_per_Week": body.alcoholPerWeek,
        "Gender_enc": gender_enc,
        "Smoker_enc": yes_no(body.smoker),
        "Diabetic_enc": yes_no(body.diabetic),
        "Heart_Disease_enc": yes_no(body.heartDisease),
    }

    X = np.array([[row[c] for c in feature_cols]])
    profile_enc = int(classifier.predict(X)[0])
    cluster_id = int(kmeans.predict(X)[0])
    profile = PROFILE_LABELS[profile_enc]

    return {
        "profile": profile,
        "profileScore": PROFILE_SCORES[profile],
        "clusterId": cluster_id,
        "clusterLabel": CLUSTER_LABELS.get(cluster_id, f"Cluster {cluster_id}"),
        "explanation": ["Classificacao gerada pelo modelo Logistic Regression treinado."],
        "confidence": float(max(classifier.predict_proba(X)[0])),
    }
