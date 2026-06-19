/*
=============================================================================
DDL Script: Create Bronze Tables
=============================================================================
Script Purpose:
    - This script creates tables in the 'bronze' schema, dropping existing tables
    if they already exists.
    - The  script also creates a table for Audit Log to log peformance metrics 
    (BatchID, StartTime, EndTime, RowCount, Status) which can be used to track pipeline
    efficiency over time.

    
    Run this script to re-define the DDL structure of 'bronze' tables.
=============================================================================
*/

IF OBJECT_ID('bronze.FactInternetSales', 'U') IS NOT NULL
    DROP TABLE bronze.FactInternetSales;
GO

CREATE TABLE bronze.FactInternetSales (
    ProductKey INT,
    OrderDateKey INT,
    DueDateKey INT,
    ShipDateKey INT,
    CustomerKey INT,
    PromotionKey INT,
    CurrencyKey INT,
    SalesTerritoryKey INT,
    SalesOrderNumber NVARCHAR(20),
    SalesOrderLineNumber TINYINT,
    RevisionNumber TINYINT,
    OrderQuantity SMALLINT,
    UnitPrice MONEY,
    ExtendedAmount MONEY,
    UnitPriceDiscountPct FLOAT,
    DiscountAmount FLOAT,
    ProductStandardCost MONEY,
    TotalProductCost MONEY,
    SalesAmount MONEY,
    TaxAmt MONEY,
    Freight MONEY,
    CarrierTrackingNumber NVARCHAR(25),
    CustomerPONumber NVARCHAR(25),
    OrderDate DATETIME,
    DueDate DATETIME,
    ShipDate DATETIME
)

IF OBJECT_ID('bronze.FactResellerSales', 'U') IS NOT NULL
    DROP TABLE bronze.FactResellerSales;
GO

CREATE TABLE bronze.FactResellerSales (
    ProductKey INT,
    OrderDateKey INT,
    DueDateKey INT,
    ShipDateKey INT,
    ResellerKey INT,
    EmployeeKey INT,
    PromotionKey INT,
    CurrencyKey INT,
    SalesTerritoryKey INT,
    SalesOrderNumber NVARCHAR(20),
    SalesOrderLineNumber TINYINT,
    RevisionNumber TINYINT,
    OrderQuantity SMALLINT,
    UnitPrice MONEY,
    ExtendedAmount MONEY,
    UnitPriceDiscountPct FLOAT,
    DiscountAmount FLOAT,
    ProductStandardCost MONEY,
    TotalProductCost MONEY,
    SalesAmount MONEY,
    TaxAmt MONEY,
    Freight MONEY,
    CarrierTrackingNumber NVARCHAR(25),
    CustomerPONumber NVARCHAR(25),
    OrderDate DATETIME,
    DueDate DATETIME,
    ShipDate DATETIME,
)

IF OBJECT_ID('bronze.FactSalesQuota', 'U') IS NOT NULL
    DROP TABLE bronze.FactSalesQuota;
GO

CREATE TABLE bronze.FactSalesQuota (
    SalesQuotaKey INT,
    EmployeeKey INT,
    DateKey INT,
    CalendarYear SMALLINT,
    CalendarQuarter TINYINT,
    SalesAmountQuota MONEY,
    Date DATETIME
) 

IF OBJECT_ID('bronze.DimCustomer', 'U') IS NOT NULL 
    DROP TABLE bronze.DimCustomer ;
GO

CREATE TABLE bronze.DimCustomer (
    CustomerKey INT,
    GeographyKey INT,
    CustomerAlternateKey NVARCHAR(15),
    Title NVARCHAR(8),
    FirstName NVARCHAR(50),
    MiddleName NVARCHAR(50),
    LastName NVARCHAR(50),
    NameStyle BIT,
    BirthDate DATE,
    MaritalStatus NCHAR(1),
    Suffix NVARCHAR(10),
    Gender NVARCHAR(1),
    EmailAddress NVARCHAR(50),
    YearlyIncome MONEY,
    TotalChildren TINYINT,
    NumberChildrenAtHome TINYINT,
    EnglishEducation NVARCHAR(50),
    SpanishEducation NVARCHAR(50),
    FrenchEducation NVARCHAR(50),
    EnglishOccupation NVARCHAR(100),
    SpanishOccupation NVARCHAR(100),
    FrenchOccupation NVARCHAR(100),
    HouseOwnerFlag NCHAR(1),
    NumberCarsOwned TINYINT,
    AddressLine1 NVARCHAR(120),
    AddressLine2 NVARCHAR(120),
    Phone NVARCHAR(20),
    DateFirstPurchase DATE,
    CommuteDistance NVARCHAR(15),
    RowHash BINARY(32) NULL
)

