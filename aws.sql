-- CREATE bucket in aws --- upload file there
-- CREATE table and stage here in snowflake 
-- create addcess keys on your aws console under security GIT_CREDENTIAL
-- 


create or replace database aws_db;

create or replace schema aws_db.ingestion_dem;

use aws_db;

CREATE OR REPLACE TABLE raw_retail_aws (
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
create or replace file format stock_csv_dem_AWS
    TYPE= CSV
    SKIP_HEADER=1
FIELD_DELIMITER=',';


CREATE OR REPLACE STAGE aws_DEMO_STAGE
    URL='s3://<buscketname/foldername>'
    credentials= AWS_KEY_ID = ''
    AWS_SECRET_KEY=''
FILE_FORMAT= stock_csv_dem_AWS;


LS @aws_DEMO_STAGE;


COPY INTO raw_retail_aws
FROM @aws_DEMO_STAGE
FILES = ('FILENAME.csv')
FILE_FORMAT = (FORMAT_NAME = stock_csv_dem_AWS)
ON_ERROR = 'CONTINUE';

select * from raw_retail_aws;


---in iam (aws) give read and write policy on your s3 create role give external id here from your snwflake give dummy value as of now and asssign that created policy  here 
--- copy arn of your role and put in snowflake . create storage integration

----AWS strg integration

CREATE OR REPLACE STORAGE INTEGRATION aws_blob_integration
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = 's3'
  ENABLED = TRUE
  STORAGE_AWS_ROLE_ARN= 'AWS_ARn_FROM_ROLE' -- Replace with your actual AWS POLICY ARN
  STORAGE_ALLOWED_LOCATIONS = ('s3://<buscketname/>');

desc integration aws_blob_integration; ----COPY STRG_AWS_IAM_USER_ARN AND STORAGE_AWS_EXTERNAL_ID FROM HERE ON AWS ROLE IN TRUST RELATIONSHIP GIVE STRG_AWS_IAM_USER_ARN AND STORAGE_AWS_EXTERNAL_ID HERE UPDATE POLICY 

-- NOW CREATE STAGE AND FILEFORMAT SAME AS ABOVE CREATED 


-- what if our table has less column then the file than what to do ? copy into wont work here 
select $1,$2,$3,$4    FROM @aws_DEMO_STAGE -----------it will give you the coulumn 
FILES = ('FILENAME.csv')
FILE_FORMAT = (FORMAT_NAME = stock_csv_dem_AWS)






