# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Mado is a card list application for the Weiss Schwarz trading card game. It is a monorepo with:
- **`back/`** — Python/FastAPI backend with Strawberry GraphQL and Meilisearch
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

# Import data into Meilisearch
uv run python src/bin/import_sets.py
uv run python src/bin/import_cards.py
```

The backend runs behind Caddy on `http://localhost`. GraphQL playground: `http://localhost/graphql`.

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

- **Entry point:** `back/src/main.py` — FastAPI app with a Strawberry GraphQL router mounted at `/graphql`.
- **Config:** `back/src/config.py` — `Settings` (Pydantic), reads from env vars. Key fields: `cards_dir`, `medias_dir`.
- **Meilisearch client:** `back/src/meili_client.py` — creates/caches a Meilisearch client.
- **Models:** `back/src/models/object_set.py` and `object_card.py` — Strawberry types. Query resolvers (`get_sets`, `search_sets`) live here.

### Frontend

- **Entry point:** `front/mado_flutter/lib/main.dart` — creates a `GraphQLClient` pointing to `$BACKEND_URL/graphql`, wraps the app in `GraphQLProvider`.
- **App routing:** `front/mado_flutter/lib/src/app.dart` — `onGenerateRoute` dispatches to feature views.
- **WsSet feature:** `front/mado_flutter/lib/src/ws_set/` — main feature; `WsSetListView` fetches/searches sets via GraphQL, `ws_set_models.dart` holds the queries and Dart models.

### Data flow

```
Flutter → POST /graphql → FastAPI/Strawberry → Meilisearch → response → Flutter
```

## Environment

Copy `back/env.sample` to `back/.env`. Key variables:

| Variable | Purpose |
|---|---|
| `MEILI_MASTER_KEY` | Meilisearch master key |
| `CARDS_FOLDERS` | Path to card/set JSON data |

## Pre-commit

```bash
pipx install pre-commit
pre-commit install
pre-commit run --all-files
```

Hooks: trailing whitespace, EOF newline, YAML check, Black formatter (targets `back/`).
