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


