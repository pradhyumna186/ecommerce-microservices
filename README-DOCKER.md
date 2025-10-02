# E-commerce Microservices - Docker Deployment

## Prerequisites

- Docker Desktop installed
- Docker Compose v3.8+
- 8GB+ RAM recommended

## Quick Start

1. **Build and run all services:**
   ```bash
   ./build-docker.sh
   docker-compose up -d
   ```

2. **Check service health:**
   ```bash
   docker-compose ps
   ```

3. **View logs:**
   ```bash
   # All services
   docker-compose logs -f
   
   # Specific service
   docker-compose logs -f user-service
   ```

## Environment Variables

All configuration is managed in `.env` file:

- **Database**: PostgreSQL credentials and connection
- **Services**: Eureka, Config Server URLs
- **Security**: JWT secret and expiration
- **Performance**: JVM memory settings

## Service Endpoints

Once running, access services via:

- **API Gateway**: http://localhost:8080
- **Eureka Dashboard**: http://localhost:8761
- **Config Server**: http://localhost:8888
- **Direct Service Access**:
  - User Service: http://localhost:8081
  - Product Service: http://localhost:8082
  - Order Service: http://localhost:8083

## Service Startup Order

Docker Compose handles startup dependencies:

1. PostgreSQL Database
2. Service Discovery (Eureka)
3. Config Server
4. API Gateway
5. Business Services (User, Product, Order)

## Management Commands

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# Rebuild and restart
docker-compose down && docker-compose build && docker-compose up -d

# View resource usage
docker stats

# Clean up volumes (removes data)
docker-compose down -v
```

## Health Checks

All services include health checks:
- HTTP health endpoints
- Database connectivity validation
- Service discovery registration verification

## Scaling Services

Scale individual services:
```bash
docker-compose up -d --scale user-service=3
docker-compose up -d --scale product-service=2
```

## Troubleshooting

1. **Services not starting**: Check logs with `docker-compose logs [service]`
2. **Database connection issues**: Verify PostgreSQL container is healthy
3. **Service discovery problems**: Ensure Eureka is running and accessible
4. **Port conflicts**: Modify ports in docker-compose.yml if needed