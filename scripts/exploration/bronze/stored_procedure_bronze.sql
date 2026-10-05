CREATE OR REPLACE PROCEDURE bronze.load_bronze()
LANGUAGE plpgsql
AS $$
DECLARE
    batch_start TIMESTAMPTZ;
    start_time  TIMESTAMPTZ;
    v_rows      INTEGER;
BEGIN
    batch_start := clock_timestamp();
    RAISE NOTICE '==========================================';
    RAISE NOTICE 'Loading Bronze Layer';
    RAISE NOTICE '==========================================';

    ------------------------------------------------------------
    RAISE NOTICE '------------------------------------------';
    RAISE NOTICE 'Loading CRM Tables';
    RAISE NOTICE '------------------------------------------';

    -- crm_cust_info
    start_time := clock_timestamp();
    TRUNCATE TABLE bronze.crm_cust_info;
    COPY bronze.crm_cust_info
    FROM '/Users/Shared/datasets/source_crm/cust_info.csv'
    WITH (FORMAT csv, HEADER true);
    SELECT COUNT(*) INTO v_rows FROM bronze.crm_cust_info;
    RAISE NOTICE '>> crm_cust_info: % rows in % sec', v_rows,
        ROUND(EXTRACT(EPOCH FROM clock_timestamp() - start_time)::numeric, 2);

    -- crm_prd_info
    start_time := clock_timestamp();
    TRUNCATE TABLE bronze.crm_prd_info;
    COPY bronze.crm_prd_info
    FROM '/Users/Shared/datasets/source_crm/prd_info.csv'
    WITH (FORMAT csv, HEADER true);
    SELECT COUNT(*) INTO v_rows FROM bronze.crm_prd_info;
    RAISE NOTICE '>> crm_prd_info: % rows in % sec', v_rows,
        ROUND(EXTRACT(EPOCH FROM clock_timestamp() - start_time)::numeric, 2);

    -- crm_sales_details
    start_time := clock_timestamp();
    TRUNCATE TABLE bronze.crm_sales_details;
    COPY bronze.crm_sales_details
    FROM '/Users/Shared/datasets/source_crm/sales_details.csv'
    WITH (FORMAT csv, HEADER true);
    SELECT COUNT(*) INTO v_rows FROM bronze.crm_sales_details;
    RAISE NOTICE '>> crm_sales_details: % rows in % sec', v_rows,
        ROUND(EXTRACT(EPOCH FROM clock_timestamp() - start_time)::numeric, 2);

    ------------------------------------------------------------
    RAISE NOTICE '------------------------------------------';
    RAISE NOTICE 'Loading ERP Tables';
    RAISE NOTICE '------------------------------------------';

    -- erp_loc_a101
    start_time := clock_timestamp();
    TRUNCATE TABLE bronze.erp_loc_a101;
    COPY bronze.erp_loc_a101
    FROM '/Users/Shared/datasets/source_erp/LOC_A101.csv'
    WITH (FORMAT csv, HEADER true);
    SELECT COUNT(*) INTO v_rows FROM bronze.erp_loc_a101;
    RAISE NOTICE '>> erp_loc_a101: % rows in % sec', v_rows,
        ROUND(EXTRACT(EPOCH FROM clock_timestamp() - start_time)::numeric, 2);

    -- erp_cust_az12
    start_time := clock_timestamp();
    TRUNCATE TABLE bronze.erp_cust_az12;
    COPY bronze.erp_cust_az12
    FROM '/Users/Shared/datasets/source_erp/CUST_AZ12.csv'
    WITH (FORMAT csv, HEADER true);
    SELECT COUNT(*) INTO v_rows FROM bronze.erp_cust_az12;
    RAISE NOTICE '>> erp_cust_az12: % rows in % sec', v_rows,
        ROUND(EXTRACT(EPOCH FROM clock_timestamp() - start_time)::numeric, 2);

    -- erp_px_cat_g1v2
    start_time := clock_timestamp();
    TRUNCATE TABLE bronze.erp_px_cat_g1v2;
    COPY bronze.erp_px_cat_g1v2
    FROM '/Users/Shared/datasets/source_erp/PX_CAT_G1V2.csv'
    WITH (FORMAT csv, HEADER true);
    SELECT COUNT(*) INTO v_rows FROM bronze.erp_px_cat_g1v2;
    RAISE NOTICE '>> erp_px_cat_g1v2: % rows in % sec', v_rows,
        ROUND(EXTRACT(EPOCH FROM clock_timestamp() - start_time)::numeric, 2);

    ------------------------------------------------------------
    RAISE NOTICE '==========================================';
    RAISE NOTICE 'Bronze Layer loaded in % sec',
        ROUND(EXTRACT(EPOCH FROM clock_timestamp() - batch_start)::numeric, 2);
    RAISE NOTICE '==========================================';

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '==========================================';
        RAISE NOTICE 'ERROR OCCURRED DURING LOADING BRONZE LAYER';
        RAISE NOTICE 'Error message: %', SQLERRM;
        RAISE NOTICE 'Error code: %', SQLSTATE;
        RAISE NOTICE '==========================================';
END;
$$;

-- Run the procedure:
CALL bronze.load_bronze();