IF OBJECT_ID('bronze.DimReseller', 'U') IS NOT NULL
    DROP TABLE bronze.DimReseller;
GO

CREATE TABLE bronze.DimReseller (
    ResellerKey INT,
    GeographyKey INT,
    ResellerAlternateKey NVARCHAR(15),
    Phone NVARCHAR(25),
    BusinessType VARCHAR(20),
    ResellerName NVARCHAR(50),
    NumberEmployees INT,
    OrderFrequency CHAR(1),
    OrderMonth TINYINT,
    FirstOrderYear INT,
    LastOrderYear INT,
    ProductLine NVARCHAR(50),
    AddressLine1 NVARCHAR(60),
    AddressLine2 NVARCHAR(60),
    AnnualSales MONEY,
    BankName NVARCHAR(50),
    MinPaymentType TINYINT,
    MinPaymentAmount MONEY,
    AnnualRevenue MONEY,
    YearOpened INT,
    RowHash BINARY(32) NULL
)

IF OBJECT_ID('bronze.DimGeography', 'U') IS NOT NULL
    DROP TABLE bronze.DimGeography;
GO

CREATE TABLE bronze.DimGeography (
    GeographyKey INT,
    City NVARCHAR(30),
    StateProvinceCode NVARCHAR(3),
    StateProvinceName NVARCHAR(50),
    CountryRegionCode NVARCHAR(3),
    EnglishCountryRegionName NVARCHAR(50),
    SpanishCountryRegionName NVARCHAR(50),
    FrenchCountryRegionName NVARCHAR(50),
    PostalCode NVARCHAR(15),
    SalesTerritoryKey INT,
    IpAddressLocator NVARCHAR(15),
    RowHash BINARY(32) NULL
)

IF OBJECT_ID('bronze.DimSalesTerritory', 'U') IS NOT NULL
    DROP TABLE bronze.DimSalesTerritory ;
GO

CREATE TABLE bronze.DimSalesTerritory (
    SalesTerritoryKey INT,
    SalesTerritoryAlternateKey INT,
    SalesTerritoryRegion NVARCHAR(50),
    SalesTerritoryCountry NVARCHAR(50),
    SalesTerritoryGroup NVARCHAR(50),
    SalesTerritoryImage VARBINARY(MAX),
    RowHash BINARY(32) NULL
)

IF OBJECT_ID('bronze.DimProduct', 'U') IS NOT NULL
    DROP TABLE bronze.DimProduct;
GO

CREATE TABLE bronze.DimProduct (
    ProductKey INT,
    ProductAlternateKey NVARCHAR(25),
    ProductSubcategoryKey INT,
    WeightUnitMeasureCode NCHAR(3),
    SizeUnitMeasureCode NCHAR(3),
    EnglishProductName NVARCHAR(50),
    SpanishProductName NVARCHAR(50),
    FrenchProductName NVARCHAR(50),
    StandardCost MONEY,
    FinishedGoodsFlag BIT,
    Color NVARCHAR(15),
    SafetyStockLevel SMALLINT,
    ReorderPoint SMALLINT,
    ListPrice MONEY,
    Size NVARCHAR(50),
    SizeRange NVARCHAR(50),
    Weight FLOAT,
    DaysToManufacture INT,
    ProductLine NCHAR(2),
    DealerPrice MONEY,
    Class NCHAR(2),
    Style NCHAR(2),
    ModelName NVARCHAR(50),
    LargePhoto VARBINARY(MAX),
    EnglishDescription NVARCHAR(400),
    FrenchDescription NVARCHAR(400),
    ChineseDescription NVARCHAR(400),
    ArabicDescription NVARCHAR(400),
    HebrewDescription NVARCHAR(400),
    ThaiDescription NVARCHAR(400),
    GermanDescription NVARCHAR(400),
    JapaneseDescription NVARCHAR(400),
    TurkishDescription NVARCHAR(400),
    StartDate DATETIME,
    EndDate DATETIME,
    Status NVARCHAR(7),
    RowHash BINARY(32) NULL
)

IF OBJECT_ID('bronze.DimProductSubcategory', 'U') IS NOT NULL
    DROP TABLE bronze.DimProductSubcategory;
GO

