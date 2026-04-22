/*
======================================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
======================================================================================
Script Purpose:
    This stored procedure loads data into the 'bronze' schema from external CSV files.
    It performs the following actions:
    - Truncates the bronze tables before loading data.
    - Uses the 'BULK INSERT' command to load data from csv files to bronze tabled.

Parameters:
    None.
  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC bronze.load_bronze;
======================================================================================
*/

create or alter procedure bronze.load_bronze as
begin
	declare @start_time datetime, @end_time datetime
	begin try
		
		/*
			For BULK Insert:
				If you are using MAC and running sql server through docker container, it has its own isolated filesystem.
				And you need to mount your local folder into the Docker container when running it.
    */
		
		print '===========================================';
		print 'LOADING Bronze Layer';
		print '===========================================';
		
		
		print '-------------------------------------------';
		print 'Loading CRM Tables';
		print '-------------------------------------------';
		
		
		set @start_time = getdate();
		
		print '>> Truncating Table: bronze.crm_cust_info';
		truncate table bronze.crm_cust_info;
		
		print '>> Inserting Data Into: bronze.crm_cust_info';
		Bulk insert bronze.crm_cust_info from '/var/opt/mssql/data/datasets/source_crm/cust_info.csv'
		with (
			firstrow = 2,
			fieldterminator = ',',
			ROWTERMINATOR = '\n',
			tablock
		);
		
		
		print '>> Truncating Table: bronze.crm_prd_info';
		truncate table bronze.crm_prd_info;
		
		print '>> Inserting Data Into: bronze.crm_prd_info';
		Bulk insert bronze.crm_prd_info from '/var/opt/mssql/data/datasets/source_crm/prd_info.csv'
		with (
			firstrow = 2,
			fieldterminator = ',',
			ROWTERMINATOR = '\n',
			tablock
		);
		
		
		
		print '>> Truncating Table: bronze.crm_sales_details';
		truncate table bronze.crm_sales_details;
		
		print '>> Inserting Data Into: bronze.crm_sales_details';
		Bulk insert bronze.crm_sales_details from '/var/opt/mssql/data/datasets/source_crm/sales_details.csv'
		with (
			firstrow = 2,
			fieldterminator = ',',
			ROWTERMINATOR = '\n',
			tablock
		);
		
		
		
		print '-------------------------------------------';
		print 'Loading ERP Tables';
		print '-------------------------------------------';
		
		
		print '>> Truncating Table: bronze.erp_cust_az12';
		truncate table bronze.erp_cust_az12;
		
		print '>> Inserting Data into: bronze.erp_cust_az12';
		Bulk insert bronze.erp_cust_az12 from '/var/opt/mssql/data/datasets/source_erp/CUST_AZ12.csv'
		with (
			firstrow = 2,
			fieldterminator = ',',
			ROWTERMINATOR = '\n',
			tablock
		);
		
		
		print '>> Truncating Table: bronze.erp_loc_a101';
		truncate table bronze.erp_loc_a101;
		
		print '>> Inserting Data Into: bronze.erp_loc_a101';
		Bulk insert bronze.erp_loc_a101 from '/var/opt/mssql/data/datasets/source_erp/LOC_A101.csv'
		with (
			firstrow = 2,
			fieldterminator = ',',
			ROWTERMINATOR = '\n',
			tablock
		);
		
		
		print '>> Truncating Table: bronze.erp_px_cat_g1v2';
		truncate table bronze.erp_px_cat_g1v2;
		
		print '>> Inserting Data Into: bronze.erp_px_cat_g1v2';
		Bulk insert bronze.erp_px_cat_g1v2 from '/var/opt/mssql/data/datasets/source_erp/PX_CAT_G1V2.csv'
		with (
			firstrow = 2,
			fieldterminator = ',',
			ROWTERMINATOR = '\n',
			tablock
		);
		
		set @end_time = getdate();
		
		print('>> Load Duration' + cast(datediff(second,@start_time,@end_time) as varchar) + ' seconds');
		print('>> ---------------------------');
		
	end try
	begin catch
		print '===========================================';
		print 'ERROR OCCURED DURING LOADING BRONZE LAYER';
		print 'Error Message' + error_message();
		print 'Error Message' + cast(error_number() as varchar);
		print 'Error Message' + cast(error_state() as varchar);
	end catch

END;
