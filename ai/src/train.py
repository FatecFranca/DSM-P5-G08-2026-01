"""
Treina classificador (Logistic Regression) e clusterizador (K-Means).
Salva modelos em ai/models/ para uso pelo serve.py.
"""
from pathlib import Path

import joblib
import pandas as pd
from sklearn.cluster import KMeans
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder

ROOT = Path(__file__).resolve().parents[1]
DATA_PATH = ROOT / "data" / "dataset_preprocessado.csv"
MODELS_DIR = ROOT / "models"

FEATURE_COLS = [
    "Age", "BMI", "Daily_Steps", "Hours_of_Sleep",
    "Exercise_Hours_per_Week", "Heart_Rate", "Calories_Intake",
    "Alcohol_Consumption_per_Week", "Gender_enc", "Smoker_enc",
    "Diabetic_enc", "Heart_Disease_enc",
]

TARGET_MAP = {"Em_Risco": 0, "Sedentario": 1, "Moderado": 2, "Saudavel_Ativo": 3}


def main() -> None:
    if not DATA_PATH.exists():
        raise FileNotFoundError(f"Coloque o CSV em {DATA_PATH}")

    df = pd.read_csv(DATA_PATH)
    X = df[FEATURE_COLS]
    y = df["Health_Profile_enc"]

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )

    classifier = LogisticRegression(max_iter=1000, random_state=42)
    classifier.fit(X_train, y_train)
    acc = classifier.score(X_test, y_test)
    print(f"Acuracia classificador: {acc:.2%}")

    kmeans = KMeans(n_clusters=4, random_state=42, n_init=10)
    kmeans.fit(X)

    MODELS_DIR.mkdir(parents=True, exist_ok=True)
    joblib.dump(classifier, MODELS_DIR / "classifier.pkl")
    joblib.dump(kmeans, MODELS_DIR / "kmeans.pkl")
    joblib.dump(FEATURE_COLS, MODELS_DIR / "feature_cols.pkl")
    joblib.dump(TARGET_MAP, MODELS_DIR / "target_map.pkl")
    print(f"Modelos salvos em {MODELS_DIR}")


if __name__ == "__main__":
    main()
