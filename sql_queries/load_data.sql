USE NorthAxis_DW;

--  load the tables order matters here , always start with indipendent tables
LOAD DATA LOCAL INFILE 'path/to/your/file'
INTO TABLE dim_date
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

--  load merchant table
LOAD DATA LOCAL INFILE 'path/to/your/file'
INTO TABLE dim_merchant
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- load data into location table
LOAD DATA LOCAL INFILE 'path/to/your/file'
INTO TABLE dim_location
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- load dim customer since it depends on location
LOAD DATA LOCAL INFILE 'path/to/your/file'
INTO TABLE dim_customer
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- load dim account since it depends on dim customer

LOAD DATA LOCAL INFILE 'path/to/your/file'
INTO TABLE dim_account
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


-- finish off by loading the fact table 
LOAD DATA LOCAL INFILE 'path/to/your/file'
INTO TABLE fact_transactions
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
