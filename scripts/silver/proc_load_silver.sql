/*
======================================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
======================================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process to
    populate the 'silver' schema tables from the 'bronze' schema.
  
  Actions Performed:
    - Truncates Silver Tables.
    - Inserts transformed and cleansed data from Bronze to Silver tables.
  
Parameters:
    None.
    This stored procedure does not accept any parameters or return any values

Usage Example:
    EXEC silver.load_silver;
======================================================================================
*/

create or alter procedure silver.load_silver as
begin
	declare @start_time datetime, @end_time datetime, @batch_start_time datetime, @batch_end_time datetime
	begin try
		
		
		print '===========================================';
		print 'LOADING SILVER LAYER';
		print '===========================================';
		
		
		print '-------------------------------------------';
		print 'Loading CRM Tables';
		print '-------------------------------------------';
		
		set @batch_start_time = getdate();
		
		
		set @start_time = getdate();
		print '>> Truncating Table: silver.crm_cust_info';
		truncate table silver.crm_cust_info;
		
		print('>> Inserting clean transformed data to the silver.crm_cust_info table');
		Insert into silver.crm_cust_info(cst_id, cst_key, cst_firstname, cst_lastname, cst_marital_status, cst_gndr, cst_create_date)
		select 
		cst_id,
		cst_key,
		TRIM(cst_firstname) cst_firstname,
		TRIM(cst_lastname) cst_lastname,
		case when UPPER(TRIM(cst_marital_status)) = 'S' then 'Single'
			 when UPPER(TRIM(cst_marital_status)) = 'M' then 'Married'
			 else 'n/a'
		END cst_marital_status,
		case when UPPER(TRIM(cst_gndr)) = 'F' then 'Female'
			 when UPPER(TRIM(cst_gndr)) = 'M' then 'Male'
			 else 'n/a'
		END cst_gndr,
		cst_create_date
		from
		(
			select * from
				(
				select
				*, row_number() over(partition by cst_id order by cst_create_date desc) as flag_last 
				from bronze.crm_cust_info
				where cst_id is not null
				) t
			where flag_last = 1
		) t2;
		
		
		set @end_time = getdate();
		print('Loading Data into silver.crm_cust_info Duration:  ' + cast(datediff(second, @start_time, @end_time) as varchar) + ' seconds.')
		print('>> ---------------------------');
		
		
		set @start_time = getdate();
		print '>> Truncating Table: silver.crm_prd_info';
		truncate table silver.crm_prd_info;
		
		print('>> Inserting clean transformed data to the silver.crm_prd_info table');
		insert into silver.crm_prd_info(
			prd_id, 
			cat_id,
			prd_key, 
			prd_nm, 
			prd_cost, 
			prd_line, 
			prd_start_dt, 
			prd_end_dt)
		select 
		prd_id,
		replace(substring(prd_key, 1, 5), '-', '_') as cat_id, 	-- Extract category ID
		substring(prd_key, 7, len(prd_key)) as prd_key, 			-- Extract product key
		prd_nm,
		isnull(prd_cost,0) as prd_cost,
		Case upper(trim(prd_line))
			 when 'M' then 'Mountain'
			 when 'R' then 'Road'
			 when 'S' then 'Other Sales'
			 when 'T' then 'Touring'
			 else 'n/a'
		End as prd_line, -- Map product line codes to descriptive values
		cast(prd_start_dt as date) as prd_start_dt,
		cast(
			 lead(prd_start_dt, 1) over(partition by prd_key order by prd_start_dt)-1 
			 as date
			) as prd_end_dt -- Calculate end date as one day before the next start date
		from bronze.crm_prd_info;
		
		
		set @end_time = getdate();
		print('Loading Data into silver.crm_prd_info Duration:  ' + cast(datediff(second, @start_time, @end_time) as varchar) + ' seconds.')
		print('>> ---------------------------');
		
		
		set @start_time = getdate();
		print '>> Truncating Table: silver.crm_sales_details';
		truncate table silver.crm_sales_details;
		
		print('>> Inserting clean transformed data to the silver.crm_sales_details table');
		insert into silver.crm_sales_details(
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			sls_order_dt,
			sls_ship_dt,
			sls_due_dt,
			sls_sales,
			sls_quantity,
			sls_price)
		select 
		sls_ord_num,
		sls_prd_key,
		sls_cust_id,
		case 
			when sls_order_dt = 0 or len(sls_order_dt) != 8 then NULL 
			else cast(cast(sls_order_dt as varchar) as date)
		end as sls_order_dt,
		case 
			when sls_ship_dt = 0 or len(sls_ship_dt) != 8 then NULL 
			else cast(cast(sls_ship_dt as varchar) as date)
		end as sls_ship_dt,
		case 
			when sls_due_dt = 0 or len(sls_due_dt) != 8 then NULL 
			else cast(cast(sls_due_dt as varchar) as date)
		end as sls_due_dt,
		case when sls_sales is null or sls_sales < 0 or sls_sales != (sls_quantity * sls_price) then (sls_quantity*abs(sls_price))
			 else sls_sales
		end as sls_sales, 
		sls_quantity,
		case when sls_price is null or sls_price <= 0 then (sls_sales / nullif(sls_quantity,0))
			 else sls_price
		end as sls_price 
		from bronze.crm_sales_details;
		
		
		set @end_time = getdate();
		print('Loading Data into silver.crm_sales_details Duration:  ' + cast(datediff(second, @start_time, @end_time) as varchar) + ' seconds.')
		print('>> ---------------------------');
		
		
		print '-------------------------------------------';
		print 'Loading ERP Tables';
		print '-------------------------------------------';
		
		
		set @start_time = getdate();
		print '>> Truncating Table: silver.erp_cust_az12';
		truncate table silver.erp_cust_az12;
		
		print('>> Inserting clean transformed data to the silver.erp_cust_az12 table');
		insert into silver.erp_cust_az12(
			cid,
			bdate,
			gen
		)
		SELECT 
		    CASE 
		        WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
		        ELSE cid
		    END AS cid,
		    CASE 
		        WHEN bdate > GETDATE() THEN NULL
		        ELSE bdate
		    END AS bdate,
		    CASE 
		        WHEN gen_clean IN ('F', 'FEMALE') THEN 'Female'
		        WHEN gen_clean IN ('M', 'MALE') THEN 'Male'
		        ELSE 'n/a'
		    END AS gen
		FROM (
		    SELECT *,
		        UPPER(
		            TRIM(
		                REPLACE(REPLACE(REPLACE(REPLACE(gen, CHAR(13), ''), CHAR(10), ''), CHAR(9), ''), CHAR(160), '')
		            )
		        ) AS gen_clean
		    FROM bronze.erp_cust_az12
		) t;
		
		
		set @end_time = getdate();
		print('Loading Data into silver.erp_cust_az12 Duration:  ' + cast(datediff(second, @start_time, @end_time) as varchar) + ' seconds.')
		print('>> ---------------------------');
		
		
		set @start_time = getdate();
		print '>> Truncating Table: silver.erp_loc_a101';
		truncate table silver.erp_loc_a101;
		
		print('>> Inserting clean transformed data to the silver.erp_loc_a101 table');
		insert into silver.erp_loc_a101(
			cid,
			cntry
		)
		select
		replace(cid, '-', '') as cid,
		case when trim(replace(cntry, char(13), '')) = '' or trim(replace(cntry, char(13), '')) is null then 'n/a'
			 when trim(replace(cntry, char(13), '')) in ('US', 'USA') then 'United States'
			 when trim(replace(cntry, char(13), '')) = 'DE' then 'Germany'
			else trim(replace(cntry, char(13), ''))
		end as cntry
		from bronze.erp_loc_a101;
		
		
		set @end_time = getdate();
		print('Loading Data into silver.erp_loc_a101 Duration:  ' + cast(datediff(second, @start_time, @end_time) as varchar) + ' seconds.')
		print('>> ---------------------------');
		
		
		set @start_time = getdate();
		print '>> Truncating Table: silver.erp_px_cat_g1v2';
		truncate table silver.erp_px_cat_g1v2;
		
		print('>> Inserting clean transformed data to the silver.erp_px_cat_g1v2 table');
		insert into silver.erp_px_cat_g1v2(
			id,
			cat,
			subcat,
			maintenance
		)
		select
		id,
		cat,
		subcat,
		replace(trim(maintenance), char(13), '') as maintenance
		from bronze.erp_px_cat_g1v2;
		
		
		set @end_time = getdate();
		print('Loading Data into silver.erp_px_cat_g1v2 Duration:  ' + cast(datediff(second, @start_time, @end_time) as varchar) + ' seconds.')
		print('>> ---------------------------');
		
		
		set @batch_end_time = getdate();
		print('SILVER LAYER LOAD DURATION:  ' + cast(datediff(second, @batch_start_time, @batch_end_time) as varchar) + ' seconds.')
		print('>> ---------------------------');
		
		
	end try
	begin catch
		print '===========================================';
		print 'ERROR OCCURED DURING LOADING SILVER LAYER';
		print 'Error Message:' + error_message();
		print 'Error Message:' + cast(error_number() as nvarchar);
		print 'Error Message:' + cast(error_state() as nvarchar);
	end catch
end;
