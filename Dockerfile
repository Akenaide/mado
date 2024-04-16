FROM python:3.11 as python

USER root
WORKDIR /app
ENV WEB_PORT 8000
EXPOSE ${WEB_PORT}
RUN useradd  app

RUN curl -sSL https://pdm-project.org/install-pdm.py | PDM_HOME=/usr/local python3 -
COPY pdm.lock .
COPY pyproject.toml .
RUN pdm install
FROM python as package_installed

# The chown is not recommended but I want to test `docker compose watch` and currently it's needed.
COPY --chown=app:app ./src src

WORKDIR /app/src

USER app
CMD ["pdm", "run", "uvicorn", "main:app", "--reload", "--port", "${WEB_PORT}", "--host", "0.0.0.0"]
