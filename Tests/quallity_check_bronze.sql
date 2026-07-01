/*
=============================================================
Data Quality Checks Bronze Layer
=============================================================
*/
/*
-------------------------------------------------------------
1. DimEmployee
-------------------------------------------------------------
*/
-- Check for Nulls or Duplicates in PrimaryKey
-- Expectation: No Results

SELECT 
EmployeeKey,
COUNT(*)
FROM bronze.DimEmployee
GROUP BY EmployeeKey
HAVING COUNT(*) > 1 OR EmployeeKey IS NULL

--  Check for unwanted spaces
-- Expectation: No Results
SELECT 
    EmergencyContactName
FROM bronze.DimEmployee
WHERE EmergencyContactName != TRIM(EmergencyContactName)

-- Data standardization & consistency
SELECT DISTINCT MaritalStatus
FROM bronze.DimEmployee

-- Check for Invalid Dates
SELECT *
FROM bronze.DimEmployee
WHERE EndDate < StartDate OR BirthDate > HireDate

--Check for Negative Numbers or Nulls
SELECT 
    *
FROM bronze.DimEmployee
WHERE BaseRate < 0

/*
-------------------------------------------------------------
2. DimCustomer
-------------------------------------------------------------
*/

-- Check for Nulls or Duplicates in PrimaryKey
-- Expectation: No Results
SELECT 
    CustomerKey,
    COUNT(*)
FROM bronze.DimCustomer
GROUP BY CustomerKey
HAVING COUNT(*) > 1 OR CustomerKey IS NULL 

-- Check data integrity
-- Expectation: No Results
SELECT 
    CustomerKey
FROM bronze.DimCustomer
WHERE CustomerKey NOT IN  (
    SELECT CustomerKey FROM bronze.FactSalesQuota
)

--  Check for unwanted spaces
-- Expectation: No Results
SELECT 
    EmailAddress
FROM bronze.DimCustomer
WHERE EmailAddress != TRIM(EmailAddress)

SELECT 
    CustomerKey
FROM bronze.DimCustomer
WHERE CustomerKey NOT IN  (
    SELECT CustomerKey FROM bronze.FactResellerSales
)

-- Check for NULLS or Negative Numbers
-- Expectation: No Results
SELECT 
    YearlyIncome
FROM bronze.DimCustomer
WHERE YearlyIncome < 0 OR YearlyIncome IS NULL

-- Data Standardization & Consistency
SELECT DISTINCT Gender
FROM bronze.DimCustomer

/*
-------------------------------------------------------------
3. DimReseller
-------------------------------------------------------------
*/

-- Check for Nulls or Duplicates in PrimaryKey
-- Expectation: No Results
SELECT 
    ResellerAlternateKey,
    COUNT(*)
FROM bronze.DimReseller
GROUP BY ResellerAlternateKey
HAVING COUNT(*) > 1 OR ResellerAlternateKey IS NULL 

-- Check for Nulls or Duplicates in PrimaryKey
-- Expectation: No Results
SELECT 
   ResellerKey,
   COUNT(*)
FROM bronze.DimReseller
GROUP BY ResellerKey
HAVING COUNT(*) > 1 OR ResellerKey IS NULL


--  Check for unwanted spaces
-- Expectation: No Results
SELECT 
    BusinessType
FROM bronze.DimReseller
WHERE BusinessType != TRIM(BusinessType)

-- Check for NULLS or Negative Numbers
-- Expectation: No Results
SELECT 
   AnnualRevenue
FROM bronze.DimReseller
WHERE AnnualRevenue < 0 OR AnnualRevenue IS NULL

-- Data Standardization & Consistency
SELECT DISTINCT  MinPaymentType
FROM bronze.DimReseller

/*
-------------------------------------------------------------
5. DimProduct
-------------------------------------------------------------
*/

-- Check for Nulls or Duplicates in PrimaryKey
-- Expectation: Many Duplicates, product table keeps historical data.

SELECT 
 ProductAlternateKey,
 COUNT(*) 
FROM bronze.DimProduct
GROUP BY ProductAlternateKey
HAVING COUNT(*) > 1 OR ProductAlternateKey IS NULL

-- Checks for Invalid Dates
-- Expectation: No Results
SELECT 
    StartDate,
    EndDate
FROM bronze.DimProduct
WHERE EndDate < StartDate

