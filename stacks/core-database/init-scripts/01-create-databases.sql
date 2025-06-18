-- BlueLab Stacks Database Initialization
-- Create databases for various services

-- Database for Immich (Photos)
CREATE DATABASE immich;
CREATE USER immich WITH ENCRYPTED PASSWORD 'immich_password_change_me';
GRANT ALL PRIVILEGES ON DATABASE immich TO immich;

-- Database for Nextcloud (Productivity)
CREATE DATABASE nextcloud;
CREATE USER nextcloud WITH ENCRYPTED PASSWORD 'nextcloud_password_change_me';
GRANT ALL PRIVILEGES ON DATABASE nextcloud TO nextcloud;

-- Database for other services that might need PostgreSQL
CREATE DATABASE services;
CREATE USER services WITH ENCRYPTED PASSWORD 'services_password_change_me';
GRANT ALL PRIVILEGES ON DATABASE services TO services;