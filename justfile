set dotenv-load

# Show available recipes
default:
    @just --list

# --- Backend ---

# Start backend with hot-reload (podman compose watch)
dev:
    cd back && podman compose watch

# Build backend podman image
build:
    cd back && podman compose build

# Build and push multi-arch backend image to Docker Hub (amd64 + arm64)
publish tag="latest":
    podman build --platform linux/amd64 -t docker.io/akenaide/mado:{{tag}}-amd64 back
    podman build --platform linux/arm64 -t docker.io/akenaide/mado:{{tag}}-arm64 back
    podman rmi docker.io/akenaide/mado:{{tag}} || true
    podman manifest rm docker.io/akenaide/mado:{{tag}} || true
    podman manifest create docker.io/akenaide/mado:{{tag}}
    podman manifest add docker.io/akenaide/mado:{{tag}} docker.io/akenaide/mado:{{tag}}-amd64
    podman manifest add docker.io/akenaide/mado:{{tag}} docker.io/akenaide/mado:{{tag}}-arm64
    podman manifest push --all docker.io/akenaide/mado:{{tag}}

# Start all services (no watch)
up:
    cd back && podman compose up

# Stop all services
down:
    cd back && podman compose down

# Connect to back
back-bash:
    cd back && podman compose exec -it back bash

# Create Meilisearch indexes
indexes:
    cd back && uv run python src/bin/create_indexes.py

# Import sets into Meilisearch
import-sets:
    cd back && uv run python src/bin/import_sets.py

# Import cards into Meilisearch
import-cards:
    cd back && uv run python src/bin/import_cards.py

# Run full data import (indexes → sets → cards)
import: indexes import-sets import-cards

# Check Meilisearch connection
meili-check:
    cd back && uv run python src/bin/try_meili_connect.py

# Lint / format backend
fmt:
    cd back && black src/

# --- Frontend ---

# Run Flutter app
flutter-run:
    cd front/mado_flutter && flutter run -d chrome --dart-define-from-file=.env.json

# Run Flutter tests
flutter-test:
    cd front/mado_flutter && flutter test

# Analyze Flutter code
flutter-analyze:
    cd front/mado_flutter && flutter analyze

# Build Flutter web and deploy to server (requires DEPLOY_HOST=user@host in .env)
deploy-front:
    cd front/mado_flutter && flutter build web --dart-define-from-file=.env.json
    rsync -az --delete front/mado_flutter/build/web/ $DEPLOY_HOST:/home/web/apps/mado_front_artifacts/

# --- Quality ---

# Run pre-commit hooks on all files
lint:
    pre-commit run --all-files
