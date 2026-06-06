# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Mado is a card list application for the Weiss Schwarz trading card game. It is a monorepo with:
- **`back/`** — Python/FastAPI backend with Strawberry GraphQL and Elasticsearch
- **`front/mado_flutter/`** — Flutter frontend
- **`data/`** — Card and set data as JSON files

## Backend Commands

All backend commands run from `back/`.

```bash
# Start dev server with hot-reload (preferred)
docker compose watch

# Run a specific script
cd back && uv run python src/bin/import_sets.py

# Lint / format
black back/

# Import data into Elasticsearch
uv run python src/bin/create_mappings.py
uv run python src/bin/import_sets.py
uv run python src/bin/import_cards.py
```

The backend runs on `http://localhost:8013`. GraphQL playground: `http://localhost:8013/graphql`.

## Frontend Commands

All frontend commands run from `front/mado_flutter/`.

```bash
flutter run          # Run on connected device/emulator
flutter test         # Run tests
flutter analyze      # Lint / static analysis
flutter build <platform>  # ios | android | web | macos | linux | windows
```

## Architecture

### Backend

- **Entry point:** `back/src/main.py` — FastAPI app with a Strawberry GraphQL router mounted at `/graphql`. Initializes an Elasticsearch API key on startup via a lifespan handler.
- **Config:** `back/src/config.py` — `Settings` (Pydantic), reads from env vars. Key fields: `cards_dir`, `set_file`, `es_url`, `set_index`, `card_index`.
- **ES client:** `back/src/es_client.py` — creates/caches an API key on first run, persisted to `es_api_key` file.
- **Models:** `back/src/models/object_set.py` and `object_card.py` — Strawberry types that double as Elasticsearch document schemas. Query resolvers live here.

### Frontend

- **Entry point:** `front/mado_flutter/lib/main.dart` — creates a `GraphQLClient` pointing to `http://localhost:8013/graphql`, wraps the app in `GraphQLProvider`.
- **App routing:** `front/mado_flutter/lib/src/app.dart` — `onGenerateRoute` dispatches to feature views.
- **WsSet feature:** `front/mado_flutter/lib/src/ws_set/` — main feature; `WsSetListView` fetches sets via GraphQL Query widget (polls every 10 s), `ws_set_models.dart` holds the query and Dart models.

### Data flow

```
Flutter → POST /graphql → FastAPI/Strawberry → Elasticsearch → response → Flutter
```

## Environment

Copy `back/env.sample` to `back/.env`. Key variables:

| Variable | Default | Purpose |
|---|---|---|
| `WEB_PORT` | `8013` | Backend HTTP port |
| `CARDS_FOLDERS` | `./data` | Path to card/set JSON data |
| `ELASTIC_PASSWORD` | — | Elasticsearch admin password |
| `ES_URL` | — | Elasticsearch endpoint |

Elasticsearch and Kibana services are defined in `back/compose.yaml` but commented out; uncomment to run the full stack locally.

## Pre-commit

```bash
pipx install pre-commit
pre-commit install
pre-commit run --all-files
```

Hooks: trailing whitespace, EOF newline, YAML check, Black formatter (targets `back/`).
