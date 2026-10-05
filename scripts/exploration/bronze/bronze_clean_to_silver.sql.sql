-- checking for null / duplicate in primary key
select
cst_id,
COUNT(*) 
from bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 or cst_id IS NULL


-- need latest value from the script here 

select *
from bronze.crm_cust_info
where cst_id = 29466

--- selecting the window

select 
*,
row_number() over(partition by cst_id order by cst_create_date desc) flag_last
from bronze.crm_cust_info


-- Double checking and removing duplicates

select 
*
from (
	select 
	*,
	row_number() over(partition by cst_id order by cst_create_date desc) flag_last
	from bronze.crm_cust_info
)t where flag_last = 1 


-- Check for unwanted spaces in firstnames  and last names
-- we should be seeing no results

select 
cst_firstname
from bronze.crm_cust_info
where cst_firstname != trim(cst_firstname) 

select 
cst_lastname
from bronze.crm_cust_info
where cst_lastname != trim(cst_lastname) 

--- checking data standardization , using full names
select distinct
cst_gndr
from bronze.crm_cust_info


-- Query to fix everything and finally inserting to silver 

INSERT INTO silver.crm_cust_info (
	cst_id,
    cst_key,
    cst_firstname,
    cst_lastname,
    cst_material_status,
    cst_gndr,
    cst_create_date
)

SELECT
	cst_id,
	cst_key,
	TRIM(cst_firstname) as cst_firstname,
	TRIM(cst_lastname) as cst_lastname,
	CASE WHEN UPPER(TRIM(cst_material_status)) = 'M' then 'Married'
		 WHEN UPPER(TRIM(cst_material_status)) = 'S' then 'Single'
		 ELSE 'n/a'
	END cst_marital_status,
	CASE WHEN UPPER(TRIM(cst_gndr)) = 'M' then 'Male'
		 WHEN UPPER(TRIM(cst_gndr)) = 'F' then 'Female'
		 ELSE 'n/a'
	END cst_gndr,
	cst_create_date
FROM (
	SELECT
	*,
	ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_last
	FROM bronze.crm_cust_info
	WHERE cst_id IS NOT NULL
	
)t WHERE flag_last =  1

