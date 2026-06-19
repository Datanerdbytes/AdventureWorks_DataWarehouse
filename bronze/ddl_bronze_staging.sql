/*
================================================================================
DDL Script: Create Staging Layers (Bronze Schema)
================================================================================
Database Context: AdventureWorksDW2022
Layer Description: Bronze Staging Layer (Transient / Landing Pads)
Script Purpose:
    - Drops existing transient staging tables safely using conditional checks.
    - Re-defines the physical structures (`STG_`) under the 'bronze' schema.
    - Preserves data engineering columns (`SourceHash`) for upsert pattern support.
    
Execution Note:
    - This script only impacts staging structures. It does not affect final 
      permanent storage bronze target layers.
================================================================================
*/

USE AdventureWorksDW2022;
GO

-- =============================================================================
-- SECTION I: FACT TABLE STAGING LAYERS
-- =============================================================================

-- 1. Staging for FactInternetSales
IF OBJECT_ID('bronze.STG_FactInternetSales', 'U') IS NOT NULL
    DROP TABLE bronze.STG_FactInternetSales;
GO

CREATE TABLE bronze.STG_FactInternetSales (
    ProductKey INT, OrderDateKey INT, DueDateKey INT, ShipDateKey INT, CustomerKey INT, PromotionKey INT,
    CurrencyKey INT, SalesTerritoryKey INT, SalesOrderNumber NVARCHAR(20), SalesOrderLineNumber TINYINT,
    RevisionNumber TINYINT, OrderQuantity SMALLINT, UnitPrice MONEY, ExtendedAmount MONEY,
    UnitPriceDiscountPct FLOAT, DiscountAmount FLOAT, ProductStandardCost MONEY, TotalProductCost MONEY,
    SalesAmount MONEY, TaxAmt MONEY, Freight MONEY, CarrierTrackingNumber NVARCHAR(25), CustomerPONumber NVARCHAR(25),
    OrderDate DATETIME, DueDate DATETIME, ShipDate DATETIME
);

-- 2. Staging for FactResellerSales
IF OBJECT_ID('bronze.STG_FactResellerSales', 'U') IS NOT NULL 
    DROP TABLE bronze.STG_FactResellerSales;
GO

CREATE TABLE bronze.STG_FactResellerSales (
    ProductKey INT, OrderDateKey INT, DueDateKey INT, ShipDateKey INT, ResellerKey INT, EmployeeKey INT, PromotionKey INT,
    CurrencyKey INT, SalesTerritoryKey INT, SalesOrderNumber NVARCHAR(20), SalesOrderLineNumber TINYINT, RevisionNumber TINYINT,
    OrderQuantity SMALLINT, UnitPrice MONEY, ExtendedAmount MONEY, UnitPriceDiscountPct FLOAT, DiscountAmount FLOAT,
    ProductStandardCost MONEY, TotalProductCost MONEY, SalesAmount MONEY, TaxAmt MONEY, Freight MONEY, CarrierTrackingNumber NVARCHAR(25),
    CustomerPONumber NVARCHAR(25), OrderDate DATETIME, DueDate DATETIME, ShipDate DATETIME
);

-- 3. Staging for FactSalesQuota
IF OBJECT_ID('bronze.STG_FactSalesQuota', 'U') IS NOT NULL
    DROP TABLE bronze.STG_FactSalesQuota;
GO

CREATE TABLE bronze.STG_FactSalesQuota (
    SalesQuotaKey INT, EmployeeKey INT, DateKey INT, CalendarYear SMALLINT, CalendarQuarter TINYINT, SalesAmountQuota MONEY, Date DATETIME
);


-- =============================================================================
-- SECTION II: DIMENSION TABLE STAGING LAYERS (Hash-Upsert Supported)
-- =============================================================================

-- 4. Staging for DimCustomer
IF OBJECT_ID('bronze.STG_DimCustomer', 'U') IS NOT NULL
    DROP TABLE bronze.STG_DimCustomer;
GO

