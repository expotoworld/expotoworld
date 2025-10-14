# Catalog Service

The Catalog Service is a Go-based microservice that provides product catalog functionality for the Made in World application. It serves as the backend API for product, category, and store data.

## Features

- **Product Management**: Retrieve products with filtering by store type and featured status
- **Category Management**: Get product categories with store type associations
- **Store Management**: Access store information and locations
- **Inventory Integration**: Real-time stock quantities for unmanned stores
- **Health Checks**: Service health monitoring endpoint

## API Endpoints

### Products
- `GET /api/v1/products` - Get all products
  - Query parameters:
    - `store_type`: Filter by store type (retail/unmanned)
    - `featured`: Filter featured products (true/false)
    - `store_id`: Get stock for specific store (unmanned only)
- `GET /api/v1/products/:id` - Get specific product by ID

### Categories
- `GET /api/v1/categories` - Get all categories
  - Query parameters:
    - `store_type`: Filter by store type association

### Stores
- `GET /api/v1/stores` - Get all stores
  - Query parameters:
    - `type`: Filter by store type (retail/unmanned)

### Health
- `GET /health` - Service health check

## Project Structure

```
catalog-service/
├── cmd/
│   └── server/
│       └── main.go              # Application entry point
├── internal/
│   ├── api/
│   │   └── handlers.go          # HTTP handlers
│   ├── db/
│   │   └── database.go          # Database connection
│   └── models/
│       └── product.go           # Data models
├── go.mod                       # Go module definition
├── go.sum                       # Go module checksums
├── .env.example                 # Environment variables example
└── README.md                    # This file
```

## Development Setup

### Prerequisites

1. **Go 1.22+** installed
2. **PostgreSQL** database running (or access to RDS instance)
3. **Environment variables** configured

### Local Development

1. **Clone and navigate to the service**:
   ```bash
   cd backend/catalog-service
   ```

2. **Install dependencies**:
   ```bash
   go mod download
   ```

3. **Set up environment variables**:
   ```bash
   cp .env.example .env
   # Edit .env with your database credentials
   ```

4. **Run the service**:
   ```bash
   go run cmd/server/main.go
   ```

The service will start on port 8080 by default.

### Testing the API

```bash
# Health check
curl http://localhost:8080/health

# Get all products
curl http://localhost:8080/api/v1/products

# Get featured products for unmanned stores
curl "http://localhost:8080/api/v1/products?store_type=unmanned&featured=true"

# Get categories for unmanned stores
curl "http://localhost:8080/api/v1/categories?store_type=unmanned"

# Get unmanned stores
curl "http://localhost:8080/api/v1/stores?type=unmanned"
```

## Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `DB_HOST` | Database host | localhost | Yes |
| `DB_PORT` | Database port | 5432 | No |
| `DB_USER` | Database username | madeinworld_admin | Yes |
| `DB_PASSWORD` | Database password | - | Yes |
| `DB_NAME` | Database name | madeinworld_db | Yes |
| `DB_SSLMODE` | SSL mode | prefer | No |
| `PORT` | Server port | 8080 | No |
| `GIN_MODE` | Gin framework mode | release | No |

## Data Models

### Product
```json
{
  "id": 1,
  "sku": "COCA-001",
  "title": "可口可乐 12瓶装",
  "description_short": "经典口味",
  "description_long": "经典可口可乐，12瓶装...",
  "manufacturer_id": 1,
  "store_type": "unmanned",
  "main_price": 9.99,
  "strikethrough_price": 12.50,
  "is_active": true,
  "is_featured": true,
  "image_urls": ["https://placehold.co/300x300/..."],
  "category_ids": ["1"],
  "stock_quantity": 25
}
```

### Category
```json
{
  "id": 1,
  "name": "饮料",
  "store_type_association": "All"
}
```

### Store
```json
{
  "id": 1,
  "name": "Via Nassa 店",
  "city": "卢加诺",
  "address": "Via Nassa 5, 6900 Lugano",
  "latitude": 46.0037,
  "longitude": 8.9511,
  "type": "unmanned",
  "is_active": true
}
```

## Business Logic

### Stock Management
- **Retail stores**: Always show as "in stock" (no inventory tracking)
- **Unmanned stores**: Real inventory with 5-unit buffer
  - Display stock = actual stock - 5
  - Minimum display stock = 0

### Store Type Filtering
- **Products**: Can be filtered by store type (retail/unmanned)
- **Categories**: Associated with specific store types or "All"
- **Stores**: Can be filtered by type for different app sections

### Featured Products
- Products marked as `is_featured = true`
- Used for home screen "热门推荐" section
- Can be combined with store type filtering

## Error Handling

The service implements comprehensive error handling:
- Database connection errors
- Query execution errors
- Invalid request parameters
- Graceful degradation (continues without images/categories if those queries fail)

## Performance Considerations

- **Connection pooling**: Configured with optimal pool settings
- **Query optimization**: Efficient queries with proper indexing
- **Timeout handling**: All database operations have timeouts
- **Graceful shutdown**: Proper cleanup on service termination

## Deployment

This service is designed to be deployed on Kubernetes (EKS). See the deployment manifests in the `kubernetes/` directory for:
- Deployment configuration
- Service configuration
- ConfigMap for environment variables
- Secret for database password

## Monitoring

- Health check endpoint for liveness/readiness probes
- Structured logging for debugging
- Database connection monitoring
- Request/response logging via Gin middleware
