/* ==========================================================================
   DIAGNOSTIC TEST: FORCE AND VERIFY HASH CHANGES IN THE SAME SESSION
   ========================================================================== */

-- ==========================================================================
-- DimCustomer
-- ==========================================================================

-- 1. Explicitly change the source email right here to make sure we hit the correct table
UPDATE dbo.DimCustomer 
SET EmailAddress = 'jon24@adventure-works.com' 
WHERE CustomerKey = 11000;

-- 2. Manually execute Step B to see what hash it generates from the current live table
SELECT 
    CustomerKey, 
    EmailAddress,
    HASHBYTES('SHA2_256',
        ISNULL(CAST(CustomerKey AS NVARCHAR(50)), '') + '|' +
        ISNULL(CAST(GeographyKey AS NVARCHAR(50)), '') + '|' +
        ISNULL(TRIM(CAST(CustomerAlternateKey AS NVARCHAR(50))), '') + '|' +
        ISNULL(TRIM(CAST(FirstName AS NVARCHAR(100))), '') + '|' +
        ISNULL(TRIM(CAST(LastName AS NVARCHAR(100))), '') + '|' +
        ISNULL(TRIM(CAST(EmailAddress AS NVARCHAR(250))), '') + '|' + 
        ISNULL(TRIM(CAST(Phone AS NVARCHAR(50))), '') + '|' +
        ISNULL(TRIM(CAST(AddressLine1 AS NVARCHAR(250))), '')
    ) AS NewGeneratedHash
FROM dbo.DimCustomer
WHERE CustomerKey = 11000;

-- 3. Check what is currently stored in your permanent Bronze table
SELECT CustomerKey, EmailAddress, RowHash 
FROM bronze.DimCustomer 
WHERE CustomerKey = 11000;

-- ===================================================================================
-- DimReseller
-- ==========================================================================

-- 1. Explicitly change the source email right here to make sure we hit the correct table
UPDATE dbo.DimReseller 
SET Phone = '245-555-0173' 
WHERE ResellerAlternateKey = 'AW00000001'

-- 2. Manually execute Step B to see what hash it generates from the current live table
SELECT 
     ResellerAlternateKey,
     Phone, -- original phone 245-555-0173
    HASHBYTES('SHA2_256',
        ISNULL(CAST(ResellerKey AS NVARCHAR(50)), '') + '|' +
        ISNULL(CAST(GeographyKey AS NVARCHAR(50)), '') + '|' +
        ISNULL(TRIM(CAST(ResellerAlternateKey AS NVARCHAR(50))), '') + '|' +
        ISNULL(TRIM(CAST(Phone AS NVARCHAR(50))), '') + '|' +
        ISNULL(TRIM(CAST(BusinessType AS NVARCHAR(100))), '') + '|' +
        ISNULL(TRIM(CAST(ResellerName AS NVARCHAR(100))), '') + '|' +
        ISNULL(TRIM(CAST(NumberEmployees AS NVARCHAR(250))), '') + '|' + -- High-fidelity text tracking
        ISNULL(TRIM(CAST(OrderFrequency AS NVARCHAR(250))), '')
    ) AS SourceHash
FROM dbo.DimReseller
WHERE ResellerAlternateKey = 'AW00000001'

-- 3. Check what is currently stored in your permanent Bronze table
SELECT ResellerAlternateKey, Phone, RowHash 
FROM bronze.DimReseller
WHERE ResellerAlternateKey = 'AW00000001';

-- ==========================================================================
-- DimGeography
-- ==========================================================================

-- 1. Explicitly change the source City right here to make sure we hit the correct table
UPDATE dbo.DimGeography
SET City = 'New Castle'
WHERE GeographyKey = 1

-- 2. Manually execute Step B to see what hash it generates from the current live table
SELECT 
    GeographyKey, City,
    HASHBYTES('SHA2_256',
        ISNULL(CAST(GeographyKey AS NVARCHAR(50)), '') + '|' +
        ISNULL(TRIM(CAST(City AS NVARCHAR(50))), '') + '|' +
        ISNULL(TRIM(CAST(StateProvinceCode AS NVARCHAR(100))), '') + '|' +
        ISNULL(TRIM(CAST(StateProvinceName AS NVARCHAR(100))), '') + '|' +
        ISNULL(TRIM(CAST(CountryRegionCode AS NVARCHAR(250))), '')
    ) AS SourceHash
