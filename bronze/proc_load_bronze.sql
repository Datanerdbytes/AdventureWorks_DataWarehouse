/*
=============================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
=============================================================================
Script Purpose:
    This stored procedure loads data into the 'bronze' schema from a database.
    It performs the following actions:
        - Truncates the bronze tables before loading data.
        - Uses 'Insert Into' command to load data from the database to bronze tables.
        - Logs metadata information to the audit log table 'bronze.Pipeline_Log' for each tables inserted 
            into the bronze layer to monitor any bottlenecks during execution of this load procedure.
        - It will also automatically delete log data that is older than 30 days 


Parameter:
    None.
    This stored procedure does not accept any parameters or return values.

Usage Example:
    EXEC bronze.load_bronze;

=============================================================================
*/

CREATE OR ALTER PROCEDURE bronze.load_bronze AS 
BEGIN
    -- Configure SQL Server environment settings
    SET NOCOUNT ON; -- Prevents extra network overhead from 'X-rows affected' messages
    SET XACT_ABORT ON; -- Automatically  rolls back the entire transaction if a runtime errors occurs

    DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
    DECLARE @rows_affected INT;

    BEGIN TRY
        SET @batch_start_time = GETDATE();

        -- Start an explicit transaction to ensure all-or-nothing data integrity
        BEGIN TRANSACTION;

        PRINT '=============================================================';
        PRINT 'Loading Bronze Layer';
        PRINT '=============================================================';

        PRINT  '------------------------------------------------------------';
        PRINT  '1. Loading Product Hierarchy Tables';
        PRINT  '------------------------------------------------------------';
        
        -- DimProduct
        SET @start_time = GETDATE();

        PRINT'Truncating Table: bronze.DimProduct';
        TRUNCATE TABLE bronze.DimProduct;

        PRINT'Inserting Data Into: bronze.DimProduct';
        INSERT INTO bronze.DimProduct (
            ProductKey, ProductAlternateKey, ProductSubcategoryKey, WeightUnitMeasureCode, SizeUnitMeasureCode, EnglishProductName,
            SpanishProductName, FrenchProductName, StandardCost, FinishedGoodsFlag, Color, SafetyStockLevel, ReorderPoint,
            ListPrice, Size, SizeRange, Weight, DaysToManufacture, ProductLine, DealerPrice, Class, Style, ModelName ,
            LargePhoto , EnglishDescription ,FrenchDescription , ChineseDescription , ArabicDescription , HebrewDescription ,
            ThaiDescription , GermanDescription, JapaneseDescription, TurkishDescription, StartDate, EndDate, Status
        )
        SELECT 
            ProductKey, ProductAlternateKey, ProductSubcategoryKey, WeightUnitMeasureCode, SizeUnitMeasureCode, EnglishProductName,
            SpanishProductName, FrenchProductName, StandardCost, FinishedGoodsFlag, Color, SafetyStockLevel, ReorderPoint,
            ListPrice, Size, SizeRange, Weight, DaysToManufacture, ProductLine, DealerPrice, Class, Style, ModelName ,
            LargePhoto , EnglishDescription ,FrenchDescription , ChineseDescription , ArabicDescription , HebrewDescription ,
            ThaiDescription , GermanDescription, JapaneseDescription, TurkishDescription, StartDate, EndDate, Status
        FROM dbo.DimProduct

        -- Audit Log
        SELECT @rows_affected = @@ROWCOUNT, @end_time = GETDATE();
        INSERT INTO bronze.Pipeline_Log VALUES ('bronze.DimProduct', @start_time, @end_time, DATEDIFF(second, @start_time, @end_time), @rows_affected, 'SUCCESS', NULL);

        PRINT'';
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> Rows affected: ' + CAST(@rows_affected  AS NVARCHAR);
        PRINT '---------------------------';

        -- DimProductSubcategory
        SET @start_time = GETDATE();

        PRINT '>> Truncating Table: bronze.DimProductSubcategory';
        TRUNCATE TABLE bronze.DimProductSubcategory;

        PRINT'>> Inserting Data Into: bronze.DimProductSubcategory';
        INSERT INTO bronze.DimProductSubcategory (
            ProductSubcategoryKey,
            ProductSubcategoryAlternateKey,
            EnglishProductSubcategoryName ,
            SpanishProductSubcategoryName,
            FrenchProductSubcategoryName,
            ProductCategoryKey
        )
        SELECT 
            ProductSubcategoryKey,
            ProductSubcategoryAlternateKey,
            EnglishProductSubcategoryName ,
            SpanishProductSubcategoryName,
            FrenchProductSubcategoryName,
            ProductCategoryKey
        FROM dbo.DimProductSubcategory

        -- Audit Log
        SELECT @rows_affected = @@ROWCOUNT, @end_time = GETDATE();
        INSERT INTO bronze.Pipeline_log VALUES ('bronze.DimProductSubcategory', @start_time, @end_time, DATEDIFF(second, @start_time, @end_time), @rows_affected, 'SUCCESS', NULL);

        PRINT'';
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> Rows affected: ' + CAST(@rows_affected  AS NVARCHAR)
        PRINT '---------------------------';


        -- DimProductCategory
        SET @start_time = GETDATE();

        PRINT'Truncating Table: bronze.DimProductCategory';
        TRUNCATE TABLE bronze.DimProductCategory;

        PRINT'Inserting Data Into: bronze.DimProductCategory';
        INSERT INTO bronze.DimProductCategory (
            ProductCategoryKey,
            ProductCategoryAlternateKey,
            EnglishProductCategoryName,
            SpanishProductCategoryName,
            FrenchProductCategoryName
        )
        SELECT 
            ProductCategoryKey,
            ProductCategoryAlternateKey,
            EnglishProductCategoryName,
            SpanishProductCategoryName,
            FrenchProductCategoryName
        FROM dbo.DimProductCategory

        -- Audit Log
        SELECT @rows_affected = @@ROWCOUNT , @start_time = GETDATE();
        INSERT INTO bronze.Pipeline_Log VALUES ('bronze.DimProductCategory', @start_time, @end_time, DATEDIFF(second, @start_time, @end_time), @rows_affected, 'SUCCESS', NULL);

        PRINT '';
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> Rows affected: ' + CAST(@rows_affected  AS NVARCHAR);
        PRINT '---------------------------';
        
        PRINT  '------------------------------------------------------------';
        PRINT  '2. Loading Custommer & Geography Tables';
        PRINT  '------------------------------------------------------------';
    
        -- DimCustomer      
        SET @start_time = GETDATE();

        PRINT'Truncating Table: bronze.DimCustomer';
        TRUNCATE TABLE bronze.DimCustomer;

        PRINT'Inserting Data Into: bronze.DimCustomer';
        INSERT INTO bronze.DimCustomer (
            CustomerKey, GeographyKey, CustomerAlternateKey, Title, FirstName, MiddleName, LastName, NameStyle,
            BirthDate, MaritalStatus, Suffix, Gender, EmailAddress, YearlyIncome, TotalChildren, NumberChildrenAtHome,
            EnglishEducation, SpanishEducation, FrenchEducation, EnglishOccupation, SpanishOccupation, FrenchOccupation,
            HouseOwnerFlag, NumberCarsOwned, AddressLine1, AddressLine2, Phone, DateFirstPurchase, CommuteDistance
        )
        SELECT 
            CustomerKey, GeographyKey, CustomerAlternateKey, Title, FirstName, MiddleName, LastName, NameStyle,
            BirthDate, MaritalStatus, Suffix, Gender, EmailAddress, YearlyIncome, TotalChildren, NumberChildrenAtHome,
            EnglishEducation, SpanishEducation, FrenchEducation, EnglishOccupation, SpanishOccupation, FrenchOccupation,
            HouseOwnerFlag, NumberCarsOwned, AddressLine1, AddressLine2, Phone, DateFirstPurchase, CommuteDistance
        FROM dbo.DimCustomer

        --  Audit Log
        SELECT @rows_affected = @@ROWCOUNT , @start_time = GETDATE();
        INSERT INTO bronze.Pipeline_Log VALUES ('bronze.DimCustomer', @start_time, @end_time, DATEDIFF(second, @start_time, @end_time), @rows_affected, 'SUCCESS', NULL);

        PRINT'';
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> Rows affected: ' + CAST(@rows_affected  AS NVARCHAR);
        PRINT '---------------------------';

        -- DimReseller
        SET @start_time = GETDATE();

        PRINT 'Truncating Table bronze.DimReseller';
        TRUNCATE TABLE bronze.DimReseller;

        PRINT 'Inserting Data Into: bronze.DimReseller';
        INSERT INTO bronze.DimReseller (
            ResellerKey, GeographyKey, ResellerAlternateKey, Phone, BusinessType, ResellerName, NumberEmployees,
            OrderFrequency, OrderMonth, FirstOrderYear, LastOrderYear, ProductLine, AddressLine1, AddressLine2,
            AnnualSales, BankName, MinPaymentType, MinPaymentAmount, AnnualRevenue, YearOpened
        ) 
        SELECT 
            ResellerKey, GeographyKey, ResellerAlternateKey, Phone, BusinessType, ResellerName, NumberEmployees,
            OrderFrequency, OrderMonth, FirstOrderYear, LastOrderYear, ProductLine, AddressLine1, AddressLine2,
            AnnualSales, BankName, MinPaymentType, MinPaymentAmount, AnnualRevenue, YearOpened
        FROM dbo.DimReseller

        -- Audit Log
        SELECT @rows_affected = @@ROWCOUNT, @end_time = GETDATE();
        INSERT INTO bronze.Pipeline_Log VALUES ('bronze.DimReseller', @start_time, @end_time, DATEDIFF(second, @start_time, @end_time), @rows_affected,'SUCCESS', NULL);

        PRINT '';
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> Rows affected: ' + CAST(@rows_affected  AS NVARCHAR);
        PRINT '---------------------------';

        -- DimReseller
        SET @start_time = GETDATE();

        PRINT 'Truncating Table: bronze.DimSalesTerritory';
        TRUNCATE TABLE bronze.DimSalesTerritory

        PRINT 'Inserting Data Into: bronze.DimSalesTerritory'
        INSERT INTO bronze.DimSalesTerritory (
            SalesTerritoryKey,
            SalesTerritoryAlternateKey,
            SalesTerritoryRegion,
            SalesTerritoryCountry,
            SalesTerritoryGroup,
            SalesTerritoryImage
        ) 
        SELECT 
            SalesTerritoryKey,
            SalesTerritoryAlternateKey,
            SalesTerritoryRegion,
            SalesTerritoryCountry,
            SalesTerritoryGroup,
            SalesTerritoryImage
        FROM dbo.DimSalesTerritory

         -- Audit Log
        SELECT @rows_affected = @@ROWCOUNT, @end_time = GETDATE();
        INSERT INTO bronze.Pipeline_Log VALUES ('bronze.DimSaleTerritor', @start_time, @end_time, DATEDIFF(second, @start_time, @end_time), @rows_affected,'SUCCESS', NULL);

        PRINT '';
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> Rows affected: ' + CAST(@rows_affected  AS NVARCHAR);
        PRINT '---------------------------';

        -- DimGeography
        SET @start_time = GETDATE();
        
        PRINT 'Truncating Table: bronze.DimGeography';
        TRUNCATE TABLE bronze.DimGeography;

        PRINT 'Inserting Data Into: bronze.DimGeography';
        INSERT INTO bronze.DimGeography (
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
            IpAddressLocator
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
            IpAddressLocator
        FROM dbo.DimGeography

        -- Audit log
        SELECT @rows_affected = @@ROWCOUNT, @end_time = GETDATE();
        INSERT INTO bronze.Pipeline_Log VALUES ('bronze.DimGeography', @start_time, @end_time, DATEDIFF(second, @start_time, @end_time), @rows_affected, 'SUCCESS', NULL);

        
        PRINT '';
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> Rows affected: ' + CAST(@rows_affected  AS NVARCHAR);
        PRINT '---------------------------';

        PRINT  '------------------------------------------------------------';
        PRINT  '3. Loading Employees & Date Tables';
        PRINT  '------------------------------------------------------------';

        -- DimEmployee
        SET @start_time = GETDATE();

        PRINT'Truncating Table: bronze.DimEmployee';
        TRUNCATE TABLE bronze.DimEmployee;

        PRINT'Inserting Data Into: bronze.DimEmployee';
        INSERT INTO bronze.DimEmployee (
            EmployeeKey, ParentEmployeeKey, EmployeeNationalIDAlternateKey, ParentEmployeeNationalIDAlternateKey, SalesTerritoryKey,
            FirstName, LastName, MiddleName, NameStyle, Title, HireDate, BirthDate, LoginID, EmailAddress, Phone, MaritalStatus,
            EmergencyContactName, EmergencyContactPhone, SalariedFlag, Gender, PayFrequency, BaseRate, VacationHours, SickLeaveHours,
            CurrentFlag, SalesPersonFlag, DepartmentName, StartDate, EndDate, Status, EmployeePhoto
        )
        SELECT 
            EmployeeKey, ParentEmployeeKey, EmployeeNationalIDAlternateKey, ParentEmployeeNationalIDAlternateKey, SalesTerritoryKey,
            FirstName, LastName, MiddleName, NameStyle, Title, HireDate, BirthDate, LoginID, EmailAddress, Phone, MaritalStatus,
            EmergencyContactName, EmergencyContactPhone, SalariedFlag, Gender, PayFrequency, BaseRate, VacationHours, SickLeaveHours,
            CurrentFlag, SalesPersonFlag, DepartmentName, StartDate, EndDate, Status, EmployeePhoto
        FROM dbo.DimEmployee

        -- Audit Log
        SELECT @rows_affected = @@ROWCOUNT, @end_time = GETDATE();
        INSERT INTO bronze.Pipeline_Log VALUES ('bronze.DimEmployee', @start_time, @end_time, DATEDIFF(second, @start_time, @end_time), @rows_affected, 'SUCCESS', NULL);
        
        PRINT'';
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> Rows affected: ' + CAST(@rows_affected  AS NVARCHAR);
        PRINT '---------------------------';

        -- DimDate
        SET @start_time = GETDATE();

        PRINT'Truncating Table: bronze.DimDate';
        TRUNCATE TABLE bronze.DimDate;

        PRINT'Inserting Data Into: bronze.DimDate';
        INSERT INTO bronze.DimDate (
            DateKey, FullDateAlternateKey, DayNumberOfWeek, EnglishDayNameOfWeek, SpanishDayNameOfWeek, FrenchDayNameOfWeek,
            DayNumberOfMonth, DayNumberOfYear, WeekNumberOfYear, EnglishMonthName, SpanishMonthName, FrenchMonthName,
            MonthNumberOfYear, CalendarQuarter, CalendarYear, CalendarSemester, FiscalQuarter, FiscalYear, FiscalSemester
        )
        SELECT 
             DateKey, FullDateAlternateKey, DayNumberOfWeek, EnglishDayNameOfWeek, SpanishDayNameOfWeek, FrenchDayNameOfWeek,
            DayNumberOfMonth, DayNumberOfYear, WeekNumberOfYear, EnglishMonthName, SpanishMonthName, FrenchMonthName,
            MonthNumberOfYear, CalendarQuarter, CalendarYear, CalendarSemester, FiscalQuarter, FiscalYear, FiscalSemester
        FROM dbo.DimDate

        -- Audit Log
        SELECT @rows_affected = @@ROWCOUNT, @end_time = GETDATE();
        INSERT INTO bronze.Pipeline_Log VALUES ('bronze.DimDate', @start_time, @end_time, DATEDIFF(second, @start_time, @end_time), @rows_affected, 'SUCCESS', NULL);

        
        PRINT '';
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> Rows affected: ' + CAST(@rows_affected  AS NVARCHAR);
        PRINT '---------------------------';

        PRINT  '------------------------------------------------------------';
        PRINT  '4. Loading Sales Transaction Tables';
        PRINT  '------------------------------------------------------------';
    
        -- FactInternetSales
        SET @start_time = GETDATE();

        PRINT'Truncating Table: bronze.FactInternetSales';
        TRUNCATE TABLE bronze.FactInternetSales;

        PRINT'Inserting Data Into: bronze.FactInternetSales';
        INSERT INTO bronze.FactInternetSales(
            ProductKey, OrderDateKey, DueDateKey, ShipDateKey, CustomerKey, PromotionKey, CurrencyKey, SalesTerritoryKey,
            SalesOrderNumber, SalesOrderLineNumber, RevisionNumber, OrderQuantity, UnitPrice, ExtendedAmount, UnitPriceDiscountPct,
            DiscountAmount, ProductStandardCost, TotalProductCost, SalesAmount, TaxAmt, Freight, CarrierTrackingNumber,
            CustomerPONumber, OrderDate, DueDate, ShipDate
        )
        SELECT
            ProductKey, OrderDateKey, DueDateKey, ShipDateKey, CustomerKey, PromotionKey, CurrencyKey, SalesTerritoryKey,
            SalesOrderNumber, SalesOrderLineNumber, RevisionNumber, OrderQuantity, UnitPrice, ExtendedAmount, UnitPriceDiscountPct,
            DiscountAmount, ProductStandardCost, TotalProductCost, SalesAmount, TaxAmt, Freight, CarrierTrackingNumber,
            CustomerPONumber, OrderDate, DueDate, ShipDate
        FROM dbo.FactInternetSales

        -- Audit Log
        SELECT @rows_affected = @@ROWCOUNT, @end_time = GETDATE();
        INSERT INTO bronze.Pipeline_Log VALUES ('bronze.FactInternetSales', @start_time, @end_time, DATEDIFF(second, @start_time, @end_time), @rows_affected, 'SUCCESS', NULL);

        
        PRINT'';
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> Rows affected: ' + CAST(@rows_affected  AS NVARCHAR);
        PRINT '---------------------------';

        -- FactResellerSales
        SET @start_time = GETDATE();

        PRINT'Truncating Table: bronze.FactResellerSales';
        TRUNCATE TABLE bronze.FactResellerSales;

        PRINT'Inserting Data Into: bronze.FactResellerSales';
        INSERT INTO bronze.FactResellerSales (
            ProductKey, OrderDateKey, DueDateKey, ShipDateKey, ResellerKey, EmployeeKey, PromotionKey, CurrencyKey, SalesTerritoryKey,
            SalesOrderNumber, SalesOrderLineNumber, RevisionNumber, OrderQuantity, UnitPrice, ExtendedAmount, UnitPriceDiscountPct,
            DiscountAmount, ProductStandardCost, TotalProductCost, SalesAmount, TaxAmt, Freight, CarrierTrackingNumber, CustomerPONumber,
            OrderDate, DueDate, ShipDate
        )
        SELECT 
            ProductKey, OrderDateKey, DueDateKey, ShipDateKey, ResellerKey, EmployeeKey, PromotionKey, CurrencyKey, SalesTerritoryKey,
            SalesOrderNumber, SalesOrderLineNumber, RevisionNumber, OrderQuantity, UnitPrice, ExtendedAmount, UnitPriceDiscountPct,
            DiscountAmount, ProductStandardCost, TotalProductCost, SalesAmount, TaxAmt, Freight, CarrierTrackingNumber, CustomerPONumber,
            OrderDate, DueDate, ShipDate
        FROM dbo.FactResellerSales

        -- Audit Log
        SELECT @rows_affected = @@ROWCOUNT, @end_time = GETDATE();
        INSERT INTO bronze.Pipeline_Log VALUES ('bronze.FactResellerSales', @start_time, @end_time, DATEDIFF(second, @start_time, @end_time), @rows_affected, 'SUCCESS', NULL);

        
        PRINT '';
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT 'Rows affected: ' + CAST(@rows_affected  AS NVARCHAR);
        PRINT '---------------------------';

        -- FactSalesQuota
        SET @start_time = GETDATE();

        PRINT'Truncating Table: bronze.FactSalesQuota';
        TRUNCATE TABLE bronze.FactSalesQuota;
        PRINT'Inserting Data Into: bronze.FactSalesQuota';
        INSERT INTO bronze.FactSalesQuota (
            SalesQuotaKey,
            EmployeeKey,
            DateKey,
            CalendarYear,
            CalendarQuarter,
            SalesAmountQuota,
            Date
        )
        SELECT 
            SalesQuotaKey,
            EmployeeKey,
            DateKey,
            CalendarYear,
            CalendarQuarter,
            SalesAmountQuota,
            Date
        from dbo.FactSalesQuota
        
        --Audit Log
        SELECT @rows_affected = @@ROWCOUNT, @end_time = GETDATE();
        INSERT INTO bronze.Pipeline_Log VALUES ('bronze.FactSalesQuota', @start_time, @end_time, DATEDIFF(second, @start_time, @end_time), @rows_affected, 'SUCCESS', NULL);

        PRINT '';
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> Rows affected: ' + CAST(@rows_affected  AS NVARCHAR);
        PRINT '---------------------------';


        -- Complete Batch Transaction
        COMMIT TRANSACTION;

        SET @batch_end_time = GETDATE();
        
        -- Log overall batch success
        INSERT INTO bronze.Pipeline_Log VALUES ('BATCH_TOTAL_BRONZE', @batch_start_time, @batch_end_time, DATEDIFF(second, @batch_start_time, @batch_end_time), NULL, 'SUCCESS', NULL);

        /*
        =========================================================================
        Automate Log Retention: Permamently deletes any logs older than  30 days.
        =========================================================================
        */

        DELETE FROM bronze.Pipeline_Log
        WHERE StartTime < DATEADD(day, -30, GETDATE());

        SET @batch_end_time = GETDATE();
        PRINT '=============================================================';
        PRINT 'Loading Bronze Layer is completed'
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