# Expo to World - Development Orchestration Makefile
# This Makefile provides convenient commands to start and manage development services

.PHONY: help dev dev-env dev-backend dev-frontend dev-flutter-ios dev-flutter-android stop

# Default target - show help
help:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  🚀 Expo to World - Development Commands"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "  📦 FULL STACK DEVELOPMENT"
	@echo "    make dev-env          Start backend + frontend (no auto-open browser)"
	@echo ""
	@echo "  🔧 BACKEND SERVICES"
	@echo "    make dev-backend      Start all 5 backend Go services"
	@echo "                          - Auth Service (port 8081)"
	@echo "                          - Order Service (port 8082)"
	@echo "                          - Catalog Service (port 8080)"
	@echo "                          - User Service (port 8083)"
	@echo "                          - Ebook Service (port 8084)"
	@echo ""
	@echo "  🎨 FRONTEND APPLICATIONS"
	@echo "    make dev-frontend     Start admin panel + ebook editor"
	@echo "                          - Admin Panel: http://localhost:3000"
	@echo "                          - Ebook Editor: http://localhost:5173"
	@echo ""
	@echo "  📱 FLUTTER MOBILE APP"
	@echo "    make dev-flutter-ios      Launch Flutter app (iOS simulator)"
	@echo "    make dev-flutter-android  Launch Flutter app (Android emulator)"
	@echo ""
	@echo "  🛑 STOP SERVICES"
	@echo "    make stop             Stop all running development services"
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Start backend + frontend (no auto-open browser)
dev-env:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  🚀 Starting Expo to World Development Environment"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "  🔧 Starting backend services..."
	@echo "  🎨 Starting frontend applications..."
	@echo ""
	@$(MAKE) -j2 dev-backend dev-frontend

# Start all backend services in parallel
dev-backend:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  🔧 Starting Backend Services"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "  ✅ Auth Service      → http://localhost:8081"
	@echo "  ✅ Order Service     → http://localhost:8082"
	@echo "  ✅ Catalog Service   → http://localhost:8080"
	@echo "  ✅ User Service      → http://localhost:8083"
	@echo "  ✅ Ebook Service     → http://localhost:8084"
	@echo ""
	@echo "  💡 Press Ctrl+C to stop all backend services"
	@echo ""
	@cd backend/auth-service && go run cmd/server/main.go & \
	cd backend/user-service && go run cmd/server/main.go & \
	cd backend/catalog-service && go run cmd/server/main.go & \
	cd backend/order-service && go run cmd/server/main.go & \
	cd backend/ebook-service && go run cmd/server/main.go & \
	wait

# Start frontend applications (no auto-open browser, show URLs)
dev-frontend:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  🎨 Starting Frontend Applications"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "  📋 Admin Panel URLs:"
	@echo "     • Local:   http://localhost:3000"
	@echo "     • Network: http://192.168.1.x:3000  (check terminal output)"
	@echo ""
	@echo "  📚 Ebook Editor URLs:"
	@echo "     • Local:   http://localhost:5173"
	@echo "     • Network: http://192.168.1.x:5173  (check terminal output)"
	@echo ""
	@echo "  💡 Copy the URL you want to use from the terminal output below"
	@echo "  💡 Press Ctrl+C to stop all frontend services"
	@echo ""
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@cd admin-panel && BROWSER=none npm start & \
	cd ebook-editor && npm run dev & \
	wait

# Start Flutter app for iOS simulator
dev-flutter-ios:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  📱 Starting Flutter App (iOS Simulator)"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "  🔧 Flavor: dev"
	@echo "  🌐 API Base: http://127.0.0.1:8787"
	@echo ""
	@./scripts/flutter_dev_ios.sh

# Start Flutter app for Android emulator
dev-flutter-android:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  📱 Starting Flutter App (Android Emulator)"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "  🔧 Flavor: dev"
	@echo "  🌐 API Base: http://10.0.2.2:8787"
	@echo ""
	@./scripts/flutter_dev_android.sh

# Stop all running development services
stop:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  🛑 Stopping All Development Services"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "  🔧 Stopping backend services (Go)..."
	@pkill -f "go run cmd/server/main.go" || true
	@echo "  🎨 Stopping frontend services (React/Vite)..."
	@pkill -f "react-scripts start" || true
	@pkill -f "vite" || true
	@echo ""
	@echo "  ✅ All services stopped!"
	@echo ""

