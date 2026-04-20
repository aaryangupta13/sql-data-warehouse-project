/*
============================================================
Create Database and Schemas
============================================================

Script Purpose:
  This script creates a new database named 'DataWarehouse' after checking if it already exists.
  If the database exists, it is dropped and recreated. Additionally, the script sets up three schemas
  within the databaseL: 'bronze', 'silver', and 'gold'.

WARNING:
		
	Running this script will drop the entire 'Datawarehouse' Database if it exists.
	All data in the database will be permanently deleted. Proceed with caution and
	ensure you have proper backups before running this script.
*/


use master;


-- drop and recreate the 'Datawarehouse' database
if exists(select 1 from sys.databases where name= 'Datawarehouse')
Begin
	alter database datawarehouse set single_user with rollback immediatel
	drop database datawarehouse;
END

-- Create the 'DataWarehouse' database
create database DataWarehouse;


-- use DataWarehouse
use datawarehouse

  
-- Create Schemas
create schema bronze;

create schema silver;

create schema gold;


