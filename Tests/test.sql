EXEC bronze.load_bronze_incremental

SELECT * FROM bronze.Pipeline_Log 
WHERE Status = 'FAILED' 
ORDER BY EndTime DESC;

SELECT * FROM bronze.Pipeline_Log
SELECT * FROM bronze.Pipeline_Watermarks


SELECT OBJECT_DEFINITION(OBJECT_ID('bronze.load_bronze_incremental')); -- Check if your stored precedure is sync with your database

-- Truncate Tables
TRUNCATE TABLE bronze.STG_FactInternetSales;
TRUNCATE TABLE bronze.FactInternetSales;
TRUNCATE TABLE bronze.STG_FactResellerSales
TRUNCATE TABLE bronze.FactResellerSales
TRUNCATE TABLE bronze.STG_FactSalesQuota;
TRUNCATE TABLE bronze.FactSalesQuota;
TRUNCATE TABLE bronze.STG_DimCustomer;
TRUNCATE TABLE bronze.DimCustomer;
TRUNCATE TABLE bronze.STG_DimReseller;
TRUNCATE TABLE bronze.DimReseller;
TRUNCATE TABLE bronze.STG_DimGeography;
TRUNCATE TABLE bronze.DimGeography;
TRUNCATE TABLE bronze.STG_DimSalesTerritory;
TRUNCATE TABLE bronze.DimSalesTerritory;
TRUNCATE TABLE bronze.STG_DimProduct;
TRUNCATE TABLE bronze.DimProduct;
TRUNCATE TABLE bronze.STG_DimProductSubcategory;
TRUNCATE TABLE bronze.DimProductSubcategory;
TRUNCATE TABLE bronze.STG_DimProductCategory;
TRUNCATE TABLE bronze.DimProductCategory;
TRUNCATE TABLE bronze.STG_DimEmployee;
TRUNCATE TABLE bronze.DimEmployee;
TRUNCATE TABLE bronze.STG_DimDate
TRUNCATE TABLE bronze.DimDate
TRUNCATE TABLE bronze.Pipeline_Log
TRUNCATE TABLE bronze.Pipeline_Watermarks









 


