/*
================================================================================
Stored Procedure: bronze.load_bronze_incremental
================================================================================
Script Purpose:
    Performs optimized, end-to-end incremental data ingestion (Delta Loads) 
    for all staging, dimensional, and transaction tables within the Bronze layer.

Architecture Design Pattern:
    1. Transactional Fact Tables: Uses a high-performance Dynamic Watermark pattern 
       relying on source date keys (OrderDate, Date) to ingest only new data.
    2. Dimensional Master Data: Uses Cryptographic Row Hashing (SHA2_256) to perform 
       high-fidelity change tracking, isolating brand new inserts from mid-stream updates.

Actions Performed:
    - Enforces all-or-nothing transaction management (COMMIT / ROLLBACK).
    - Automatically truncates internal transaction staging structures.
    - Captures operational lineage metrics (Rows Affected, Execution Duration, 
      Status) inside the metadata ledger (bronze.Pipeline_Log).

Parameters: 
    None (Designed for scheduled pipeline/agent orchestration).

Usage Example:
    EXEC bronze.load_bronze_incremental;
================================================================================
*/

CREATE OR ALTER PROCEDURE bronze.load_bronze_incremental AS 
    BEGIN
        -- Configure SQL Server environment settings
        SET NOCOUNT ON; -- Prevents extra network overhead from 'X rows affected' messages
        SET XACT_ABORT ON; --  Automatically rolls back the entire transaction if a runtime error occurs

        DECLARE @batch_start_time DATETIME = GETDATE();
        DECLARE @start_time DATETIME, @end_time DATETIME;
        DECLARE @rows_affected INT;
        DECLARE @LastWaterMark DATETIME;
        DECLARE @inserted_rows INT, @updated_rows INT;

        BEGIN TRY
            -- Start an explicit transaction to ensure all-or-nothing data integrity
            BEGIN TRANSACTION;

            PRINT '==================================================================';
            PRINT 'Executing Incremental Load for Fact Tables';
            PRINT '==================================================================';

        /* ==========================================================================
            1. INCREMENTAL LOAD: FactInternetSales
            =========================================================================
        */
            SET @start_time = GETDATE();
            
            -- DYNAMIC WATERMARK LOOKUP: Fallback to MIN(OrderDate) if unseeded
            SELECT @LastWaterMark = ISNULL(
                (SELECT LastLoadedDate FROM bronze.Pipeline_Watermarks WHERE TableName = 'bronze.FactInternetSales'),
                (SELECT MIN(OrderDate) FROM dbo.FactInternetSales)
            );

            -- Empty Staging
            TRUNCATE TABLE bronze.STG_FactInternetSales;

            -- Extract new delta rows into staging using OrderDate
            INSERT INTO bronze.STG_FactInternetSales
            SELECT * FROM dbo.FactInternetSales WHERE OrderDate > @LastWaterMark;

            -- Safe Append: Only insert rows that don't already exist in Bronze (composite key check)
            INSERT INTO bronze.FactInternetSales (
                ProductKey, OrderDateKey, DueDateKey, ShipDateKey, CustomerKey, PromotionKey, CurrencyKey, SalesTerritoryKey, SalesOrderNumber,
                SalesOrderLineNumber, RevisionNumber, OrderQuantity, UnitPrice, ExtendedAmount, UnitPriceDiscountPct, DiscountAmount, ProductStandardCost,
                TotalProductCost, SalesAmount, TaxAmt, Freight, CarrierTrackingNumber, CustomerPONumber, OrderDate, DueDate, ShipDate
            )
            SELECT stg.* FROM bronze.STG_FactInternetSales stg
            WHERE NOT EXISTS (
                SELECT 1 FROM bronze.FactInternetSales b 
                WHERE b.SalesOrderNumber = stg.SalesOrderNumber
                AND b.SalesOrderLineNumber = stg.SalesOrderLineNumber
            );
            
            SELECT @rows_affected = @@ROWCOUNT;

            -- Update Watermark
            UPDATE bronze.Pipeline_Watermarks
            SET LastLoadedDate = (SELECT ISNULL(MAX(OrderDate), @LastWaterMark) FROM bronze.STG_FactInternetSales)
            WHERE TableName = 'bronze.FactInternetSales';

            -- If the table wasn't in the tracking table yet
            IF @@ROWCOUNT = 0
            BEGIN
                INSERT INTO bronze.Pipeline_Watermarks (TableName, LastLoadedDate)
                VALUES ('bronze.FactInternetSales', (SELECT ISNULL(MAX(OrderDate), @LastWaterMark) FROM bronze.STG_FactInternetSales));
            END

            -- Audit Log
            SET @end_time = GETDATE();
            INSERT INTO bronze.Pipeline_Log VALUES ('bronze.FactInternetSales (Incremental)', @start_time, @end_time, DATEDIFF(second, @start_time, @end_time), @rows_affected, 'SUCCESS', NULL);

        /*  ==========================================================================
            2. INCREMENTAL LOAD: FactResellerSales
            =========================================================================
        */   

            SET @start_time = GETDATE();

            -- DYNAMIC WATERMARK LOOKUP: Fallback to MIN(OrderDate) if unseeded
            SELECT @LastWaterMark = ISNULL(
                (SELECT LastLoadedDate FROM bronze.Pipeline_Watermarks WHERE TableName = 'bronze.FactResellerSales'),
                (SELECT MIN(OrderDate) FROM dbo.FactResellerSales)
            )

            -- Empty Staging
            TRUNCATE TABLE bronze.STG_FactResellerSales
            
            -- Extract new delta rows into staging using OrderDate
            INSERT INTO bronze.STG_FactResellerSales
            SELECT * FROM dbo.FactResellerSales WHERE OrderDate > @LastWaterMark;

            INSERT INTO bronze.FactResellerSales (
                ProductKey, OrderDateKey, DueDateKey, ShipDateKey, ResellerKey, EmployeeKey, PromotionKey, CurrencyKey, SalesTerritoryKey,
                SalesOrderNumber, SalesOrderLineNumber, RevisionNumber, OrderQuantity, UnitPrice, ExtendedAmount, UnitPriceDiscountPct,
                DiscountAmount, ProductStandardCost, TotalProductCost, SalesAmount, TaxAmt, Freight, CarrierTrackingNumber, CustomerPONumber,
                OrderDate, DueDate, ShipDate
            ) 
            SELECT stg.* FROM bronze.STG_FactResellerSales stg
            WHERE NOT EXISTS (
                SELECT 1 FROM bronze.FactResellerSales b
                WHERE b.SalesOrderNumber = stg.SalesOrderNumber
                AND b.SalesOrderLineNumber = stg.SalesOrderLineNumber
            );

            SELECT @rows_affected = @@ROWCOUNT;

            UPDATE bronze.Pipeline_Watermarks
            SET LastLoadedDate = (SELECT ISNULL(MAX(OrderDate), @LastWaterMark) FROM bronze.STG_FactResellerSales)
            WHERE TableName = 'bronze.FactResellerSales'

            IF @@ROWCOUNT = 0
            BEGIN
                INSERT INTO bronze.Pipeline_Watermarks (TableName, LastLoadedDate)
                VALUES ('bronze.FactResellerSales', (SELECT ISNULL(MAX(OrderDate), @LastWaterMark) FROM bronze.STG_FactResellerSales));
            END

            -- Audit Log
            SET @end_time = GETDATE();
            INSERT INTO bronze.Pipeline_Log VALUES ('bronze.FactResellerSales (Incremental))', @start_time, @end_time, DATEDIFF(second, @start_time, @end_time), @rows_affected, 'SUCCESS',NULL);

             /* ==========================================================================
                3. INCREMENTAL LOAD: FactSalesQuota
               =========================================================================  */

            SET @start_time = GETDATE();

            -- DYNAMIC WATERMARK LOOKUP: Fallback to MIN(OrderDate) if unseeded
            SELECT @LastWaterMark = ISNULL(
                 (SELECT LastLoadedDate FROM bronze.Pipeline_Watermarks WHERE TableName = 'bronze.FactSalesQuota'),
                 (SELECT MIN(Date) FROM dbo.FactSalesQuota)
            )

            -- Empty Staging
            TRUNCATE TABLE bronze.STG_FactSalesQuota;

            INSERT INTO bronze.STG_FactSalesQuota
            SELECT * FROM dbo.FactSalesQuota WHERE [Date] > @LastWaterMark

            INSERT INTO bronze.FactSalesQuota (SalesQuotaKey,EmployeeKey,DateKey,CalendarYear,CalendarQuarter,SalesAmountQuota,Date)
            
            SELECT stg.* FROM bronze.STG_FactSalesQuota stg 
            WHERE NOT EXISTS (
                SELECT 1 FROM bronze.FactSalesQuota b  
                WHERE b.EmployeeKey = stg.EmployeeKey
                AND b.DateKey = stg.DateKey
            );

            SELECT @rows_affected = @@ROWCOUNT;

            UPDATE bronze.Pipeline_Watermarks
            SET LastLoadedDate = (SELECT ISNULL(MAX(Date), @LastWaterMark) FROM bronze.STG_FactSalesQuota)
            WHERE TableName = 'bronze.FactSalesQuota';

            -- If the table wasn't in the tracking table yet, seed it now
            IF @@ROWCOUNT = 0
            BEGIN
                INSERT INTO bronze.Pipeline_Watermarks (TableName, LastLoadedDate)
                VALUES ('bronze.FactSalesQuota', (SELECT ISNULL(MAX(Date), @LastWaterMark) FROM bronze.STG_FactSalesQuota));
            END

            -- Audit log
            SET @end_time = GETDATE();
            INSERT INTO bronze.Pipeline_Log VALUES ('bronze.FactSalesQuota (Incremental)', @start_time, @end_time, DATEDIFF(second, @start_time, @end_time), @rows_affected, 'SUCCESS', NULL);

            PRINT '==================================================================';
            PRINT 'Executing Incremental Load for Dimension Tables';
            PRINT '==================================================================';

             /* 
             ==========================================================================
               4. INCREMENTAL DIMENSION LOAD: DimCustomer (Hash-Based Upsert)
             =========================================================================
            */

            SET @start_time = GETDATE();

            -- Step A: Empty Staging
            TRUNCATE TABLE bronze.STG_DimCustomer;

            -- Step B: Extract All records from source and generate fresh hashes
            INSERT INTO bronze.STG_DimCustomer (
                CustomerKey, GeographyKey, CustomerAlternateKey, Title, FirstName, MiddleName, 
                LastName, NameStyle, BirthDate, MaritalStatus, Suffix, Gender, EmailAddress,
                YearlyIncome, TotalChildren, NumberChildrenAtHome, EnglishEducation, 
                SpanishEducation, FrenchEducation, EnglishOccupation, SpanishOccupation, FrenchOccupation, 
                HouseOwnerFlag, NumberCarsOwned, AddressLine1, AddressLine2, Phone, DateFirstPurchase, 
                CommuteDistance, SourceHash
            )
            SELECT 
                CustomerKey, GeographyKey, CustomerAlternateKey, Title, FirstName, MiddleName, 
                LastName, NameStyle, BirthDate, MaritalStatus, Suffix, Gender, EmailAddress,
                YearlyIncome, TotalChildren, NumberChildrenAtHome, EnglishEducation, 
                SpanishEducation, FrenchEducation, EnglishOccupation, SpanishOccupation, FrenchOccupation, 
                HouseOwnerFlag, NumberCarsOwned, AddressLine1, AddressLine2, Phone, DateFirstPurchase, CommuteDistance,
                -- Generate Row Hash 
                HASHBYTES('SHA2_256',
                    ISNULL(CAST(CustomerKey AS NVARCHAR(50)), '') + '|' +
                    ISNULL(CAST(GeographyKey AS NVARCHAR(50)), '') + '|' +
                    ISNULL(TRIM(CAST(CustomerAlternateKey AS NVARCHAR(50))), '') + '|' +
                    ISNULL(TRIM(CAST(FirstName AS NVARCHAR(100))), '') + '|' +
                    ISNULL(TRIM(CAST(LastName AS NVARCHAR(100))), '') + '|' +
                    ISNULL(TRIM(CAST(EmailAddress AS NVARCHAR(250))), '') + '|' + -- High-fidelity text tracking
                    ISNULL(TRIM(CAST(Phone AS NVARCHAR(50))), '') + '|' +
                    ISNULL(TRIM(CAST(AddressLine1 AS NVARCHAR(250))), '')
                ) AS SourceHash
            FROM dbo.DimCustomer;
            
            -- Step C: Insert Completely brand new records
            INSERT INTO bronze.DimCustomer (
                CustomerKey, GeographyKey, CustomerAlternateKey, Title, FirstName, MiddleName, 
                LastName, NameStyle, BirthDate, MaritalStatus, Suffix, Gender, EmailAddress,
                YearlyIncome, TotalChildren, NumberChildrenAtHome, EnglishEducation, 
                SpanishEducation, FrenchEducation, EnglishOccupation, SpanishOccupation, FrenchOccupation, 
                HouseOwnerFlag, NumberCarsOwned, AddressLine1, AddressLine2, Phone, DateFirstPurchase, CommuteDistance,
                RowHash     
            )
            SELECT 
                stg.CustomerKey, stg.GeographyKey, stg.CustomerAlternateKey, stg.Title, stg.FirstName, stg.MiddleName, 
                stg.LastName, stg.NameStyle, stg.BirthDate, stg.MaritalStatus, stg.Suffix, stg.Gender, stg.EmailAddress,
                stg.YearlyIncome, stg.TotalChildren, stg.NumberChildrenAtHome, stg.EnglishEducation, 
                stg.SpanishEducation, stg.FrenchEducation, stg.EnglishOccupation, stg.SpanishOccupation, stg.FrenchOccupation, 
                stg.HouseOwnerFlag, stg.NumberCarsOwned, stg.AddressLine1, stg.AddressLine2, stg.Phone, stg.DateFirstPurchase, stg.CommuteDistance,
                stg.SourceHash   
            FROM bronze.STG_DimCustomer stg
            WHERE NOT EXISTS (
                SELECT 1 FROM bronze.DimCustomer b 
                WHERE b.CustomerKey = stg.CustomerKey
            );

            SELECT @inserted_rows =  @@ROWCOUNT;

            -- Step D: Update existing records where data has changed
            UPDATE b
            SET b.GeographyKey = stg.GeographyKey,
                b.CustomerAlternateKey = stg.CustomerAlternateKey,
                b.FirstName = stg.FirstName,
                b.LastName = stg.LastName,
                b.EmailAddress = stg.EmailAddress,
                b.Phone = stg.Phone,
                b.AddressLine1 = stg.AddressLine1,
                b.RowHash = stg.SourceHash -- Save the updated hash for next time
            FROM bronze.DimCustomer b
            INNER JOIN bronze.STG_DimCustomer stg
            ON b.CustomerKey = stg.CustomerKey
            WHERE b.RowHash IS NULL OR  b.RowHash <> stg.SourceHash; -- targets only the modified records

            SELECT @updated_rows = @@ROWCOUNT;

            -- Calculate aggregate metrics
            SET @rows_affected = @inserted_rows + @updated_rows;

            -- Audito Log
            SET @end_time = GETDATE();
            INSERT INTO bronze.Pipeline_Log VALUES ('bronze.DimCustomer (Hash-Incremental)', @start_time, @end_time, DATEDIFF(second, @start_time, @end_time),@rows_affected, 'SUCCESS', NULL);

            /* 
             ==========================================================================
               5. INCREMENTAL DIMENSION LOAD: DimReseller (Hash-Based Upsert)
             =========================================================================
            */

            SET @start_time = GETDATE();

            -- Step A: Empty Staging
            TRUNCATE TABLE bronze.STG_DimReseller;

            -- Step B: Extract All records from source and generate fresh hashes
            INSERT INTO bronze.STG_DimReseller (
                ResellerKey, GeographyKey, ResellerAlternateKey, Phone, BusinessType ,
                ResellerName, NumberEmployees, OrderFrequency, OrderMonth, FirstOrderYear, LastOrderYear,
                ProductLine, AddressLine1, AddressLine2, AnnualSales, BankName,
                MinPaymentType, MinPaymentAmount, AnnualRevenue, YearOpened, SourceHash
            )
            SELECT 
                ResellerKey, GeographyKey, ResellerAlternateKey, Phone, BusinessType,
                ResellerName, NumberEmployees, OrderFrequency, OrderMonth, FirstOrderYear, LastOrderYear,
                ProductLine, AddressLine1, AddressLine2, AnnualSales, BankName,
                MinPaymentType, MinPaymentAmount, AnnualRevenue, YearOpened,
                -- Generate Row Hash 
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

            -- Step C: Insert Completely brand new records
            INSERT INTO bronze.DimReseller (
                ResellerKey, GeographyKey, ResellerAlternateKey, Phone, BusinessType,
                ResellerName, NumberEmployees, OrderFrequency, OrderMonth, FirstOrderYear,
                LastOrderYear, ProductLine, AddressLine1, AddressLine2, AnnualSales,
                BankName, MinPaymentType, MinPaymentAmount, AnnualRevenue, YearOpened, 
                RowHash
            )
            SELECT 
                stg.ResellerKey, stg.GeographyKey, stg.ResellerAlternateKey, stg.Phone, stg.BusinessType ,
                stg.ResellerName, stg.NumberEmployees, stg.OrderFrequency, stg.OrderMonth, stg.FirstOrderYear, stg.LastOrderYear,
                stg.ProductLine, stg.AddressLine1, stg.AddressLine2, stg.AnnualSales, stg.BankName, stg.MinPaymentType, 
                stg.MinPaymentAmount, stg.AnnualRevenue, stg.YearOpened, stg.SourceHash
            FROM bronze.STG_DimReseller stg
            WHERE NOT EXISTS (
                SELECT 1 FROM bronze.DimReseller b
                WHERE b.ResellerKey = stg.ResellerKey
            );

            SELECT @inserted_rows =  @@ROWCOUNT;

            -- Step D: Update existing records where data has changed
            UPDATE b 
            SET    b.GeographyKey = stg.GeographyKey,
                   b.ResellerAlternateKey = stg.ResellerAlternateKey,
                   b.Phone = stg.Phone,
                   b.BusinessType = stg.BusinessType,
                   b.ResellerName = stg.ResellerName,
                   b.NumberEmployees = stg.NumberEmployees,
                   b.OrderFrequency = stg.OrderFrequency,
                   b.RowHash = stg.SourceHash -- Save the updated hash
            FROM bronze.DimReseller b
            INNER JOIN bronze.STG_DimReseller stg 
            ON  b.ResellerKey = stg.ResellerKey
            WHERE b.RowHash IS NULL OR b.RowHash <> stg.SourceHash

            SELECT @updated_rows = @@ROWCOUNT;

            -- Calculate aggregate metrics
            SET @rows_affected = ISNULL(@inserted_rows, 0) + ISNULL(@updated_rows, 0);

            -- Audit Log
            SET @end_time = GETDATE();
            INSERT INTO bronze.Pipeline_Log VALUES ('bronze.DimReseller (Hash-Incremental)', @start_time, @end_time, DATEDIFF(second, @start_time, @end_time),@rows_affected, 'SUCCESS', NULL);

               /* 
             ==========================================================================
               6. INCREMENTAL DIMENSION LOAD: DimGeography (Hash-Based Upsert)
             =========================================================================
            */

            SET @start_time = GETDATE();

            -- Step A: Empty Staging
            TRUNCATE TABLE bronze.STG_DimGeography;

            -- Step B: Extract All records from source and generate fresh hashes
            INSERT INTO bronze.STG_DimGeography (
                GeographyKey, City, StateProvinceCode, StateProvinceName, CountryRegionCode,
                EnglishCountryRegionName, SpanishCountryRegionName, FrenchCountryRegionName,
                PostalCode, SalesTerritoryKey, IpAddressLocator, SourceHash
            )
            SELECT 
                GeographyKey, City, StateProvinceCode, StateProvinceName, CountryRegionCode,
                EnglishCountryRegionName, SpanishCountryRegionName, FrenchCountryRegionName,
                ISNULL(PostalCode, ''), SalesTerritoryKey, ISNULL(IpAddressLocator, ''),
                -- Generate Row Hash 
                HASHBYTES('SHA2_256',
                    ISNULL(CAST(GeographyKey AS NVARCHAR(50)), '') + '|' +
                    ISNULL(TRIM(CAST(City AS NVARCHAR(50))), '') + '|' +
                    ISNULL(TRIM(CAST(StateProvinceCode AS NVARCHAR(100))), '') + '|' +
                    ISNULL(TRIM(CAST(StateProvinceName AS NVARCHAR(100))), '') + '|' +
                    ISNULL(TRIM(CAST(CountryRegionCode AS NVARCHAR(250))), '')
                ) AS SourceHash
            FROM dbo.DimGeography

            -- Step C: Insert Completely brand new records
            INSERT INTO bronze.DimGeography (
                GeographyKey, City, StateProvinceCode, StateProvinceName, CountryRegionCode,
                EnglishCountryRegionName, SpanishCountryRegionName, FrenchCountryRegionName,
                PostalCode, SalesTerritoryKey, IpAddressLocator, RowHash
            )
            SELECT 
                stg.GeographyKey, stg.City, stg.StateProvinceCode, stg.StateProvinceName, stg.CountryRegionCode,
                stg.EnglishCountryRegionName, stg.SpanishCountryRegionName, stg.FrenchCountryRegionName,
                stg.PostalCode, stg.SalesTerritoryKey, stg.IpAddressLocator, stg.SourceHash
            FROM bronze.STG_DimGeography stg
            WHERE NOT EXISTS (
                SELECT 1 FROM bronze.DimGeography b
                WHERE stg.GeographyKey = b.GeographyKey
            )

            SELECT @inserted_rows =  @@ROWCOUNT;

            -- Step D: Update existing records where data has changed
            UPDATE b 
            SET    b.City               = stg.City,
                   b.StateProvinceCode  = stg.StateProvinceCode,
                   b.StateProvinceName  = stg.StateProvinceName,
                   b.CountryRegionCode  = stg.CountryRegioncode,
                   b.RowHash = stg.SourceHash
            FROM bronze.DimGeography b
            INNER JOIN bronze.STG_DimGeography stg ON stg.GeographyKey = b.GeographyKey
            WHERE b.RowHash IS NULL OR b.RowHash <> stg.SourceHash

            SELECT @updated_rows = @@ROWCOUNT;

            -- Calculate aggregate metrics
            -- Dynamic evaluation ensures NULL safety
            SET @rows_affected = ISNULL(@inserted_rows, 0) + ISNULL(@updated_rows, 0);

            -- Audit Log
            SET @end_time = GETDATE();
            INSERT INTO bronze.Pipeline_Log VALUES ('bronze.DimGeography (Hash-Incremental)', @start_time, @end_time, DATEDIFF(second,@start_time, @end_time), @rows_affected, 'SUCCESS', NULL);

            /* 
             ==========================================================================
               7. INCREMENTAL DIMENSION LOAD: DimSalesTerritory (Hash-Based Upsert)
             =========================================================================
            */

            SET @start_time = GETDATE();

            -- Step A: Empty Staging
            TRUNCATE TABLE bronze.STG_DimSalesTerritory;

            -- Step B: Extract All records from source and generate fresh hashes
            INSERT INTO bronze.STG_DimSalesTerritory (
                SalesTerritoryKey, SalesTerritoryAlternateKey, SalesTerritoryRegion,SalesTerritoryCountry,
                SalesTerritoryGroup, SalesTerritoryImage, SourceHash
            )
            SELECT 
                SalesTerritoryKey, SalesTerritoryAlternateKey, SalesTerritoryRegion,SalesTerritoryCountry,
                SalesTerritoryGroup, SalesTerritoryImage,
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

            -- Step C: Insert Completely brand new records
             INSERT INTO bronze.DimSalesTerritory (
                SalesTerritoryKey, SalesTerritoryAlternateKey, SalesTerritoryRegion,SalesTerritoryCountry,
                SalesTerritoryGroup, SalesTerritoryImage, RowHash
             )
             SELECT 
                stg.SalesTerritoryKey, stg.SalesTerritoryAlternateKey, stg.SalesTerritoryRegion,stg.SalesTerritoryCountry,
                stg.SalesTerritoryGroup, stg.SalesTerritoryImage, stg.SourceHash
             FROM bronze.STG_DimSalesTerritory stg
             WHERE NOT EXISTS (
                SELECT 1 FROM bronze.DimSalesTerritory b 
                WHERE b.SalesTerritoryKey = stg.SalesTerritoryKey
             )

             SELECT @inserted_rows =  @@ROWCOUNT;

            -- Step D: Update existing records where data has changed
            UPDATE b
            SET    b.SalesTerritoryAlternateKey = stg.SalesTerritoryAlternateKey,
                   b.SalesTerritoryRegion = stg.SalesTerritoryRegion,
                   b.SalesTerritoryCountry = stg.SalesTerritoryCountry,
                   b.SalesTerritoryGroup = stg.SalesTerritoryGroup,
                   b.SalesTerritoryImage = stg.SalesTerritoryImage,
                   b.RowHash = stg.SourceHash
            FROM bronze.DimSalesTerritory b
            INNER JOIN bronze.STG_DimSalesTerritory stg ON stg.SalesTerritoryKey = b.SalesTerritoryKey
            WHERE b.RowHash IS NULL OR b.RowHash <> stg.SourceHash

            SELECT @updated_rows = @@ROWCOUNT;

            -- Calculate aggregate metrics
            -- Dynamic evaluation ensures NULL safety
            SET @rows_affected = ISNULL(@inserted_rows, 0) + ISNULL(@updated_rows, 0);

            -- Audit Log
            SET @end_time = GETDATE();
            INSERT INTO bronze.Pipeline_Log VALUES ('bronze.DimSalesTerritory (Hash-Incremental)', @start_time, @end_time, DATEDIFF(second, @start_time, @end_time), @rows_affected, 'SUCCESS', NULL);

             /* 
             ==========================================================================
               8. INCREMENTAL DIMENSION LOAD: DimProduct (Hash-Based Upsert)
             =========================================================================
            */

            SET @start_time = GETDATE();

            -- Step A: Empty Staging
            TRUNCATE TABLE bronze.STG_DimProduct;

            -- Step B: Extract All records from source and generate fresh hashes
            INSERT INTO bronze.STG_DimProduct (
                ProductKey, ProductAlternateKey, ProductSubcategoryKey, WeightUnitMeasureCode,
                SizeUnitMeasureCode, EnglishProductName, SpanishProductName, FrenchProductName,
                StandardCost, FinishedGoodsFlag, Color, SafetyStockLevel, ReorderPoint,
                ListPrice, Size, SizeRange, Weight, DaysToManufacture, ProductLine,
                DealerPrice,Class, Style, ModelName, LargePhoto, EnglishDescription,
                FrenchDescription, ChineseDescription, ArabicDescription, HebrewDescription,
                ThaiDescription, GermanDescription, JapaneseDescription,TurkishDescription,
                StartDate, EndDate, Status, SourceHash
            )
            SELECT
                ProductKey, ProductAlternateKey, ProductSubcategoryKey, WeightUnitMeasureCode,
                SizeUnitMeasureCode, EnglishProductName, SpanishProductName, FrenchProductName,
                StandardCost, FinishedGoodsFlag, Color, SafetyStockLevel, ReorderPoint,
                ListPrice, Size, SizeRange, Weight, DaysToManufacture, ProductLine,
                DealerPrice,Class, Style, ModelName, LargePhoto, EnglishDescription,
                FrenchDescription, ChineseDescription, ArabicDescription, HebrewDescription,
                ThaiDescription, GermanDescription, JapaneseDescription,TurkishDescription,
                StartDate, EndDate, Status,
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

            -- Step C: Insert Completely brand new records
            INSERT INTO bronze.DimProduct (
                ProductKey, ProductAlternateKey, ProductSubcategoryKey, WeightUnitMeasureCode,
                SizeUnitMeasureCode, EnglishProductName, SpanishProductName, FrenchProductName,
                StandardCost, FinishedGoodsFlag, Color, SafetyStockLevel, ReorderPoint,
                ListPrice, Size, SizeRange, Weight, DaysToManufacture, ProductLine,
                DealerPrice,Class, Style, ModelName, LargePhoto, EnglishDescription,
                FrenchDescription, ChineseDescription, ArabicDescription, HebrewDescription,
                ThaiDescription, GermanDescription, JapaneseDescription,TurkishDescription,
                StartDate, EndDate, Status, RowHash    
            )
            SELECT 
                stg.ProductKey, stg.ProductAlternateKey, stg.ProductSubcategoryKey, stg.WeightUnitMeasureCode,
                stg.SizeUnitMeasureCode, stg.EnglishProductName, stg.SpanishProductName, stg.FrenchProductName,
                stg.StandardCost, stg.FinishedGoodsFlag, stg.Color, stg.SafetyStockLevel, stg.ReorderPoint,
                stg.ListPrice, stg.Size, stg.SizeRange, stg.Weight, stg.DaysToManufacture, stg.ProductLine,
                stg.DealerPrice, stg.Class, stg.Style, stg.ModelName, stg.LargePhoto, stg.EnglishDescription,
                stg.FrenchDescription, stg.ChineseDescription, stg.ArabicDescription, stg.HebrewDescription,
                stg.ThaiDescription, stg.GermanDescription, stg.JapaneseDescription, stg.TurkishDescription,
                stg.StartDate, stg.EndDate, stg.Status, stg.SourceHash
            FROM bronze.STG_DimProduct stg
            WHERE NOT EXISTS (
                SELECT 1 FROM bronze.DimProduct b
                WHERE b.ProductKey = stg.ProductKey
            )

            SELECT @inserted_rows = @@ROWCOUNT;

            -- Step D: Update existing records where data has changed
            UPDATE  b 
            SET     b.ProductAlternateKey           = stg.ProductAlternateKey,
                    b.ProductSubcategoryKey         = stg.ProductSubcategoryKey,
                    b.WeightUnitMeasureCode         = stg.WeightUnitMeasureCode,
                    b.SizeUnitMeasureCode           = stg.SizeUnitMeasureCode,
                    b.EnglishProductName            = stg.EnglishProductName,
                    b.SpanishProductName            = stg.SpanishProductName,
                    b.FrenchProductName             = stg.FrenchProductName,
                    b.StandardCost                  = stg.StandardCost,
                    b.FinishedGoodsFlag             = stg.FinishedGoodsFlag,
                    b.Color                         = stg.Color,
                    b.SafetyStockLevel              = stg.SafetyStockLevel,
                    b.ReorderPoint                  = stg.ReorderPoint,
                    b.ListPrice                     = stg.ListPrice,
                    b.Size                          = stg.Size,
                    b.SizeRange                     = stg.SizeRange,
                    b.Weight                        = stg.Weight,
                    b.DaysToManufacture             = stg.DaysToManufacture,
                    b.ProductLine                   = stg.ProductLine,
                    b.DealerPrice                   = stg.DealerPrice,
                    b.Class                         = stg.Class,
                    b.Style                         = stg.Style,
                    b.ModelName                     = stg.ModelName,
                    b.LargePhoto                    = stg.LargePhoto,
                    b.EnglishDescription            = stg.EnglishDescription,
                    b.FrenchDescription             = stg.FrenchDescription,
                    b.ChineseDescription            = stg.ChineseDescription,
                    b.ArabicDescription             = stg.ArabicDescription,
                    b.HebrewDescription             = stg.HebrewDescription,
                    b.ThaiDescription               = stg.ThaiDescription,
                    b.GermanDescription             = stg.GermanDescription,
                    b.JapaneseDescription           = stg.JapaneseDescription,
                    b.TurkishDescription            = stg.TurkishDescription,
                    b.StartDate                     = stg.StartDate,
                    b.EndDate                       = stg.EndDate,
                    b.Status                        = stg.Status,
                    b.RowHash                       = stg.SourceHash
            FROM bronze.DimProduct b
            INNER JOIN  bronze.STG_DimProduct stg ON stg.ProductKey = b.Productkey
            WHERE b.RowHash IS NULL OR b.RowHash <> stg.SourceHash

            SELECT @updated_rows = @@ROWCOUNT;

            -- Calculate aggregate metrics
            SET @rows_affected = ISNULL(@inserted_rows, 0) + ISNULL(@updated_rows, 0);

            -- Audit Log for DimProduct
            SET @end_time = GETDATE();
            INSERT INTO bronze.Pipeline_Log VALUES ('bronze.DimProduct (Hash-Incremental)', @start_time, @end_time, DATEDIFF(second, @start_time, @end_time), @rows_affected, 'SUCCESS', NULL);

                  /* 
             ==========================================================================
               9. INCREMENTAL DIMENSION LOAD: DimProductSubcategory (Hash-Based Upsert)
             =========================================================================
            */

            SET @start_time = GETDATE();

            -- Step A: Empty Staging
            TRUNCATE TABLE bronze.STG_DimProductSubcategory;

            -- Step B: Extract All records from source and generate fresh hashes
            INSERT INTO bronze.STG_DimProductSubcategory (
                 ProductSubcategoryKey, ProductSubcategoryAlternateKey, EnglishProductSubcategoryName,
                 SpanishProductSubcategoryName, FrenchProductSubcategoryName, ProductCategoryKey, SourceHash
            ) 
            SELECT 
                ProductSubcategoryKey, ProductSubcategoryAlternateKey, EnglishProductSubcategoryName,
                SpanishProductSubcategoryName, FrenchProductSubcategoryName, ProductCategoryKey,
                 -- Generate Row Hash 
                HASHBYTES('SHA2_256',
                    ISNULL(CAST(ProductSubcategoryKey AS NVARCHAR(50)), '') + '|' +
                    ISNULL(TRIM(CAST(ProductSubcategoryAlternateKey AS NVARCHAR(50))), '') + '|' +
                    ISNULL(TRIM(CAST(EnglishProductSubcategoryName AS NVARCHAR(100))), '') + '|' +
                    ISNULL(TRIM(CAST(SpanishProductSubcategoryName AS NVARCHAR(100))), '') + '|' +
                    ISNULL(TRIM(CAST(FrenchProductSubcategoryName AS NVARCHAR(250))), '') + '|' +
                    ISNULL(TRIM(CAST([ProductCategoryKey] AS NVARCHAR(50))), '')
                ) AS SourceHash
            FROM dbo.DimProductSubcategory

            -- Step C: Insert Completely brand new records
            INSERT INTO bronze.DimProductSubcategory (
                ProductSubcategoryKey, ProductSubcategoryAlternateKey, EnglishProductSubcategoryName,
                SpanishProductSubcategoryName, FrenchProductSubcategoryName, ProductCategoryKey, RowHash
            )
            SELECT 
                stg.ProductSubcategoryKey, stg.ProductSubcategoryAlternateKey, stg.EnglishProductSubcategoryName,
                stg.SpanishProductSubcategoryName, stg.FrenchProductSubcategoryName, stg.ProductCategoryKey, stg.SourceHash
            FROM bronze.STG_DimProductSubcategory stg
            WHERE NOT EXISTS (
                SELECT 1 FROM bronze.DimProductSubcategory b  
                WHERE stg.ProductSubcategoryKey = b.ProductSubcategoryKey
            )

            SELECT @inserted_rows = @@ROWCOUNT

            -- Step D: Update existing records where data has changed
            UPDATE  b 
            SET     b.ProductSubcategoryAlternateKey = stg.ProductSubcategoryAlternateKey,
                    b.EnglishProductSubcategoryName  = stg.EnglishProductSubcategoryName,
                    b.SpanishProductSubcategoryName = stg.SpanishProductSubcategoryName,
                    b.FrenchProductSubcategoryName = stg.FrenchProductSubcategoryName,
                    b.ProductCategoryKey = stg.ProductCategoryKey,
                    b.RowHash = stg.SourceHash
            FROM bronze.DimProductSubcategory b
            INNER JOIN bronze.STG_DimProductSubcategory stg ON stg.ProductSubcategoryKey = b.ProductSubcategoryKey
            WHERE b.RowHash IS NULL OR  b.RowHash <> stg.SourceHash

            SELECT @updated_rows = @@ROWCOUNT;

            -- Calculate aggregate metrics
            -- Dynamic evaluation ensures NULL safety
            SET @rows_affected = ISNULL(@inserted_rows, 0) + ISNULL(@updated_rows, 0);

            -- Audit Log
            SET @end_time = GETDATE();
            INSERT INTO bronze.Pipeline_Log VALUES ('bronze.DimProductSubcategory (Hash-Incremental)', @start_time, @end_time, DATEDIFF(second, @start_time, @end_time), @rows_affected, 'SUCCESS', NULL);

                  /* 
             ==========================================================================
               10. INCREMENTAL DIMENSION LOAD: DimProductCategory (Hash-Based Upsert)
             =========================================================================
            */

            SET @start_time = GETDATE();

            -- Step A: Empty Staging
            TRUNCATE TABLE bronze.STG_DimProductCategory;

            -- Step B: Extract All records from source and generate fresh hashes
            INSERT INTO bronze.STG_DimProductCategory (
                ProductCategoryKey, ProductCategoryAlternateKey, EnglishProductCategoryName,
                SpanishProductCategoryName, FrenchProductCategoryName,SourceHash
            )
            SELECT 
                ProductCategoryKey, ProductCategoryAlternateKey, EnglishProductCategoryName,
                SpanishProductCategoryName, FrenchProductCategoryName,
                 HASHBYTES('SHA2_256',
                    ISNULL(CAST(ProductCategoryKey AS NVARCHAR(50)), '') + '|' +
                    ISNULL(TRIM(CAST(ProductCategoryAlternateKey AS NVARCHAR(50))), '') + '|' +
                    ISNULL(TRIM(CAST(EnglishProductCategoryName AS NVARCHAR(100))), '') + '|' +
                    ISNULL(TRIM(CAST(SpanishProductCategoryName AS NVARCHAR(100))), '') + '|' +
                    ISNULL(TRIM(CAST(FrenchProductCategoryName AS NVARCHAR(250))), '') + '|'
                ) AS SourceHash
            FROM dbo.DimProductCategory

             -- Step C: Insert Completely brand new records
             INSERT INTO bronze.DimProductCategory (
                ProductCategoryKey, ProductCategoryAlternateKey, EnglishProductCategoryName,
                SpanishProductCategoryName, FrenchProductCategoryName,RowHash
             )
             SELECT 
                stg.ProductCategoryKey, stg.ProductCategoryAlternateKey, stg.EnglishProductCategoryName,
                stg.SpanishProductCategoryName, stg.FrenchProductCategoryName,stg.SourceHash
             FROM bronze.STG_DimProductCategory stg
             WHERE NOT EXISTS (
                SELECT 1 FROM bronze.DimProductCategory b  
                WHERE  b.ProductCategoryKey = stg.ProductCategoryKey
             )

             SELECT @inserted_rows = @@ROWCOUNT;

             -- Step D: Update existing records where data has changed
             UPDATE b 
             SET    b.ProductCategoryAlternateKey = stg.ProductCategoryAlternateKey,
                    b.EnglishProductCategoryName = stg.EnglishProductCategoryName,
                    b.SpanishProductCategoryName = stg.SpanishProductCategoryName,
                    b.FrenchProductCategoryName = stg.FrenchProductCategoryName,
                    b.Rowhash = stg.SourceHash
             FROM bronze.DimProductCategory b
             INNER JOIN bronze.STG_DimProductCategory stg  ON stg.ProductCategoryKey = stg.ProductCategoryKey
             WHERE b.RowHash IS NULL OR b.RowHash <> stg.SourceHash 

            SELECT @updated_rows = @@ROWCOUNT;

            -- Calculate aggregate metrics
            SET @rows_affected = ISNULL(@inserted_rows, 0) + ISNULL(@updated_rows, 0);

            -- Audit Log
            SET @end_time = GETDATE();
            INSERT INTO bronze.Pipeline_Log VALUES ('bronze.DimProductCategory (Hash-Incremental)', @start_time, @end_time, DATEDIFF(second, @start_time, @end_time), @rows_affected, 'SUCCESS', NULL);

                  /* 
             ==========================================================================
               11. INCREMENTAL DIMENSION LOAD: DimEmployee (Hash-Based Upsert)
             =========================================================================
            */
            
            SET @start_time = GETDATE();

            -- Step A: Empty Staging
            TRUNCATE TABLE bronze.STG_DimEmployee;

            -- Step B: Extract All records from source and generate fresh hashes
            INSERT INTO bronze.STG_DimEmployee (
                EmployeeKey, ParentEmployeeKey, EmployeeNationalIDAlternateKey, ParentEmployeeNationalIDAlternateKey,
                SalesTerritoryKey, FirstName, LastName, MiddleName, NameStyle, Title, HireDate, BirthDate, 
                LoginID, EmailAddress, Phone, MaritalStatus, EmergencyContactName, EmergencyContactPhone, SalariedFlag, 
                Gender, PayFrequency, BaseRate, VacationHours, SickLeaveHours, CurrentFlag, SalesPersonFlag, DepartmentName,
                StartDate, EndDate, Status, EmployeePhoto, SourceHash
            )
            SELECT
                EmployeeKey, ParentEmployeeKey, EmployeeNationalIDAlternateKey, ParentEmployeeNationalIDAlternateKey,
                SalesTerritoryKey, FirstName, LastName, MiddleName, NameStyle, Title, HireDate, BirthDate, 
                LoginID, EmailAddress, Phone, MaritalStatus, EmergencyContactName, EmergencyContactPhone, SalariedFlag, 
                Gender, PayFrequency, BaseRate, VacationHours, SickLeaveHours, CurrentFlag, SalesPersonFlag, DepartmentName,
                StartDate, EndDate, Status, EmployeePhoto, 
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

             -- Step C: Insert Completely brand new records
             INSERT INTO bronze.DimEmployee (
                EmployeeKey, ParentEmployeeKey, EmployeeNationalIDAlternateKey, ParentEmployeeNationalIDAlternateKey,
                SalesTerritoryKey, FirstName, LastName, MiddleName, NameStyle, Title, HireDate, BirthDate, 
                LoginID, EmailAddress, Phone, MaritalStatus, EmergencyContactName, EmergencyContactPhone, SalariedFlag, 
                Gender, PayFrequency, BaseRate, VacationHours, SickLeaveHours, CurrentFlag, SalesPersonFlag, DepartmentName,
                StartDate, EndDate, Status, EmployeePhoto, RowHash
             )
             SELECT 
                stg.EmployeeKey, stg.ParentEmployeeKey, stg.EmployeeNationalIDAlternateKey, stg.ParentEmployeeNationalIDAlternateKey,
                stg.SalesTerritoryKey, stg.FirstName, stg.LastName, stg.MiddleName, stg.NameStyle, stg.Title, stg.HireDate, stg.BirthDate, 
                stg.LoginID, stg.EmailAddress, stg.Phone, stg.MaritalStatus, stg.EmergencyContactName, stg.EmergencyContactPhone, stg.SalariedFlag, 
                stg.Gender, stg.PayFrequency, stg.BaseRate, stg.VacationHours, stg.SickLeaveHours, stg.CurrentFlag, stg.SalesPersonFlag, stg.DepartmentName,
                stg.StartDate, stg.EndDate, stg.Status, stg.EmployeePhoto, stg.SourceHash
            FROM bronze.STG_DimEmployee stg   
            WHERE NOT EXISTS (
                SELECT 1 FROM bronze.DimEmployee b 
                WHERE b.EmployeeKey = stg.EmployeeKey
            )

            SELECT @inserted_rows = @@ROWCOUNT;

            -- Step D: Update existing records where data has changed
            UPDATE  b  
            SET     b.ParentEmployeeKey                     = stg.ParentEmployeeKey,
                    b.EmployeeNationalIDAlternateKey        = stg.EmployeeNationalIDAlternateKey,
                    b.ParentEmployeeNationalIDAlternateKey  = stg.ParentEmployeeNationalIDAlternateKey,
                    b.SalesTerritoryKey                     = stg.SalesTerritoryKey,
                    b.FirstName                             = stg.FirstName,
                    b.LastName                              = stg.LastName,
                    b.MiddleName                            = stg.MiddleName,
                    b.NameStyle                             = stg.NameStyle,
                    b.Title                                 = stg.Title,
                    b.HireDate                              = stg.HireDate,
                    b.BirthDate                             = stg.BirthDate,
                    b.LoginID                               = stg.LoginID,
                    b.EmailAddress                          = stg.EmailAddress,
                    b.Phone                                 = stg.Phone,
                    b.MaritalStatus                         = stg.MaritalStatus,
                    b.EmergencyContactName                  = stg.EmergencyContactName,
                    b.EmergencyContactPhone                 = stg.EmergencyContactPhone,
                    b.SalariedFlag                          = stg.SalariedFlag,
                    b.Gender                                = stg.Gender,
                    b.PayFrequency                          = stg.PayFrequency,
                    b.BaseRate                              = stg.BaseRate,
                    b.VacationHours                         = stg.VacationHours,
                    b.SickLeaveHours                        = stg.SickLeaveHours,
                    b.CurrentFlag                           = stg.CurrentFlag,
                    b.SalesPersonFlag                       = stg.SalesPersonFlag,
                    b.DepartmentName                        = stg.DepartmentName,
                    b.StartDate                             = stg.StartDate,
                    b.EndDate                               = stg.EndDate,
                    b.Status                                = stg.Status,
                    b.EmployeePhoto                         = stg.EmployeePhoto,
                    b.RowHash                               = stg.SourceHash
            FROM bronze.DimEmployee b
            INNER JOIN bronze.STG_DimEmployee stg ON b.EmployeeKey = stg.EmployeeKey
            WHERE b.RowHash IS NULL OR b.RowHash <> stg.SourceHash

            SELECT @updated_rows = @@ROWCOUNT;

            -- Calculate aggregate metrics
            SET @rows_affected = ISNULL(@inserted_rows, 0) + ISNULL(@updated_rows, 0);

            -- Audit Log
            SET @end_time = GETDATE();
            INSERT INTO bronze.Pipeline_Log VALUES ('bronze.DimEmployee (Hash-Incremental)', @start_time, @end_time, DATEDIFF(second, @start_time, @end_time), @rows_affected, 'SUCCESS', NULL);

            /* 
            ==========================================================================
               12. INCREMENTAL DIMENSION LOAD: DimDate (Hash-Based Upsert)
            =========================================================================
            */

            SET @start_time = GETDATE();

            -- Step A: Empty Staging
            TRUNCATE TABLE bronze.STG_DimDate

            -- Step B: Extract All records from source and generate fresh hashes
            INSERT INTO bronze.STG_DimDate (
                DateKey, FullDateAlternateKey, DayNumberOfWeek, EnglishDayNameOfWeek, SpanishDayNameOfWeek,
                FrenchDayNameOfWeek, DayNumberOfMonth, DayNumberOfYear, WeekNumberOfYear, EnglishMonthName,
                SpanishMonthName, FrenchMonthName, MonthNumberOfYear, CalendarQuarter, CalendarYear, 
                CalendarSemester, FiscalQuarter, FiscalYear, FiscalSemester,
                SourceHash
            )
            SELECT 
                DateKey, FullDateAlternateKey, DayNumberOfWeek, EnglishDayNameOfWeek, SpanishDayNameOfWeek,
                FrenchDayNameOfWeek, DayNumberOfMonth, DayNumberOfYear, WeekNumberOfYear, EnglishMonthName,
                SpanishMonthName, FrenchMonthName, MonthNumberOfYear, CalendarQuarter, CalendarYear, 
                CalendarSemester, FiscalQuarter, FiscalYear, FiscalSemester,
                 -- Generate Row Hash 
                HASHBYTES('SHA2_256',
                    ISNULL(CAST(DateKey AS NVARCHAR(50)), '') + '|' +
                    ISNULL(TRIM(CAST(FullDateAlternateKey AS NVARCHAR(50))), '') + '|' +
                    ISNULL(TRIM(CAST(DayNumberOfWeek AS NVARCHAR(100))), '') + '|' +
                    ISNULL(TRIM(CAST(EnglishDayNameOfWeek AS NVARCHAR(100))), '') + '|' +
                    ISNULL(TRIM(CAST(SpanishDayNameOfWeek AS NVARCHAR(250))), '') + '|' +
                    ISNULL(TRIM(CAST(FrenchDayNameOfWeek AS NVARCHAR(50))), '') + '|' +
                    ISNULL(TRIM(CAST(DayNumberOfMonth AS NVARCHAR(100))), '') + '|' +
                    ISNULL(TRIM(CAST(DayNumberOfYear AS NVARCHAR(100))), '') + '|' +
                    ISNULL(TRIM(CAST(WeekNumberOfYear AS NVARCHAR(250))), '') + '|' +
                    ISNULL(TRIM(CAST(EnglishMonthName AS NVARCHAR(50))), '') + '|' +
                    ISNULL(TRIM(CAST(SpanishMonthName AS NVARCHAR(100))), '') + '|' +
                    ISNULL(TRIM(CAST(FrenchMonthName AS NVARCHAR(100))), '') + '|' +
                    ISNULL(TRIM(CAST(MonthNumberOfYear AS NVARCHAR(250))), '') + '|' +
                    ISNULL(TRIM(CAST(CalendarQuarter AS NVARCHAR(50))), '') + '|' +
                    ISNULL(TRIM(CAST(CalendarYear AS NVARCHAR(100))), '') + '|' +
                    ISNULL(TRIM(CAST(CalendarSemester AS NVARCHAR(100))), '') + '|' +
                    ISNULL(TRIM(CAST(FiscalQuarter AS NVARCHAR(250))), '') + '|' +
                    ISNULL(TRIM(CAST(FiscalYear AS NVARCHAR(250))), '') + '|' +
                    ISNULL(TRIM(CAST([FiscalSemester] AS NVARCHAR(50))), '')
                ) AS SourceHash
            FROM dbo.DimDate

            -- Step C: Insert Completely brand new records
            INSERT INTO bronze.DimDate (
                DateKey, FullDateAlternateKey, DayNumberOfWeek, EnglishDayNameOfWeek, SpanishDayNameOfWeek,
                FrenchDayNameOfWeek, DayNumberOfMonth, DayNumberOfYear, WeekNumberOfYear, EnglishMonthName,
                SpanishMonthName, FrenchMonthName, MonthNumberOfYear, CalendarQuarter, CalendarYear, 
                CalendarSemester, FiscalQuarter, FiscalYear, FiscalSemester,
                RowHash
            )
            SELECT  
                stg.DateKey, stg.FullDateAlternateKey, stg.DayNumberOfWeek, stg.EnglishDayNameOfWeek, stg.SpanishDayNameOfWeek,
                stg.FrenchDayNameOfWeek, stg.DayNumberOfMonth, stg.DayNumberOfYear, stg.WeekNumberOfYear, stg.EnglishMonthName,
                stg.SpanishMonthName, stg.FrenchMonthName, stg.MonthNumberOfYear, stg.CalendarQuarter, stg.CalendarYear, 
                stg.CalendarSemester, stg.FiscalQuarter, stg.FiscalYear, stg.FiscalSemester, stg.SourceHash
            FROM bronze.STG_DimDate stg
            WHERE NOT EXISTS (
                SELECT 1 FROM bronze.DimDate b
                WHERE b.DateKey = stg.DateKey
            )

            SELECT @inserted_rows = @@ROWCOUNT;

            -- Step D: Update existing records where data has changed
            UPDATE  b
            SET     b.FullDateAlternateKey = stg.FullDateAlternateKey,
                    b.DayNumberOfWeek = stg.DayNumberOfWeek,
                    b.EnglishDayNameOfWeek = stg.EnglishDayNameOfWeek,
                    b.SpanishDayNameOfWeek = stg.SpanishDayNameOfWeek,
                    b.FrenchDayNameOfWeek = stg.FrenchDayNameOfWeek,
                    b.DayNumberOfMonth =  stg.DayNumberOfMonth,
                    b.DayNumberOfYear = stg.DayNumberOfYear,
                    b.WeekNumberOfYear = stg.WeekNumberOfYear,
                    b.EnglishMonthName = stg.EnglishMonthName,
                    b.SpanishMonthName = stg.SpanishMonthName,
                    b.FrenchMonthName = stg.FrenchMonthName,
                    b.MonthNumberOfYear = stg.MonthNumberOfYear,
                    b.CalendarQuarter = stg.CalendarQuarter,
                    b.CalendarYear = stg.CalendarYear,
                    b.CalendarSemester =stg.CalendarSemester,
                    b.FiscalQuarter = stg.FiscalQuarter,
                    b.FiscalYear = stg.FiscalYear,
                    b.FiscalSemester = stg.FiscalSemester,
                    b.RowHash = stg.SourceHash
            FROM bronze.DimDate b
            INNER JOIN bronze.STG_DimDate stg ON stg.DateKey = b.DateKey
            WHERE b.RowHash IS NULL OR b.RowHash <> stg.SourceHash

            SELECT @updated_rows = @@ROWCOUNT;

            -- Calculate aggregate metrics
            SET @rows_affected = ISNULL(@inserted_rows, 0) + ISNULL(@updated_rows, 0);

            -- Audit Log
            SET @end_time = GETDATE();
            INSERT INTO bronze.Pipeline_Log VALUES ('bronze.DimDate (Hash-Incremental)', @start_time, @end_time, DATEDIFF(second, @start_time, @end_time), @rows_affected, 'SUCCESS', NULL);

            /* ==========================================================================
               PIPELINE COMMIT & GLOBAL BATCH METRICS
             =========================================================================
            */
            --Complete Batch Transaction safely across all 12 tables
             COMMIT  TRANSACTION

            INSERT INTO bronze.Pipeline_Log VALUES ('BATCH_TOTAL_BRONZE_INCREMENTAL', @batch_start_time, GETDATE(), DATEDIFF(second, @batch_start_time, GETDATE()), NULL, 'SUCCESS', NULL);
            
            PRINT 'Incremental load completed successfully for all tables.';

        END TRY
        BEGIN CATCH
            -- Roll back everything if any point of the pipeline breaks
            IF (XACT_STATE()) = -1 OR @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

            -- Log the failure to the metadata audit table
            INSERT INTO bronze.Pipeline_Log VALUES (
                'BATCH_INCREMENTAL_FAILURE', @batch_start_time, GETDATE(), NULL, NULL, 'FAILED',
                'ERROR: ' + CAST(ERROR_NUMBER() AS VARCHAR) + ': '  + ERROR_MESSAGE()
            );
            -- Throw the error upward so orchestrators know the script failed!
            THROW;
        END CATCH
    END