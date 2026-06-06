FROM ghcr.io/astral-sh/uv:latest AS uv

FROM python:3.11 as python

USER root
WORKDIR /app
ENV WEB_PORT 8000
EXPOSE ${WEB_PORT}

COPY --from=uv /uv /uvx /usr/local/bin/

COPY uv.lock .
COPY pyproject.toml .
RUN uv sync

FROM python as package_installed

COPY ./src src
WORKDIR /app/src

CMD ["uv", "run", "uvicorn", "main:app", "--reload", "--port", "${WEB_PORT}", "--host", "0.0.0.0"]
