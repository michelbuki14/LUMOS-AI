# =============================================================================
# LUMOS AI — Makefile
# =============================================================================
# Convenient commands for local development
# =============================================================================

.PHONY: help install dev test build clean docker-up docker-down docker-build lint format typecheck

# Default target
help: ## Show this help message
	@echo "LUMOS AI — AI Operating System for Professional Photography"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# =============================================================================
# Development
# =============================================================================

install: ## Install all dependencies
	pnpm install
	cd services/api && pip install -r requirements.txt
	cd services/ai && pip install -r requirements.txt

dev: ## Start all services in development mode
	pnpm dev

dev:api ## Start only the API server
	pnpm dev:api

dev:ai ## Start only the AI service
	pnpm dev:ai

dev:render ## Start only the rendering engine
	pnpm dev:render

dev:desktop ## Start only the Flutter desktop app
	pnpm dev:desktop

# =============================================================================
# Testing
# =============================================================================

test: ## Run all tests
	pnpm test

test:api ## Run API tests only
	pnpm test:api

test:ai ## Run AI service tests only
	pnpm test:ai

test:desktop ## Run Flutter tests only
	pnpm test:desktop

# =============================================================================
# Code Quality
# =============================================================================

lint: ## Lint all code
	pnpm lint

format: ## Format all code
	pnpm format

typecheck: ## Type check Python code
	cd services/api && pnpm typecheck

# =============================================================================
# Database
# =============================================================================

db:migrate: ## Run database migrations
	pnpm db:migrate

db:seed: ## Seed the database with demo data
	pnpm db:seed

db:reset: ## Reset the database
	docker compose down postgres
	docker volume rm lumos-ai_postgres_data
	docker compose up postgres

# =============================================================================
# Docker
# =============================================================================

docker-up: ## Start all services with Docker Compose
	docker compose up -d

docker-down: ## Stop all Docker services
	docker compose down

docker-build: ## Build all Docker images
	docker compose build

docker-logs: ## View Docker logs
	docker compose logs -f

docker-clean: ## Clean Docker volumes and images
	docker compose down -v
	docker system prune -f

# =============================================================================
# Production Build
# =============================================================================

build: ## Build all services for production
	pnpm build

build:api: ## Build API for production
	pnpm build:api

build:ai: ## Build AI service for production
	pnpm build:ai

build:render: ## Build rendering engine for production
	pnpm build:render

build:desktop: ## Build Flutter desktop app
	pnpm build:desktop

# =============================================================================
# Cleanup
# =============================================================================

clean: ## Clean all build artifacts
	pnpm clean
	rm -rf node_modules
	rm -rf services/api/__pycache__
	rm -rf services/ai/__pycache__
	rm -rf apps/desktop/build

# =============================================================================
# Setup
# =============================================================================

setup: ## Initial project setup
	cp -n .env.example .env || true
	pnpm install
	@echo ""
	@echo "Setup complete! Run 'make dev' to start development."

setup:docker: ## Setup with Docker (recommended)
	cp -n .env.example .env || true
	docker compose up -d postgres redis minio
	@echo ""
	@echo "Infrastructure started! Run 'make install' to install dependencies."
