select 
REPLACE(cid, '-','') cid,
CASE WHEN UPPER(TRIM(cntry)) IN ('US','USA') THEN 'United States'
	 WHEN UPPER(TRIM(cntry)) IN ('DE') THEN 'Germany'
	 WHEN UPPER(TRIM(cntry)) = '' OR cntry IS NULL THEN 'n/a'
	 ELSE TRIM(cntry)
END cntry
from bronze.erp_loc_a101
WHERE REPLACE(cid, '-','') NOT IN 
(select cst_key from bronze.crm_cust_info)

select cst_key from bronze.crm_cust_info;



select distinct
cntry
from bronze.erp_loc_a101
order by cntry

--- fINAL QUERY TO TRANSFER bronze.erp_loc_a101 to silver.erp_loc_a101


INSER INTO silver.erp_loc_a101 (
cid,
cntry
)

select 
REPLACE(cid, '-','') cid,
CASE WHEN UPPER(TRIM(cntry)) IN ('US','USA') THEN 'United States'
	 WHEN UPPER(TRIM(cntry)) IN ('DE') THEN 'Germany'
	 WHEN UPPER(TRIM(cntry)) = '' OR cntry IS NULL THEN 'n/a'
	 ELSE TRIM(cntry)
END cntry
from bronze.erp_loc_a101


