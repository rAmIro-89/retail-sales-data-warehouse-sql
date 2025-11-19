-- ============================================================================
-- Retail Sales Data Warehouse - DDL Script
-- ============================================================================
-- This script creates the dimensional model (star schema) for retail sales
-- analytics. It includes dimension and fact tables.
-- ============================================================================

-- Drop tables if they exist (for clean re-creation)
DROP TABLE IF EXISTS fact_sales CASCADE;
DROP TABLE IF EXISTS dim_customer CASCADE;
DROP TABLE IF EXISTS dim_product CASCADE;
DROP TABLE IF EXISTS dim_store CASCADE;
DROP TABLE IF EXISTS dim_date CASCADE;

-- ============================================================================
-- Dimension Tables
-- ============================================================================

-- Date Dimension
CREATE TABLE dim_date (
    date_id INT PRIMARY KEY,
    date DATE NOT NULL,
    year INT NOT NULL,
    quarter INT NOT NULL,
    month INT NOT NULL,
    month_name VARCHAR(20) NOT NULL,
    week INT NOT NULL,
    day_of_week INT NOT NULL,
    day_name VARCHAR(20) NOT NULL,
    is_weekend BOOLEAN NOT NULL,
    is_holiday BOOLEAN DEFAULT FALSE
);

-- Customer Dimension
CREATE TABLE dim_customer (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    email VARCHAR(100),
    phone VARCHAR(20),
    address VARCHAR(200),
    city VARCHAR(50),
    state VARCHAR(50),
    zip_code VARCHAR(10),
    country VARCHAR(50),
    customer_segment VARCHAR(50),
    registration_date DATE,
    CONSTRAINT customer_email_unique UNIQUE(email)
);

-- Product Dimension
CREATE TABLE dim_product (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    product_description TEXT,
    category VARCHAR(50) NOT NULL,
    sub_category VARCHAR(50),
    brand VARCHAR(50),
    unit_price DECIMAL(10, 2) NOT NULL,
    cost DECIMAL(10, 2),
    supplier VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE
);

-- Store Dimension
CREATE TABLE dim_store (
    store_id INT PRIMARY KEY,
    store_name VARCHAR(100) NOT NULL,
    address VARCHAR(200),
    city VARCHAR(50) NOT NULL,
    state VARCHAR(50) NOT NULL,
    zip_code VARCHAR(10),
    country VARCHAR(50) NOT NULL,
    store_type VARCHAR(50),
    square_footage INT,
    manager_name VARCHAR(100),
    opening_date DATE
);

-- ============================================================================
-- Fact Tables
-- ============================================================================

-- Sales Fact Table
CREATE TABLE fact_sales (
    sale_id BIGINT PRIMARY KEY,
    date_id INT NOT NULL,
    customer_id INT NOT NULL,
    product_id INT NOT NULL,
    store_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    discount_amount DECIMAL(10, 2) DEFAULT 0,
    tax_amount DECIMAL(10, 2) DEFAULT 0,
    total_amount DECIMAL(12, 2) NOT NULL,
    CONSTRAINT fk_date FOREIGN KEY (date_id) REFERENCES dim_date(date_id),
    CONSTRAINT fk_customer FOREIGN KEY (customer_id) REFERENCES dim_customer(customer_id),
    CONSTRAINT fk_product FOREIGN KEY (product_id) REFERENCES dim_product(product_id),
    CONSTRAINT fk_store FOREIGN KEY (store_id) REFERENCES dim_store(store_id)
);

-- ============================================================================
-- Indexes for Performance Optimization
-- ============================================================================

-- Date dimension indexes
CREATE INDEX idx_dim_date_date ON dim_date(date);
CREATE INDEX idx_dim_date_year_month ON dim_date(year, month);

-- Customer dimension indexes
CREATE INDEX idx_dim_customer_city ON dim_customer(city);
CREATE INDEX idx_dim_customer_segment ON dim_customer(customer_segment);

-- Product dimension indexes
CREATE INDEX idx_dim_product_category ON dim_product(category);
CREATE INDEX idx_dim_product_brand ON dim_product(brand);

-- Store dimension indexes
CREATE INDEX idx_dim_store_city ON dim_store(city);
CREATE INDEX idx_dim_store_type ON dim_store(store_type);

-- Fact table indexes
CREATE INDEX idx_fact_sales_date ON fact_sales(date_id);
CREATE INDEX idx_fact_sales_customer ON fact_sales(customer_id);
CREATE INDEX idx_fact_sales_product ON fact_sales(product_id);
CREATE INDEX idx_fact_sales_store ON fact_sales(store_id);
CREATE INDEX idx_fact_sales_date_store ON fact_sales(date_id, store_id);

-- ============================================================================
-- Comments
-- ============================================================================

COMMENT ON TABLE dim_date IS 'Date dimension for time-based analysis';
COMMENT ON TABLE dim_customer IS 'Customer dimension containing customer details';
COMMENT ON TABLE dim_product IS 'Product dimension containing product catalog';
COMMENT ON TABLE dim_store IS 'Store dimension containing store locations and details';
COMMENT ON TABLE fact_sales IS 'Fact table containing sales transactions';
