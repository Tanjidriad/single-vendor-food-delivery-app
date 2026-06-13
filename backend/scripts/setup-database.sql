-- Run as PostgreSQL superuser (postgres) in pgAdmin or psql
CREATE USER food_delivery WITH PASSWORD 'food_delivery';
CREATE DATABASE food_delivery OWNER food_delivery;
GRANT ALL PRIVILEGES ON DATABASE food_delivery TO food_delivery;
\c food_delivery
GRANT ALL ON SCHEMA public TO food_delivery;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO food_delivery;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO food_delivery;
