# EXPO to WORLD Backend
# ======================
# Monorepo backend for EXPO to WORLD platform
# 
# Services:
#   - auth-service: Authentication and authorization
#   - user-service: User profile management
#   - catalog-service: Product catalog and categories
#   - order-service: Cart and order management
#   - ebook-service: E-book publishing platform

.PHONY: help build test lint run dev clean docker
.DEFAULT_GOAL := help

# ============================================
# Variables
# ============================================
GO := go
GOFMT := gofmt
GOLINT := golangci-lint
GOTEST := $(GO) test
GOBUILD := $(GO) build

# Build flags
CGO_ENABLED := 0
GOOS := linux
GOARCH := amd64
BUILD_FLAGS := -ldflags="-s -w" -trimpath

# Directories
BIN_DIR := ./bin
CMD_DIR := ./cmd
PKG_DIR := ./pkg
INTERNAL_DIR := ./internal

# Services
SERVICES := auth catalog ebook order user

# ============================================
# Help
# ============================================
help: ## Show this help message
	@echo ""
	@echo "╔══════════════════════════════════════════════════════════════════╗"
	@echo "║           EXPO to WORLD Backend - Development Commands           ║"
	@echo "╚══════════════════════════════════════════════════════════════════╝"
	@echo ""
	@echo "Development:"
	@awk 'BEGIN {FS = ":.*##"; printf ""} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST) | grep -E "dev|run|test|lint|fmt"
	@echo ""
	@echo "Build:"
	@awk 'BEGIN {FS = ":.*##"; printf ""} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST) | grep -E "build|clean|docker"
	@echo ""
	@echo "Database:"
	@awk 'BEGIN {FS = ":.*##"; printf ""} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST) | grep -E "migrate|db"
	@echo ""

# ============================================
# Development Commands
# ============================================
dev: dev-deps ## Start all services in development mode
	@echo "Starting all services..."
	@$(MAKE) -j5 run-auth run-catalog run-ebook run-order run-user

dev-deps: ## Install development dependencies
	@echo "Installing development dependencies..."
	@$(GO) install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
	@$(GO) install github.com/air-verse/air@latest
	@$(GO) install github.com/golang-migrate/migrate/v4/cmd/migrate@latest
	@$(GO) install go.uber.org/mock/mockgen@latest
	@echo "✓ Development dependencies installed"

run-auth: ## Run auth service
	@echo "Starting auth-service on :8081..."
	@$(GO) run ./services/auth/cmd/server

run-catalog: ## Run catalog service
	@echo "Starting catalog-service on :8080..."
	@$(GO) run ./services/catalog/cmd/server

run-ebook: ## Run ebook service
	@echo "Starting ebook-service on :8084..."
	@$(GO) run ./services/ebook/cmd/server

run-order: ## Run order service
	@echo "Starting order-service on :8082..."
	@$(GO) run ./services/order/cmd/server

run-user: ## Run user service
	@echo "Starting user-service on :8083..."
	@$(GO) run ./services/user/cmd/server

# ============================================
# Testing Commands
# ============================================
test: ## Run all unit tests
	@echo "Running unit tests..."
	@$(GOTEST) -v -race -coverprofile=coverage.out ./...
	@echo "✓ Tests complete"

test-coverage: test ## Run tests and generate HTML coverage report
	@$(GO) tool cover -html=coverage.out -o coverage.html
	@echo "✓ Coverage report: coverage.html"

test-integration: ## Run integration tests (requires database)
	@echo "Running integration tests..."
	@$(GOTEST) -v -race -tags=integration ./test/integration/...

test-short: ## Run tests without race detection (faster)
	@$(GOTEST) -v -short ./...

# ============================================
# Code Quality
# ============================================
lint: ## Run linter
	@echo "Running linter..."
	@$(GOLINT) run ./...
	@echo "✓ Lint complete"

lint-fix: ## Run linter with auto-fix
	@echo "Running linter with auto-fix..."
	@$(GOLINT) run --fix ./...
	@echo "✓ Lint fix complete"

fmt: ## Format all Go files
	@echo "Formatting code..."
	@$(GOFMT) -s -w .
	@$(GO) mod tidy
	@echo "✓ Format complete"

vet: ## Run go vet
	@echo "Running go vet..."
	@$(GO) vet ./...
	@echo "✓ Vet complete"

check: fmt lint vet test ## Run all checks (format, lint, vet, test)
	@echo "✓ All checks passed"

# ============================================
# Build Commands
# ============================================
build: clean ## Build all services
	@echo "Building all services..."
	@mkdir -p $(BIN_DIR)
	@for svc in $(SERVICES); do \
		echo "  Building $$svc-service..."; \
		CGO_ENABLED=$(CGO_ENABLED) GOOS=$(GOOS) GOARCH=$(GOARCH) \
		$(GOBUILD) $(BUILD_FLAGS) -o $(BIN_DIR)/$$svc-service ./services/$$svc/cmd/server; \
	done
	@echo "✓ Build complete"

