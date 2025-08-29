-- E-Commerce Microservices Database Setup Script
-- Run this script in PostgreSQL to create the required databases

-- Create databases for each microservice
CREATE DATABASE ecommerce_user;
CREATE DATABASE ecommerce_product;
CREATE DATABASE ecommerce_order;

-- Optional: Create a dedicated user for the applications
CREATE USER ecommerce_user WITH ENCRYPTED PASSWORD 'password';

-- Grant privileges to the user
GRANT ALL PRIVILEGES ON DATABASE ecommerce_user TO ecommerce_user;
GRANT ALL PRIVILEGES ON DATABASE ecommerce_product TO ecommerce_user;
GRANT ALL PRIVILEGES ON DATABASE ecommerce_order TO ecommerce_user;

-- Connect to each database and grant schema privileges
\connect ecommerce_user;
GRANT ALL ON SCHEMA public TO ecommerce_user;

\connect ecommerce_product;
GRANT ALL ON SCHEMA public TO ecommerce_user;

\connect ecommerce_order;
GRANT ALL ON SCHEMA public TO ecommerce_user;