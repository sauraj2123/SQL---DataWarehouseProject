/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver) (PostgreSQL)
===============================================================================
What this procedure does:
    For each silver table:
      1. Empties the table (TRUNCATE).
      2. Reads the bronze table, cleans the data and inserts it.
      3. Prints how many rows were loaded and how long it took.

Run the bronze load first, then:
    CALL silver.load_silver();
===============================================================================
*/

CREATE OR REPLACE PROCEDURE silver.load_silver()
LANGUAGE plpgsql
AS $$
DECLARE
    batch_start TIMESTAMPTZ;  -- when the whole load started
    start_time  TIMESTAMPTZ;  -- when the current table started
    row_count   INT;          -- rows loaded into the current table
BEGIN
    batch_start := clock_timestamp();
    RAISE NOTICE '================================================';
    RAISE NOTICE 'Loading Silver Layer';
    RAISE NOTICE '================================================';

    RAISE NOTICE '------------------------------------------------';
    RAISE NOTICE 'Loading CRM Tables';
    RAISE NOTICE '------------------------------------------------';

    -- -------------------------------------------------------------------------
    -- silver.crm_cust_info
    -- Keep only the newest row per customer, trim names,
    -- and turn single-letter codes into readable words.
    -- -------------------------------------------------------------------------
    start_time := clock_timestamp();
    TRUNCATE TABLE silver.crm_cust_info;
    INSERT INTO silver.crm_cust_info (
        cst_id,
        cst_key,
        cst_firstname,
        cst_lastname,
        cst_marital_status,
        cst_gndr,
        cst_create_date
    )
    SELECT
        cst_id,
        cst_key,
        TRIM(cst_firstname) AS cst_firstname,  -- remove extra spaces
        TRIM(cst_lastname)  AS cst_lastname,
        CASE
            WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
            WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
            ELSE 'n/a'
        END AS cst_marital_status,
        CASE
            WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
            WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
            ELSE 'n/a'
        END AS cst_gndr,
        cst_create_date
    FROM (
        -- Number each customer's rows, newest first
        SELECT
            *,
            ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
        FROM bronze.crm_cust_info
        WHERE cst_id IS NOT NULL
    ) t
    WHERE flag_last = 1;  -- keep only the newest row
    GET DIAGNOSTICS row_count = ROW_COUNT;
    RAISE NOTICE '>> silver.crm_cust_info: % rows in % sec', row_count,
        ROUND(EXTRACT(EPOCH FROM clock_timestamp() - start_time)::NUMERIC, 2);

    -- -------------------------------------------------------------------------
    -- silver.crm_prd_info
    -- Split prd_key into category id + product key, replace missing cost
    -- with 0, spell out product line, and rebuild end dates so product
    -- history periods never overlap.
    -- -------------------------------------------------------------------------
    start_time := clock_timestamp();
    TRUNCATE TABLE silver.crm_prd_info;
    INSERT INTO silver.crm_prd_info (
        prd_id,
        cat_id,
        prd_key,
        prd_nm,
        prd_cost,
        prd_line,
        prd_start_dt,
        prd_end_dt
    )
    SELECT
        prd_id,
        REPLACE(SUBSTRING(prd_key FROM 1 FOR 5), '-', '_') AS cat_id,  -- first 5 chars, e.g. 'CO_RF'
        SUBSTRING(prd_key FROM 7)                          AS prd_key, -- rest of the key
        prd_nm,
        COALESCE(prd_cost, 0) AS prd_cost,                             -- missing cost -> 0
        CASE UPPER(TRIM(prd_line))
            WHEN 'M' THEN 'Mountain'
            WHEN 'R' THEN 'Road'
            WHEN 'S' THEN 'Other Sales'
            WHEN 'T' THEN 'Touring'
            ELSE 'n/a'
        END AS prd_line,
        prd_start_dt::DATE AS prd_start_dt,
        -- End date = one day before the next version of the same product starts
        (LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)
            - INTERVAL '1 day')::DATE AS prd_end_dt
    FROM bronze.crm_prd_info;
    GET DIAGNOSTICS row_count = ROW_COUNT;
    RAISE NOTICE '>> silver.crm_prd_info: % rows in % sec', row_count,
        ROUND(EXTRACT(EPOCH FROM clock_timestamp() - start_time)::NUMERIC, 2);

    -- -------------------------------------------------------------------------
    -- silver.crm_sales_details
    -- Convert number dates (20101229) to real dates, and fix bad
    -- sales / price values using: sales = quantity * price.
    -- -------------------------------------------------------------------------
    start_time := clock_timestamp();
    TRUNCATE TABLE silver.crm_sales_details;
    INSERT INTO silver.crm_sales_details (
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,
        sls_order_dt,
        sls_ship_dt,
        sls_due_dt,
        sls_sales,
        sls_quantity,
        sls_price
    )
    SELECT
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,
        -- 0 or not 8 digits = invalid date -> NULL
        CASE
            WHEN sls_order_dt = 0 OR LENGTH(sls_order_dt::TEXT) != 8 THEN NULL
            ELSE TO_DATE(sls_order_dt::TEXT, 'YYYYMMDD')
        END AS sls_order_dt,
        CASE
            WHEN sls_ship_dt = 0 OR LENGTH(sls_ship_dt::TEXT) != 8 THEN NULL
            ELSE TO_DATE(sls_ship_dt::TEXT, 'YYYYMMDD')
        END AS sls_ship_dt,
        CASE
            WHEN sls_due_dt = 0 OR LENGTH(sls_due_dt::TEXT) != 8 THEN NULL
            ELSE TO_DATE(sls_due_dt::TEXT, 'YYYYMMDD')
        END AS sls_due_dt,
        -- Missing, negative or wrong sales -> recalculate from quantity * price
        CASE
            WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
                THEN sls_quantity * ABS(sls_price)
            ELSE sls_sales
        END AS sls_sales,
        sls_quantity,
        -- Missing or negative price -> work it out from sales / quantity
        CASE
            WHEN sls_price IS NULL OR sls_price <= 0
                THEN sls_sales / NULLIF(sls_quantity, 0)
            ELSE sls_price
        END AS sls_price
    FROM bronze.crm_sales_details;
    GET DIAGNOSTICS row_count = ROW_COUNT;
    RAISE NOTICE '>> silver.crm_sales_details: % rows in % sec', row_count,
        ROUND(EXTRACT(EPOCH FROM clock_timestamp() - start_time)::NUMERIC, 2);

    RAISE NOTICE '------------------------------------------------';
    RAISE NOTICE 'Loading ERP Tables';
    RAISE NOTICE '------------------------------------------------';

    -- -------------------------------------------------------------------------
    -- silver.erp_cust_az12
    -- Remove the 'NAS' prefix so ids match CRM, blank out future
    -- birthdates, and standardise gender.
    -- -------------------------------------------------------------------------
    start_time := clock_timestamp();
    TRUNCATE TABLE silver.erp_cust_az12;
    INSERT INTO silver.erp_cust_az12 (
        cid,
        bdate,
        gen
    )
    SELECT
        CASE
            WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid FROM 4)  -- drop 'NAS' prefix
            ELSE cid
        END AS cid,
        CASE
            WHEN bdate > CURRENT_DATE THEN NULL               -- future birthdate is invalid
            ELSE bdate
        END AS bdate,
        CASE
            WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
            WHEN UPPER(TRIM(gen)) IN ('M', 'MALE')   THEN 'Male'
            ELSE 'n/a'
        END AS gen
    FROM bronze.erp_cust_az12;
    GET DIAGNOSTICS row_count = ROW_COUNT;
    RAISE NOTICE '>> silver.erp_cust_az12: % rows in % sec', row_count,
        ROUND(EXTRACT(EPOCH FROM clock_timestamp() - start_time)::NUMERIC, 2);

    -- -------------------------------------------------------------------------
    -- silver.erp_loc_a101
    -- Remove dashes from ids so they match CRM, and spell out country codes.
    -- -------------------------------------------------------------------------
    start_time := clock_timestamp();
    TRUNCATE TABLE silver.erp_loc_a101;
    INSERT INTO silver.erp_loc_a101 (
        cid,
        cntry
    )
    SELECT
        REPLACE(cid, '-', '') AS cid,  -- 'AW-00011000' -> 'AW00011000'
        CASE
            WHEN TRIM(cntry) = 'DE'                 THEN 'Germany'
            WHEN TRIM(cntry) IN ('US', 'USA')       THEN 'United States'
            WHEN TRIM(cntry) = '' OR cntry IS NULL  THEN 'n/a'
            ELSE TRIM(cntry)
        END AS cntry
    FROM bronze.erp_loc_a101;
    GET DIAGNOSTICS row_count = ROW_COUNT;
    RAISE NOTICE '>> silver.erp_loc_a101: % rows in % sec', row_count,
        ROUND(EXTRACT(EPOCH FROM clock_timestamp() - start_time)::NUMERIC, 2);

    -- -------------------------------------------------------------------------
    -- silver.erp_px_cat_g1v2
    -- Data is already clean, so copy it across as-is.
    -- -------------------------------------------------------------------------
    start_time := clock_timestamp();
    TRUNCATE TABLE silver.erp_px_cat_g1v2;
    INSERT INTO silver.erp_px_cat_g1v2 (
        id,
        cat,
        subcat,
        maintenance
    )
    SELECT
        id,
        cat,
        subcat,
        maintenance
    FROM bronze.erp_px_cat_g1v2;
    GET DIAGNOSTICS row_count = ROW_COUNT;
    RAISE NOTICE '>> silver.erp_px_cat_g1v2: % rows in % sec', row_count,
        ROUND(EXTRACT(EPOCH FROM clock_timestamp() - start_time)::NUMERIC, 2);

    RAISE NOTICE '================================================';
    RAISE NOTICE 'Silver Layer loaded. Total time: % sec',
        ROUND(EXTRACT(EPOCH FROM clock_timestamp() - batch_start)::NUMERIC, 2);
    RAISE NOTICE '================================================';

EXCEPTION
    -- If anything fails, all changes are rolled back and the error is shown
    WHEN OTHERS THEN
        RAISE NOTICE '================================================';
        RAISE NOTICE 'ERROR WHILE LOADING SILVER LAYER';
        RAISE NOTICE 'Message: %', SQLERRM;
        RAISE NOTICE 'Code:    %', SQLSTATE;
        RAISE NOTICE '================================================';
END;
$$;
