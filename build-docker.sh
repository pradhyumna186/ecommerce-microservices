#!/bin/bash

echo "Building E-commerce Microservices for Docker..."

# Build all services
echo "Building Maven artifacts..."
mvn clean package -DskipTests

# Build Docker images
echo "Building Docker images..."
docker-compose build

echo "Docker build complete!"
echo ""
echo "To start the services:"
echo "  docker-compose up -d"
echo ""
echo "To view logs:"
echo "  docker-compose logs -f [service-name]"
echo ""
echo "To stop all services:"
echo "  docker-compose down"