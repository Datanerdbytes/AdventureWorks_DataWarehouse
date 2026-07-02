/*
===================================================================================
ORCHESTRATION PIPELINE LAYER: SILVER FACTS INCREMENTAL EXTRACT, TRANSFORM, & LOAD (ETL)
===================================================================================
Procedure Name: silver.load_silver_facts_incremental
Layer Rank:     Silver Layer (Data Quality, Governance, business Logic, & Margins)
Target Tables:  - silver.FactInternetSales  (Incremental Append via Composite Key)
                - silver.FactResellerSales  (Incremental Append via Composite Key)
                - silver.FactSalesQuota     (Incremental Append via Primary Key)

Architectural Design Patterns Implemented:
    1. STATE-BASED HIGH WATERMARK LOGIC:
       - Dynamically tracks delta progression via bronze.Pipeline_Watermarks.
       - Implements dual-layered NULL containment ('1900-01-01' fallback variables)
         to protect logic evaluation if the core ingestion storage layer is cleared.
    2. DATA DECOUPLING VIA INTERMEDIARY STAGING:
       - Uses transaction-scoped truncation on transient staging structures 
         (bronze.STG_*) to isolate incoming boundaries before final ingestion.
    3. RIGOROUS DATA CLEANSING & CALCULATION DEFENSE:
       - Recomputes missing unit prices and derived sales metrics dynamically.
       - Implements business cost models: TotalProductCost = Quantity * StandardCost.
       - Protects financial arithmetic against NULL propagation via ISNULL() injection.
    4. ENTERPRISE BUSINESS INTELLIGENCE DERIVATIONS:
       - Programmatically computes GrossProfit ($) and GrossProfitMargin (%) metrics.
       - Uses NULLIF() division-by-zero guardrails to shield performance models.
    5. TRANSACTIONAL BOUNDARY PROTECTION:
       - Wrapped inside ATOMIC explicit transactions with active state validation (XACT_STATE()).
       - Centralized logging telemetry logs success/failure states to bronze.Pipeline_Log.

Execution Dependency:
    - MUST run AFTER dimension processing completes successfully (silver.load_silver_dimensions).
===================================================================================
*/

