CREATE OR ALTER PROCEDURE bronze.load_bronze AS 
BEGIN
    PRINT '=============================================================';
    PRINT 'Loading Bronze Layer';
    PRINT '=============================================================';

    PRINT  '------------------------------------------------------------';
    PRINT  '1. Loading Product Hierarchy Tables';
    PRINT  '------------------------------------------------------------';
    TRUNCATE TABLE bronze.DimProduct;

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

    TRUNCATE TABLE bronze.DimProductSubcategory;

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

    TRUNCATE TABLE bronze.DimProductCategory;

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

    PRINT  '------------------------------------------------------------';
    PRINT  '2. Loading Custommer & Geography ables';
    PRINT  '------------------------------------------------------------';

    TRUNCATE TABLE bronze.DimCustomer;

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


    TRUNCATE TABLE bronze.DimGeography;

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

    PRINT  '------------------------------------------------------------';
    PRINT  '3. Loading Employees & Date Tables';
    PRINT  '------------------------------------------------------------';

    TRUNCATE TABLE bronze.DimEmployee;

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


    TRUNCATE TABLE bronze.DimDate;

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

    PRINT  '------------------------------------------------------------';
    PRINT  '4. Loading Sales Transaction Tables';
    PRINT  '------------------------------------------------------------';
   
    TRUNCATE TABLE bronze.FactInternetSales;

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

    TRUNCATE TABLE bronze.FactResellerSales;

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

    TRUNCATE TABLE bronze.FactSalesQuota;

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
END