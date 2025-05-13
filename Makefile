# Default user and group IDs, can be overridden when calling
USER_ID ?= 1000
GROUP_ID ?= 1000

# Docker Compose command shortcut
DC := docker compose

# Main target: full project setup and deployment
.PHONY: all
all: setup

# Full project setup: build, prepare env, install dependencies, generate keys, migrate and seed DB
.PHONY: setup
setup: build env-prepare composer-install key-generate jwt-generate migrate-seed

# Build and start containers in detached mode, removing orphans
.PHONY: build
build:
	$(DC) up --build -d --remove-orphans

# Start containers in detached mode
.PHONY: start
start:
	$(DC) up -d

# Stop and remove containers and volumes
.PHONY: stop
stop:
	$(DC) down -v

# Restart containers
.PHONY: restart
restart: stop start

# Copy .env.example to .env if .env does not exist
.PHONY: env-prepare
env-prepare:
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo ".env file created from .env.example"; \
	else \
		echo ".env file already exists, skipping"; \
	fi

# Install Composer dependencies inside the app container
.PHONY: composer-install
composer-install:
	$(DC) exec app composer install --no-interaction --prefer-dist --optimize-autoloader

# Generate Laravel application key
.PHONY: key-generate
key-generate:
	$(DC) exec app php artisan key:generate

# Generate JWT secret key
.PHONY: jwt-generate
jwt-generate:
	$(DC) exec app php artisan jwt:secret

# Refresh database and seed
.PHONY: migrate-seed
migrate-seed:
	$(DC) exec app php artisan migrate:fresh --seed

# Show list of available commands
.PHONY: help
help:
	@echo "Available commands:"
	@echo "  make all              - Full project setup and deployment"
	@echo "  make build            - Build and start containers"
	@echo "  make start            - Start containers"
	@echo "  make stop             - Stop and remove containers and volumes"
	@echo "  make restart          - Restart containers"
	@echo "  make env-prepare      - Create .env from .env.example if missing"
	@echo "  make composer-install - Install Composer dependencies"
	@echo "  make key-generate     - Generate Laravel app key"
	@echo "  make jwt-generate     - Generate JWT secret key"
	@echo "  make migrate-seed     - Refresh database and run seeders"
	@echo ""
	@echo "You can override USER_ID and GROUP_ID when calling, e.g.:"
	@echo "  make build USER_ID=1001 GROUP_ID=1001"
