/*
============================================================================================
Create Database and Schemas
============================================================================================
Script Purpose:
    This script creates a  new database named: 'AW_DataWarehous' after checking if it already exists.
    If the database exists, it is dropped and recreated. Additionally, the script sets up three schemas
    within the database: 'bronze', 'silver', 'gold'.

WARNING:
    Running this script will drop the entire 'AW_DataWarehouse'  database if it exists.
    All data in the database  will be permanently deleted. Proceed with caution  and ensure
    you have proper backups  before running this script.
*/

USE master;
GO

-- Drop and recreate the 'AW_DataWarehouse' database
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'AW_DataWarehouse')
BEGIN
    ALTER DATABASE AW_DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE AW_DataWarehouse;
END;

-- Create the ''AW_DataWarehouse' database
CREATE DATABASE AW_DataWarehouse;
GO

USE AW_DataWarehouse;
GO

-- Create Schemas
CREATE SCHEMA bronze;
GO

CREATE SCHEMA silver;
GO

CREATE SCHEMA gold;
GO