FROM dbo.DimGeography
WHERE GeographyKey = '1'

-- 3. Check what is currently stored in your permanent Bronze table
SELECT GeographyKey, City, RowHash 
FROM bronze.DimGeography 
WHERE GeographyKey = '1'

-- ==========================================================================
-- DimSalesTerritory
-- ==========================================================================
-- 1. Explicitly change the source City right here to make sure we hit the correct table

UPDATE dbo.DimSalesTerritory
SET SalesTerritoryCountry = 'Singapore'
WHERE SalesTerritoryKey = 1

-- 2. Manually execute Step B to see what hash it generates from the current live table
SELECT 
    SalesTerritoryKey, SalesTerritoryCountry,
    -- Generate Row Hash 
    HASHBYTES('SHA2_256',
        ISNULL(CAST(SalesTerritoryKey AS NVARCHAR(50)), '') + '|' +
        ISNULL(TRIM(CAST(SalesTerritoryAlternateKey AS NVARCHAR(50))), '') + '|' +
        ISNULL(TRIM(CAST(SalesTerritoryRegion AS NVARCHAR(100))), '') + '|' +
        ISNULL(TRIM(CAST(SalesTerritoryCountry AS NVARCHAR(100))), '') + '|' +
        ISNULL(TRIM(CAST(SalesTerritoryGroup AS NVARCHAR(250))), '') + '|' +
        ISNULL(TRIM(CAST(SalesTerritoryImage AS NVARCHAR(250))), '')
    ) AS SourceHash
FROM dbo.DimSalesTerritory
WHERE SalesTerritoryKey = 1

-- 3. Check what is currently stored in your permanent Bronze table
SELECT SalesTerritoryKey, SalesTerritoryCountry, RowHash 
FROM bronze.DimSalesTerritory
WHERE SalesTerritoryKey = '1'

-- ==========================================================================
-- DimProduct
-- ==========================================================================
-- 1. Explicitly change the source City right here to make sure we hit the correct table

UPDATE dbo.DimProduct
SET EnglishProductName = 'Tight Race'
WHERE ProductKey = 1

