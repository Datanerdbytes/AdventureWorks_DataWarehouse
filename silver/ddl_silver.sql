/*
===================================================================================
DATA WAREHOUSE LIFECYCLE: SILVER SCHEMA DDL ARCHITECTURE
===================================================================================
Script Blueprint:  Create Silver Cleansed Layer Tables
Database Context:  AdventureWorksDW2022
Target Schema:     silver
Data Architecture: Medallion Architecture (Cleansed / Integrated Enterprise Truth)

Description:
    - This script initializes the physical storage structures for the Silver layer.
    - Implements a clean DROP-IF-EXISTS pattern to allow schema resets or design 
      modifications before data cleansing pipelines run.
    - Preserves historical key mappings passed from the Bronze layer to ensure 
      relational integrity across the data warehouse.

Metadata & Architecture Design Patterns:
    - Audit Traceability: Integrates a default system timestamp (`DWHCreateDate`) 
      on every table to track exactly when records enter the enterprise truth layer.
    - Data Governance: Serves as the backbone for downstream reporting by enforcing
      strongly typed columns, eliminating source ingestion metadata (like RowHashes),
      and paving the way for data standardizations.

Prerequisites / Usage:
    - The 'silver' database schema must exist prior to executing this script.
    - Warning: Running this script drops any existing physical Silver tables 
      and clears their structured contents.
===================================================================================
*/

USE AdventureWorksDW2022;
GO

-- =============================================================================
-- SECTION I: FACT TABLE LAYERS
-- =============================================================================

-- 1. Permanent Table for FactInternetSales
IF OBJECT_ID('silver.FactInternetSales', 'U') IS NOT NULL
    DROP TABLE silver.FactInternetSales;
GO

CREATE TABLE silver.FactInternetSales (
    ProductKey INT, OrderDateKey INT, DueDateKey INT, ShipDateKey INT, CustomerKey INT, PromotionKey INT, CurrencyKey INT,
    SalesTerritoryKey INT, SalesOrderNumber NVARCHAR(20),SalesOrderLineNumber TINYINT, RevisionNumber TINYINT, OrderQuantity SMALLINT,
    UnitPrice MONEY, ExtendedAmount MONEY, UnitPriceDiscountPct FLOAT, DiscountAmount FLOAT, ProductStandardCost MONEY, TotalProductCost MONEY,
    SalesAmount MONEY, GrossProfit DECIMAL(18,2), GrossProfitMargin DECIMAL(5,4), TaxAmt MONEY, Freight MONEY, CarrierTrackingNumber NVARCHAR(25), CustomerPONumber NVARCHAR(25),
    OrderDate DATETIME, DueDate DATETIME, ShipDate DATETIME, DWHCreateDate DATETIME2 DEFAULT GETDATE()
)

-- 2. Permanent Table for FactResellerSales
IF OBJECT_ID('silver.FactResellerSales', 'U') IS NOT NULL
    DROP TABLE silver.FactResellerSales;
GO

CREATE TABLE silver.FactResellerSales (
    ProductKey INT, OrderDateKey INT, DueDateKey INT, ShipDateKey INT, ResellerKey INT, EmployeeKey INT, PromotionKey INT,
    CurrencyKey INT, SalesTerritoryKey INT, SalesOrderNumber NVARCHAR(20), SalesOrderLineNumber TINYINT, RevisionNumber TINYINT,
    OrderQuantity SMALLINT, UnitPrice MONEY, ExtendedAmount MONEY, UnitPriceDiscountPct FLOAT, DiscountAmount FLOAT,
    ProductStandardCost MONEY, TotalProductCost MONEY, SalesAmount MONEY, GrossProfit DECIMAL(18,2), GrossProfitMargin DECIMAL(5,4), TaxAmt MONEY, Freight MONEY,
    CarrierTrackingNumber NVARCHAR(25), CustomerPONumber NVARCHAR(25), OrderDate DATETIME, DueDate DATETIME, ShipDate DATETIME,
    DWHCreateDate DATETIME2 DEFAULT GETDATE()
)

-- 3. Permanent Table for FactSalesQuota
IF OBJECT_ID('silver.FactSalesQuota', 'U') IS NOT NULL
    DROP TABLE silver.FactSalesQuota;
GO

CREATE TABLE silver.FactSalesQuota (
    SalesQuotaKey INT, EmployeeKey INT, DateKey INT, CalendarYear SMALLINT,  CalendarQuarter TINYINT,
    SalesAmountQuota MONEY, Date DATETIME, DWHCreateDate DATETIME2 DEFAULT GETDATE()
)

-- =============================================================================
-- SECTION II: DIMENSION TABLE STAGING LAYERS
-- =============================================================================

