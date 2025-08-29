# E-Commerce Microservices Setup Guide

## Prerequisites

1. **Java 17** or higher
2. **Maven 3.6+**
3. **PostgreSQL 12+**
4. **Docker** (optional, for containerized deployment)

## Technology Stack

- **Spring Boot:** 3.5.5 (Latest as of August 2025)
- **Spring Cloud:** 2025.0.0 (Northfields Release Train)
- **Java:** 17
- **PostgreSQL Driver:** 42.7.7 (Latest security release)
- **JWT (JJWT):** 0.13.0 (Latest modular version)

## Database Setup

1. Install and start PostgreSQL
2. Run the database setup script:
   ```bash
   psql -U postgres -f database-setup.sql
   ```

## Starting the Services

Start services in the following order:

### 1. Service Discovery (Eureka Server)
```bash
cd infrastructure/service-discovery
./mvnw spring-boot:run
```
Access at: http://localhost:8761

### 2. Config Server
```bash
cd infrastructure/config-server
./mvnw spring-boot:run
```
Access at: http://localhost:8888

### 3. API Gateway
```bash
cd infrastructure/api-gateway
./mvnw spring-boot:run
```
Access at: http://localhost:8080

### 4. Business Services

**User Service:**
```bash
cd services/user-service
./mvnw spring-boot:run
```
Access at: http://localhost:8081

**Product Service:**
```bash
cd services/product-service
./mvnw spring-boot:run
```
Access at: http://localhost:8082

**Order Service:**
```bash
cd services/order-service
./mvnw spring-boot:run
```
Access at: http://localhost:8083

## API Endpoints

All requests go through the API Gateway at `http://localhost:8080`

### Authentication
- `POST /api/auth/login` - User login
- `POST /api/users/register` - User registration

### User Management
- `GET /api/users/{id}` - Get user by ID
- `GET /api/users` - Get all users
- `PUT /api/users/{id}` - Update user

### Product Management
- `GET /api/products` - Get all products (paginated)
- `GET /api/products/{id}` - Get product by ID
- `POST /api/products` - Create product
- `GET /api/categories` - Get all categories
- `POST /api/categories` - Create category

### Order Management
- `POST /api/orders` - Create order
- `GET /api/orders/{id}` - Get order by ID
- `GET /api/orders/user/{userId}` - Get orders by user

## Service Ports

- **API Gateway:** 8080
- **Eureka Server:** 8761
- **Config Server:** 8888
- **User Service:** 8081
- **Product Service:** 8082
- **Order Service:** 8083

## Architecture Features

✅ **Microservices Architecture**
✅ **Service Discovery** (Eureka)
✅ **API Gateway** (Spring Cloud Gateway)
✅ **Configuration Management** (Spring Cloud Config)
✅ **Load Balancing**
✅ **JWT Authentication**
✅ **PostgreSQL Databases**
✅ **RESTful APIs**
✅ **Exception Handling**
✅ **Data Validation**

## Testing the Application

1. Register a new user:
```bash
curl -X POST http://localhost:8080/api/users/register \
  -H "Content-Type: application/json" \
  -d '{
    "firstName": "John",
    "lastName": "Doe",
    "email": "john@example.com",
    "password": "password123",
    "confirmPassword": "password123"
  }'
```

2. Login:
```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john@example.com",
    "password": "password123"
  }'
```

3. Create a category:
```bash
curl -X POST http://localhost:8080/api/categories \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Electronics",
    "description": "Electronic devices and gadgets"
  }'
```

4. Create a product:
```bash
curl -X POST http://localhost:8080/api/products \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Laptop",
    "description": "High-performance laptop",
    "price": 999.99,
    "stockQuantity": 50,
    "categoryId": 1
  }'
```

## Monitoring

- **Eureka Dashboard:** http://localhost:8761
- **Gateway Actuator:** http://localhost:8080/actuator
- **Service Health Checks:** Available through actuator endpoints

## Future Enhancements

- Payment Integration
- Notification Service
- Analytics Service
- Admin Dashboard
- Docker Containerization
- CI/CD Pipeline
- Monitoring with Prometheus/Grafana
- Distributed Tracing