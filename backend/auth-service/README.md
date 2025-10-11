# Auth Service

A standalone Go-based authentication microservice for the Made in World application. This service handles user registration, login, and JWT token management.

## Features

- User registration with email validation
- Secure password hashing using bcrypt
- JWT token generation and validation
- PostgreSQL database integration
- RESTful API endpoints
- Health check endpoint
- Docker containerization
- Kubernetes deployment ready

## API Endpoints

### Authentication Endpoints

#### POST /api/auth/signup
Register a new user account.

**Request Body:**
```json
{
  "username": "string (required, min 3 chars)",
  "email": "string (required, valid email)",
  "password": "string (required, min 8 chars)",
  "phone": "string (optional)",
  "first_name": "string (optional)",
  "last_name": "string (optional)"
}
```

**Success Response (201):**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "uuid",
    "username": "string",
    "email": "string",
    "phone": "string",
    "first_name": "string",
    "last_name": "string",
    "created_at": "2025-07-09T20:00:00Z",
    "updated_at": "2025-07-09T20:00:00Z"
  }
}
```

**Error Responses:**
- `400` - Invalid request data or validation errors
- `409` - Email or username already exists
- `500` - Internal server error

#### POST /api/auth/login
Authenticate user and get JWT token.

**Request Body:**
```json
{
  "email": "string (required)",
  "password": "string (required)"
}
```

**Success Response (200):**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "uuid",
    "username": "string",
    "email": "string",
    "phone": "string",
    "first_name": "string",
    "last_name": "string",
    "created_at": "2025-07-09T20:00:00Z",
    "updated_at": "2025-07-09T20:00:00Z"
  }
}
```

**Error Responses:**
- `400` - Invalid request data
- `401` - Invalid credentials
- `500` - Internal server error

### Protected Endpoints

#### GET /api/protected/profile
Get authenticated user's profile information.

**Headers:**
```
Authorization: Bearer <jwt_token>
```

**Success Response (200):**
```json
{
  "user_id": "uuid",
  "email": "string",
  "message": "Profile retrieved successfully"
}
```

**Error Responses:**
- `401` - Missing or invalid authorization token

### Health Check

#### GET /health
Check service health and database connectivity.

**Success Response (200):**
```json
{
  "status": "healthy",
  "service": "auth-service",
  "timestamp": "2025-07-09T20:00:00Z"
}
```

#### GET /
Get basic service information.

**Success Response (200):**
```json
{
  "service": "auth-service",
  "version": "1.0.0",
  "status": "running"
}
```

## JWT Token Structure

The service generates JWT tokens with the following claims:

```json
{
  "user_id": "uuid",
  "email": "string",
  "exp": 1752178477,
  "iat": 1752092077
}
```

- `user_id`: User's unique identifier
- `email`: User's email address
- `exp`: Token expiration timestamp
- `iat`: Token issued at timestamp

## Environment Variables

### Database Configuration
- `DB_HOST` - Database hostname (default: localhost)
- `DB_PORT` - Database port (default: 5432)
- `DB_USER` - Database username (default: madeinworld_admin)
- `DB_PASSWORD` - Database password
- `DB_NAME` - Database name (default: madeinworld_db)
- `DB_SSLMODE` - SSL mode (default: prefer)

### Service Configuration
- `AUTH_PORT` - Service port (default: 8081)
- `GIN_MODE` - Gin framework mode (debug/release)

### JWT Configuration
- `JWT_SECRET` - Secret key for JWT signing (required for production)
- `JWT_EXPIRATION_HOURS` - Token expiration time in hours (default: 24)

## Database Schema

The service uses the existing `users` table with the following structure:

```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);
```

## Development

### Prerequisites
- Go 1.23 or later
- PostgreSQL database
- Git

### Local Setup

1. Clone the repository and navigate to the auth service:
```bash
cd backend/auth-service
```

2. Install dependencies:
```bash
go mod tidy
```

3. Create a `.env` file:
```bash
cp .env.example .env
# Edit .env with your database credentials
```

4. Run the service:
```bash
go run cmd/server/main.go
```

The service will start on port 8081 by default.

### Testing

Test the endpoints using cURL:

```bash
# Health check
curl http://localhost:8081/health

# Register a user
curl -X POST http://localhost:8081/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "testpassword123",
    "first_name": "Test",
    "last_name": "User"
  }'

# Login
curl -X POST http://localhost:8081/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "testpassword123"
  }'

# Access protected endpoint
curl -X GET http://localhost:8081/api/protected/profile \
  -H "Authorization: Bearer <your_jwt_token>"
```

## Deployment

### Docker

Build the Docker image:
```bash
./build.sh
```

Run with Docker:
```bash
docker run -p 8081:8081 \
  -e DB_HOST=your_db_host \
  -e DB_PASSWORD=your_db_password \
  -e JWT_SECRET=your_jwt_secret \
  auth-service:latest
```

### Kubernetes

See the [Kubernetes README](kubernetes/README.md) for detailed deployment instructions.

## Security Considerations

- Passwords are hashed using bcrypt with appropriate salt rounds
- JWT tokens are signed with HMAC-SHA256
- Service runs as non-root user in containers
- Input validation on all endpoints
- CORS middleware configured
- Database connections use connection pooling

## Integration with Other Services

The auth service is designed to work alongside other microservices:

- **Catalog Service**: Runs on port 8080
- **Auth Service**: Runs on port 8081
- **Shared Database**: Both services use the same PostgreSQL database

For service-to-service authentication, other services can validate JWT tokens using the same JWT secret.

## Monitoring and Logging

- Health check endpoint for monitoring
- Structured logging with request/response details
- Gin framework provides request logging middleware
- Database connection health monitoring

## Contributing

1. Follow the existing code structure and patterns
2. Add tests for new functionality
3. Update documentation for API changes
4. Ensure security best practices are followed
