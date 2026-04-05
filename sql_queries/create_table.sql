USE NorthAxis_DW;

CREATE TABLE dim_location (
	location_key BIGINT PRIMARY KEY,
	country VARCHAR(100),
	city VARCHAR(100),
	region VARCHAR(100),
	is_high_risk_country TINYINT(1)
);

CREATE TABLE dim_customer (
    customer_key BIGINT PRIMARY KEY,
    customer_id VARCHAR(50),
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    full_name VARCHAR(200),
    email VARCHAR(150),
    phone BIGINT,
    country VARCHAR(100),
    city VARCHAR(100),
    location_key BIGINT,
    kyc_status VARCHAR(50),
    preferred_channel VARCHAR(50),
    join_date DATE,
    customer_segment VARCHAR(50),
    is_fraud_target TINYINT(1),
    FOREIGN KEY (location_key) REFERENCES dim_location(location_key)
);


CREATE TABLE dim_account (
    account_key BIGINT PRIMARY KEY,
    account_id VARCHAR(50),
    customer_key BIGINT,
    account_type VARCHAR(50),
    currency VARCHAR(10),
    credit_limit DECIMAL(15, 2), -- Using Decimal for financial precision
    current_balance DECIMAL(15, 2),
    account_status VARCHAR(50),
    open_date DATE,
    balance_tier VARCHAR(50),
    FOREIGN KEY (customer_key) REFERENCES dim_customer(customer_key)
);

CREATE TABLE dim_date (
    date_key BIGINT PRIMARY KEY,
    full_date DATE,
    day_of_week VARCHAR(20),
    day_number INT,
    week_number INT,
    month_number INT,
    month_name VARCHAR(20),
    quarter_number INT,
    quarter_name VARCHAR(10),
    year_number INT,
    is_weekend TINYINT(1),
    is_month_end TINYINT(1)
);

CREATE TABLE dim_merchant (
    merchant_key BIGINT PRIMARY KEY,
    merchant_name VARCHAR(200),
    merchant_category VARCHAR(100),
    is_shell_merchant TINYINT(1),
    risk_rating VARCHAR(20),
    country VARCHAR(100)
);

CREATE TABLE fact_transactions (
    transaction_key BIGINT PRIMARY KEY,
    transaction_id VARCHAR(100),
    customer_key BIGINT,
    account_key BIGINT,
    merchant_key BIGINT,
    location_key BIGINT,
    date_key BIGINT,
    transaction_datetime DATETIME,
    transaction_date DATE,
    transaction_hour INT,
    transaction_type VARCHAR(50),
    channel VARCHAR(50),
    amount_usd DECIMAL(15, 2),
    currency VARCHAR(10),
    is_flagged TINYINT(1),
    fraud_type VARCHAR(100),
    is_off_hours TINYINT(1),
    status VARCHAR(50),
    
    -- Relationships
    FOREIGN KEY (customer_key) REFERENCES dim_customer(customer_key),
    FOREIGN KEY (account_key) REFERENCES dim_account(account_key),
    FOREIGN KEY (merchant_key) REFERENCES dim_merchant(merchant_key),
    FOREIGN KEY (location_key) REFERENCES dim_location(location_key),
    FOREIGN KEY (date_key) REFERENCES dim_date(date_key)
);
