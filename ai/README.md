# AI (Python) — Vitalis ML

Classificacao (**Logistic Regression**) + clusterizacao (**K-Means**) para perfis de habitos.

## Estrutura

```
ai/
├── data/dataset_preprocessado.csv
├── notebooks/              # entrega Aprendizagem de Maquina
├── models/                 # .pkl gerados pelo treino
├── reports/                # graficos e metricas
├── src/
│   ├── preprocess.py       # features raw → normalizadas
│   ├── train.py            # treina e salva modelos
│   ├── evaluate.py         # relatorios visuais
│   └── serve.py            # FastAPI inferencia :8000
└── Dockerfile              # deploy Azure
```

## Setup

```bash
cd ai
py -3 -m pip install -r requirements.txt
```

## Treinar

```bash
cd src
py -3 train.py
py -3 evaluate.py
```

Metricas atuais (ultimo treino): veja `models/metrics.json`.

## Servir (porta 8000)

```bash
cd src
py -3 -m uvicorn serve:app --reload --port 8000
```

## Notebooks

```bash
py -3 scripts/build_notebooks.py
jupyter notebook notebooks/
```

## Integracao API Node

No `.env` da raiz:
```env
ML_SERVICE_URL=http://localhost:8000
```

A API chama `POST /predict` ao processar `POST /assessments`.

## Credenciais

Veja [docs/CREDENCIAIS.md](../docs/CREDENCIAIS.md) — ML nao precisa de API key; Gemini sim (na API Node).
