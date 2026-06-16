"""
Treina classificador (Logistic Regression) e clusterizador (K-Means).
Salva modelos e metadados em ai/models/ para uso pelo serve.py.
"""
from __future__ import annotations

import json
from pathlib import Path

import joblib
import pandas as pd
from sklearn.cluster import KMeans
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score, classification_report, silhouette_score
from sklearn.model_selection import train_test_split

from preprocess import FEATURE_COLS, TARGET_MAP, build_raw_bounds

ROOT = Path(__file__).resolve().parents[1]
DATA_PATH = ROOT / "data" / "dataset_preprocessado.csv"
MODELS_DIR = ROOT / "models"
REPORTS_DIR = ROOT / "reports"
MODEL_VERSION = "ml-v1.0"


def main() -> None:
    if not DATA_PATH.exists():
        raise FileNotFoundError(f"Coloque o CSV em {DATA_PATH}")

    df = pd.read_csv(DATA_PATH)
    X = df[FEATURE_COLS]
    y = df["Health_Profile_enc"]

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )

    # class_weight="balanced" corrige o desbalanceamento do dataset
    # (a classe "Moderado" domina e fazia o modelo ignorar "Sedentario").
    classifier = LogisticRegression(
        max_iter=2000,
        random_state=42,
        class_weight="balanced",
        solver="lbfgs",
    )
    classifier.fit(X_train, y_train)
    y_pred = classifier.predict(X_test)
    acc = accuracy_score(y_test, y_pred)
    report = classification_report(y_test, y_pred, output_dict=True, zero_division=0)
    print(f"Acuracia classificador: {acc:.2%}")
    print(classification_report(y_test, y_pred, zero_division=0))

    class_counts = y.value_counts().sort_index().to_dict()
    print(f"Distribuicao de classes (treino+teste): {class_counts}")

    kmeans = KMeans(n_clusters=4, random_state=42, n_init=10)
    kmeans.fit(X)
    silhouette = float(silhouette_score(X, kmeans.labels_))
    print(f"Silhouette K-Means: {silhouette:.3f}")

    raw_bounds = build_raw_bounds(df)

    MODELS_DIR.mkdir(parents=True, exist_ok=True)
    REPORTS_DIR.mkdir(parents=True, exist_ok=True)

    joblib.dump(classifier, MODELS_DIR / "classifier.pkl")
    joblib.dump(kmeans, MODELS_DIR / "kmeans.pkl")
    joblib.dump(FEATURE_COLS, MODELS_DIR / "feature_cols.pkl")
    joblib.dump(TARGET_MAP, MODELS_DIR / "target_map.pkl")
    joblib.dump(raw_bounds, MODELS_DIR / "raw_bounds.pkl")

    metrics = {
        "modelVersion": MODEL_VERSION,
        "accuracy": round(acc, 4),
        "silhouetteScore": round(silhouette, 4),
        "trainSamples": len(X_train),
        "testSamples": len(X_test),
        "classDistribution": {str(k): int(v) for k, v in class_counts.items()},
        "classWeight": "balanced",
        "classificationReport": report,
        "rawBounds": {k: list(v) for k, v in raw_bounds.items()},
    }
    metrics_path = MODELS_DIR / "metrics.json"
    metrics_path.write_text(json.dumps(metrics, indent=2), encoding="utf-8")
    (REPORTS_DIR / "metrics.json").write_text(json.dumps(metrics, indent=2), encoding="utf-8")

    print(f"Modelos salvos em {MODELS_DIR}")
    print(f"Metricas em {metrics_path}")


if __name__ == "__main__":
    main()
