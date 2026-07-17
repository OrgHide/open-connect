# XStack Open-Connect Makefile
# Comprehensive build and deployment automation

.PHONY: help install dev test lint format build docker docker-railway deploy deploy-railway clean

# Environment
NODE_ENV ?= development
PORT ?= 3000

# Help
help: ## Show this help message
	@echo "XStack Open-Connect - Build & Deployment Commands"
	@echo "==============================================="
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "%-20s %s\n", $$1, $$2}'
	@echo ""

# Install dependencies
install: ## Install all dependencies
	@echo "Installing dependencies..."
	cd xstack && npm install
	@echo "Dependencies installed successfully!"

# Development setup
dev: install ## Start development server
	@echo "Starting development server..."
	cd xstack && npm run dev

# Run tests
test: ## Run all tests
	@echo "Running tests..."
	cd xstack && npm test

# Run linter
lint: ## Run ESLint
	@echo "Running linter..."
	cd xstack && npm run lint

# Format code
format: ## Format code with Prettier
	@echo "Formatting code..."
	cd xstack && npm run format

# Build production bundle
build: ## Build production bundle
	@echo "Building production bundle..."
	cd xstack && npm run build
	@echo "Build completed successfully!"

# Docker build
docker: ## Build Docker image
	@echo "Building Docker image..."
	docker build -t orghide/open-connect:xstack -f Dockerfile .
	@echo "Docker image built successfully!"

# Docker build for Railway
docker-railway: ## Build Docker image for Railway
	@echo "Building Railway Docker image..."
	docker build -t orghide/open-connect:xstack-railway -f Dockerfile.railway .
	@echo "Railway Docker image built successfully!"

# Deploy to Railway (requires railway CLI)
deploy-railway: docker-railway ## Deploy to Railway
	@echo "Deploying to Railway..."
	railway up --detach
	@echo "Deployment initiated! Check Railway dashboard for progress."

# General deploy target
deploy: build ## Deploy the application
	@echo "Deploying application..."
	@echo "Use make deploy-railway for Railway deployment"
	@echo "Build completed. Ready for deployment!"

# Clean
clean: ## Clean build artifacts
	@echo "Cleaning build artifacts..."
	cd xstack && rm -rf dist node_modules
	docker rmi orghide/open-connect:xstack orghide/open-connect:xstack-railway 2>/dev/null || true
	@echo "Cleanup completed!"

# Setup environment
setup-env: ## Create .env file from example
	@echo "Setting up environment..."
	cp .env.example .env
	@echo "Environment file created from .env.example"
	@echo "Please edit .env with your actual configuration values"

# Health check
health: ## Check application health
	@echo "Checking application health..."
	curl -f http://localhost:$(PORT)/health || echo "Health check failed"
	@echo "Health check completed!"
