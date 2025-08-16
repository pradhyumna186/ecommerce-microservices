# E-commerce Microservices Architecture

A comprehensive e-commerce platform built using Spring Boot microservices architecture with modern cloud-native technologies.

## 🏗️ Architecture Overview

This project implements a microservices-based e-commerce platform with the following components:

### Infrastructure Services
- **Service Discovery** - Eureka server for service registration and discovery
- **Config Server** - Centralized configuration management
- **API Gateway** - Single entry point for all client requests

### Business Services
- **User Service** - User management, authentication, and authorization
- **Product Service** - Product catalog and inventory management
- **Order Service** - Order processing and management

### Common Module
- Shared utilities, DTOs, and common configurations

## 🚀 Technology Stack

- **Framework**: Spring Boot 3.x
- **Build Tool**: Maven
- **Service Discovery**: Netflix Eureka
- **Configuration**: Spring Cloud Config
- **API Gateway**: Spring Cloud Gateway
- **Database**: PostgreSQL, MongoDB
- **Containerization**: Docker
- **Language**: Java 17+

## 📁 Project Structure

```
ecommerce-microservices/
├── common/                    # Shared utilities and DTOs
├── infrastructure/           # Infrastructure services
│   ├── api-gateway/         # API Gateway service
│   ├── config-server/       # Configuration server
│   └── service-discovery/   # Eureka discovery server
├── services/                 # Business logic services
│   ├── user-service/        # User management service
│   ├── product-service/     # Product catalog service
│   └── order-service/       # Order processing service
└── pom.xml                  # Parent POM file
```

## 🛠️ Prerequisites

- Java 17 or higher
- Maven 3.6+
- Docker and Docker Compose
- Git

## 🚀 Getting Started

### 1. Clone the Repository
```bash
git clone <your-repo-url>
cd ecommerce-microservices
```

### 2. Start Infrastructure Services
```bash
# Start databases using Docker
docker-compose up -d postgres mongo

# Start infrastructure services
cd infrastructure/service-discovery
mvn spring-boot:run

cd ../config-server
mvn spring-boot:run

cd ../api-gateway
mvn spring-boot:run
```

### 3. Start Business Services
```bash
# Start business services in separate terminals
cd services/user-service
mvn spring-boot:run

cd ../product-service
mvn spring-boot:run

cd ../order-service
mvn spring-boot:run
```

## 🔧 Configuration

Each service has its own `application.properties` file. Key configurations include:

- **Service Discovery**: `http://localhost:8761`
- **Config Server**: `http://localhost:8888`
- **API Gateway**: `http://localhost:8080`

## 📊 API Endpoints

### User Service
- `POST /api/users` - Create user
- `GET /api/users/{id}` - Get user by ID
- `PUT /api/users/{id}` - Update user
- `DELETE /api/users/{id}` - Delete user

### Product Service
- `GET /api/products` - Get all products
- `GET /api/products/{id}` - Get product by ID
- `POST /api/products` - Create product
- `PUT /api/products/{id}` - Update product
- `DELETE /api/products/{id}` - Delete product

### Order Service
- `POST /api/orders` - Create order
- `GET /api/orders/{id}` - Get order by ID
- `GET /api/orders/user/{userId}` - Get orders by user
- `PUT /api/orders/{id}/status` - Update order status

## 🐳 Docker Support

The project includes Docker configurations for easy deployment:

```bash
# Build all services
mvn clean package -DskipTests

# Run with Docker Compose
docker-compose up -d
```

## 🧪 Testing

Run tests for all services:

```bash
# Run all tests
mvn test

# Run tests for specific service
cd services/user-service
mvn test
```

## 📝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Support

For support and questions, please open an issue in the GitHub repository.

## 🔮 Roadmap

- [ ] Add authentication and authorization
- [ ] Implement payment service
- [ ] Add notification service
- [ ] Implement event sourcing
- [ ] Add monitoring and logging
- [ ] Implement CI/CD pipeline
- [ ] Add comprehensive testing
- [ ] Implement caching layer
- [ ] Add rate limiting
- [ ] Implement circuit breaker pattern
