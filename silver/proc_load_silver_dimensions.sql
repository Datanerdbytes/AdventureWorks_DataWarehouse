/*
===================================================================================
ORCHESTRATION PIPELINE LAYER: SILVER DIMENSIONS EXTRACT, TRANSFORM, & LOAD (ETL)
===================================================================================
Procedure Name: silver.load_silver_dimensions
Layer Rank:     Silver Layer (Data Quality, Governance, and Standardization)
Target Tables:  - silver.DimEmployee          - silver.DimGeography
                - silver.DimCustomer          - silver.DimSalesTerritory
                - silver.DimReseller          - silver.DimProduct
                - silver.DimProductSubcategory- silver.DimProductCategory
                - silver.DimDate

Architectural Design Patterns Implemented:
    1. POSITIONAL INSERTION SAFETY:
       - Employs explicit column mapping arrays for all INSERT INTO clauses. Ensures
         structural insulation against column-order changes in underlying DDL.
    2. DATA QUALITY & STANDARDIZATION CLEANUPS:
       - Standardizes binary indicator flags (e.g., FinishedGoodsFlag -> Text).
       - Decodes single-character operational business keys (ProductLine, Class, Style).
       - Implements robust string handling via TRIM() and NULL propagation handling via CONCAT().
    3. ADVANCED SCD TYPE 2 TIMELINE RECONSTRUCTION:
       - Uses a specialized analytical window function sequence (LEAD()) in DimProduct 
         to programmatically repair overlapping timelines and chronological bugs 
         (EndDate < StartDate) inherited from source system data entry.
    4. ENTERPRISE RECOVERY & METADATA AUDITING:
       - Wrapped completely in explicit ATOMIC transactions (COMMIT/ROLLBACK) with XACT_ABORT.
       - Logs complete execution lineage (runtimes, status, rowcounts) to bronze.Pipeline_Log.
       - Automatically enforces a rolling 30-day log retention purge policy.

Execution Dependency:
    - MUST run AFTER the Bronze layer ingestion completes successfully.
    - MUST run BEFORE executing the Fact incremental load pipelines (silver.load_silver_facts).
===================================================================================
*/
CREATE OR ALTER PROCEDURE silver.load_silver_dimensions AS 
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME, @rows_affected INT;

    BEGIN TRY
        SET @batch_start_time = GETDATE();

        BEGIN TRANSACTION;

        PRINT '=============================================================';
        PRINT 'Loading Silver Layer';
        PRINT '=============================================================';

        PRINT  '------------------------------------------------------------';
        PRINT  '1. Loading Dimension Tables';
        PRINT  '------------------------------------------------------------';

        -- DimEmployee
        SET @start_time = GETDATE();
        PRINT 'Truncating Table: silver.DimEmployee';
        TRUNCATE TABLE silver.DimEmployee;
        PRINT 'Inserting Data Into: silver.DimEmployee';
        INSERT INTO silver.DimEmployee (
            EmployeeKey, ParentEmployeeKey, EmployeeNationalIDAlternateKey, ParentEmployeeNationalIDAlternateKey,
            SalesTerritoryKey, FirstName, LastName, MiddleName, FullName, NameStyle, Title,
            HireDate, BirthDate, LoginID, EmailAddress, Phone, MaritalStatus,
            EmergencyContactName, EmergencyContactPhone, SalariedFlag, Gender, PayFrequency,
            BaseRate, VacationHours, SickLeaveHours, CurrentFlag, SalesPersonFlag, DepartmentName,
            StartDate, EndDate, Status, EmployeePhoto, DWHCreateDate
        )
        SELECT 
            EmployeeKey,
            ISNULL(ParentEmployeeKey, -1) AS ParentEmployeeKey, -- Standardized missing parent key
            EmployeeNationalIDAlternateKey,
            ParentEmployeeNationalIDAlternateKey,
            SalesTerritoryKey,
            FirstName,
            LastName,
            MiddleName,
            -- Unified Full Name (Handles NULL Middlenames)
        CONCAT(TRIM(FirstName), ' ', ISNULL(TRIM(MiddleName) + ' ', ''), TRIM(LastName)) AS FullName,
            NameStyle,
            Title,
            HireDate,
            BirthDate,
            LoginID,
            EmailAddress,
            Phone,
            CASE 
                WHEN UPPER(TRIM(MaritalStatus)) = 'M' THEN 'Married'
                WHEN UPPER(TRIM(MaritalStatus)) = 'S' THEN 'Single'
                ELSE 'Unknown' END AS MaritalStatus,
            EmergencyContactName,
            EmergencyContactPhone,
            CASE WHEN SalariedFlag = 1 THEN 'Salaried' ELSE 'Hourly' END AS PayType,
            CASE 
                WHEN UPPER(TRIM(Gender)) = 'M' THEN 'Male'
                WHEN UPPER(TRIM(Gender)) = 'F' THEN 'Female'
                ELSE 'Unknown' END AS Gender,
            PayFrequency,
            BaseRate,
            VacationHours,
            SickLeaveHours,
            CASE WHEN CurrentFlag = 1 THEN 'Active' ELSE 'Inactive' END AS EmploymentStatus,
            SalesPersonFlag,
            DepartmentName,
            StartDate,
            EndDate,
            [Status],
            EmployeePhoto,
            GETDATE() AS DWHCreateDate
        FROM bronze.DimEmployee

        --Audit Log
        SELECT @rows_affected = @@ROWCOUNT, @end_time = GETDATE();
        INSERT INTO bronze.Pipeline_Log VALUES ('silver.DimEmployee', @start_time, @end_time, DATEDIFF(second, @start_time, @end_time), @rows_affected,'SUCCESS', NULL);

        PRINT'';
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '---------------------------';

        -- DimCustomer
        SET @start_time = GETDATE();
        PRINT 'Truncating Table: silver.DimCustomer';
        TRUNCATE TABLE silver.DimCustomer;
        PRINT 'Inserting Data Into: silver.DimCustomer';
        INSERT INTO silver.DimCustomer (
            CustomerKey, GeographyKey, CustomerAlternateKey, Title, FirstName, MiddleName, LastName, FullName, NameStyle, BirthDate, MaritalStatus,
            Suffix, Gender, EmailAddress, YearlyIncome, TotalChildren, NumberChildrenAtHome, EnglishEducation, SpanishEducation, FrenchEducation,
            EnglishOccupation, SpanishOccupation, FrenchOccupation, HouseOwnerFlag, NumberCarsOwned, AddressLine1, AddressLine2, Phone,
            DateFirstPurchase, CommuteDistance, DWHCreateDate
        )
        SELECT
            CustomerKey,
            GeographyKey,
            CustomerAlternateKey,
            ISNULL(Title,'Unknown') Title,
            FirstName,
            MiddleName,
            LastName,
            CONCAT(TRIM(FirstName), ' ', ISNULL(TRIM(MiddleName) + ' ', '' ), TRIM(LastName)) AS FullName,
            NameStyle,
            BirthDate,
            CASE UPPER(TRIM(MaritalStatus))
                WHEN 'M' THEN 'Married'
                WHEN 'S' THEN 'Single'
            ELSE 'Unknown' END AS MaritalStatus,
            ISNULL(Suffix, 'Unknown') AS Suffix,
            CASE  UPPER(TRIM(Gender)) 
                WHEN 'M' THEN 'Male'
                WHEN 'F' THEN 'Female'
            ELSE 'Unknown' END AS Gender,
            EmailAddress,
            YearlyIncome,
            TotalChildren,
            NumberChildrenAtHome,
            EnglishEducation,
            SpanishEducation,
            FrenchEducation,
            EnglishOccupation,
            SpanishOccupation,
            FrenchOccupation,
            HouseOwnerFlag,
            NumberCarsOwned,
            AddressLine1,
            ISNULL(AddressLine2,'') AS AddressLine2,
            Phone,
            DateFirstPurchase,
            CommuteDistance,
            GETDATE() AS DWHCreateDate
        FROM bronze.DimCustomer
        -- Audit Log
        SELECT @rows_affected = @@ROWCOUNT, @end_time = GETDATE();
        INSERT INTO bronze.Pipeline_Log VALUES ('silver.DimCustomer', @start_time, @end_time, DATEDIFF(second, @start_time, @end_time),@rows_affected, 'SUCCESS',NULL);

        PRINT'';
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '---------------------------';

        -- DimReseller
        SET  @start_time = GETDATE();
        PRINT 'Truncationg Table:  DimReseller';
        TRUNCATE TABLE silver.DimReseller;
        PRINT 'Inserting Data Into:  DimReseller';
        INSERT INTO silver.DimReseller (
            ResellerKey, GeographyKey, ResellerAlternateKey, Phone, BusinessType, ResellerName, NumberEmployees, 
            OrderFrequency, OrderMonth, OrderMonthAbbr, FirstOrderYear, LastOrderYear, ProductLine, AddressLine1, AddressLine2, 
            AnnualSales, BankName, MinPaymentType, MinPaymentAmount, AnnualRevenue, YearOpened, DWHCreateDate
        )
        SELECT 
            ResellerKey,
            GeographyKey,
            ResellerAlternateKey,
            ISNULL(Phone, 'Unknown') AS Phone,
            BusinessType,
            ResellerName,
            NumberEmployees,
            CASE  WHEN OrderFrequency = 'A' THEN 'Annual'
                WHEN OrderFrequency = 'S' THEN 'Semi-Annual'
                WHEN OrderFrequency = 'Q' THEN 'Quarterly'
                ELSE 'Unknown' END AS OrderFrequency,
            OrderMonth,
            SUBSTRING(DATENAME(month, DATEADD(month, OrderMonth, -1)),1,3) AS OrderMonthAbbr,
            FirstOrderYear,
            LastOrderYear,
            ProductLine,
            AddressLine1,
            ISNULL(AddressLine2,'') AS AddressLine2,
            AnnualSales,
            ISNULL(BankName,'Unknown') BankName,
            CASE WHEN MinPaymentType = 1 THEN 'Percent'
                WHEN MinPaymentType = 2 THEN 'Min Amount'
                WHEN MinPaymentType = 3 THEN 'None'
            ELSE 'Unknown' END AS MinPaymentType,
            ISNULL(MinPaymentAmount,0) MinPaymentAmount,
            AnnualRevenue,
            YearOpened,
            GETDATE() AS DWHCreateDate
        FROM bronze.DimReseller
        -- Audit Log
        SELECT @rows_affected = @@ROWCOUNT, @end_time = GETDATE();
        INSERT INTO bronze.Pipeline_Log VALUES ('silver.DimReseller', @start_time, @end_time, DATEDIFF(second, @start_time, @end_time),@rows_affected, 'SUCCESS', NULL);

        PRINT'';
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '---------------------------';

        -- DimGeography
        SET @start_time = GETDATE();
        PRINT 'Truncating Table: DimGeography';
        TRUNCATE TABLE silver.DimGeography;
        PRINT 'Inserting Data Into: DimGeography';
        INSERT INTO silver.DimGeography (
            GeographyKey, City, StateProvinceCode, StateProvinceName, CountryRegionCode, EnglishCountryRegionName, 
            SpanishCountryRegionName, FrenchCountryRegionName, PostalCode, SalesTerritoryKey, IpAddressLocator, 
            DWHCreateDate
        )
        SELECT 
            GeographyKey,
            City,
            StateProvinceCode,
            StateProvinceName,
            CountryRegionCode,
            EnglishCountryRegionName,
            SpanishCountryRegionName,
            FrenchCountryRegionName,
            PostalCode,
            SalesTerritoryKey,
            IpAddressLocator,
            GETDATE() AS DWHCreateDate
        FROM bronze.DimGeography
        --Audit Log
        SELECT @rows_affected = @@ROWCOUNT, @end_time = GETDATE();
        INSERT INTO bronze.Pipeline_Log VALUES ('silver.DimGeography', @start_time, @end_time, DATEDIFF(second, @start_time, @end_time), @rows_affected, 'SUCCESS', NULL);
        
        PRINT'';
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '---------------------------';

        --DimSalesTerritory
        SET @start_time = GETDATE();
        PRINT 'Truncating Table: DimSalesTerritory';
        TRUNCATE TABLE silver.DimSalesTerritory;
        PRINT 'Inserting Data Into: DimsalesTerritory';
        INSERT INTO silver.DimSalesTerritory (
            SalesTerritoryKey, SalesTerritoryAlternateKey, SalesTerritoryRegion,
            SalesTerritoryCountry, SalesTerritoryGroup, SalesTerritoryImage,
            DWHCreateDate
        )
        SELECT 
            SalesTerritoryKey,
            SalesTerritoryAlternateKey,
            SalesTerritoryRegion,
            SalesTerritoryCountry,
            SalesTerritoryGroup,
            SalesTerritoryImage,
            GETDATE() AS DWHCreateDate
        FROM bronze.DimSalesTerritory
        -- Audit Log
        SELECT @rows_affected = @@ROWCOUNT, @end_time = GETDATE();
        INSERT INTO bronze.Pipeline_Log VALUES('silver.DimSalesTerritory', @start_time, @end_time, DATEDIFF(second,@start_time,@end_time), @rows_affected, 'SUCCESS',NULL);

        PRINT'';
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '---------------------------';

        --DinProduct
        SET @start_time = GETDATE();
        PRINT 'Truncating Table: DimProduct';
        TRUNCATE TABLE silver.DimProduct;
        PRINT 'Inserting Data Into: DimProduct';
        INSERT INTO silver.DimProduct (
            ProductKey, ProductAlternateKey, ProductSubcategoryKey, WeightUnitMeasureCode, SizeUnitMeasureCode,
            EnglishProductName, SpanishProductName, FrenchProductName, StandardCost,
            ProductType, Color, SafetyStockLevel, ReorderPoint, ListPrice, Size,
            SizeRange, Weight, DaysToManufacture, ProductLine, DealerPrice, ProductClass, ProductStyle,
            ModelName, LargePhoto, EnglishDescription, FrenchDescription,
            ChineseDescription, ArabicDescription, HebrewDescription, ThaiDescription, GermanDescription,
            JapaneseDescription, TurkishDescription, StartDate, EndDate, Status, DWHCreateDate
        )

        SELECT 
            ProductKey,
            ProductAlternateKey,
            ProductSubcategoryKey,
            WeightUnitMeasureCode,
            SizeUnitMeasureCode,
            EnglishProductName,
            SpanishProductName,
            FrenchProductName,
            ISNULL(StandardCost,0) StandardCost,
            CASE WHEN FinishedGoodsFlag = 1 THEN 'Finished Product'
                WHEN FinishedGoodsFlag = 0 THEN 'Component / Internal Part'
            ELSE 'Unknown' END AS ProductType,
            Color,
            SafetyStockLevel,
            ReorderPoint,
            ISNULL(ListPrice,0) AS  ListPrice,
            Size,
            SizeRange,
            Weight,
            DaysToManufacture,
            -- Expanding product line segmentation codes
            CASE WHEN ProductLine = 'M' THEN 'Mountain'
                WHEN ProductLine = 'R' THEN 'Road'
                WHEN ProductLine = 'S' THEN 'Sport'
                WHEN ProductLine = 'T' THEN 'Touring'
            ELSE 'Accessory / Other' END AS ProductLine,
            ISNULL(DealerPrice,0) AS DealerPrice,
            CASE WHEN Class = 'H' THEN 'High'
                WHEN Class = 'M' THEN 'Medium'
                WHEN Class = 'L' THEN 'Low'
            ELSE 'Standard' END AS ProductClass,
            CASE WHEN Style = 'M' THEN 'Mens'
                WHEN Style = 'W' THEN 'Womens'
                WHEN Style = 'U' THEN 'Universal'
            ELSE 'Universal' END AS ProductStyle,
            ISNULL(ModelName,'Unknown')  AS ModelName,
            LargePhoto,
            EnglishDescription,
            FrenchDescription,
            ChineseDescription,
            ArabicDescription,
            HebrewDescription,
            ThaiDescription,
            GermanDescription,
            JapaneseDescription,
            TurkishDescription,
            StartDate,
            /*  DATA QUALITY FIX: Microsoft's source data has a bug where EndDate < StartDate.
                We use LEAD() to look ahead at the NEXT version's StartDate and subtract 1 day.
                This dynamically builds a perfect, gapless SCD Type 2 timeline for each product SKU.
            */
            LEAD(StartDate) OVER(PARTITION BY ProductAlternateKey ORDER BY StartDate)-1 AS EndDate,
            CASE 
                WHEN [Status] = 'Current' OR LEAD(StartDate) OVER(PARTITION BY ProductAlternateKey ORDER BY StartDate)-1 IS NULL THEN 'Current'
                ELSE 'Expired' 
            END AS Status,
            GETDATE() AS DWHCreateDate
        FROM bronze.DimProduct
        --Audit Log
        SELECT @rows_affected = @@ROWCOUNT, @end_time = GETDATE();
        INSERT INTO bronze.Pipeline_Log VALUES('silver.DimProduct',@start_time, @end_time,DATEDIFF(second, @start_time, @end_time), @rows_affected, 'SUCCESS',NULL);

        PRINT'';
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '---------------------------';

        --DimProductSubcategory
        SET @start_time = GETDATE();
        PRINT 'Truncating Table: DimProductSubcategory';
        TRUNCATE TABLE silver.DimProductSubcategory;
        PRINT 'Inserting Data Into: DimProductSubcategory';
        INSERT INTO silver.DimProductSubcategory (
            ProductSubcategoryKey, ProductSubcategoryAlternateKey, EnglishProductSubcategoryName,
            SpanishProductSubcategoryName, FrenchProductSubcategoryName,ProductCategoryKey, DWHCreateDate
        )
        SELECT 
            ProductSubcategoryKey,
            ProductSubcategoryAlternateKey,
            EnglishProductSubcategoryName,
            SpanishProductSubcategoryName,
            FrenchProductSubcategoryName,
            ProductCategoryKey,
            GETDATE() AS DWHCreateDate
        FROM bronze.DimProductSubcategory
        -- Audit Log
        SELECT @rows_affected = @@ROWCOUNT, @end_time = GETDATE();
        INSERT INTO bronze.Pipeline_Log VALUES('silver.DimProductSubcategory',@start_time, @end_time,DATEDIFF(second, @start_time, @end_time), @rows_affected, 'SUCCESS',NULL);

        PRINT'';
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '---------------------------';

        -- DimProductCategory
        SET @start_time = GETDATE();
        PRINT 'Truncating Table: DimProductCategory';
        TRUNCATE TABLE silver.DimProductCategory;
        PRINT 'Inserting Data Into: DimProductCategory';
        INSERT INTO silver.DimProductCategory (
            ProductCategoryKey, ProductCategoryAlternateKey, EnglishProductCategoryName, SpanishProductCategoryName,
            FrenchProductCategoryName, DWHCreateDate
        )
        SELECT 
            ProductCategoryKey,
            ProductCategoryAlternateKey,
            EnglishProductCategoryName,
            SpanishProductCategoryName,
            FrenchProductCategoryName,
            GETDATE() AS DWHCreateDate
        FROM bronze.DimProductCategory
        -- Audit Log
        SELECT @rows_affected = @@ROWCOUNT, @end_time = GETDATE();
        INSERT INTO bronze.Pipeline_Log VALUES('silver.DimProductCategory',@start_time, @end_time,DATEDIFF(second, @start_time, @end_time), @rows_affected, 'SUCCESS',NULL);

        PRINT'';
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        
        -- DimDate
        PRINT 'Truncating Table: silver.DimDate';
        TRUNCATE TABLE silver.DimDate;
        PRINT 'Inserting Data Into: silver.DimDate';
        INSERT INTO silver.DimDate (
            DateKey, FullDateAlternateKey, DayNumberOfWeek, EnglishDayNameOfWeek, SpanishDayNameOfWeek,
            FrenchDayNameOfWeek, DayNumberOfMonth, DayNumberOfYear, WeekNumberOfYear, EnglishMonthName, 
            SpanishMonthName, FrenchMonthName, MonthNumberOfYear, CalendarQuarter, CalendarYear,
            CalendarSemester, FiscalQuarter, FiscalYear, FiscalSemester, DWHCreateDate
        )

        SELECT 
            DateKey,
            FullDateAlternateKey,
            DayNumberOfWeek,
            EnglishDayNameOfWeek,
            SpanishDayNameOfWeek,
            FrenchDayNameOfWeek,
            DayNumberOfMonth,
            DayNumberOfYear,
            WeekNumberOfYear,
            EnglishMonthName,
            SpanishMonthName,
            FrenchMonthName,
            MonthNumberOfYear,
            CalendarQuarter,
            CalendarYear,
            CalendarSemester,
            FiscalQuarter,
            FiscalYear,
            FiscalSemester,
            GETDATE() AS DWHCreateDate
      FROM bronze.DimDate
       -- Audit Log
        SELECT @rows_affected = @@ROWCOUNT, @end_time = GETDATE();
        INSERT INTO bronze.Pipeline_Log VALUES('silver.DimDate',@start_time, @end_time,DATEDIFF(second, @start_time, @end_time), @rows_affected, 'SUCCESS',NULL);

        PRINT'';
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';

        -- Complete Batch Transaction
        COMMIT TRANSACTION;

        SET @batch_end_time = GETDATE();

        INSERT INTO bronze.Pipeline_Log VALUES ('BATCH_TOTAL_SILVER_DIM', @batch_start_time, @batch_end_time, DATEDIFF(second, @batch_start_time, @batch_end_time), NULL, 'SUCCESS', NULL);

        PRINT 'Incremental load completed successfully for all Dimension tables.';

     /*
        =========================================================================
        Automate Log Retention: Permamently deletes any logs older than  30 days.
        =========================================================================
    */

        /* Log Retention Housekeeping */
        DELETE FROM bronze.Pipeline_Log
        WHERE StartTime < DATEADD(day, -30, GETDATE());

        PRINT '=============================================================';
        PRINT 'Loading Silver Layer is completed'
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
        PRINT '=============================================================';

    END TRY
    BEGIN CATCH
         -- Rollback everything if any point of the pipeline breaks
        IF (XACT_STATE()) = -1 OR @@TRANCOUNT > 0 
        BEGIN
            ROLLBACK TRANSACTION;
        END

         -- Log Failure to metadata audit table
        INSERT INTO bronze.Pipeline_Log VALUES (
            'BATCH_FAILURE',
            @batch_start_time,
            GETDATE(),
            NULL,
            NULL,
            'FAILED',
            'Error ' + CAST(ERROR_NUMBER() AS VARCHAR) +  ': ' + ERROR_MESSAGE()
        );
        THROW; -- Throw the error upward so orchestrator know the script failed!

        PRINT '=============================================================';
        PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER';
        PRINT 'Error Message' + ERROR_MESSAGE();
        PRINT 'Error Message' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Error Message' + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT '=============================================================';
    END CATCH
END