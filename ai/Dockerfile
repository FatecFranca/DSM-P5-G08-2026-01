FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY src/ ./src/
COPY models/ ./models/

ENV PORT=8000
EXPOSE 8000

CMD ["sh", "-c", "cd src && uvicorn serve:app --host 0.0.0.0 --port ${PORT:-8000}"]