-- 2. Manually execute Step B to see what hash it generates from the current live table
SELECT
    ProductKey, EnglishProductName,
        -- Generate Row Hash 
    HASHBYTES('SHA2_256',
        ISNULL(CAST(ProductKey AS NVARCHAR(50)), '') + '|' +
        ISNULL(TRIM(CAST(ProductAlternateKey AS NVARCHAR(50))), '') + '|' +
        ISNULL(TRIM(CAST(ProductSubcategoryKey AS NVARCHAR(100))), '') + '|' +
        ISNULL(TRIM(CAST(WeightUnitMeasureCode AS NVARCHAR(100))), '') + '|' +
        ISNULL(TRIM(CAST(SizeUnitMeasureCode AS NVARCHAR(250))), '') + '|' +
        ISNULL(TRIM(CAST(EnglishProductName AS NVARCHAR(250))), '') + '|' +
        ISNULL(TRIM(CAST(SpanishProductName AS NVARCHAR(250))), '') + '|' +
        ISNULL(TRIM(CAST(FrenchProductName AS NVARCHAR(250))), '') + '|' +
        ISNULL(TRIM(CAST(StandardCost AS NVARCHAR(250))), '') + '|' +
        ISNULL(TRIM(CAST(FinishedGoodsFlag AS NVARCHAR(250))), '') + '|' +
        ISNULL(TRIM(CAST(Color AS NVARCHAR(250))), '') + '|' +
        ISNULL(TRIM(CAST(SafetyStockLevel AS NVARCHAR(250))), '') + '|' +
        ISNULL(TRIM(CAST(ReorderPoint AS NVARCHAR(250))), '') + '|' +
        ISNULL(TRIM(CAST(ListPrice AS NVARCHAR(250))), '') + '|' +
        ISNULL(TRIM(CAST(Size AS NVARCHAR(250))), '') + '|' +
        ISNULL(TRIM(CAST(SizeRange AS NVARCHAR(250))), '') + '|' +
        ISNULL(TRIM(CAST(Weight AS NVARCHAR(250))), '') + '|' +
        ISNULL(TRIM(CAST(DaysToManufacture AS NVARCHAR(250))), '') + '|' +
        ISNULL(TRIM(CAST(ProductLine AS NVARCHAR(250))), '') + '|' +
        ISNULL(TRIM(CAST(DealerPrice AS NVARCHAR(250))), '') + '|' +
        ISNULL(TRIM(CAST(Class AS NVARCHAR(250))), '') + '|' +
        ISNULL(TRIM(CAST(Style AS NVARCHAR(250))), '') + '|' +
        ISNULL(TRIM(CAST(ModelName AS NVARCHAR(250))), '') + '|' +
        ISNULL(TRIM(CAST(LargePhoto AS NVARCHAR(250))), '') + '|' +
        ISNULL(TRIM(CAST(EnglishDescription AS NVARCHAR(250))), '') + '|' +
        ISNULL(TRIM(CAST(FrenchDescription AS NVARCHAR(250))), '') + '|' +
        ISNULL(TRIM(CAST(ChineseDescription AS NVARCHAR(250))), '') + '|' +
        ISNULL(TRIM(CAST(ArabicDescription AS NVARCHAR(250))), '') + '|' +
        ISNULL(TRIM(CAST(HebrewDescription AS NVARCHAR(250))), '') + '|' +
        ISNULL(TRIM(CAST(ThaiDescription AS NVARCHAR(250))), '') + '|' +
        ISNULL(TRIM(CAST(GermanDescription AS NVARCHAR(250))), '') + '|' +
        ISNULL(TRIM(CAST(JapaneseDescription AS NVARCHAR(250))), '') + '|' +
        ISNULL(TRIM(CAST(TurkishDescription AS NVARCHAR(250))), '') + '|' +
        ISNULL(TRIM(CAST(StartDate AS NVARCHAR(250))), '') + '|' +
        ISNULL(TRIM(CAST(EndDate AS NVARCHAR(250))), '') + '|' +
        ISNULL(TRIM(CAST([Status] AS NVARCHAR(250))), '')
    ) AS SourceHash
FROM dbo.DimProduct
WHERE ProductKey = 1

-- 3. Check what is currently stored in your permanent Bronze table
SELECT ProductKey, EnglishProductName, RowHash 
FROM bronze.DimProduct
WHERE ProductKey = '1'

-- ==========================================================================
-- DimProductSubcategory
-- ==========================================================================
-- 1. Explicitly change the source City right here to make sure we hit the correct table
UPDATE dbo.DimProductSubcategory
SET EnglishProductSubcategoryName = 'Trail Bike'
WHERE ProductSubcategoryKey = 1

-- 2. Manually execute Step B to see what hash it generates from the current live table
SELECT 
    ProductSubcategoryKey, EnglishProductSubcategoryName,
    HASHBYTES('SHA2_256',
        ISNULL(CAST(ProductSubcategoryKey AS NVARCHAR(50)), '') + '|' +
        ISNULL(TRIM(CAST(ProductSubcategoryAlternateKey AS NVARCHAR(50))), '') + '|' +
        ISNULL(TRIM(CAST(EnglishProductSubcategoryName AS NVARCHAR(100))), '') + '|' +
        ISNULL(TRIM(CAST(SpanishProductSubcategoryName AS NVARCHAR(100))), '') + '|' +
        ISNULL(TRIM(CAST(FrenchProductSubcategoryName AS NVARCHAR(250))), '') + '|' +
        ISNULL(TRIM(CAST([ProductCategoryKey] AS NVARCHAR(50))), '')
    ) AS SourceHash
FROM dbo.DimProductSubcategory
WHERE ProductSubcategoryKey = 1

-- 3. Check what is currently stored in your permanent Bronze table
SELECT ProductSubcategoryKey, EnglishProductSubcategoryName, RowHash 
FROM bronze.DimProductSubcategory
WHERE ProductSubcategoryKey = '1'

