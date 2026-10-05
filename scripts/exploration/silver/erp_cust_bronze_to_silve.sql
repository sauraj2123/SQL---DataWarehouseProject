select
CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LENGTH(cid))
	 ELSE cid
END as cid,
CASE WHEN bdate > CURRENT_DATE THEN NULL
	 ELSE bdate
END bdate,
CASE WHEN UPPER(TRIM(gen)) IN ('M','MALE') THEN 'Male'
	 WHEN UPPER(TRIM(gen)) IN ('F','FEMALE') THEN 'Female'
	 ELSE 'n/a'
END gen
from bronze.erp_cust_az12;



select distinct
gen
from bronze.erp_cust_az12;

select distinct
bdate
FROM bronze.erp_cust_az12
WHERE bdate < '1924-01-01' or bdate > CURRENT_DATE




---
INSERT INTO silver.erp_cust_az12(
cid,
bdate,
gen
)
select
CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LENGTH(cid))
	 ELSE cid
END as cid,
CASE WHEN bdate > CURRENT_DATE THEN NULL
	 ELSE bdate
END bdate,
CASE WHEN UPPER(TRIM(gen)) IN ('M','MALE') THEN 'Male'
	 WHEN UPPER(TRIM(gen)) IN ('F','FEMALE') THEN 'Female'
	 ELSE 'n/a'
END gen
from bronze.erp_cust_az12;