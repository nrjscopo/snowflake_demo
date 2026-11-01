create or replace database demo_db;

create or replace schema demo_db.ingestion_dem;

use demo_db;

CREATE OR REPLACE TABLE raw_retail (
    invoice NUMBER,
    stockcode NUMBER,
    description STRING,
    quantity INT,
    invoicedate DATE,
    price INT,
    customer_id INT,
    country STRING
);

select * from raw_retail;

--- create snowflake stage copy the file from azure and load the data into the table 1 by sas token 2 azure strg integration


---BY sas token

-- CREATING THE FILE FORMAT
create or replace file format stock_csv_dem
    TYPE= CSV
    SKIP_HEADER=1
FIELD_DELIMITER=','

-- IN CREDENTIALS AT THE STARTING APPLY (?)

CREATE OR REPLACE STAGE AZURE_DEMO_STAGE
    URL='azure://mission100adlsadf.blob.core.windows.net/landingzone/'
    credentials=(AZURE_SAS_TOKEN='your_token')
FILE_FORMAT= stock_csv_dem;


----TO LIST AZURE ACCOUNT FILES

LS @AZURE_DEMO_STAGE;

SELECT CURRENT_REGION();

COPY INTO raw_retail
FROM @AZURE_DEMO_STAGE
FILES = ('retail_data.csv')
FILE_FORMAT = (FORMAT_NAME = stock_csv_dem)
ON_ERROR = 'CONTINUE';

select * from raw_retail;


----azure strg integration

CREATE OR REPLACE STORAGE INTEGRATION azure_blob_integration
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = 'AZURE'
  ENABLED = TRUE
  AZURE_TENANT_ID = 'tenant_Id' -- Replace with your actual Azure Tenant ID (GUID)
  STORAGE_ALLOWED_LOCATIONS = ('azure://mission100adlsadf.blob.core.windows.net/landingzone/');

desc integration azure_blob_integration;

-- 1st give consent on consent url than copy azue_multi_tenant_appnam--stating only --- utm4esnowflakepacint



    CREATE OR REPLACE STAGE AZURE_DEMO_STAGE_with_integration
    STORAGE_INTEGRATION = azure_blob_integration
    URL = 'azure://mission100adlsadf.blob.core.windows.net/landingzone/'
    FILE_FORMAT = stock_csv_dem; 

select * from raw_retail;
truncate table raw_retail;

COPY INTO raw_retail
FROM @AZURE_DEMO_STAGE_with_integration
FILES = ('retail_data.csv')
FILE_FORMAT = (FORMAT_NAME = stock_csv_dem)
ON_ERROR = 'CONTINUE';