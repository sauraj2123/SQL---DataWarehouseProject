-- checking for null / duplicate in primary key
select
prd_nm,
COUNT(*) 
from silver.crm_prd_info
GROUP BY prd_nm
HAVING COUNT(*) > 1 or prd_nm IS NULL


-- Check for unwanted spaces in firstnames  and last names
-- we should be seeing no results

select 
prd_nm
from silver.crm_prd_info
where prd_nm != trim(prd_nm) 

select 
cst_lastname
from silver.crm_cust_info
where cst_lastname != trim(cst_lastname) 


select distinct
cst_gndr
from silver.crm_cust_info

select *
from silver.crm_cust_info


select 
*
from silver.crm_prd_info
