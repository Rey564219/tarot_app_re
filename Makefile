SHELL := /bin/sh

FRONTEND_DIR := frontend
BACKEND_DIR := backend

FLUTTER ?= flutter
# Prefer virtualenv python if present, fallback to system python
VENV_PY := .venv/bin/python
PYTHON ?= $(VENV_PY)
COMPOSE ?= docker compose
ADB ?= $(LOCALAPPDATA)\Android\Sdk\platform-tools\adb.exe
ANDROID_EMULATOR ?= Medium_Phone_API_36.1
ANDROID_DEVICE ?= emulator-5554
DEV_USER_ID ?= e154d397-dff7-4780-b5c4-5aa3a3889a7d
DEV_AUTH_TOKEN ?= test
DEV_ENV ?= test

# Postgres defaults (can be overridden by environment or .env)
POSTGRES_DB ?= tarot_db
POSTGRES_USER ?= tarot_user
POSTGRES_PASSWORD ?= admin1234
DATABASE_URL ?= postgresql://$(POSTGRES_USER):$(POSTGRES_PASSWORD)@localhost:5432/$(POSTGRES_DB)

.DEFAULT_GOAL := help

.PHONY: help get clean format analyze test run run-web build-apk build-web build-ios \
	frontend-get frontend-clean frontend-format frontend-analyze frontend-test \
	frontend-run frontend-run-web frontend-run-android frontend-build-apk frontend-build-web frontend-build-ios \
	android-adb-kill android-adb-start android-emulator android-devices \
	venv-create backend-install backend-run backend-build docker-up docker-down docker-build docker-logs \
	postgres-up postgres-stop postgres-rm postgres-logs postgres-run-standalone postgres-psql

help:
	@echo "Available targets:"
	@echo "  make frontend-get        - Run flutter pub get in frontend/"
	@echo "  make frontend-clean      - Remove Flutter build artifacts"
	@echo "  make frontend-format     - Format Dart code"
	@echo "  make frontend-analyze    - Run static analysis"
	@echo "  make frontend-test       - Run Flutter tests"
	@echo "  make frontend-run        - Run the app on the connected device"
	@echo "  make frontend-run-web    - Run the app in Chrome"
	@echo "  make frontend-run-android - Run the app on the Android emulator"
	@echo "  make frontend-build-apk  - Build an Android APK"
	@echo "  make frontend-build-web  - Build the web app"
	@echo "  make frontend-build-ios  - Build the iOS app"
	@echo "  make android-adb-kill    - Stop adb server"
	@echo "  make android-adb-start   - Start adb server"
	@echo "  make android-emulator    - Launch the Android emulator"
	@echo "  make android-devices     - List connected Android devices"
	@echo "  make backend-install     - Install backend Python dependencies"
	@echo "  make backend-run         - Run the FastAPI backend"
	@echo "  make backend-build       - Build the backend Docker image"
	@echo "  make docker-up           - Start the Docker Compose stack"
	@echo "  make docker-down         - Stop the Docker Compose stack"
	@echo "  make docker-build        - Build the Docker Compose stack"
	@echo "  make docker-logs         - Follow the Docker Compose logs"
	@echo "  make get/clean/...       - Backward-compatible aliases for frontend targets"

frontend-get:
	cd "$(FRONTEND_DIR)" && $(FLUTTER) pub get

frontend-clean:
	cd "$(FRONTEND_DIR)" && $(FLUTTER) clean

frontend-format:
	cd "$(FRONTEND_DIR)" && $(FLUTTER) format .

frontend-analyze:
	cd "$(FRONTEND_DIR)" && $(FLUTTER) analyze

frontend-test:
	cd "$(FRONTEND_DIR)" && $(FLUTTER) test

frontend-run-web:
	@echo "Note: run 'make backend-install' and 'make backend-run' in a separate terminal first"
	cd "$(FRONTEND_DIR)" && $(FLUTTER) run -d chrome --dart-define=DEV_USER_ID=$(DEV_USER_ID) --dart-define=DEV_AUTH_TOKEN=$(DEV_AUTH_TOKEN)