-- ==========================================================================
-- DimProductCategory
-- ==========================================================================
-- 1. Explicitly change the source City right here to make sure we hit the correct table
UPDATE dbo.DimProductCategory
SET EnglishProductCategoryName = 'Mountain Bike'
WHERE ProductCategoryKey = 1

-- 2. Manually execute Step B to see what hash it generates from the current live table
SELECT 
    ProductCategoryKey, EnglishProductCategoryName,
    HASHBYTES('SHA2_256',
        ISNULL(CAST(ProductCategoryKey AS NVARCHAR(50)), '') + '|' +
        ISNULL(TRIM(CAST(ProductCategoryAlternateKey AS NVARCHAR(50))), '') + '|' +
        ISNULL(TRIM(CAST(EnglishProductCategoryName AS NVARCHAR(100))), '') + '|' +
        ISNULL(TRIM(CAST(SpanishProductCategoryName AS NVARCHAR(100))), '') + '|' +
        ISNULL(TRIM(CAST(FrenchProductCategoryName AS NVARCHAR(250))), '') + '|'
    ) AS SourceHash
FROM dbo.DimProductCategory
WHERE ProductCategoryKey = 1

-- 3. Check what is currently stored in your permanent Bronze table
SELECT ProductCategoryKey, EnglishProductCategoryName, RowHash 
FROM bronze.DimProductCategory
WHERE ProductCategoryKey = '1'

-- ==========================================================================
-- DimEmployee
-- ==========================================================================
-- 1. Explicitly change the source City right here to make sure we hit the correct table
UPDATE dbo.DimEmployee
SET Title = 'Field Technician'
WHERE EmployeeKey = 1

-- 2. Manually execute Step B to see what hash it generates from the current live table
SELECT
    EmployeeKey,  Title,
        -- Generate Row Hash 
    HASHBYTES('SHA2_256',
        ISNULL(CAST(EmployeeKey AS NVARCHAR(50)), '') + '|' +
        ISNULL(TRIM(CAST(ParentEmployeeKey AS NVARCHAR(50))), '') + '|' +
        ISNULL(TRIM(CAST(EmployeeNationalIDAlternateKey AS NVARCHAR(100))), '') + '|' +
        ISNULL(TRIM(CAST(ParentEmployeeNationalIDAlternateKey AS NVARCHAR(100))), '') + '|' +
        ISNULL(TRIM(CAST(SalesTerritoryKey AS NVARCHAR(250))), '') + '|' +
        ISNULL(TRIM(CAST(FirstName AS NVARCHAR(50))), '') + '|' +
        ISNULL(TRIM(CAST(LastName AS NVARCHAR(100))), '') + '|' +
        ISNULL(TRIM(CAST(MiddleName AS NVARCHAR(100))), '') + '|' +
        ISNULL(TRIM(CAST(NameStyle AS NVARCHAR(250))), '') + '|' +
        ISNULL(TRIM(CAST(Title AS NVARCHAR(50))), '') + '|' +
        ISNULL(TRIM(CAST(HireDate AS NVARCHAR(100))), '') + '|' +
        ISNULL(TRIM(CAST(BirthDate AS NVARCHAR(100))), '') + '|' +
        ISNULL(TRIM(CAST(LoginID AS NVARCHAR(250))), '') + '|' +
        ISNULL(TRIM(CAST(EmailAddress AS NVARCHAR(50))), '') + '|' +
        ISNULL(TRIM(CAST(Phone AS NVARCHAR(100))), '') + '|' +
        ISNULL(TRIM(CAST(MaritalStatus AS NVARCHAR(100))), '') + '|' +
        ISNULL(TRIM(CAST(EmergencyContactName AS NVARCHAR(250))), '') + '|' +
        ISNULL(TRIM(CAST(EmergencyContactPhone AS NVARCHAR(250))), '') + '|' +
        ISNULL(TRIM(CAST(SalariedFlag AS NVARCHAR(250))), '') + '|' +
        ISNULL(TRIM(CAST(Gender AS NVARCHAR(250))), '') + '|' +
        ISNULL(TRIM(CAST(PayFrequency AS NVARCHAR(250))), '') + '|' +
        ISNULL(TRIM(CAST(BaseRate AS NVARCHAR(250))), '') + '|' +
        ISNULL(TRIM(CAST(VacationHours AS NVARCHAR(250))), '') + '|' +
        ISNULL(TRIM(CAST(SickLeaveHours AS NVARCHAR(250))), '') + '|' +
        ISNULL(TRIM(CAST(CurrentFlag AS NVARCHAR(250))), '') + '|' +
        ISNULL(TRIM(CAST(SalesPersonFlag AS NVARCHAR(250))), '') + '|' +
        ISNULL(TRIM(CAST(DepartmentName AS NVARCHAR(250))), '') + '|' +
        ISNULL(TRIM(CAST(StartDate AS NVARCHAR(250))), '') + '|' +
        ISNULL(TRIM(CAST(EndDate AS NVARCHAR(250))), '') + '|' +
        ISNULL(TRIM(CAST(Status AS NVARCHAR(250))), '') + '|' +
        ISNULL(TRIM(CAST([EmployeePhoto] AS NVARCHAR(50))), '')
    ) AS SourceHash
