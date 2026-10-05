-- SECOND TABLE FROM BRONZE 

-- checking dups or nulls
select
prd_id,
COUNT(*) 
from bronze.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 or prd_id IS NULL


select * 
from bronze.crm_prd_info

-- checking namespaces

select prd_nm
from bronze.crm_prd_info 
where prd_nm != trim(prd_nm)

-- checking quality of numbers in prd_cost 

select prd_cost
from bronze.crm_prd_info
where prd_cost < 0 OR prd_cost IS NUll


-- data standardizatoin & conistency 

select distinct prd_line
from bronze.crm_prd_info

-- checking start and end date 

select * 
from bronze.crm_prd_info
where prd_end_dt < prd_start_dt; -- this shouldn;t be true at all ! 

-- things to consider 
-- timeline overlaps cant be there 

SELECT
	prd_id,
	prd_key,
	prd_nm,
	prd_start_dt,
	prd_end_dt,
	LEAD (prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) - 1 AS prd_end_dt_test
FROM bronze.crm_prd_info
WHERE prd_key IN ('AC-HE-HL-U509-R', 'AC-HE-HL-U509');


--- REPAIR / PREPARE THE DDL FOR THE NEW VALUES 

DROP TABLE IF EXISTS silver.crm_prd_info;

CREATE TABLE silver.crm_prd_info (
    prd_id          INT,
    cat_id          VARCHAR(50),
    prd_key         VARCHAR(50),
    prd_nm          VARCHAR(50),
    prd_cost        INT,
    prd_line        VARCHAR(50),
    prd_start_dt    DATE,
    prd_end_dt      DATE,
    dwh_create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


--- FINAl TRANSFORMED SCRIPT TO LOAD 


INSERT INTO silver.crm_prd_info (
    prd_id,
    cat_id,
    prd_key,
    prd_nm,
    prd_cost,
    prd_line,
    prd_start_dt,
    prd_end_dt,
    dwh_create_date
)
SELECT
    prd_id,
    -- 2nd position: cat_id
    REPLACE(SUBSTR(prd_key, 1, 5), '-', '_') as cat_id,
    -- 3rd position: prd_key
    SUBSTRING(prd_key, 7) as prd_key,
    -- 4th position: prd_nm
    prd_nm,
    -- 5th position: prd_cost (now safely aligned with COALESCE returning an int)
    COALESCE(prd_cost, 0) as prd_cost,
    -- 6th position: prd_line
    CASE UPPER(TRIM(prd_line)) 
         WHEN 'M' then 'Mountain'
         WHEN 'R' then 'Road'
         WHEN 'S' then 'other sales'
         WHEN 'T' then 'Touring'
         ELSE 'n/a'
    END as prd_line,    
    -- 7th position: prd_start_dt
    CAST(prd_start_dt AS DATE) as prd_start_dt,
    -- 8th position: prd_end_dt
    CAST(LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) - 1 AS DATE) AS prd_end_dt,
    -- 9th position: dwh_create_date (added to match the insert list)
    CURRENT_TIMESTAMP as dwh_create_date
FROM bronze.crm_prd_info;








