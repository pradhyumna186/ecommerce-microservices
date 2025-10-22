-- Initialize databases for microservices (PostgreSQL)
-- This script is executed only on first-time data directory initialization
-- The POSTGRES_DB env var already creates the primary database; keeping this
-- for clarity and idempotent initial setups.

CREATE DATABASE ecommerce;

-- Note: Individual services will create their tables via JPA/Hibernate
-- This script ensures the database exists when containers start