FROM dbo.DimEmployee
WHERE EmployeeKey = 1


-- 3. Check what is currently stored in your permanent Bronze table
SELECT EmployeeKey, Title, RowHash 
FROM bronze.DimEmployee
WHERE EmployeeKey = 1

DELETE FROM bronze.Pipeline_Watermarks WHERE TableName = 'silver.FactInternetSales';
TRUNCATE TABLE bronze.STG_FactInternetSales;

PRINT '--- SETUP COMPLETE: Watermark table is empty, Staging is empty ---';
SELECT * FROM bronze.Pipeline_Watermarks WHERE TableName = 'silver.FactInternetSales';

/*
===================================================================================
          GRID-BASED DIAGNOSTIC TEST: INCREMENTAL WATERMARK SIMULATION
===================================================================================
*/

-- --------------------------------------------------------------------------------
-- SETUP STEP: Clear old state
-- --------------------------------------------------------------------------------
DELETE FROM bronze.Pipeline_Watermarks WHERE TableName = 'silver.FactInternetSales';
TRUNCATE TABLE bronze.STG_FactInternetSales;

-- Create a temporary tracking table to capture our steps into a grid
IF OBJECT_ID('tempdb..#DiagnosticGrid') IS NOT NULL DROP TABLE #DiagnosticGrid;
CREATE TABLE #DiagnosticGrid (
    StepName VARCHAR(50),
    WatermarkValueUsed VARCHAR(30),
    StagingRowsLoaded INT,
    SavedBookmarkValue VARCHAR(30)
);

-- --------------------------------------------------------------------------------
-- 🚀 TEST RUN 1: The Initial Baseline Load
-- --------------------------------------------------------------------------------
DECLARE @LastWaterMark_Run1 DATETIME;
DECLARE @Rows_Run1 INT;
DECLARE @NewWaterMark_Run1 DATETIME;

-- 1A. Check watermark (It is empty, so grabs MIN date)
SELECT @LastWaterMark_Run1 = ISNULL(
            (SELECT LastLoadedDate FROM bronze.Pipeline_Watermarks WHERE TableName = 'silver.FactInternetSales'),
            (SELECT MIN(OrderDate) FROM bronze.FactInternetSales)
        );

-- 1B. Extract data into staging using strict ">"
INSERT INTO bronze.STG_FactInternetSales 
SELECT * FROM bronze.FactInternetSales WHERE OrderDate > @LastWaterMark_Run1;
SET @Rows_Run1 = @@ROWCOUNT;

-- 1C. Save the new bookmark state (Highest date found in staging)
SELECT @NewWaterMark_Run1 = MAX(OrderDate) FROM bronze.STG_FactInternetSales;

INSERT INTO bronze.Pipeline_Watermarks (TableName, LastLoadedDate)
VALUES ('silver.FactInternetSales', @NewWaterMark_Run1);

-- Record Run 1 results to our grid
INSERT INTO #DiagnosticGrid VALUES (
    'Run 1 (Initial Load)', 
    CAST(@LastWaterMark_Run1 AS VARCHAR), 
    @Rows_Run1, 
    CAST(@NewWaterMark_Run1 AS VARCHAR)
);


