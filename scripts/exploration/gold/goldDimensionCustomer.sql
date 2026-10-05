CREATE VIEW gold.dim_customers AS
SELECT
ROW_NUMBER() OVER (ORDER BY cst_id) customer_key,
ci.cst_id AS customer_id,
ci.cst_key AS customer_number,
ci.cst_firstname AS firstname,
ci.cst_lastname AS lastname,
la.cntry AS country,
ci.cst_material_status AS marital_status,
CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr -- CRM is the MAster for gender info
	 ELSE COALESCE(ca.gen,'n/a')
END as gender,
ca.bdate AS birth_date,
ci.cst_create_date AS create_date
FROM silver.crm_cust_info as ci
LEFT JOIN silver.erp_cust_az12 as ca
ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 as la
ON ci.cst_key = la.cid




--- SURROGATE KEYS are made to generate unique identifiers, 


--- TESTER 
SELECT DISTINCT
ci.cst_gndr,
CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr -- CRM is the MAster for gender info
	 ELSE COALESCE(ca.gen,'n/a')
END as new_gen,
ca.gen
FROM silver.crm_cust_info as ci
LEFT JOIN silver.erp_cust_az12 as ca
ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 as la
ON ci.cst_key = la.cid
ORDER  BY 1,2

