TRUNCATE TABLE bronze.crm_sales_details;

COPY bronze.crm_sales_details
FROM '/Users/Shared/datasets/source_crm/sales_details.csv'
WITH (FORMAT csv, HEADER true);

SELECT 
COUNT(*) 
FROM bronze.crm_sales_details;

---

TRUNCATE TABLE bronze.crm_prd_info;

COPY bronze.crm_prd_info
FROM '/Users/Shared/datasets/source_crm/prd_info.csv'
WITH (FORMAT csv, HEADER true);

SELECT COUNT(*)
FROM bronze.crm_prd_info;


---

TRUNCATE TABLE bronze.crm_cust_info;

COPY bronze.crm_cust_info
FROM '/Users/Shared/datasets/source_crm/cust_info.csv'
WITH (FORMAT csv, HEADER true);

SELECT *
FROM bronze.crm_cust_info;

---

TRUNCATE TABLE bronze.erp_px_cat_g1v2;

COPY bronze.erp_px_cat_g1v2
FROM '/Users/Shared/datasets/source_erp/PX_CAT_G1V2.csv'
WITH (FORMAT csv, HEADER true);

SELECT *
FROM bronze.erp_px_cat_g1v2;

---

TRUNCATE TABLE bronze.erp_loc_a101;

COPY bronze.erp_loc_a101
FROM '/Users/Shared/datasets/source_erp/LOC_A101.csv'
WITH (FORMAT csv, HEADER true);

SELECT *
FROM bronze.erp_loc_a101;

---

TRUNCATE TABLE bronze.erp_cust_az12;

COPY bronze.erp_cust_az12
FROM '/Users/Shared/datasets/source_erp/CUST_AZ12.csv'
WITH (FORMAT csv, HEADER true);

SELECT *
FROM bronze.erp_cust_az12;