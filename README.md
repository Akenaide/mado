# mado
Card list for card game weiss schwarz

## Front
- https://flutter.dev

## Database
- https://strawberry.rocks/docs GraphQl

## Python
- https://fastapi.tiangolo.com web framework
- https://www.meilisearch.com search engine
- https://github.com/astral-sh/uv package manager


## Local dev
- Docker compose v2.22 or later to use `watch`
- `pipx install pre-commit` (https://pre-commit.com/#intro)[https://pre-commit.com/#intro]

### Env
- `CARDS_FOLDERS`: path to card files, used when importing card data
- `MEILI_MASTER_KEY`: Meilisearch master key — any random string (min 16 chars). Generate one with `openssl rand -hex 32`

### Start
- Use `docker compose watch` to start the project.
- API: http://localhost/graphql
- Meilisearch UI: http://meili.localhost
  - Use your `MEILI_MASTER_KEY` as the API key to log in

### Import data
```bash
uv run python src/bin/create_indexes.py
uv run python src/bin/import_sets.py
uv run python src/bin/import_cards.py
```
