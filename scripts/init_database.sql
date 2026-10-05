/*
===============================================================================
Create Database and Schemas (PostgreSQL)
===============================================================================
What this script does:
    1. Drops the 'datawarehouse' database if it already exists.
    2. Creates a fresh 'datawarehouse' database.
    3. Creates three schemas inside it: bronze, silver and gold.

How to run:
    Run with psql while connected to a different database (e.g. 'postgres'),
    because PostgreSQL cannot drop the database you are connected to:
        psql -U postgres -d postgres -f scripts/init_database.sql

WARNING:
    This deletes the whole 'datawarehouse' database and all its data.
    Make a backup first if you need to keep anything.
===============================================================================
*/

-- Drop the old database (FORCE closes any open connections to it)
DROP DATABASE IF EXISTS datawarehouse WITH (FORCE);

-- Create a new, empty database
CREATE DATABASE datawarehouse;

-- Switch to the new database (psql command)
\c datawarehouse

-- Create one schema per layer
CREATE SCHEMA IF NOT EXISTS bronze;  -- raw data, loaded as-is from CSV files
CREATE SCHEMA IF NOT EXISTS silver;  -- cleaned and standardised data
CREATE SCHEMA IF NOT EXISTS gold;    -- business-ready star schema (views)
