-- Initialize databases for microservices
CREATE DATABASE IF NOT EXISTS ecommerce;

-- Note: Individual services will create their tables via JPA/Hibernate
-- This script ensures the database exists when containers start