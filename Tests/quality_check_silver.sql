/*
=============================================================
Data Quality Checks Silver Layer
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
FROM silver.DimEmployee
GROUP BY EmployeeKey
HAVING COUNT(*) > 1 OR EmployeeKey IS NULL

--  Check for unwanted spaces
-- Expectation: No Results
SELECT 
    EmergencyContactName
FROM silver.DimEmployee
WHERE EmergencyContactName != TRIM(EmergencyContactName)

-- Data standardization & consistency
SELECT DISTINCT MaritalStatus
FROM silver.DimEmployee

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
FROM silver.DimCustomer
GROUP BY CustomerKey
HAVING COUNT(*) > 1 OR CustomerKey IS NULL 

-- Check data integrity
-- Expectation: No Results
SELECT 
    CustomerKey
FROM silver.DimCustomer
WHERE CustomerKey NOT IN  (
    SELECT CustomerKey FROM silver.FactSalesQuota
)

--  Check for unwanted spaces
-- Expectation: No Results
SELECT 
    EmailAddress
FROM silver.DimCustomer
WHERE EmailAddress != TRIM(EmailAddress)

SELECT 
    CustomerKey
FROM silver.DimCustomer
WHERE CustomerKey NOT IN  (
    SELECT CustomerKey FROM silver.FactResellerSales
)

-- Check for NULLS or Negative Numbers
-- Expectation: No Results
SELECT 
    YearlyIncome
FROM silver.DimCustomer
WHERE YearlyIncome < 0 OR YearlyIncome IS NULL

-- Data Standardization & Consistency
SELECT DISTINCT Gender
FROM silver.DimCustomer

-- Final Look 
SELECT * FROM silver.DimCustomer

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
FROM silver.DimReseller
GROUP BY ResellerAlternateKey
HAVING COUNT(*) > 1 OR ResellerAlternateKey IS NULL 

-- Check for Nulls or Duplicates in PrimaryKey
-- Expectation: No Results
SELECT 
   ResellerKey,
   COUNT(*)
FROM silver.DimReseller
GROUP BY ResellerKey
HAVING COUNT(*) > 1 OR ResellerKey IS NULL


--  Check for unwanted spaces
-- Expectation: No Results
SELECT 
    BusinessType
FROM silver.DimReseller
WHERE BusinessType != TRIM(BusinessType)

-- Check for NULLS or Negative Numbers
-- Expectation: No Results
SELECT 
   AnnualRevenue
FROM silver.DimReseller
WHERE AnnualRevenue < 0 OR AnnualRevenue IS NULL

-- Data Standardization & Consistency
SELECT DISTINCT  MinPaymentType
FROM silver.DimReseller

SELECT * FROM silver.DimReseller

/*
-------------------------------------------------------------
4. DimGeography
-------------------------------------------------------------
*/

-- Verify Total of rows inserted
SELECT COUNT(*) FROM silver.DimGeography

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
FROM silver.DimProduct
GROUP BY ProductAlternateKey
HAVING COUNT(*) > 1 OR ProductAlternateKey IS NULL

-- Checks for Invalid Dates
-- Expectation: No Results
SELECT 
    StartDate,
    EndDate
FROM silver.DimProduct
WHERE EndDate < StartDate

-- Data Standardization & Consistency
SELECT DISTINCT  Style
FROM silver.DimProduct

SELECT * FROM silver.DimProduct


/*
-------------------------------------------------------------
5. DimProductSubcategory
-------------------------------------------------------------
*/

-- Check total rows inserted
SELECT COUNT(*) FROM silver.DimProductSubcategory

/*
-------------------------------------------------------------
5. DimProductCategory
-------------------------------------------------------------
*/

SELECT COUNT(*) FROM silver.DimProductCategory

/*
-------------------------------------------------------------
6. DimDate
-------------------------------------------------------------
*/
SELECT * FROM silver.DimDate

/*
-------------------------------------------------------------
7. FactInternetSaes
-------------------------------------------------------------
*/
-- Check integrity of FactInternetSales with silver.DimProduct
-- Expecation No Result
SELECT 
    ProductKey
FROM silver.FactInternetSales
WHERE ProductKey NOT IN (
    SELECT ProductKey FROM silver.DimProduct
)

-- Check integrity of FactInternetSales with silver.DimCustomer
-- Expecation No Result
SELECT 
    CustomerKey
FROM silver.FactInternetSales
WHERE CustomerKey NOT IN (
    SELECT CustomerKey FROM silver.DimCustomer
)

-- Check for Invalid Dates

SELECT 
    OrderDate
FROM silver.FactInternetSales
WHERE OrderDate > ShipDate OR OrderDate > DueDate

-- Check data consistency between OrderQuanty, UnitPrice, SalesAmount
SELECT DISTINCT 
    OrderQuantity,
    UnitPrice,
    SalesAmount
FROM silver.FactInternetSales
WHERE SalesAmount != OrderQuantity * SalesAmount
OR OrderQuantity IS NULL OR UnitPrice IS NULL OR SalesAmount IS NULL
OR OrderQuantity <= 0 OR UnitPrice <= 0 OR SalesAmount <= 0
ORDER BY OrderQuantity,  UnitPrice,  SalesAmount


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
FROM silver.FactSalesQuota
GROUP BY SalesQuotaKey
HAVING COUNT(*) > 1 OR SalesQuotaKey IS NULL

--Check for Negative Numbers or Nulls

SELECT 
    SalesAmountQuota
FROM silver.FactSalesQuota
WHERE SalesAmountQuota < 0

