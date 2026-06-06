"""Gera notebooks Jupyter para entrega da disciplina Aprendizagem de Maquina."""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
NOTEBOOKS = ROOT / "notebooks"


def nb(cells: list[dict]) -> dict:
    return {
        "nbformat": 4,
        "nbformat_minor": 5,
        "metadata": {
            "kernelspec": {
                "display_name": "Python 3",
                "language": "python",
                "name": "python3",
            },
            "language_info": {"name": "python", "version": "3.12.0"},
        },
        "cells": cells,
    }


def md(source: str) -> dict:
    return {"cell_type": "markdown", "metadata": {}, "source": source.splitlines(keepends=True)}


def code(source: str) -> dict:
    return {
        "cell_type": "code",
        "metadata": {},
        "source": source.splitlines(keepends=True),
        "outputs": [],
        "execution_count": None,
    }


NOTEBOOKS.mkdir(parents=True, exist_ok=True)

notebooks = {
    "01_exploracao_eda.ipynb": [
        md("# 01 — Exploracao de Dados (EDA)\n\n**Vitalis PI** — Dataset Health & Lifestyle preprocessado."),
        code(
            "import pandas as pd\nimport seaborn as sns\nimport matplotlib.pyplot as plt\n\n"
            "df = pd.read_csv('../data/dataset_preprocessado.csv')\n"
            "df.head()"
        ),
        code("df.info()\ndf.describe()"),
        code(
            "sns.countplot(data=df, x='Health_Profile', order=df['Health_Profile'].value_counts().index)\n"
            "plt.title('Distribuicao de Perfis')\nplt.xticks(rotation=15)\nplt.show()"
        ),
        code(
            "numeric = ['Age','BMI','Daily_Steps','Hours_of_Sleep','Exercise_Hours_per_Week']\n"
            "sns.heatmap(df[numeric].corr(), annot=True, cmap='coolwarm')\nplt.show()"
        ),
    ],
    "02_preprocessamento.ipynb": [
        md("# 02 — Preprocessamento\n\nEncoding, normalizacao MinMax e target `Health_Profile`."),
        code(
            "import pandas as pd\nfrom sklearn.preprocessing import MinMaxScaler\n\n"
            "df = pd.read_csv('../data/dataset_preprocessado.csv')\n"
            "print('Dataset ja preprocessado com colunas encoded e normalizadas.')\n"
            "df[['Gender_enc','Smoker_enc','Health_Profile_enc']].head()"
        ),
        md("O CSV exportado alimenta `train.py` e os modelos `.pkl`."),
    ],
    "03_treinamento_logistic_regression.ipynb": [
        md("# 03 — Classificacao (Logistic Regression)\n\nAprendizado **supervisionado**."),
        code(
            "import pandas as pd\nfrom sklearn.model_selection import train_test_split\n"
            "from sklearn.linear_model import LogisticRegression\n"
            "from sklearn.metrics import classification_report, accuracy_score\n\n"
            "FEATURE_COLS = ['Age','BMI','Daily_Steps','Hours_of_Sleep','Exercise_Hours_per_Week',"
            "'Heart_Rate','Calories_Intake','Alcohol_Consumption_per_Week',"
            "'Gender_enc','Smoker_enc','Diabetic_enc','Heart_Disease_enc']\n\n"
            "df = pd.read_csv('../data/dataset_preprocessado.csv')\n"
            "X, y = df[FEATURE_COLS], df['Health_Profile_enc']\n"
            "X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42, stratify=y)\n"
            "clf = LogisticRegression(max_iter=1000).fit(X_train, y_train)\n"
            "y_pred = clf.predict(X_test)\n"
            "print('Acuracia:', accuracy_score(y_test, y_pred))\n"
            "print(classification_report(y_test, y_pred))"
        ),
    ],
    "04_clusterizacao_kmeans.ipynb": [
        md("# 04 — Clusterizacao (K-Means)\n\nAprendizado **nao supervisionado**."),
        code(
            "import pandas as pd\nfrom sklearn.cluster import KMeans\n"
            "from sklearn.metrics import silhouette_score\n\n"
            "FEATURE_COLS = ['Age','BMI','Daily_Steps','Hours_of_Sleep','Exercise_Hours_per_Week',"
            "'Heart_Rate','Calories_Intake','Alcohol_Consumption_per_Week',"
            "'Gender_enc','Smoker_enc','Diabetic_enc','Heart_Disease_enc']\n\n"
            "df = pd.read_csv('../data/dataset_preprocessado.csv')\n"
            "X = df[FEATURE_COLS]\n"
            "km = KMeans(n_clusters=4, random_state=42, n_init=10).fit(X)\n"
            "print('Silhouette:', silhouette_score(X, km.labels_))\n"
            "print('Clusters:', pd.Series(km.labels_).value_counts().sort_index())"
        ),
    ],
    "05_avaliacao_metricas.ipynb": [
        md("# 05 — Avaliacao Final\n\nMetricas e exportacao de relatorios."),
        code(
            "import json\nfrom pathlib import Path\n\n"
            "metrics = json.loads(Path('../models/metrics.json').read_text())\n"
            "print('Versao:', metrics['modelVersion'])\n"
            "print('Acuracia:', metrics['accuracy'])\n"
            "print('Silhouette:', metrics['silhouetteScore'])"
        ),
        md(
            "**Disclaimer:** sistema de perfil comportamental — nao substitui orientacao medica.\n\n"
            "Execute `python src/train.py` e `python src/evaluate.py` para regenerar modelos e graficos em `reports/`."
        ),
    ],
}

for name, cells in notebooks.items():
    path = NOTEBOOKS / name
    path.write_text(json.dumps(nb(cells), indent=1), encoding="utf-8")
    print(f"Gerado: {path}")