CREATE OR ALTER PROCEDURE silver.load_silver_facts_incremental AS
BEGIN
     -- Configure SQL Server environment settings
     SET NOCOUNT ON;
     SET XACT_ABORT ON;

    DECLARE @batch_start_time DATETIME, @batch_end_time DATETIME;
    DECLARE @start_time DATETIME, @end_time DATETIME;
    DECLARE @rows_affected INT;
    DECLARE @LastWaterMark DATETIME;

    BEGIN TRY
        SET @batch_start_time = GETDATE();
        BEGIN TRANSACTION;

        PRINT '==================================================================';
        PRINT 'Executing Incremental Load for Fact Tables For Silver Layer';
        PRINT '==================================================================';

        /* 
        ==========================================================================
            1. INCREMENTAL LOAD: FactInternetSales
        ==========================================================================
        */

        PRINT '-----------------------------------------';
        PRINT 'Loading FactInternetSales';
        PRINT '-----------------------------------------';
        PRINT '';

        SET @start_time = GETDATE();

        -- If tracking is empty AND bronze is empty, fall back to a safe baseline date
        SELECT @LastWaterMark = ISNULL(
                    (SELECT LastLoadedDate FROM bronze.Pipeline_Watermarks WHERE TableName = 'silver.FactInternetSales'),
                    ISNULL((SELECT MIN(OrderDate) FROM bronze.FactInternetSales), '1900-01-01')
                );

        PRINT 'Truncating Staging Table: bronze.STG_FactInternetSales';
        TRUNCATE TABLE bronze.STG_FactInternetSales;

        PRINT 'Extracting new delta rows into staging table: bronze.STG_FactInternetSales';
        INSERT INTO bronze.STG_FactInternetSales 
        SELECT * FROM bronze.FactInternetSales WHERE OrderDate >= @LastWaterMark;
        
        PRINT 'Inserting new data into final table: silver.FactInternetSales';
        INSERT INTO silver.FactInternetSales (
            ProductKey, OrderDateKey, DueDateKey, ShipDateKey, CustomerKey, PromotionKey, CurrencyKey,
            SalesTerritoryKey, SalesOrderNumber, SalesOrderLineNumber, RevisionNumber, OrderQuantity,
            UnitPrice, ExtendedAmount, UnitPriceDiscountPct, DiscountAmount, ProductStandardCost, TotalProductCost,
            SalesAmount, GrossProfit, GrossProfitMargin, TaxAmt, Freight, CarrierTrackingNumber, CustomerPONumber, OrderDate, DueDate, 
            ShipDate, DWHCreateDate
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
            CASE WHEN UnitPrice IS NULL OR UnitPrice <= 0
                THEN SalesAmount / NULLIF(OrderQuantity,0)
                ELSE UnitPrice 
            END AS UnitPrice,
            CASE WHEN ExtendedAmount IS NULL OR ExtendedAmount <=0 OR ExtendedAmount != OrderQuantity * ABS(UnitPrice)
                 THEN OrderQuantity * ABS(UnitPrice)
            ELSE ExtendedAmount 
            END AS ExtendedAmount,
            UnitPriceDiscountPct, 
            DiscountAmount, 
            ISNULL(ProductStandardCost,0) AS ProductStandardCost,
            CASE WHEN TotalProductCost IS NULL OR TotalProductCost <= 0 OR TotalProductCost != OrderQuantity * ISNULL(ProductStandardCost,0)
                 THEN OrderQuantity * ISNULL(ProductStandardCost,0)
            ELSE TotalProductCost 
            END AS TotalProductCost,
            CASE WHEN SalesAmount IS NULL OR SalesAmount <= 0 OR SalesAmount != (OrderQuantity * ABS(UnitPrice)) - ISNULL(DiscountAmount,0)
                THEN (OrderQuantity * ABS(UnitPrice)) - ISNULL(DiscountAmount,0)
                ELSE SalesAmount
            END AS SalesAmount,
            (SalesAmount - TotalProductCost) AS GrossProfit,
            CASE 
                WHEN SalesAmount = 0 THEN 0
                ELSE ROUND((SalesAmount - TotalProductCost) /  NULLIF(SalesAmount,0),4)
            END AS GrossProfitMargin,
            TaxAmt, 
            Freight, 
            CarrierTrackingNumber, 
            CustomerPONumber, 
            OrderDate, 
            DueDate, 
            ShipDate, 
            GETDATE() AS DWHCreateDate
        FROM bronze.STG_FactInternetSales stg
        WHERE NOT EXISTS (
            SELECT 1 FROM silver.FactInternetSales s  
            WHERE s.SalesOrderNumber = stg.SalesOrderNumber
            AND   s.SalesOrderLineNumber = stg.SalesOrderLineNumber
        );

        SELECT @rows_affected = @@ROWCOUNT;

        UPDATE bronze.Pipeline_Watermarks
        SET LastLoadedDate = ISNULL((SELECT MAX(OrderDate) FROM bronze.STG_FactInternetSales), @LastWaterMark)
        WHERE TableName = 'silver.FactInternetSales';

        -- If the table layout tracking row didn't exist yet, insert baseline row entry
        IF @@ROWCOUNT = 0
        BEGIN
            INSERT INTO bronze.Pipeline_Watermarks (TableName, LastLoadedDate)
            VALUES (
                'silver.FactInternetSales', 
                ISNULL((SELECT MAX(OrderDate) FROM bronze.STG_FactInternetSales), @LastWaterMark)
            );
        END;

         -- Audit Log Entry
        SET @end_time = GETDATE();
        INSERT INTO bronze.Pipeline_Log VALUES ('silver.FactInternetSales (Incremental)', @start_time, @end_time, DATEDIFF(second, @start_time, @end_time), @rows_affected, 'SUCCESS', NULL);

        PRINT'';
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> Rows affected: ' + CAST(@rows_affected  AS NVARCHAR);
        PRINT '---------------------------';

         /* 
         ==========================================================================
            2. INCREMENTAL LOAD: FactResellerSales
        ==========================================================================
        */

        PRINT '-----------------------------------------';
        PRINT 'Loading FactResellerSales';
        PRINT '-----------------------------------------';

        SET @start_time  = GETDATE();

        -- If tracking is empty AND bronze is empty, fall back to a safe baseline date
        SELECT @LastWaterMark = ISNULL(
                (SELECT LastLoadedDate FROM bronze.Pipeline_Watermarks WHERE TableName = 'silver.FactResellerSales'),
                ISNULL((SELECT MIN(OrderDate) FROM bronze.FactResellerSales), '1900-01-01')
        );

        -- Empty Staging
        PRINT 'Truncating Staging Table: bronze.STG_FactResellerSales';
        TRUNCATE TABLE bronze.STG_FactResellerSales;

        PRINT 'Extracting new delta rows into staging table: bronze.STG_FactResellerSales';
        INSERT INTO bronze.STG_FactResellerSales
        SELECT * FROM bronze.FactResellerSales WHERE OrderDate >= @LastWaterMark;

        PRINT 'Inserting new data into final table: silver.FactResellerSales';
         -- Safe Append: Only insert rows that don't already exist in Bronze (composite key check)
        INSERT INTO silver.FactResellerSales (
            ProductKey, OrderDateKey, DueDateKey, ShipDateKey, ResellerKey, EmployeeKey, PromotionKey,
            CurrencyKey, SalesTerritoryKey, SalesOrderNumber, SalesOrderLineNumber, RevisionNumber,
            OrderQuantity, UnitPrice, ExtendedAmount, UnitPriceDiscountPct, DiscountAmount,
            ProductStandardCost, TotalProductCost, SalesAmount, GrossProfit, GrossProfitMargin, TaxAmt, Freight,
            CarrierTrackingNumber, CustomerPONumber, OrderDate, DueDate, ShipDate, DWHCreateDate
        )
        SELECT 
            ProductKey,
            OrderDateKey,
            DueDateKey,
            ShipDateKey,
            ResellerKey,
            EmployeeKey,
            PromotionKey,
            CurrencyKey,
            SalesTerritoryKey,
            SalesOrderNumber,
            SalesOrderLineNumber,
            RevisionNumber,
            OrderQuantity,
            CASE WHEN UnitPrice IS NULL OR UnitPrice <= 0
                THEN SalesAmount / NULLIF(OrderQuantity,0)
            ELSE UnitPrice END AS UnitPrice,
            CASE 
                WHEN ExtendedAmount IS NULL OR ExtendedAmount <= 0 OR ExtendedAmount != OrderQuantity * ABS(UnitPrice)
                THEN OrderQuantity * ABS(UnitPrice)
            ELSE ExtendedAmount END AS ExtendedAmount,
            UnitPriceDiscountPct,
            DiscountAmount,
            ISNULL(ProductStandardCost,0) AS ProductStandardCost,
            CASE WHEN TotalProductCost IS NULL OR TotalProductCost <= 0 OR TotalProductCost != OrderQuantity * ISNULL(ProductStandardCost,0)
                 THEN OrderQuantity * ISNULL(ProductStandardCost,0)
            ELSE TotalProductCost END AS TotaLProductCost,
            CASE 
                WHEN SalesAmount IS NULL OR SalesAmount <= 0 OR SalesAmount != (OrderQuantity * ABS(UnitPrice)) - ISNULL(DiscountAmount,0)
                THEN ROUND((OrderQuantity * ABS(UnitPrice)) - ISNULL(DiscountAmount,0),2)
            ELSE SalesAmount END AS SalesAmount,
            (SalesAmount - TotalProductCost) AS GrossProfit,
            CASE 
                WHEN SalesAmount = 0 THEN 0
                ELSE ROUND((SalesAmount - TotalProductCost) / NULLIF(SalesAmount, 0),4)
            END AS GrosProfitMargin,
            TaxAmt,
            Freight,
            CarrierTrackingNumber,
            CustomerPONumber,
            OrderDate,
            DueDate,
            ShipDate,
            GETDATE() AS DWHCreateDate
        FROM bronze.STG_FactResellerSales stg 
        WHERE NOT EXISTS (
            SELECT 1 FROM silver.FactResellerSales s
            WHERE s.SalesOrderNumber = stg.SalesOrderNumber
            AND  s.SalesOrderLineNumber = stg.SalesOrderLineNumber
        );

        SELECT @rows_affected = @@ROWCOUNT;

        UPDATE bronze.Pipeline_Watermarks
        SET LastLoadedDate = (SELECT ISNULL(MAX(OrderDate), @LastWaterMark) FROM bronze.STG_FactResellerSales)
        WHERE TableName = 'silver.FactResellerSales';

        IF @@ROWCOUNT = 0
        BEGIN
            INSERT INTO bronze.Pipeline_Watermarks (TableName, LastLoadedDate)
            VALUES (
                'silver.FactResellerSales', 
                (SELECT ISNULL(MAX(OrderDate), @LastWaterMark) FROM bronze.STG_FactResellerSales)
            );
        END;

        --Audit log
        SET @end_time = GETDATE();
        INSERT INTO bronze.Pipeline_Log VALUES('silver.FactResellerSales (Incremental)', @start_time, @end_time, DATEDIFF(second, @start_time, @end_time),@rows_affected, 'SUCCESS',NULL);

        PRINT'';
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> Rows affected: ' + CAST(@rows_affected  AS NVARCHAR);
        PRINT '---------------------------';

         /* 
         ==========================================================================
            3. INCREMENTAL LOAD: FactSalesQuota
         ==========================================================================
        */

        PRINT '-----------------------------------------';
        PRINT 'Loading FactSalesQuota';
        PRINT '-----------------------------------------';

        SET @start_time = GETDATE();

        -- Select Watermark
        SELECT @LastWaterMark = ISNULL(
            (SELECT LastLoadedDate FROM bronze.Pipeline_Watermarks WHERE TableName = 'silver.FactSalesQuota'),
            ISNULL((SELECT MIN(Date) FROM bronze.FactSalesQuota),'1900-01-01')
        );

        --Empty Staging
        PRINT 'Truncating Staging Table: bronze.STG_FactSalesQuota';
        TRUNCATE TABLE bronze.STG_FactSalesQuota;

        PRINT 'Extracting new delta rows into staging table: bronze.STG_FactSalesQuota';
        INSERT INTO bronze.STG_FactSalesQuota
        SELECT * FROM bronze.FactSalesQuota WHERE Date >= @LastWaterMark;

        PRINT 'Inserting new data into final table: silver.FactSalesQuota';
        -- Safe Append: Protect target table layout from duplicates
        INSERT INTO silver.FactSalesQuota (
            SalesQuotaKey, EmployeeKey, DateKey, CalendarYear, CalendarQuarter,
            SalesAmountQuota, Date, DWHCreateDate
        )
        SELECT 
            SalesQuotaKey,
            EmployeeKey,
            DateKey,
            CalendarYear,
            CalendarQuarter,
            CASE 
                WHEN SalesAmountQuota IS NULL OR SalesAmountQuota < 0 THEN 0
                ELSE SalesAmountQuota
            END AS SalesAmountQuota,
            [Date],
            GETDATE() AS DWHCreateDate     
        FROM bronze.STG_FactSalesQuota stg 
        WHERE NOT EXISTS (
            SELECT 1 FROM silver.FactSalesQuota s
            WHERE s.SalesQuotaKey = stg.SalesQuotaKey
        );

        SELECT @rows_affected = @@ROWCOUNT;

        -- Update Watermark tracking metrics safely
        UPDATE bronze.Pipeline_Watermarks
        SET LastLoadedDate = ISNULL((SELECT MAX(DATE) FROM bronze.STG_FactSalesQuota), @LastWaterMark)
        WHERE TableName = 'silver.FactSalesQuota';

        IF @@ROWCOUNT = 0
        BEGIN
            INSERT INTO bronze.Pipeline_Watermarks (TableName, LastLoadedDate)
            VALUES (
                'silver.FactSalesQuota',
                ISNULL((SELECT MAX(Date) FROM bronze.STG_FactSalesQuota), @LastWaterMark)
            );
        END

        -- Audit Log Entry
        SET @end_time = GETDATE();
        INSERT INTO bronze.Pipeline_Log VALUES ('silver.FactSalesQuota (Incremental)', @start_time, @end_time, DATEDIFF(second, @start_time, @end_time), @rows_affected, 'SUCCESS',NULL);

        PRINT'';
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        PRINT '>> Rows affected: ' + CAST(@rows_affected  AS NVARCHAR);
        PRINT '---------------------------';

        /* ==========================================================================
               PIPELINE COMMIT & GLOBAL BATCH METRICS
        =========================================================================
        */
        COMMIT TRANSACTION;

        SET @batch_end_time = GETDATE();

        -- FIXED: Changed log text to state 'BATCH_TOTAL_SILVER_INCREMENTAL' to align with layer processing
        INSERT INTO bronze.Pipeline_Log VALUES ('BATCH_TOTAL_SILVER_INCREMENTAL', @batch_start_time, @batch_end_time, DATEDIFF(second, @batch_start_time, @batch_end_time), NULL, 'SUCCESS', NULL);

        /*
        =========================================================================
        Automate Log Retention: Permamently deletes any logs older than  30 days.
        =========================================================================
        */

        /* Log Retention Housekeeping */
        DELETE FROM bronze.Pipeline_Log
        WHERE StartTime < DATEADD(day, -30, GETDATE());

        PRINT '=============================================================';
        PRINT 'Loading Fact Tables to Silver Layer is completed'
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' seconds';
        PRINT '=============================================================';

    END TRY
    BEGIN CATCH
        IF (XACT_STATE()) = -1 OR @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        INSERT INTO bronze.Pipeline_Log VALUES (
            'BATCH_INCREMENTAL_FAILURE', @batch_start_time, GETDATE(), NULL, NULL, 'FAILED',
            'ERROR: ' + CAST(ERROR_NUMBER() AS VARCHAR) + ': '  + ERROR_MESSAGE()
        );
        THROW;
    END CATCH
END;