CREATE TABLE bronze.STG_DimCustomer (
    CustomerKey INT, GeographyKey INT, CustomerAlternateKey NVARCHAR(15), Title NVARCHAR(8), FirstName NVARCHAR(50),
    MiddleName NVARCHAR(50), LastName NVARCHAR(50), NameStyle BIT, BirthDate DATE, MaritalStatus NCHAR(1),
    Suffix NVARCHAR(10), Gender NVARCHAR(1), EmailAddress NVARCHAR(50), YearlyIncome MONEY, TotalChildren TINYINT,
    NumberChildrenAtHome TINYINT, EnglishEducation NVARCHAR(50), SpanishEducation NVARCHAR(50), FrenchEducation NVARCHAR(50),
    EnglishOccupation NVARCHAR(100), SpanishOccupation NVARCHAR(100), FrenchOccupation NVARCHAR(100), HouseOwnerFlag NCHAR(1),
    NumberCarsOwned TINYINT, AddressLine1 NVARCHAR(120), AddressLine2 NVARCHAR(120), Phone NVARCHAR(20), DateFirstPurchase DATE,
    CommuteDistance NVARCHAR(15), SourceHash BINARY(32) NULL
);

-- 5. Staging for DimReseller
IF OBJECT_ID('bronze.STG_DimReseller', 'U') IS NOT NULL 
    DROP TABLE bronze.STG_DimReseller;
GO

CREATE TABLE bronze.STG_DimReseller (
    ResellerKey INT, GeographyKey INT, ResellerAlternateKey NVARCHAR(15), Phone NVARCHAR(25), BusinessType VARCHAR(20),
    ResellerName NVARCHAR(50), NumberEmployees INT, OrderFrequency CHAR(1), OrderMonth TINYINT, FirstOrderYear INT, LastOrderYear INT,
    ProductLine NVARCHAR(50), AddressLine1 NVARCHAR(60), AddressLine2 NVARCHAR(60), AnnualSales MONEY, BankName NVARCHAR(50),
    MinPaymentType TINYINT, MinPaymentAmount MONEY, AnnualRevenue MONEY, YearOpened INT, SourceHash BINARY(32) NULL
);

-- 6. Staging for DimGeography
IF OBJECT_ID('bronze.STG_DimGeography', 'U') IS NOT NULL 
    DROP TABLE bronze.STG_DimGeography;
GO

CREATE TABLE bronze.STG_DimGeography (
    GeographyKey INT, City NVARCHAR(30), StateProvinceCode NVARCHAR(3), StateProvinceName NVARCHAR(50), CountryRegionCode NVARCHAR(3),
    EnglishCountryRegionName NVARCHAR(50), SpanishCountryRegionName NVARCHAR(50), FrenchCountryRegionName NVARCHAR(50),
    PostalCode NVARCHAR(15), SalesTerritoryKey INT, IpAddressLocator NVARCHAR(15), SourceHash BINARY(32) NULL
);

-- 7. Staging for DimSalesTerritory
IF OBJECT_ID('bronze.STG_DimSalesTerritory', 'U') IS NOT NULL
    DROP TABLE bronze.STG_DimSalesTerritory;
GO

CREATE TABLE bronze.STG_DimSalesTerritory (
    SalesTerritoryKey INT, SalesTerritoryAlternateKey INT, SalesTerritoryRegion NVARCHAR(50), SalesTerritoryCountry NVARCHAR(50),
    SalesTerritoryGroup NVARCHAR(50), SalesTerritoryImage VARBINARY(MAX), SourceHash BINARY(32) NULL
);

-- 8. Staging for DimProduct
IF OBJECT_ID('bronze.STG_DimProduct', 'U') IS NOT NULL
    DROP TABLE bronze.STG_DimProduct;
GO

CREATE TABLE bronze.STG_DimProduct (
    ProductKey INT, ProductAlternateKey NVARCHAR(25), ProductSubcategoryKey INT, WeightUnitMeasureCode NCHAR(3),
    SizeUnitMeasureCode NCHAR(3), EnglishProductName NVARCHAR(50), SpanishProductName NVARCHAR(50), FrenchProductName NVARCHAR(50),
    StandardCost MONEY, FinishedGoodsFlag BIT, Color NVARCHAR(15), SafetyStockLevel SMALLINT, ReorderPoint SMALLINT,
    ListPrice MONEY, Size NVARCHAR(50), SizeRange NVARCHAR(50), Weight FLOAT, DaysToManufacture INT, ProductLine NCHAR(2),
    DealerPrice MONEY, Class NCHAR(2), Style NCHAR(2), ModelName NVARCHAR(50), LargePhoto VARBINARY(MAX), EnglishDescription NVARCHAR(400),
    FrenchDescription NVARCHAR(400), ChineseDescription NVARCHAR(400), ArabicDescription NVARCHAR(400), HebrewDescription NVARCHAR(400),
    ThaiDescription NVARCHAR(400), GermanDescription NVARCHAR(400), JapaneseDescription NVARCHAR(400), TurkishDescription NVARCHAR(400),
    StartDate DATETIME, EndDate DATETIME, Status NVARCHAR(7), SourceHash BINARY(32) NULL
);

