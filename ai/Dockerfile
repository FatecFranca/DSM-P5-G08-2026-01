FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY src/ ./src/
COPY models/ ./models/
COPY data/dataset_preprocessado.csv ./data/dataset_preprocessado.csv

ENV PORT=8000
EXPOSE 8000

CMD ["sh", "-c", "uvicorn src.serve:app --host 0.0.0.0 --port ${PORT:-8000}"]
