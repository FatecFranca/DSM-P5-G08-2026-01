# AI (Python)

Modelos de Machine Learning: classificacao (Logistic Regression) e clusterizacao (K-Means).

## Estrutura

```
ai/
├── data/              # dataset_preprocessado.csv
├── notebooks/         # treino e avaliacao
├── models/            # .pkl exportados
├── src/
│   ├── train.py       # treina e salva modelos
│   └── serve.py       # FastAPI para inferencia
└── requirements.txt
```

## Setup

```bash
cd ai
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
```

## Treinar

```bash
python src/train.py
```

## Servir (API ML na porta 8000)

```bash
uvicorn src.serve:app --reload --port 8000
```

A API Node (`api/`) chama `POST http://localhost:8000/predict` quando `ML_SERVICE_URL` estiver configurado.