-- --------------------------------------------------------------------------------
-- 🔄 TEST RUN 2: The Next-Day Incremental Load
-- --------------------------------------------------------------------------------
DECLARE @LastWaterMark_Run2 DATETIME;
DECLARE @Rows_Run2 INT;
DECLARE @NewWaterMark_Run2 DATETIME;

-- 2A. Check watermark table (Finds our saved bookmarked date from Run 1!)
SELECT @LastWaterMark_Run2 = ISNULL(
            (SELECT LastLoadedDate FROM bronze.Pipeline_Watermarks WHERE TableName = 'silver.FactInternetSales'),
            (SELECT MIN(OrderDate) FROM bronze.FactInternetSales)
        );

-- 2B. Clear staging to simulate a new execution day
TRUNCATE TABLE bronze.STG_FactInternetSales;

-- 2C. Grab new delta rows using strict ">"
INSERT INTO bronze.STG_FactInternetSales 
SELECT * FROM bronze.FactInternetSales WHERE OrderDate > @LastWaterMark_Run2;
SET @Rows_Run2 = @@ROWCOUNT;

SELECT @NewWaterMark_Run2 = ISNULL(MAX(OrderDate), @LastWaterMark_Run2) FROM bronze.STG_FactInternetSales;

-- Record Run 2 results to our grid
INSERT INTO #DiagnosticGrid VALUES (
    'Run 2 (Incremental Pass)', 
    CAST(@LastWaterMark_Run2 AS VARCHAR), 
    @Rows_Run2, 
    CAST(@NewWaterMark_Run2 AS VARCHAR)
);

-- --------------------------------------------------------------------------------
-- 🔍 SHOW DIAGNOSTIC RESULTS GRID
-- --------------------------------------------------------------------------------
SELECT * FROM tempdb..#DiagnosticGrid;


/*
===================================================================================
              DIAGNOSTIC TEST: SILVER LAYER INCREMENTAL PROCESSING
===================================================================================
Focus: Understanding how Silver uses the watermark and deduplicates data.
*/

-- --------------------------------------------------------------------------------
-- SETUP STEP: Reset the tables so we have a clean test environment
-- --------------------------------------------------------------------------------
DELETE FROM bronze.Pipeline_Watermarks WHERE TableName = 'silver.FactInternetSales';
TRUNCATE TABLE bronze.STG_FactInternetSales;
TRUNCATE TABLE silver.FactInternetSales;

PRINT '--- SETUP COMPLETE: Watermark, Bronze STG, and Silver Target are all empty ---';

-- --------------------------------------------------------------------------------
-- 🚀 SILVER TEST RUN 1: Full Historical Load
-- --------------------------------------------------------------------------------
PRINT '==================================================================';
PRINT 'STEP 1: Executing Silver Run 1 (Initial Load)';
PRINT '==================================================================';

DECLARE @SilverWaterMark_Run1 DATETIME;

-- 1A. Calculate Watermark (Will be NULL, so it falls back to MIN date)
SELECT @SilverWaterMark_Run1 = ISNULL(
            (SELECT LastLoadedDate FROM bronze.Pipeline_Watermarks WHERE TableName = 'silver.FactInternetSales'),
            (SELECT MIN(OrderDate) FROM bronze.FactInternetSales)
        );

PRINT 'Diagnostic -> Silver Run 1 @LastWaterMark fallback to MIN: ' + CAST(@SilverWaterMark_Run1 AS VARCHAR);

-- 1B. Simulate Bronze Ingestion (Loading all history into staging)
INSERT INTO bronze.STG_FactInternetSales 
SELECT * FROM bronze.FactInternetSales WHERE OrderDate >= @SilverWaterMark_Run1;

PRINT 'Diagnostic -> Rows loaded into Bronze STG: ' + CAST(@@ROWCOUNT AS VARCHAR);

