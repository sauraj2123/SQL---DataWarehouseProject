-- checking for null / duplicate in primary key
select
cst_id,
COUNT(*) 
from silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 or cst_id IS NULL


-- Check for unwanted spaces in firstnames  and last names
-- we should be seeing no results

select 
cst_firstname
from silver.crm_cust_info
where cst_firstname != trim(cst_firstname) 

select 
cst_lastname
from silver.crm_cust_info
where cst_lastname != trim(cst_lastname) 


select distinct
cst_gndr
from silver.crm_cust_info

select *
from silver.crm_cust_info