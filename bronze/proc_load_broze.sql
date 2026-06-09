/*
=============================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
=============================================================================
Script Purpose:
    This stored procedure loads data into the 'bronze' schema from a database.
    It performs the following actions:
        - Truncates the bronze tables before loading data.
        - Uses 'Insert Into' command to load data from the database to bronze tables.

Parameter:
    None.
    This stored procedure does not accept any parameters or return values.

Usage Example:
    EXEC bronze.load_bronze;

=============================================================================
*/

CREATE OR ALTER PROCEDURE bronze.load_bronze AS 
BEGIN
    DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
    BEGIN TRY
        SET @batch_start_time = GETDATE();
        PRINT '=============================================================';
        PRINT 'Loading Bronze Layer';
        PRINT '=============================================================';

        PRINT  '------------------------------------------------------------';
        PRINT  '1. Loading Product Hierarchy Tables';
        PRINT  '------------------------------------------------------------';
        
        SET @start_time = GETDATE();
        PRINT'Truncating Table: bronze.DimProduct';
        TRUNCATE TABLE bronze.DimProduct;
        PRINT'Inserting Data Into: bronze.DimProduct';
        INSERT INTO bronze.DimProduct (
            ProductKey,
            ProductAlternateKey,
            ProductSubcategoryKey,
            WeightUnitMeasureCode,
            SizeUnitMeasureCode,
            EnglishProductName,
            SpanishProductName,
            FrenchProductName,
            StandardCost,
            FinishedGoodsFlag,
            Color,
            SafetyStockLevel,
            ReorderPoint,
            ListPrice,
            Size,
            SizeRange,
            Weight,
            DaysToManufacture,
            ProductLine,
            DealerPrice,
            Class,
            Style,
            ModelName ,
            LargePhoto ,
            EnglishDescription ,
            FrenchDescription ,
            ChineseDescription ,
            ArabicDescription ,
            HebrewDescription ,
            ThaiDescription ,
            GermanDescription,
            JapaneseDescription,
            TurkishDescription,
            StartDate,
            EndDate,
            Status
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
            StandardCost,
            FinishedGoodsFlag,
            Color,
            SafetyStockLevel,
            ReorderPoint,
            ListPrice,
            Size,
            SizeRange,
            Weight,
            DaysToManufacture,
            ProductLine,
            DealerPrice,
            Class,
            Style,
            ModelName ,
            LargePhoto ,
            EnglishDescription ,
            FrenchDescription ,
            ChineseDescription ,
            ArabicDescription ,
            HebrewDescription ,
            ThaiDescription ,
            GermanDescription,
            JapaneseDescription,
            TurkishDescription,
            StartDate,
            EndDate,
            Status
        FROM dbo.DimProduct
        PRINT'';
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '---------------------------';

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
        PRINT'';
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '---------------------------';

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
        PRINT '';
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '---------------------------';
        
        PRINT  '------------------------------------------------------------';
        PRINT  '2. Loading Custommer & Geography ables';
        PRINT  '------------------------------------------------------------';
    
        SET @start_time = GETDATE();
        PRINT'Truncating Table: bronze.DimCustomer';
        TRUNCATE TABLE bronze.DimCustomer;
        PRINT'Inserting Data Into: bronze.DimCustomer';
        INSERT INTO bronze.DimCustomer (
            CustomerKey,
            GeographyKey,
            CustomerAlternateKey,
            Title,
            FirstName,
            MiddleName,
            LastName,
            NameStyle,
            BirthDate,
            MaritalStatus,
            Suffix,
            Gender,
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
            AddressLine2,
            Phone,
            DateFirstPurchase,
            CommuteDistance
        )
        SELECT 
            CustomerKey,
            GeographyKey,
            CustomerAlternateKey,
            Title,
            FirstName,
            MiddleName,
            LastName,
            NameStyle,
            BirthDate,
            MaritalStatus,
            Suffix,
            Gender,
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
            AddressLine2,
            Phone,
            DateFirstPurchase,
            CommuteDistance
        FROM dbo.DimCustomer
        PRINT'';
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '---------------------------';

        SET @start_time = GETDATE();
        PRINT'Truncating Table: bronze.DimGeography';
        TRUNCATE TABLE bronze.DimGeography;
        PRINT'Inserting Data Into: bronze.DimGeography';
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
        PRINT '';
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '---------------------------';

        PRINT  '------------------------------------------------------------';
        PRINT  '3. Loading Employees & Date Tables';
        PRINT  '------------------------------------------------------------';

        SET @start_time = GETDATE();
        PRINT'Truncating Table: bronze.DimEmployee';
        TRUNCATE TABLE bronze.DimEmployee;
        PRINT'Inserting Data Into: bronze.DimEmployee';
        INSERT INTO bronze.DimEmployee (
            EmployeeKey,
            ParentEmployeeKey,
            EmployeeNationalIDAlternateKey,
            ParentEmployeeNationalIDAlternateKey,
            SalesTerritoryKey,
            FirstName,
            LastName,
            MiddleName,
            NameStyle,
            Title,
            HireDate,
            BirthDate,
            LoginID,
            EmailAddress,
            Phone,
            MaritalStatus,
            EmergencyContactName,
            EmergencyContactPhone,
            SalariedFlag,
            Gender,
            PayFrequency,
            BaseRate,
            VacationHours,
            SickLeaveHours,
            CurrentFlag,
            SalesPersonFlag,
            DepartmentName,
            StartDate,
            EndDate,
            Status,
            EmployeePhoto
        )
        SELECT 
            EmployeeKey,
            ParentEmployeeKey,
            EmployeeNationalIDAlternateKey,
            ParentEmployeeNationalIDAlternateKey,
            SalesTerritoryKey,
            FirstName,
            LastName,
            MiddleName,
            NameStyle,
            Title,
            HireDate,
            BirthDate,
            LoginID,
            EmailAddress,
            Phone,
            MaritalStatus,
            EmergencyContactName,
            EmergencyContactPhone,
            SalariedFlag,
            Gender,
            PayFrequency,
            BaseRate,
            VacationHours,
            SickLeaveHours,
            CurrentFlag,
            SalesPersonFlag,
            DepartmentName,
            StartDate,
            EndDate,
            Status,
            EmployeePhoto
        FROM dbo.DimEmployee
        PRINT'';
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '---------------------------';

        SET @end_time = GETDATE();
        PRINT'Truncating Table: bronze.DimDate';
        TRUNCATE TABLE bronze.DimDate;
        PRINT'Inserting Data Into: bronze.DimDate';
        INSERT INTO bronze.DimDate (
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
            FiscalSemester
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
            FiscalSemester
        FROM dbo.DimDate
        PRINT '';
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '---------------------------';

        PRINT  '------------------------------------------------------------';
        PRINT  '4. Loading Sales Transaction Tables';
        PRINT  '------------------------------------------------------------';
    
        SET @start_time = GETDATE();
        PRINT'Truncating Table: bronze.FactInternetSales';
        TRUNCATE TABLE bronze.FactInternetSales;
        PRINT'Inserting Data Into: bronze.FactInternetSales';
        INSERT INTO bronze.FactInternetSales(
            ProductKey,
            OrderDateKey,
            DueDateKey,
            ShipDateKey,
            CustomerKey,
            PromotionKey,
            CurrencyKey,
            SalesTerritoryKey,
            SalesOrderNumber,
            SalesOrderLineNumber,
            RevisionNumber,
            OrderQuantity,
            UnitPrice,
            ExtendedAmount,
            UnitPriceDiscountPct,
            DiscountAmount,
            ProductStandardCost,
            TotalProductCost,
            SalesAmount,
            TaxAmt,
            Freight,
            CarrierTrackingNumber,
            CustomerPONumber,
            OrderDate,
            DueDate,
            ShipDate
        )
        SELECT
            ProductKey,
            OrderDateKey,
            DueDateKey,
            ShipDateKey,
            CustomerKey,
            PromotionKey,
            CurrencyKey,
            SalesTerritoryKey,
            SalesOrderNumber,
            SalesOrderLineNumber,
            RevisionNumber,
            OrderQuantity,
            UnitPrice,
            ExtendedAmount,
            UnitPriceDiscountPct,
            DiscountAmount,
            ProductStandardCost,
            TotalProductCost,
            SalesAmount,
            TaxAmt,
            Freight,
            CarrierTrackingNumber,
            CustomerPONumber,
            OrderDate,
            DueDate,
            ShipDate
        FROM dbo.FactInternetSales
        PRINT'';
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '---------------------------';

        SET @start_time = GETDATE();
        PRINT'Truncating Table: bronze.FactResellerSales';
        TRUNCATE TABLE bronze.FactResellerSales;

        PRINT'Inserting Data Into: bronze.FactResellerSales';
        INSERT INTO bronze.FactResellerSales (
            ProductKey,
            DueDateKey,
            ShipDateKey,
            ResellerKey,
            EmployeeKey,
            PromotionKey,
            CurrencyKey ,
            SalesTerritoryKey,
            SalesOrderNumber,
            SalesOrderLineNumber,
            RevisionNumber,
            OrderQuantity,
            UnitPrice,
            ExtendedAmount,
            UnitPriceDiscountPct,
            DiscountAmount,
            ProductStandardCost,
            TotalProductCost,
            SalesAmount,
            TaxAmt,
            Freight,
            CarrierTrackingNumber,
            CustomerPONumber,
            OrderDate,
            DueDate,
            ShipDate
        )
        SELECT 
            ProductKey,
            DueDateKey,
            ShipDateKey,
            ResellerKey,
            EmployeeKey,
            PromotionKey,
            CurrencyKey ,
            SalesTerritoryKey,
            SalesOrderNumber,
            SalesOrderLineNumber,
            RevisionNumber,
            OrderQuantity,
            UnitPrice,
            ExtendedAmount,
            UnitPriceDiscountPct,
            DiscountAmount,
            ProductStandardCost,
            TotalProductCost,
            SalesAmount,
            TaxAmt,
            Freight,
            CarrierTrackingNumber,
            CustomerPONumber,
            OrderDate,
            DueDate,
            ShipDate
        FROM dbo.FactResellerSales
        PRINT '';
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '---------------------------';

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
        PRINT '';
        SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '---------------------------';

        SET @batch_end_time = GETDATE();
        PRINT '=============================================================';
        PRINT 'Loading Bronze Layer is completed'
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
        PRINT '=============================================================';
     END TRY
    BEGIN CATCH
        PRINT '=============================================================';
        PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER';
        PRINT 'Error Message' + ERROR_MESSAGE();
        PRINT 'Error Message' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Error Message' + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT '=============================================================';
    END CATCH
END