-- 1C. Silver Transformation & Insert (Using >= to catch everything from the baseline)
INSERT INTO silver.FactInternetSales (
    SalesOrderNumber, SalesOrderLineNumber, OrderQuantity, UnitPrice, SalesAmount, OrderDate, DWHCreateDate
)
SELECT 
    SalesOrderNumber, 
    SalesOrderLineNumber, 
    OrderQuantity,
    CASE WHEN UnitPrice IS NULL OR UnitPrice <= 0 THEN SalesAmount / NULLIF(OrderQuantity,0) ELSE UnitPrice END,
    SalesAmount,
    OrderDate,
    GETDATE()
FROM bronze.STG_FactInternetSales stg
WHERE NOT EXISTS (
    SELECT 1 FROM silver.FactInternetSales s  
    WHERE s.SalesOrderNumber = stg.SalesOrderNumber
    AND   s.SalesOrderLineNumber = stg.SalesOrderLineNumber
);

PRINT 'Diagnostic -> Rows safely appended to SILVER table: ' + CAST(@@ROWCOUNT AS VARCHAR);

-- 1D. Save the watermark checkpoint state
DECLARE @NewWaterMark_Run1 DATETIME;
SELECT @NewWaterMark_Run1 = MAX(OrderDate) FROM bronze.STG_FactInternetSales;

INSERT INTO bronze.Pipeline_Watermarks (TableName, LastLoadedDate)
VALUES ('silver.FactInternetSales', @NewWaterMark_Run1);

PRINT 'Diagnostic -> Saved current MAX date bookmark: ' + CAST(@NewWaterMark_Run1 AS VARCHAR);
PRINT '';


-- --------------------------------------------------------------------------------
-- 🔄 SILVER TEST RUN 2: Simulating the Next Ingestion & Deduplication Check
-- --------------------------------------------------------------------------------
PRINT '==================================================================';
PRINT 'STEP 2: Executing Silver Run 2 (Subsequent Incremental Load)';
PRINT '==================================================================';

DECLARE @SilverWaterMark_Run2 DATETIME;

-- 2A. Read the saved watermark (This time it will return our saved bookmark!)
SELECT @SilverWaterMark_Run2 = ISNULL(
            (SELECT LastLoadedDate FROM bronze.Pipeline_Watermarks WHERE TableName = 'silver.FactInternetSales'),
            (SELECT MIN(OrderDate) FROM bronze.FactInternetSales)
        );

PRINT 'Diagnostic -> Silver Run 2 read @LastWaterMark as: ' + CAST(@SilverWaterMark_Run2 AS VARCHAR);

-- 2B. Clear Staging for the new load pass
TRUNCATE TABLE bronze.STG_FactInternetSales;

-- 2C. Simulate Bronze Ingestion for Run 2 using `>=` to match your Silver processing logic.
-- Note: Because we use >=, it will pull any records from that exact final day boundary into staging again.
INSERT INTO bronze.STG_FactInternetSales 
SELECT * FROM bronze.FactInternetSales WHERE OrderDate >= @SilverWaterMark_Run2;

PRINT 'Diagnostic -> Rows brought into Bronze STG for Run 2: ' + CAST(@@ROWCOUNT AS VARCHAR);

-- 2D. Silver Transformation Pass with `WHERE NOT EXISTS` deduplication active
INSERT INTO silver.FactInternetSales (
    SalesOrderNumber, SalesOrderLineNumber, OrderQuantity, UnitPrice, SalesAmount, OrderDate, DWHCreateDate
)
SELECT 
    SalesOrderNumber, 
    SalesOrderLineNumber, 
    OrderQuantity,
    CASE WHEN UnitPrice IS NULL OR UnitPrice <= 0 THEN SalesAmount / NULLIF(OrderQuantity,0) ELSE UnitPrice END,
    SalesAmount,
    OrderDate,
    GETDATE()
FROM bronze.STG_FactInternetSales stg
WHERE NOT EXISTS (
    SELECT 1 FROM silver.FactInternetSales s  
    WHERE s.SalesOrderNumber = stg.SalesOrderNumber
    AND   s.SalesOrderLineNumber = stg.SalesOrderLineNumber
);

PRINT 'Diagnostic -> Rows actually written to SILVER on Run 2: ' + CAST(@@ROWCOUNT AS VARCHAR);
PRINT '==================================================================';