-- Data Standardization & Consistency
SELECT DISTINCT  Style
FROM bronze.DimProduct

/*
-------------------------------------------------------------
6. DimProductSubcategory
-------------------------------------------------------------
*/


-- Check for Nulls or Duplicates in PrimaryKey
-- Expectation: No Results

SELECT 
    ProductSubcategoryAlternateKey,
    COUNT(*)
FROM bronze.DimProductSubcategory
GROUP BY ProductSubcategoryAlternateKey
HAVING COUNT(*) > 1 OR ProductSubcategoryAlternateKey IS NULL

-- Check for unwanted spaces
SELECT 
    EnglishProductSubcategoryName
FROM bronze.DimProductSubcategory
WHERE EnglishProductSubcategoryName != TRIM(EnglishProductSubcategoryName)

/*
-------------------------------------------------------------
7. FactInternetSaes
-------------------------------------------------------------
*/
-- Check integrity of FactInternetSales with silver.DimProduct
-- Expecation No Result
SELECT 
    ProductKey
FROM bronze.FactInternetSales
WHERE ProductKey NOT IN (
    SELECT ProductKey FROM silver.DimProduct
)

-- Check integrity of FactInternetSales with silver.DimCustomer
-- Expecation No Result
SELECT 
    CustomerKey
FROM bronze.FactInternetSales
WHERE CustomerKey NOT IN (
    SELECT CustomerKey FROM silver.DimCustomer
)

-- Check for Invalid Dates

SELECT 
    OrderDate
FROM bronze.FactInternetSales
WHERE OrderDate > ShipDate OR OrderDate > DueDate

-- Check data consistency between OrderQuanty, UnitPrice, SalesAmount
SELECT DISTINCT 
    OrderQuantity,
    UnitPrice,
    SalesAmount
FROM bronze.FactInternetSales
WHERE SalesAmount != OrderQuantity * UnitPrice
OR OrderQuantity IS NULL OR UnitPrice IS NULL OR SalesAmount IS NULL
OR OrderQuantity <= 0 OR UnitPrice <= 0 OR SalesAmount <= 0
ORDER BY OrderQuantity,  UnitPrice,  SalesAmount


/*
-------------------------------------------------------------
8. FactResellerKey
-------------------------------------------------------------
*/

-- Check for invalid dates
SELECT 
    OrderDate
FROM bronze.FactResellerSales
WHERE OrderDate > ShipDate OR OrderDate > DueDate

-- Check data consistency between OrderQuanty, UnitPrice, SalesAmount

SELECT 
    OrderQuantity,
    UnitPrice,
    ExtendedAmount,
    ProductStandardCost,
    TotalProductCost,
    SalesAmount AS old_SalesAmount,
    CASE WHEN SalesAmount IS NULL OR SalesAmount <= 0 OR SalesAmount != OrderQuantity * ABS(UnitPrice)
                THEN  OrderQuantity * ABS(UnitPrice)
            ELSE SalesAmount END AS SalesAmount,
    TaxAmt,
    Freight
FROM bronze.FactResellerSales
WHERE SalesAmount != OrderQuantity * UnitPrice
OR OrderQuantity IS NULL OR UnitPrice IS NULL OR ExtendedAmount IS NULL OR ProductStandardCost IS NULL OR TotalProductCost IS NULL OR SalesAmount IS NULL OR TaxAmt IS NULL OR Freight IS NULL
OR OrderQuantity <= 0 OR UnitPrice <= 0 OR ExtendedAmount <= 0 OR ProductStandardCost <= 0 
OR TotalProductCost <= 0 OR SalesAmount <= 0 OR TaxAmt <= 0 OR Freight <= 0 

SELECT * FROM bronze.DimEmployee


/*
-------------------------------------------------------------
9. FactSalesQuota
-------------------------------------------------------------
*/

-- Check for Nulls or Duplicates in PrimaryKey
-- Expectation: No Results

SELECT 
    SalesQuotaKey,
    COUNT(*)
FROM bronze.FactSalesQuota
GROUP BY SalesQuotaKey
HAVING COUNT(*) > 1 OR SalesQuotaKey IS NULL

--Check for Negative Numbers or Nulls

SELECT 
    SalesAmountQuota
FROM bronze.FactSalesQuota
WHERE SalesAmountQuota < 0