CREATE TABLE bronze.DimProductSubcategory (
    ProductSubcategoryKey INT,
    ProductSubcategoryAlternateKey INT,
    EnglishProductSubcategoryName NVARCHAR(50),
    SpanishProductSubcategoryName NVARCHAR(50),
    FrenchProductSubcategoryName NVARCHAR(50),
    ProductCategoryKey INT,
    RowHash BINARY(32) NULL
)

IF OBJECT_ID('bronze.DimProductCategory', 'U') IS NOT NULL
    DROP TABLE bronze.DimProductCategory;
GO

CREATE TABLE bronze.DimProductCategory (
    ProductCategoryKey INT,
    ProductCategoryAlternateKey INT,
    EnglishProductCategoryName NVARCHAR(50),
    SpanishProductCategoryName NVARCHAR(50),
    FrenchProductCategoryName NVARCHAR(50),
    RowHash BINARY(32) NULL
)

IF OBJECT_ID('bronze.DimDate', 'U') IS NOT NULL
DROP TABLE bronze.DimDate;
GO

CREATE TABLE bronze.DimDate (
    DateKey INT,
    FullDateAlternateKey DATE,
    DayNumberOfWeek TINYINT,
    EnglishDayNameOfWeek NVARCHAR(10),
    SpanishDayNameOfWeek NVARCHAR(10),
    FrenchDayNameOfWeek NVARCHAR(10),
    DayNumberOfMonth TINYINT,
    DayNumberOfYear SMALLINT,
    WeekNumberOfYear TINYINT,
    EnglishMonthName NVARCHAR(10),
    SpanishMonthName NVARCHAR(10),
    FrenchMonthName NVARCHAR(10),
    MonthNumberOfYear TINYINT,
    CalendarQuarter TINYINT,
    CalendarYear SMALLINT,
    CalendarSemester TINYINT,
    FiscalQuarter TINYINT,
    FiscalYear SMALLINT,
    FiscalSemester TINYINT,
    RowHash BINARY(32) NULL
)

IF OBJECT_ID('bronze.DimEmployee', 'U') IS NOT NULL
    DROP TABLE bronze.DimEmployee;
GO

CREATE TABLE bronze.DimEmployee (
    EmployeeKey INT,
    ParentEmployeeKey INT,
    EmployeeNationalIDAlternateKey NVARCHAR(15),
    ParentEmployeeNationalIDAlternateKey NVARCHAR(15),
    SalesTerritoryKey INt,
    FirstName NVARCHAR(50),
    LastName NVARCHAR(50),
    MiddleName NVARCHAR(50),
    NameStyle BIT,
    Title NVARCHAR(50),
    HireDate DATE,
    BirthDate DATE,
    LoginID NVARCHAR(256),
    EmailAddress NVARCHAR(50),
    Phone NVARCHAR(25),
    MaritalStatus NCHAR(1),
    EmergencyContactName NVARCHAR(50),
    EmergencyContactPhone NVARCHAR(25),
    SalariedFlag BIT,
    Gender NCHAR(1),
    PayFrequency TINYINT,
    BaseRate MONEY,
    VacationHours SMALLINT,
    SickLeaveHours SMALLINT,
    CurrentFlag BIT,
    SalesPersonFlag BIT,
    DepartmentName NVARCHAR(50),
    StartDate DATE,
    EndDate DATE,
    Status NVARCHAR(50),
    EmployeePhoto VARBINARY(MAX),
    RowHash BINARY(32) NULL
)

/*
===================================================================
Auditing logs Tables
===================================================================
*/
IF OBJECT_ID('bronze.Pipeline_Log', 'U') IS NOT NULL
    DROP TABLE bronze.Pipeline_Log;
GO

CREATE TABLE bronze.Pipeline_Log (
    LogID INT IDENTITY(180,1) PRIMARY KEY,
    TableName VARCHAR(100),
    StartTime DATETIME,
    EndTime DATETIME,
    DurationSeconds INT,
    RowsInserted INT,
    Status VARCHAR(20),
    ErrorMessage NVARCHAR(MAX) NULL
)

/*
===================================================================
Date WaterMarks Tables
===================================================================
*/

IF OBJECT_ID('bronze.Pipeline_Watermarks', 'U') IS NOT NULL
    DROP TABLE bronze.Pipeline_Watermarks;
GO

CREATE TABLE bronze.Pipeline_Watermarks (
    TableName VARCHAR(100) PRIMARY KEY,
    LastLoadedDate DATETIME NOT NULL
);