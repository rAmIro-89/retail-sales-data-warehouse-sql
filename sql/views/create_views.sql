-- ============================================================================
-- Retail Sales Data Warehouse - Views
-- ============================================================================
-- This script creates analytical views for common reporting needs
-- ============================================================================

-- Drop views if they exist
DROP VIEW IF EXISTS v_sales_summary CASCADE;
DROP VIEW IF EXISTS v_monthly_sales CASCADE;
DROP VIEW IF EXISTS v_product_performance CASCADE;
DROP VIEW IF EXISTS v_customer_analytics CASCADE;
DROP VIEW IF EXISTS v_store_performance CASCADE;

-- ============================================================================
-- Sales Summary View
-- ============================================================================
CREATE VIEW v_sales_summary AS
SELECT 
    fs.sale_id,
    dd.date,
    dd.year,
    dd.month,
    dd.month_name,
    dc.customer_name,
    dc.customer_segment,
    dp.product_name,
    dp.category,
    dp.sub_category,
    ds.store_name,
    ds.city AS store_city,
    ds.state AS store_state,
    fs.quantity,
    fs.unit_price,
    fs.discount_amount,
    fs.tax_amount,
    fs.total_amount,
    (fs.total_amount - fs.discount_amount - fs.tax_amount) AS net_sales
FROM fact_sales fs
JOIN dim_date dd ON fs.date_id = dd.date_id
JOIN dim_customer dc ON fs.customer_id = dc.customer_id
JOIN dim_product dp ON fs.product_id = dp.product_id
JOIN dim_store ds ON fs.store_id = ds.store_id;

-- ============================================================================
-- Monthly Sales View
-- ============================================================================
CREATE VIEW v_monthly_sales AS
SELECT 
    dd.year,
    dd.month,
    dd.month_name,
    COUNT(DISTINCT fs.sale_id) AS total_transactions,
    SUM(fs.quantity) AS total_quantity,
    SUM(fs.total_amount) AS total_revenue,
    SUM(fs.discount_amount) AS total_discounts,
    SUM(fs.tax_amount) AS total_tax,
    AVG(fs.total_amount) AS avg_transaction_value
FROM fact_sales fs
JOIN dim_date dd ON fs.date_id = dd.date_id
GROUP BY dd.year, dd.month, dd.month_name
ORDER BY dd.year, dd.month;

-- ============================================================================
-- Product Performance View
-- ============================================================================
CREATE VIEW v_product_performance AS
SELECT 
    dp.product_id,
    dp.product_name,
    dp.category,
    dp.sub_category,
    dp.brand,
    COUNT(DISTINCT fs.sale_id) AS total_transactions,
    SUM(fs.quantity) AS total_quantity_sold,
    SUM(fs.total_amount) AS total_revenue,
    AVG(fs.total_amount) AS avg_sale_amount,
    SUM(fs.total_amount) - (SUM(fs.quantity) * dp.cost) AS total_profit
FROM fact_sales fs
JOIN dim_product dp ON fs.product_id = dp.product_id
GROUP BY dp.product_id, dp.product_name, dp.category, dp.sub_category, dp.brand, dp.cost
ORDER BY total_revenue DESC;

-- ============================================================================
-- Customer Analytics View
-- ============================================================================
CREATE VIEW v_customer_analytics AS
SELECT 
    dc.customer_id,
    dc.customer_name,
    dc.customer_segment,
    dc.city,
    dc.state,
    COUNT(DISTINCT fs.sale_id) AS total_purchases,
    SUM(fs.quantity) AS total_items_purchased,
    SUM(fs.total_amount) AS lifetime_value,
    AVG(fs.total_amount) AS avg_purchase_value,
    MIN(dd.date) AS first_purchase_date,
    MAX(dd.date) AS last_purchase_date
FROM fact_sales fs
JOIN dim_customer dc ON fs.customer_id = dc.customer_id
JOIN dim_date dd ON fs.date_id = dd.date_id
GROUP BY dc.customer_id, dc.customer_name, dc.customer_segment, dc.city, dc.state
ORDER BY lifetime_value DESC;

-- ============================================================================
-- Store Performance View
-- ============================================================================
CREATE VIEW v_store_performance AS
SELECT 
    ds.store_id,
    ds.store_name,
    ds.city,
    ds.state,
    ds.store_type,
    COUNT(DISTINCT fs.sale_id) AS total_transactions,
    SUM(fs.quantity) AS total_quantity_sold,
    SUM(fs.total_amount) AS total_revenue,
    AVG(fs.total_amount) AS avg_transaction_value,
    COUNT(DISTINCT fs.customer_id) AS unique_customers
FROM fact_sales fs
JOIN dim_store ds ON fs.store_id = ds.store_id
GROUP BY ds.store_id, ds.store_name, ds.city, ds.state, ds.store_type
ORDER BY total_revenue DESC;

-- ============================================================================
-- Comments
-- ============================================================================

COMMENT ON VIEW v_sales_summary IS 'Comprehensive sales summary with all dimension details';
COMMENT ON VIEW v_monthly_sales IS 'Monthly aggregated sales metrics';
COMMENT ON VIEW v_product_performance IS 'Product-level performance metrics';
COMMENT ON VIEW v_customer_analytics IS 'Customer behavior and lifetime value analytics';
COMMENT ON VIEW v_store_performance IS 'Store-level performance metrics';
