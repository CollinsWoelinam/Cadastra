FROM python:3.12-slim
WORKDIR /srv
COPY requirements.txt requirements-dev.txt ./
RUN pip install --no-cache-dir -r requirements-dev.txt
COPY app ./app
COPY migrations ./migrations
COPY tests ./tests
COPY scripts ./scripts
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