build-auth: ## Build auth service only
	@CGO_ENABLED=$(CGO_ENABLED) $(GOBUILD) $(BUILD_FLAGS) -o $(BIN_DIR)/auth-service ./services/auth/cmd/server

build-catalog: ## Build catalog service only
	@CGO_ENABLED=$(CGO_ENABLED) $(GOBUILD) $(BUILD_FLAGS) -o $(BIN_DIR)/catalog-service ./services/catalog/cmd/server

build-ebook: ## Build ebook service only
	@CGO_ENABLED=$(CGO_ENABLED) $(GOBUILD) $(BUILD_FLAGS) -o $(BIN_DIR)/ebook-service ./services/ebook/cmd/server

build-order: ## Build order service only
	@CGO_ENABLED=$(CGO_ENABLED) $(GOBUILD) $(BUILD_FLAGS) -o $(BIN_DIR)/order-service ./services/order/cmd/server

build-user: ## Build user service only
	@CGO_ENABLED=$(CGO_ENABLED) $(GOBUILD) $(BUILD_FLAGS) -o $(BIN_DIR)/user-service ./services/user/cmd/server

build-darwin: ## Build all services for macOS
	@echo "Building for macOS..."
	@mkdir -p $(BIN_DIR)/darwin
	@for svc in $(SERVICES); do \
		CGO_ENABLED=$(CGO_ENABLED) GOOS=darwin GOARCH=arm64 \
		$(GOBUILD) $(BUILD_FLAGS) -o $(BIN_DIR)/darwin/$$svc-service ./services/$$svc/cmd/server; \
	done
	@echo "✓ macOS build complete"

clean: ## Remove build artifacts
	@echo "Cleaning..."
	@rm -rf $(BIN_DIR)
	@rm -f coverage.out coverage.html
	@echo "✓ Clean complete"

# ============================================
# Docker Commands
# ============================================
docker-build: ## Build all Docker images
	@echo "Building Docker images..."
	@for svc in $(SERVICES); do \
		echo "  Building expotoworld-$$svc-service..."; \
		docker build -t expotoworld-$$svc-service:latest \
			-f deployments/docker/Dockerfile.$$svc .; \
	done
	@echo "✓ Docker images built"

docker-build-auth: ## Build auth service Docker image
	@docker build -t expotoworld-auth-service:latest -f deployments/docker/Dockerfile.auth .

docker-build-catalog: ## Build catalog service Docker image
	@docker build -t expotoworld-catalog-service:latest -f deployments/docker/Dockerfile.catalog .

docker-push: ## Push all Docker images to ECR
	@echo "Pushing Docker images to ECR..."
	@for svc in $(SERVICES); do \
		docker push 834076182408.dkr.ecr.eu-central-1.amazonaws.com/expotoworld-$$svc-service:latest; \
	done
	@echo "✓ Docker images pushed"

# ============================================
# Database Migration Commands
# ============================================
migrate-up: ## Apply all pending migrations
	@echo "Applying database migrations..."
	@migrate -path ./migrations -database "$(DATABASE_URL)" up
	@echo "✓ Migrations applied"

migrate-down: ## Rollback last migration
	@echo "Rolling back last migration..."
	@migrate -path ./migrations -database "$(DATABASE_URL)" down 1
	@echo "✓ Migration rolled back"

migrate-status: ## Show migration status
	@migrate -path ./migrations -database "$(DATABASE_URL)" version

migrate-create: ## Create new migration (usage: make migrate-create name=create_users)
	@migrate create -ext sql -dir ./migrations -seq $(name)
	@echo "✓ Migration created: $(name)"

migrate-force: ## Force migration version (usage: make migrate-force version=1)
	@migrate -path ./migrations -database "$(DATABASE_URL)" force $(version)

# ============================================
# Mock Generation
# ============================================
mocks: ## Generate mocks for interfaces
	@echo "Generating mocks..."
	@mockgen -source=pkg/database/interfaces.go -destination=pkg/database/mocks/mock_database.go -package=mocks
	@mockgen -source=pkg/auth/interfaces.go -destination=pkg/auth/mocks/mock_auth.go -package=mocks
	@echo "✓ Mocks generated"

# ============================================
# API Documentation
# ============================================
docs: ## Generate API documentation
	@echo "Generating API documentation..."
	@swag init -g ./cmd/catalog/main.go -o ./api/docs --parseInternal
	@echo "✓ API docs generated"

# ============================================
# Release
# ============================================
release: check build docker-build ## Full release (check, build, docker)
	@echo "✓ Release complete"
