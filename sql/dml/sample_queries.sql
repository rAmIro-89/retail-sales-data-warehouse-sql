-- ============================================================================
-- Retail Sales Data Warehouse - DML Script
-- ============================================================================
-- Sample data manipulation queries for the retail sales data warehouse
-- ============================================================================

-- ============================================================================
-- Sample INSERT Statements
-- ============================================================================

-- Sample Date Dimension Data (for demonstration)
-- INSERT INTO dim_date (date_id, date, year, quarter, month, month_name, week, day_of_week, day_name, is_weekend, is_holiday)
-- VALUES 
--     (20240101, '2024-01-01', 2024, 1, 1, 'January', 1, 2, 'Monday', FALSE, TRUE),
--     (20240102, '2024-01-02', 2024, 1, 1, 'January', 1, 3, 'Tuesday', FALSE, FALSE);

-- ============================================================================
-- Sample UPDATE Statements
-- ============================================================================

-- Update customer segment
-- UPDATE dim_customer
-- SET customer_segment = 'Premium'
-- WHERE customer_id IN (
--     SELECT customer_id 
--     FROM v_customer_analytics 
--     WHERE lifetime_value > 10000
-- );

-- Update product status
-- UPDATE dim_product
-- SET is_active = FALSE
-- WHERE product_id IN (
--     SELECT product_id 
--     FROM dim_product 
--     WHERE product_id NOT IN (
--         SELECT DISTINCT product_id 
--         FROM fact_sales 
--         WHERE date_id >= 20230101
--     )
-- );

-- ============================================================================
-- Sample DELETE Statements (with caution)
-- ============================================================================

-- Note: Generally avoid deleting from fact tables in a data warehouse
-- Instead, consider marking records as deleted or using effective dating

-- DELETE FROM fact_sales
-- WHERE sale_id IN (
--     SELECT sale_id 
--     FROM fact_sales 
--     WHERE total_amount < 0  -- Remove erroneous records
-- );

-- ============================================================================
-- Common Query Patterns
-- ============================================================================

-- Total sales by year and month
-- SELECT 
--     year,
--     month,
--     month_name,
--     total_revenue
-- FROM v_monthly_sales
-- ORDER BY year DESC, month DESC;

-- Top 10 products by revenue
-- SELECT 
--     product_name,
--     category,
--     total_revenue
-- FROM v_product_performance
-- LIMIT 10;

-- Customer lifetime value ranking
-- SELECT 
--     customer_name,
--     customer_segment,
--     lifetime_value,
--     total_purchases
-- FROM v_customer_analytics
-- ORDER BY lifetime_value DESC
-- LIMIT 20;

-- Store comparison
-- SELECT 
--     store_name,
--     city,
--     total_revenue,
--     unique_customers
-- FROM v_store_performance
-- ORDER BY total_revenue DESC;
