/*
===============================================================================
Stored Procedure: Load Bronze Layer (CSV -> Bronze) (PostgreSQL)
===============================================================================
What this procedure does:
    For each bronze table:
      1. Empties the table (TRUNCATE).
      2. Loads the matching CSV file with COPY.
      3. Prints how many rows were loaded and how long it took.

Before you run it:
    - COPY reads files from the database SERVER, so the CSV files must be in a
      folder the PostgreSQL server can read. This project uses:
          /Users/Shared/datasets/source_crm/
          /Users/Shared/datasets/source_erp/
      Change the paths below if your files live somewhere else.
    - The user running it needs superuser or the 'pg_read_server_files' role.

How to run:
    CALL bronze.load_bronze();
===============================================================================
*/

CREATE OR REPLACE PROCEDURE bronze.load_bronze()
LANGUAGE plpgsql
AS $$
DECLARE
    batch_start TIMESTAMPTZ;  -- when the whole load started
    start_time  TIMESTAMPTZ;  -- when the current table started
    row_count   INT;          -- rows loaded into the current table
BEGIN
    batch_start := clock_timestamp();
    RAISE NOTICE '================================================';
    RAISE NOTICE 'Loading Bronze Layer';
    RAISE NOTICE '================================================';

    RAISE NOTICE '------------------------------------------------';
    RAISE NOTICE 'Loading CRM Tables';
    RAISE NOTICE '------------------------------------------------';

    -- crm_cust_info
    start_time := clock_timestamp();
    TRUNCATE TABLE bronze.crm_cust_info;
    COPY bronze.crm_cust_info
    FROM '/Users/Shared/datasets/source_crm/cust_info.csv'
    WITH (FORMAT csv, HEADER true);
    GET DIAGNOSTICS row_count = ROW_COUNT;
    RAISE NOTICE '>> bronze.crm_cust_info: % rows in % sec', row_count,
        ROUND(EXTRACT(EPOCH FROM clock_timestamp() - start_time)::NUMERIC, 2);

    -- crm_prd_info
    start_time := clock_timestamp();
    TRUNCATE TABLE bronze.crm_prd_info;
    COPY bronze.crm_prd_info
    FROM '/Users/Shared/datasets/source_crm/prd_info.csv'
    WITH (FORMAT csv, HEADER true);
    GET DIAGNOSTICS row_count = ROW_COUNT;
    RAISE NOTICE '>> bronze.crm_prd_info: % rows in % sec', row_count,
        ROUND(EXTRACT(EPOCH FROM clock_timestamp() - start_time)::NUMERIC, 2);

    -- crm_sales_details
    start_time := clock_timestamp();
    TRUNCATE TABLE bronze.crm_sales_details;
    COPY bronze.crm_sales_details
    FROM '/Users/Shared/datasets/source_crm/sales_details.csv'
    WITH (FORMAT csv, HEADER true);
    GET DIAGNOSTICS row_count = ROW_COUNT;
    RAISE NOTICE '>> bronze.crm_sales_details: % rows in % sec', row_count,
        ROUND(EXTRACT(EPOCH FROM clock_timestamp() - start_time)::NUMERIC, 2);

    RAISE NOTICE '------------------------------------------------';
    RAISE NOTICE 'Loading ERP Tables';
    RAISE NOTICE '------------------------------------------------';

    -- erp_loc_a101
    start_time := clock_timestamp();
    TRUNCATE TABLE bronze.erp_loc_a101;
    COPY bronze.erp_loc_a101
    FROM '/Users/Shared/datasets/source_erp/LOC_A101.csv'
    WITH (FORMAT csv, HEADER true);
    GET DIAGNOSTICS row_count = ROW_COUNT;
    RAISE NOTICE '>> bronze.erp_loc_a101: % rows in % sec', row_count,
        ROUND(EXTRACT(EPOCH FROM clock_timestamp() - start_time)::NUMERIC, 2);

    -- erp_cust_az12
    start_time := clock_timestamp();
    TRUNCATE TABLE bronze.erp_cust_az12;
    COPY bronze.erp_cust_az12
    FROM '/Users/Shared/datasets/source_erp/CUST_AZ12.csv'
    WITH (FORMAT csv, HEADER true);
    GET DIAGNOSTICS row_count = ROW_COUNT;
    RAISE NOTICE '>> bronze.erp_cust_az12: % rows in % sec', row_count,
        ROUND(EXTRACT(EPOCH FROM clock_timestamp() - start_time)::NUMERIC, 2);

    -- erp_px_cat_g1v2
    start_time := clock_timestamp();
    TRUNCATE TABLE bronze.erp_px_cat_g1v2;
    COPY bronze.erp_px_cat_g1v2
    FROM '/Users/Shared/datasets/source_erp/PX_CAT_G1V2.csv'
    WITH (FORMAT csv, HEADER true);
    GET DIAGNOSTICS row_count = ROW_COUNT;
    RAISE NOTICE '>> bronze.erp_px_cat_g1v2: % rows in % sec', row_count,
        ROUND(EXTRACT(EPOCH FROM clock_timestamp() - start_time)::NUMERIC, 2);

    RAISE NOTICE '================================================';
    RAISE NOTICE 'Bronze Layer loaded. Total time: % sec',
        ROUND(EXTRACT(EPOCH FROM clock_timestamp() - batch_start)::NUMERIC, 2);
    RAISE NOTICE '================================================';

EXCEPTION
    -- If anything fails, all changes are rolled back and the error is shown
    WHEN OTHERS THEN
        RAISE NOTICE '================================================';
        RAISE NOTICE 'ERROR WHILE LOADING BRONZE LAYER';
        RAISE NOTICE 'Message: %', SQLERRM;
        RAISE NOTICE 'Code:    %', SQLSTATE;
        RAISE NOTICE '================================================';
END;
$$;
