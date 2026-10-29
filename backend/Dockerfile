FROM python:3.12-slim AS base
WORKDIR /srv
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt
COPY app ./app
COPY migrations ./migrations
COPY scripts ./scripts

# Development and CI: adds pytest and the test suite.
FROM base AS dev
COPY requirements-dev.txt ./
RUN pip install --no-cache-dir -r requirements-dev.txt
COPY tests ./tests
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]

# Production: no test tooling, unprivileged user. Uvicorn reads FORWARDED_ALLOW_IPS
# and WEB_CONCURRENCY from the environment.
FROM base AS prod
RUN useradd --system --no-create-home cadastra
USER cadastra
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--proxy-headers"]
