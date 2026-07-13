# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Mado is a card list application for the Weiss Schwarz trading card game. It is a monorepo with:
- **`back/`** — Python/FastAPI backend with Strawberry GraphQL and Meilisearch
- **`front/mado_flutter/`** — Flutter frontend
- **`data/`** — Card and set data as JSON files

## Backend Commands

A `justfile` at the repo root wraps common commands. All backend commands run from `back/`.

```bash
# Start dev server with hot-reload (preferred)
just dev          # → cd back && podman compose watch

# Lint / format
just fmt          # → black src/

# Import data into Meilisearch (order matters)
just import       # indexes → sets → cards

# Or step by step:
just indexes      # create_indexes.py
just import-sets
just import-cards
```

The backend runs behind Caddy on `http://localhost` in dev. GraphQL playground: `http://localhost/graphql`.

## Frontend Commands

All frontend commands run from `front/mado_flutter/`.

```bash
just flutter-run     # flutter run -d chrome --dart-define-from-file=.env.json
just flutter-test    # flutter test
just flutter-analyze # flutter analyze
just deploy-front    # build web + rsync to $DEPLOY_HOST
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
- **WsSet feature:** `front/mado_flutter/lib/src/ws_set/` — main feature; `WsSetListView` fetches/searches sets, `WsCardListView` lists cards for a set, `WsCardDetailView` shows a single card. Models/queries in `ws_set_models.dart` and `ws_card_models.dart`.

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
