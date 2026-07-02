-- Truncate Tables (Bronze)
TRUNCATE TABLE bronze.Pipeline_Log;
TRUNCATE TABLE bronze.Pipeline_Watermarks;
TRUNCATE TABLE bronze.FactInternetSales;
TRUNCATE TABLE bronze.STG_FactInternetSales;
TRUNCATE TABLE bronze.FactResellerSales
TRUNCATE TABLE bronze.STG_FactResellerSales
TRUNCATE TABLE bronze.FactSalesQuota;
TRUNCATE TABLE bronze.STG_FactSalesQuota;
TRUNCATE TABLE bronze.DimCustomer;
TRUNCATE TABLE bronze.STG_DimCustomer;
TRUNCATE TABLE bronze.DimReseller;
TRUNCATE TABLE bronze.STG_DimReseller;
TRUNCATE TABLE bronze.DimGeography;
TRUNCATE TABLE bronze.STG_DimGeography;
TRUNCATE TABLE bronze.DimSalesTerritory;
TRUNCATE TABLE bronze.STG_DimSalesTerritory;
TRUNCATE TABLE bronze.DimProduct;
TRUNCATE TABLE bronze.STG_DimProduct;
TRUNCATE TABLE bronze.DimProductSubcategory;
TRUNCATE TABLE bronze.STG_DimProductSubcategory;
TRUNCATE TABLE bronze.DimProductCategory;
TRUNCATE TABLE bronze.STG_DimProductCategory;
TRUNCATE TABLE bronze.DimEmployee;
TRUNCATE TABLE bronze.STG_DimEmployee;
TRUNCATE TABLE bronze.DimDate
TRUNCATE TABLE bronze.STG_DimDate

-- Silver Tables
TRUNCATE TABLE silver.FactInternetSales;
TRUNCATE TABLE silver.FactResellerSales
TRUNCATE TABLE silver.FactSalesQuota;
TRUNCATE TABLE silver.DimCustomer;
TRUNCATE TABLE silver.DimReseller;
TRUNCATE TABLE silver.DimGeography;
TRUNCATE TABLE silver.DimSalesTerritory;
TRUNCATE TABLE silver.DimProduct;
TRUNCATE TABLE silver.DimProductSubcategory;
TRUNCATE TABLE silver.DimProductCategory;
TRUNCATE TABLE silver.DimEmployee;
TRUNCATE TABLE silver.DimDate

-- Stored Procedures
EXEC bronze.load_bronze
EXEC bronze.load_bronze_incremental
EXEC silver.load_silver_dimensions
EXEC silver.load_silver_facts_incremental

SELECT * FROM bronze.Pipeline_Log
SELECT * FROM bronze.Pipeline_Watermarks

SELECT * FROM silver.DimCustomer