-- 4. Permanent Table for DimCustomer
IF OBJECT_ID('silver.DimCustomer', 'U') IS NOT NULL 
    DROP TABLE silver.DimCustomer ;
GO

CREATE TABLE silver.DimCustomer (
    CustomerKey INT, GeographyKey INT, CustomerAlternateKey NVARCHAR(15), Title NVARCHAR(8), FirstName NVARCHAR(50),
    MiddleName NVARCHAR(50), LastName NVARCHAR(50), FullName NVARCHAR(150), NameStyle BIT, BirthDate DATE, MaritalStatus NVARCHAR(20), Suffix NVARCHAR(10),
    Gender NVARCHAR(20), EmailAddress NVARCHAR(50), YearlyIncome MONEY, TotalChildren TINYINT, NumberChildrenAtHome TINYINT,
    EnglishEducation NVARCHAR(50), SpanishEducation NVARCHAR(50), FrenchEducation NVARCHAR(50), EnglishOccupation NVARCHAR(100),
    SpanishOccupation NVARCHAR(100), FrenchOccupation NVARCHAR(100), HouseOwnerFlag NCHAR(1), NumberCarsOwned TINYINT, AddressLine1 NVARCHAR(120),
    AddressLine2 NVARCHAR(120), Phone NVARCHAR(20), DateFirstPurchase DATE, CommuteDistance NVARCHAR(15), DWHCreateDate DATETIME2 DEFAULT GETDATE()
)

-- 5. Permanent Table for DimReseller
IF OBJECT_ID('silver.DimReseller', 'U') IS NOT NULL
    DROP TABLE silver.DimReseller;
GO

CREATE TABLE silver.DimReseller (
    ResellerKey INT, GeographyKey INT, ResellerAlternateKey NVARCHAR(15), Phone NVARCHAR(25), BusinessType VARCHAR(20),
    ResellerName NVARCHAR(50), NumberEmployees INT, OrderFrequency NVARCHAR(20), OrderMonth TINYINT, OrderMonthAbbr NVARCHAR(20), 
    FirstOrderYear INT, LastOrderYear INT, ProductLine NVARCHAR(50), AddressLine1 NVARCHAR(60), AddressLine2 NVARCHAR(60), 
    AnnualSales MONEY, BankName NVARCHAR(50), MinPaymentType NVARCHAR(20), MinPaymentAmount MONEY, AnnualRevenue MONEY, YearOpened INT,
    DWHCreateDate DATETIME2 DEFAULT GETDATE()
)

-- 6. Permanent Table for DimGeography
IF OBJECT_ID('silver.DimGeography', 'U') IS NOT NULL
    DROP TABLE silver.DimGeography;
GO

CREATE TABLE silver.DimGeography (
    GeographyKey INT, City NVARCHAR(30), StateProvinceCode NVARCHAR(3), StateProvinceName NVARCHAR(50), CountryRegionCode NVARCHAR(3),
    EnglishCountryRegionName NVARCHAR(50), SpanishCountryRegionName NVARCHAR(50), FrenchCountryRegionName NVARCHAR(50),
    PostalCode NVARCHAR(15), SalesTerritoryKey INT, IpAddressLocator NVARCHAR(15), DWHCreateDate DATETIME2 DEFAULT GETDATE()
)

-- 7. Permanent Table for DimSalesTerritory
IF OBJECT_ID('silver.DimSalesTerritory', 'U') IS NOT NULL
    DROP TABLE silver.DimSalesTerritory ;
GO

CREATE TABLE silver.DimSalesTerritory (
    SalesTerritoryKey INT, SalesTerritoryAlternateKey INT, SalesTerritoryRegion NVARCHAR(50), SalesTerritoryCountry NVARCHAR(50),
    SalesTerritoryGroup NVARCHAR(50), SalesTerritoryImage VARBINARY(MAX), DWHCreateDate DATETIME2 DEFAULT GETDATE()
)

-- 8. Permanent Table for DimProduct
IF OBJECT_ID('silver.DimProduct', 'U') IS NOT NULL
    DROP TABLE silver.DimProduct;
GO

CREATE TABLE silver.DimProduct (
    ProductKey INT, ProductAlternateKey NVARCHAR(25), ProductSubcategoryKey INT, WeightUnitMeasureCode NCHAR(3), SizeUnitMeasureCode NCHAR(3),
    EnglishProductName NVARCHAR(50), SpanishProductName NVARCHAR(50), FrenchProductName NVARCHAR(50), StandardCost MONEY,
    ProductType NVARCHAR(30), Color NVARCHAR(15), SafetyStockLevel SMALLINT, ReorderPoint SMALLINT, ListPrice MONEY, Size NVARCHAR(50),
    SizeRange NVARCHAR(50), Weight FLOAT, DaysToManufacture INT, ProductLine NVARCHAR(25), DealerPrice MONEY, ProductClass NVARCHAR(25), ProductStyle NVARCHAR(25),
    ModelName NVARCHAR(50), LargePhoto VARBINARY(MAX), EnglishDescription NVARCHAR(400), FrenchDescription NVARCHAR(400),
    ChineseDescription NVARCHAR(400), ArabicDescription NVARCHAR(400), HebrewDescription NVARCHAR(400), ThaiDescription NVARCHAR(400), GermanDescription NVARCHAR(400),
    JapaneseDescription NVARCHAR(400), TurkishDescription NVARCHAR(400), StartDate DATETIME, EndDate DATETIME, Status NVARCHAR(7), DWHCreateDate DATETIME2 DEFAULT GETDATE()
)

