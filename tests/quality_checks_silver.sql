/*
===============================================================================
Quality Checks: Silver Layer (PostgreSQL)
===============================================================================
What this script does:
    Runs checks on the silver tables after loading. It looks for:
      - NULL or duplicate primary keys
      - Extra spaces in text
      - Inconsistent values (codes, categories)
      - Invalid or out-of-order dates
      - Sales that do not equal quantity * price

How to use:
    Run each query after CALL silver.load_silver();
    Most checks should return NO rows. If a check returns rows, investigate.
===============================================================================
*/

-- ============================================================================
-- silver.crm_cust_info
-- ============================================================================

-- NULL or duplicate customer ids. Expect: no rows
SELECT
    cst_id,
    COUNT(*)
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- Extra spaces in customer key. Expect: no rows
SELECT
    cst_key
FROM silver.crm_cust_info
WHERE cst_key != TRIM(cst_key);

-- List marital status values. Expect: Single, Married, n/a
SELECT DISTINCT
    cst_marital_status
FROM silver.crm_cust_info;

-- ============================================================================
-- silver.crm_prd_info
-- ============================================================================

-- NULL or duplicate product ids. Expect: no rows
SELECT
    prd_id,
    COUNT(*)
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;

-- Extra spaces in product name. Expect: no rows
SELECT
    prd_nm
FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);

-- NULL or negative cost. Expect: no rows
SELECT
    prd_cost
FROM silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL;

-- List product line values. Expect: Mountain, Road, Other Sales, Touring, n/a
SELECT DISTINCT
    prd_line
FROM silver.crm_prd_info;

-- End date before start date. Expect: no rows
SELECT
    *
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt;

-- ============================================================================
-- silver.crm_sales_details
-- ============================================================================

-- Invalid number dates in the BRONZE source (shows what silver had to fix)
SELECT
    NULLIF(sls_due_dt, 0) AS sls_due_dt
FROM bronze.crm_sales_details
WHERE sls_due_dt <= 0
    OR LENGTH(sls_due_dt::TEXT) != 8
    OR sls_due_dt > 20500101
    OR sls_due_dt < 19000101;

-- Order date after ship or due date. Expect: no rows
SELECT
    *
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt
   OR sls_order_dt > sls_due_dt;

-- Sales must equal quantity * price, and none can be NULL, zero or negative.
-- Expect: no rows
SELECT DISTINCT
    sls_sales,
    sls_quantity,
    sls_price
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
   OR sls_sales IS NULL
   OR sls_quantity IS NULL
   OR sls_price IS NULL
   OR sls_sales <= 0
   OR sls_quantity <= 0
   OR sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price;

-- ============================================================================
-- silver.erp_cust_az12
-- ============================================================================

-- Birthdates that are too old or in the future.
-- Expect: only very old dates (future dates were set to NULL)
SELECT DISTINCT
    bdate
FROM silver.erp_cust_az12
WHERE bdate < '1924-01-01'
   OR bdate > CURRENT_DATE;

-- List gender values. Expect: Male, Female, n/a
SELECT DISTINCT
    gen
FROM silver.erp_cust_az12;

-- ============================================================================
-- silver.erp_loc_a101
-- ============================================================================

-- List country values. Expect: full country names and n/a, no codes
SELECT DISTINCT
    cntry
FROM silver.erp_loc_a101
ORDER BY cntry;

-- ============================================================================
-- silver.erp_px_cat_g1v2
-- ============================================================================

-- Extra spaces in category columns. Expect: no rows
SELECT
    *
FROM silver.erp_px_cat_g1v2
WHERE cat != TRIM(cat)
   OR subcat != TRIM(subcat)
   OR maintenance != TRIM(maintenance);

-- List maintenance values. Expect: Yes, No
SELECT DISTINCT
    maintenance
FROM silver.erp_px_cat_g1v2;
