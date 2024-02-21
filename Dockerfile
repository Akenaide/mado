FROM python:3.11 as python

WORKDIR /app
ENV PATH /root/.local/bin:$PATH
ENV WEB_PORT 8000
EXPOSE ${WEB_PORT}


RUN curl -sSL https://pdm-project.org/install-pdm.py | python3 -
COPY pdm.lock .
COPY pyproject.toml .
RUN pdm install
FROM python as package_installed

COPY alembic.ini .
COPY alembic/* alembic/
COPY src/* src/

WORKDIR /app/src

CMD ["pdm", "run", "uvicorn", "main:app", "--reload", "--port", "${WEB_PORT}", "--host", "0.0.0.0"]
