"""Gera relatorios visuais e metricas a partir dos modelos treinados."""
from __future__ import annotations

import json
from pathlib import Path

import joblib
import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import pandas as pd
import seaborn as sns
from sklearn.metrics import ConfusionMatrixDisplay, confusion_matrix

from preprocess import FEATURE_COLS

ROOT = Path(__file__).resolve().parents[1]
DATA_PATH = ROOT / "data" / "dataset_preprocessado.csv"
MODELS_DIR = ROOT / "models"
REPORTS_DIR = ROOT / "reports"

PROFILE_NAMES = ["Em_Risco", "Sedentario", "Moderado", "Saudavel_Ativo"]


def main() -> None:
    if not (MODELS_DIR / "classifier.pkl").exists():
        raise FileNotFoundError("Execute train.py antes de evaluate.py")

    df = pd.read_csv(DATA_PATH)
    X = df[FEATURE_COLS]
    y = df["Health_Profile_enc"]

    classifier = joblib.load(MODELS_DIR / "classifier.pkl")
    kmeans = joblib.load(MODELS_DIR / "kmeans.pkl")

    y_pred = classifier.predict(X)
    cm = confusion_matrix(y, y_pred)

    REPORTS_DIR.mkdir(parents=True, exist_ok=True)

    fig, ax = plt.subplots(figsize=(8, 6))
    ConfusionMatrixDisplay(confusion_matrix=cm, display_labels=PROFILE_NAMES).plot(ax=ax, cmap="Blues")
    ax.set_title("Matriz de Confusao - Logistic Regression")
    fig.tight_layout()
    fig.savefig(REPORTS_DIR / "confusion_matrix.png", dpi=120)
    plt.close(fig)

    clusters = kmeans.predict(X)
    fig, ax = plt.subplots(figsize=(8, 6))
    scatter = ax.scatter(
        X["Daily_Steps"],
        X["Hours_of_Sleep"],
        c=clusters,
        cmap="viridis",
        alpha=0.6,
        s=20,
    )
    ax.set_xlabel("Daily_Steps (normalizado)")
    ax.set_ylabel("Hours_of_Sleep (normalizado)")
    ax.set_title("K-Means Clusters")
    fig.colorbar(scatter, ax=ax, label="Cluster")
    fig.tight_layout()
    fig.savefig(REPORTS_DIR / "cluster_scatter.png", dpi=120)
    plt.close(fig)

    profile_counts = df["Health_Profile"].value_counts()
    fig, ax = plt.subplots(figsize=(8, 5))
    sns.barplot(x=profile_counts.index, y=profile_counts.values, ax=ax, palette="Set2")
    ax.set_title("Distribuicao de Perfis no Dataset")
    ax.set_ylabel("Quantidade")
    fig.tight_layout()
    fig.savefig(REPORTS_DIR / "profile_distribution.png", dpi=120)
    plt.close(fig)

    metrics = json.loads((MODELS_DIR / "metrics.json").read_text(encoding="utf-8"))
    metrics["figures"] = [
        "confusion_matrix.png",
        "cluster_scatter.png",
        "profile_distribution.png",
    ]
    (REPORTS_DIR / "metrics.json").write_text(json.dumps(metrics, indent=2), encoding="utf-8")
    print(f"Relatorios salvos em {REPORTS_DIR}")


if __name__ == "__main__":
    main()