frontend-run-android:
	@echo "Note: run 'make backend-install' and 'make backend-run' in a separate terminal first"
	cd "$(FRONTEND_DIR)" && $(FLUTTER) run -d $(ANDROID_DEVICE) --dart-define=DEV_USER_ID=$(DEV_USER_ID) --dart-define=ENV=$(DEV_ENV)

frontend-build-apk:
	$(MAKE) android-adb-kill
	$(MAKE) android-adb-start
	$(MAKE) android-emulator
	$(MAKE) android-devices
	$(MAKE) frontend-run-android

frontend-build-web:
	cd "$(FRONTEND_DIR)" && $(FLUTTER) build web

frontend-build-ios:
	cd "$(FRONTEND_DIR)" && $(FLUTTER) build ios

venv-create:
	python3 -m venv .venv
	. .venv/bin/activate

backend-install: venv-create
	$(VENV_PY) -m pip install -r "$(BACKEND_DIR)/requirements.txt"

backend-run: venv-create
	$(VENV_PY) -m uvicorn backend.main:app --host 0.0.0.0 --port 8000 --reload

backend-build:
	$(COMPOSE) build backend

android-adb-kill:
	"$(ADB)" kill-server

android-adb-start:
	"$(ADB)" start-server

android-emulator:
	$(FLUTTER) emulators --launch $(ANDROID_EMULATOR)

android-devices:
	"$(ADB)" wait-for-device
	"$(ADB)" devices
	$(FLUTTER) devices --device-timeout 60

docker-up:
	$(COMPOSE) up --build

docker-down:
	$(COMPOSE) down

docker-build:
	$(COMPOSE) build

docker-logs:
	$(COMPOSE) logs -f

# PostgreSQL convenience targets
postgres-up:
	@echo "Starting only the 'db' service via docker compose (trying docker-compose or docker compose)"
	@sh -c '\
if command -v docker-compose >/dev/null 2>&1; then \
  docker-compose up -d db; \
elif docker compose version >/dev/null 2>&1; then \
  docker compose up -d db; \
else \
  echo "Neither docker-compose nor docker compose is available. Install Docker Desktop or docker-compose."; exit 1; \
fi'

postgres-stop:
	@echo "Stopping the 'db' service"
	@sh -c '\
if command -v docker-compose >/dev/null 2>&1; then \
  docker-compose stop db; \
elif docker compose version >/dev/null 2>&1; then \
  docker compose stop db; \
else \
  echo "No docker compose available"; exit 1; \
fi'

postgres-rm:
	@echo "Removing stopped 'db' service container and volumes"
	@sh -c '\
if command -v docker-compose >/dev/null 2>&1; then \
  docker-compose rm -sf db; \
elif docker compose version >/dev/null 2>&1; then \
  docker compose rm -sf db; \
else \
  echo "No docker compose available"; exit 1; \
fi'

postgres-logs:
	@echo "Tailing logs for the 'db' service"
	@sh -c '\
if command -v docker-compose >/dev/null 2>&1; then \
  docker-compose logs -f db; \
elif docker compose version >/dev/null 2>&1; then \
  docker compose logs -f db; \
else \
  echo "No docker compose available"; exit 1; \
fi'

postgres-run-standalone:
	@echo "Run PostgreSQL standalone container (name: tarot_db)"
	docker run --name tarot_db -e POSTGRES_DB=$(POSTGRES_DB) -e POSTGRES_USER=$(POSTGRES_USER) -e POSTGRES_PASSWORD=$(POSTGRES_PASSWORD) -p 5432:5432 -v $(CURDIR)/db_data:/var/lib/postgresql/data -d postgres:16

postgres-psql:
	@echo "Open psql shell into tarot_db container"
	docker exec -it tarot_db psql -U $(POSTGRES_USER) -d $(POSTGRES_DB)

get: frontend-get

clean: frontend-clean

format: frontend-format

analyze: frontend-analyze

test: frontend-test

run: frontend-run

run-web: frontend-run-web

build-apk: frontend-build-apk

build-web: frontend-build-web

build-ios: frontend-build-ios