-- 9. Permanent Table for DimProductSubcategory
IF OBJECT_ID('silver.DimProductSubcategory', 'U') IS NOT NULL
    DROP TABLE silver.DimProductSubcategory;
GO

CREATE TABLE silver.DimProductSubcategory (
    ProductSubcategoryKey INT, ProductSubcategoryAlternateKey INT, EnglishProductSubcategoryName NVARCHAR(50),
    SpanishProductSubcategoryName NVARCHAR(50), FrenchProductSubcategoryName NVARCHAR(50),ProductCategoryKey INT,
    DWHCreateDate DATETIME2 DEFAULT GETDATE()
)

-- 10. Permanent Table for DimProductCategory
IF OBJECT_ID('silver.DimProductCategory', 'U') IS NOT NULL
    DROP TABLE silver.DimProductCategory;
GO

CREATE TABLE silver.DimProductCategory (
    ProductCategoryKey INT, ProductCategoryAlternateKey INT, EnglishProductCategoryName NVARCHAR(50), SpanishProductCategoryName NVARCHAR(50),
    FrenchProductCategoryName NVARCHAR(50), DWHCreateDate DATETIME2 DEFAULT GETDATE()
)

-- 11. Permanent Table for DimEmployee
IF OBJECT_ID('silver.DimEmployee', 'U') IS NOT NULL
    DROP TABLE silver.DimEmployee;
GO

CREATE TABLE silver.DimEmployee (
    EmployeeKey INT NOT NULL, ParentEmployeeKey INT NULL, EmployeeNationalIDAlternateKey NVARCHAR(15) NULL, ParentEmployeeNationalIDAlternateKey NVARCHAR(15) NULL,
    SalesTerritoryKey INT NULL, FirstName NVARCHAR(50) NULL, LastName NVARCHAR(50) NULL, MiddleName NVARCHAR(50) NULL, FullName NVARCHAR(150) NULL, NameStyle BIT NULL, Title NVARCHAR(50) NULL,
    HireDate DATE NULL, BirthDate DATE NULL, LoginID NVARCHAR(256) NULL, EmailAddress NVARCHAR(50) NULL, Phone NVARCHAR(25) NULL, MaritalStatus NVARCHAR(20) NULL,
    EmergencyContactName NVARCHAR(50) NULL, EmergencyContactPhone NVARCHAR(25) NULL, SalariedFlag NVARCHAR(20) NULL, Gender NVARCHAR(20) NULL, PayFrequency TINYINT,
    BaseRate MONEY NULL, VacationHours SMALLINT NULL, SickLeaveHours SMALLINT NULL, CurrentFlag NVARCHAR(20), SalesPersonFlag BIT NULL, DepartmentName NVARCHAR(50) NULL,
    StartDate DATE NULL, EndDate DATE NULL, Status NVARCHAR(50) NULL, EmployeePhoto VARBINARY(MAX) NULL , DWHCreateDate DATETIME2 DEFAULT GETDATE()
)

-- 12. Permanent Table Table for DimDate
IF OBJECT_ID('silver.DimDate', 'U') IS NOT NULL
DROP TABLE silver.DimDate;
GO

CREATE TABLE silver.DimDate (
    DateKey INT, FullDateAlternateKey DATE, DayNumberOfWeek TINYINT, EnglishDayNameOfWeek NVARCHAR(10), SpanishDayNameOfWeek NVARCHAR(10),
    FrenchDayNameOfWeek NVARCHAR(10), DayNumberOfMonth TINYINT, DayNumberOfYear SMALLINT, WeekNumberOfYear TINYINT, EnglishMonthName NVARCHAR(10), 
    SpanishMonthName NVARCHAR(10), FrenchMonthName NVARCHAR(10), MonthNumberOfYear TINYINT, CalendarQuarter TINYINT, CalendarYear SMALLINT,
    CalendarSemester TINYINT, FiscalQuarter TINYINT, FiscalYear SMALLINT, FiscalSemester TINYINT, DWHCreateDate DATETIME2 DEFAULT GETDATE()
)