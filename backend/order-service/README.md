# Order Service

The Order Service is a Go-based microservice that provides cart and order management functionality for the Made in World application. It handles mini-app specific cart isolation and order processing with JWT authentication.

## Features

- **Mini-App Isolated Carts**: Separate cart management for each mini-app (无人商店, 展销展消, 零售商店, 团购团批)
- **JWT Authentication**: All endpoints require valid JWT tokens
- **Stock Verification**: Real-time stock checking with display buffer (DB - 5)
- **Order Management**: Create and retrieve orders with proper mini-app filtering
- **Store Validation**: Location-based mini-apps require valid store selection
- **Health Checks**: Service health monitoring endpoint

## API Endpoints

### Cart Management
- `GET /api/cart/{mini_app_type}` - Get user's cart for specific mini-app
- `POST /api/cart/{mini_app_type}/add` - Add product to mini-app cart
- `PUT /api/cart/{mini_app_type}/update` - Update cart item quantity
- `DELETE /api/cart/{mini_app_type}/remove/{product_id}` - Remove item from cart

### Order Management
- `POST /api/orders/{mini_app_type}` - Create order from cart
- `GET /api/orders/{mini_app_type}` - Get user's orders for mini-app
- `GET /api/orders/{order_id}` - Get specific order details

### Health
- `GET /health` - Service health check

## Mini-App Types

- `RetailStore` - 零售商店
- `UnmannedStore` - 无人商店 (requires store_id)
- `ExhibitionSales` - 展销展消 (requires store_id)
- `GroupBuying` - 团购团批

## Authentication

All API endpoints require a valid JWT token in the Authorization header:
```
Authorization: Bearer <jwt_token>
```

## Stock Management

- **Display Stock**: Shows actual stock - 5 buffer
- **Availability**: Products with display stock > 0 can be added to cart
- **Real-time Verification**: Stock checked during cart operations

## Environment Variables

- `ORDER_PORT` - Service port (default: 8082)
- `DB_HOST` - Database host
- `DB_PORT` - Database port
- `DB_USER` - Database user
- `DB_PASSWORD` - Database password
- `DB_NAME` - Database name
- `JWT_SECRET` - JWT signing secret

## Development Setup

### Prerequisites
- Go 1.23 or later
- PostgreSQL database with Made in World schema
- Auth service running (for JWT validation)
- Environment variables configured

### Database Setup

1. **Apply database migrations:**
   ```bash
   # Run the migration to add mini_app_type fields
   psql -h localhost -U madeinworld_admin -d madeinworld_db -f ../../database/migrations/001_add_mini_app_type_to_carts_orders.sql
   ```

2. **Verify tables exist:**
   ```sql
   -- Check that required tables exist with mini_app_type fields
   \d carts
   \d orders
   \d products
   \d users
   ```

### Service Dependencies

1. **Auth Service** (required for JWT validation)
   ```bash
   cd ../auth-service
   go run cmd/server/main.go
   ```

2. **Database** (PostgreSQL with Made in World schema)
   - Host: localhost:5432 (default)
   - Database: madeinworld_db
   - User: madeinworld_admin

### Running the Service

1. **Configure environment:**
   ```bash
   cp .env.example .env
   # Edit .env with your database credentials and JWT secret
   ```

2. **Start the service:**
   ```bash
   go mod tidy
   go run cmd/server/main.go
   ```

3. **Verify startup:**
   ```bash
   curl http://localhost:8082/health
   ```

### Testing the API

1. **Get JWT token from auth service:**
   ```bash
   JWT_TOKEN=$(curl -s -X POST \
     -H "Content-Type: application/json" \
     -d '{"email":"test@example.com","password":"password"}' \
     http://localhost:8081/api/auth/login | jq -r '.token')
   ```

2. **Test cart operations:**
   ```bash
   # Get empty cart
   curl -H "Authorization: Bearer $JWT_TOKEN" \
     http://localhost:8082/api/cart/RetailStore

   # Add item to cart
   curl -X POST -H "Authorization: Bearer $JWT_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"product_id": 1, "quantity": 2}' \
     http://localhost:8082/api/cart/RetailStore/add

   # Add item to location-based mini-app (requires store_id)
   curl -X POST -H "Authorization: Bearer $JWT_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"product_id": 1, "quantity": 2, "store_id": 1}' \
     http://localhost:8082/api/cart/UnmannedStore/add
   ```

3. **Test order operations:**
   ```bash
   # Create order from cart
   curl -X POST -H "Authorization: Bearer $JWT_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{}' \
     http://localhost:8082/api/orders/RetailStore

   # Get user orders
   curl -H "Authorization: Bearer $JWT_TOKEN" \
     http://localhost:8082/api/orders/RetailStore
   ```

4. **Run comprehensive tests:**
   ```bash
   ./test_endpoints.sh
   ```