-- 9. Staging for DimProductSubcategory
IF OBJECT_ID('bronze.STG_DimProductSubcategory', 'U') IS NOT NULL
    DROP TABLE bronze.STG_DimProductSubcategory;
GO

CREATE TABLE bronze.STG_DimProductSubcategory (
    ProductSubcategoryKey INT, ProductSubcategoryAlternateKey INT, EnglishProductSubcategoryName NVARCHAR(50),
    SpanishProductSubcategoryName NVARCHAR(50), FrenchProductSubcategoryName NVARCHAR(50), ProductCategoryKey INT,
    SourceHash BINARY(32) NULL
);

-- 10. Staging for DimProductCategory
IF OBJECT_ID('bronze.STG_DimProductCategory', 'U') IS NOT NULL 
    DROP TABLE bronze.STG_DimProductCategory;
GO

CREATE TABLE bronze.STG_DimProductCategory (
    ProductCategoryKey INT, ProductCategoryAlternateKey INT, EnglishProductCategoryName NVARCHAR(50),
    SpanishProductCategoryName NVARCHAR(50), FrenchProductCategoryName NVARCHAR(50), SourceHash BINARY(32) NULL
);

-- 11. Staging for DimEmployee
IF OBJECT_ID('bronze.STG_DimEmployee', 'U') IS NOT NULL
    DROP TABLE bronze.STG_DimEmployee;
GO

CREATE TABLE bronze.STG_DimEmployee (
    EmployeeKey INT, ParentEmployeeKey INT, EmployeeNationalIDAlternateKey NVARCHAR(15), ParentEmployeeNationalIDAlternateKey NVARCHAR(15),
    SalesTerritoryKey INT, FirstName NVARCHAR(50), LastName NVARCHAR(50), MiddleName NVARCHAR(50), NameStyle BIT, Title NVARCHAR(50),
    HireDate DATE, BirthDate DATE, LoginID NVARCHAR(256), EmailAddress NVARCHAR(50), Phone NVARCHAR(25), MaritalStatus NCHAR(1),
    EmergencyContactName NVARCHAR(50), EmergencyContactPhone NVARCHAR(25), SalariedFlag BIT, Gender NCHAR(1), PayFrequency TINYINT,
    BaseRate MONEY, VacationHours SMALLINT, SickLeaveHours SMALLINT, CurrentFlag BIT, SalesPersonFlag BIT, DepartmentName NVARCHAR(50),
    StartDate DATE, EndDate DATE, Status NVARCHAR(50), EmployeePhoto VARBINARY(MAX), SourceHash BINARY(32) NULL
);

-- 12. Staging for DimDate
IF OBJECT_ID('bronze.STG_DimDate', 'U') IS NOT NULL
    DROP TABLE bronze.STG_DimDate;
GO

CREATE TABLE bronze.STG_DimDate (
    DateKey INT, FullDateAlternateKey DATE, DayNumberOfWeek TINYINT, EnglishDayNameOfWeek NVARCHAR(10), SpanishDayNameOfWeek NVARCHAR(10),
    FrenchDayNameOfWeek NVARCHAR(10), DayNumberOfMonth TINYINT, DayNumberOfYear SMALLINT, WeekNumberOfYear TINYINT, EnglishMonthName NVARCHAR(10),
    SpanishMonthName NVARCHAR(10), FrenchMonthName NVARCHAR(10), MonthNumberOfYear TINYINT, CalendarQuarter TINYINT,
    CalendarYear SMALLINT, CalendarSemester TINYINT, FiscalQuarter TINYINT, FiscalYear SMALLINT, FiscalSemester TINYINT,
    SourceHash BINARY(32) NULL
);