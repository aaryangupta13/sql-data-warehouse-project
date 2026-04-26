/*
=====================================================================================
QUALITY CHECKS
=====================================================================================
Script Purpose:
  This script Performs various quality checks for data consistency, accuracy and 
  standardisation accross the 'silver' schemas. It includes checks for:
    - NULL or duplicate primary keys.
    - Unwanted spaces in string fields.
    - Data standardisation and consistency.
    - Invalid date ranges and orders.
    - Data consistency between related fields.

Usage Notes:
    - Run these checks after the loading silver layer
    - Investigate and resolve any discrepancies found during the checks.
=====================================================================================
*/


-------- Identifying & Cleaning Each Table for Correctness of Data --------

-- Check For Nulls or Duplicates in Primary Key
-- Expectation: No Results
SELECT
id,
count(*)
from bronze.erp_px_cat_g1v2
group by id
having count(*) > 1 or id is NULL;


select * from bronze.erp_px_cat_g1v2;

-- Check for Unwanted Spaces
-- Expectation: No Results

select subcat
from bronze.erp_px_cat_g1v2
where subcat != TRIM(subcat);

select
maintenance
from bronze.erp_px_cat_g1v2
where maintenance != TRIM(maintenance)

-- Data Standardisation & Consistency
select distinct 
gen,
case when UPPER(TRIM(gen)) in ('F', 'FEMALE') then 'Female'
	 when UPPER(TRIM(gen)) in ('M', 'MALE') then 'Male'
	 else 'n/a'
end as gen2
from bronze.erp_cust_az12;


select distinct
    gen,
    len(gen) as len,
    len(trim(gen)) as trimmed_len,
    ascii(substring(gen, 1, 1)) as first_char_ascii,
    gen+'X'
from bronze.erp_cust_az12;

WITH cleaned AS (
    SELECT 
        gen,
        UPPER(
            LTRIM(RTRIM(
                REPLACE(REPLACE(gen, CHAR(13), ''), CHAR(10), '')
            ))
        ) AS gen_clean
    FROM bronze.erp_cust_az12
)
SELECT DISTINCT
    gen,
    CASE 
        WHEN gen_clean IN ('F', 'FEMALE') THEN 'Female'
        WHEN gen_clean IN ('M', 'MALE') THEN 'Male'
        ELSE 'n/a'
    END AS gen2
FROM cleaned;

select distinct trim(replace(cntry, char(13), '')), ascii(substring(trim(replace(cntry, char(13), '')),1,1))
from bronze.erp_loc_a101;


select * from bronze.erp_loc_a101 where trim(replace(cntry, char(13), '')) = ''


select distinct replace(trim(maintenance), char(13), '')
from bronze.erp_px_cat_g1v2;


-- Check For Nulls or Negative Values in Transactions Columns (like price, quantity, sales etc.)
-- Expectation: No Results
select distinct sls_ord_num,
sls_sales,
sls_quantity,
sls_price
from bronze.crm_sales_details
where sls_sales != (sls_quantity * sls_price)
or sls_sales is null or sls_quantity is null or sls_price is null
or sls_sales < 1 or sls_quantity < 1 or sls_price < 1
order by sls_sales, sls_quantity, sls_price;


-- Check For Invalid Date Orders
-- Expectation: No Results
select prd_start_dt
from bronze.crm_prd_info
where prd_end_dt < prd_start_dt;

-- 2 Examples of wrong dates
select * from bronze.crm_prd_info where substring(prd_key, 7, len(prd_key)) = 'HL-U509-R';
select * from bronze.crm_prd_info where substring(prd_key, 7, len(prd_key)) = 'HL-U509';

select prd_id, 
prd_key, 
prd_nm, 
prd_start_dt, 
prd_end_dt,
lead(prd_start_dt, 1) over(partition by prd_key order by prd_start_dt)-1 as prd_end_dt_test
from
bronze.crm_prd_info 
where prd_key IN ('AC-HE-HL-U509-R', 'AC-HE-HL-U509')


select 
nullif(sls_due_dt,0) sls_due_dt 
from bronze.crm_sales_details 
where sls_due_dt < 1 
or len(sls_due_dt) != 8
or sls_due_dt > 20500101
or sls_due_dt < 19000101


select 
*
from bronze.crm_sales_details
where sls_ship_dt < sls_order_dt or sls_due_dt < sls_order_dt


select 
*
from bronze.erp_cust_az12
where bdate < '1924-01-01' or bdate > getdate()


--====================================================================================


-------- Validating Each Table for Correctness of Data --------

-- Check For Nulls or Duplicates in Primary Key
-- Expectation: No Results
SELECT
CID,
count(*)
from silver.erp_cust_az12 
group by CID
having count(*) > 1 or CID is NULL;


-- Check for Unwanted Spaces
-- Expectation: No Results
select prd_nm
from silver.crm_prd_info
where prd_nm != TRIM(prd_nm);

select cst_lastname
from silver.crm_cust_info
where cst_lastname != TRIM(cst_lastname);


-- Data Standardisation & Consistency
select distinct maintenance
from silver.erp_px_cat_g1v2;;

select distinct cst_marital_status
from silver.crm_cust_info;


-- Check For Nulls or Duplicates in Primary Key
-- Expectation: No Results
select prd_cost
from silver.crm_prd_info
where prd_cost is null or prd_cost < 1;


-- Check For Invalid Date Orders
-- Expectation: No Results
select prd_start_dt
from silver.crm_prd_info
where prd_end_dt < prd_start_dt;

-- 2 Examples of wrong dates
select * from silver.crm_prd_info where prd_key = 'HL-U509-R'
union all
select * from silver.crm_prd_info where prd_key = 'HL-U509';

select 
*
from bronze.crm_sales_details
where sls_ship_dt < sls_order_dt or sls_due_dt < sls_order_dt

select 
*
from silver.erp_cust_az12
where bdate is null


-- Check For Nulls or Negative Values in Transactions Columns (like price, quantity, sales etc.)
-- Expectation: No Results
select distinct sls_ord_num,
sls_sales,
sls_quantity,
sls_price
from silver.crm_sales_details
where sls_sales != (sls_quantity * sls_price)
or sls_sales is null or sls_quantity is null or sls_price is null
or sls_sales < 1 or sls_quantity < 1 or sls_price < 1
order by sls_sales, sls_quantity, sls_price;
