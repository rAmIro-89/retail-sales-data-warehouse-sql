-- 10_analisis_rfm.sql
-- Análisis RFM (Recency, Frequency, Monetary) para segmentación de clientes

USE DW_Celulares;
GO

PRINT '=== Análisis RFM de Clientes ===';
PRINT '';
GO

-- =====================================================
-- 1. CÁLCULO DE MÉTRICAS RFM
-- =====================================================
PRINT '--- Cálculo de métricas RFM por cliente ---';

DECLARE @fecha_referencia DATE = CAST(GETDATE() AS DATE);

WITH ClienteMetricas AS (
    SELECT 
        c.sk_cliente,
        c.nombre,
        c.apellido,
        c.genero,
        -- RECENCY: Días desde la última compra
        DATEDIFF(DAY, MAX(d.fecha), @fecha_referencia) AS dias_ultima_compra,
        -- FREQUENCY: Número de transacciones
        COUNT(DISTINCT f.id_venta) AS num_transacciones,
        -- MONETARY: Total gastado
        SUM(f.importe) AS importe_total,
        -- Métricas adicionales
        AVG(f.importe) AS ticket_promedio,
        SUM(f.margen) AS margen_total
    FROM dbo.FactVentas f
    JOIN dbo.DimCliente c ON c.sk_cliente = f.sk_cliente
    JOIN dbo.DimFecha d ON d.sk_fecha = f.sk_fecha
    WHERE c.sk_cliente > 0
    GROUP BY c.sk_cliente, c.nombre, c.apellido, c.genero
),
-- Asignar quintiles (1-5) para cada métrica
ClienteQuintiles AS (
    SELECT 
        *,
        -- Recency: menor es mejor (invertimos la escala)
        NTILE(5) OVER (ORDER BY dias_ultima_compra DESC) AS r_score,
        -- Frequency: mayor es mejor
        NTILE(5) OVER (ORDER BY num_transacciones ASC) AS f_score,
        -- Monetary: mayor es mejor
        NTILE(5) OVER (ORDER BY importe_total ASC) AS m_score
    FROM ClienteMetricas
),
-- Calcular score combinado RFM
ClienteRFM AS (
    SELECT 
        *,
        (r_score + f_score + m_score) AS rfm_score,
        CAST(r_score AS VARCHAR) + CAST(f_score AS VARCHAR) + CAST(m_score AS VARCHAR) AS rfm_celula
    FROM ClienteQuintiles
)
SELECT 
    sk_cliente,
    nombre,
    apellido,
    genero,
    dias_ultima_compra,
    num_transacciones,
    ROUND(importe_total, 2) AS importe_total,
    ROUND(ticket_promedio, 2) AS ticket_promedio,
    ROUND(margen_total, 2) AS margen_total,
    r_score,
    f_score,
    m_score,
    rfm_score,
    rfm_celula,
    -- Segmentación basada en RFM
    CASE 
        WHEN rfm_score >= 13 THEN 'Champions (RFM alto)'
        WHEN rfm_score >= 10 THEN 'Loyal Customers (Leales)'
        WHEN rfm_score >= 8 AND r_score >= 4 THEN 'Potential Loyalists (Potencial)'
        WHEN rfm_score >= 8 THEN 'Recent Customers (Recientes)'
        WHEN rfm_score >= 6 AND f_score >= 3 THEN 'Promising (Prometedores)'
        WHEN rfm_score >= 6 THEN 'Customers Needing Attention (Necesitan atención)'
        WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk (En riesgo)'
        WHEN r_score <= 2 AND f_score <= 2 THEN 'Hibernating (Inactivos)'
        WHEN r_score <= 2 THEN 'Lost (Perdidos)'
        ELSE 'About to Sleep (Por dormir)'
    END AS segmento_rfm
FROM ClienteRFM
ORDER BY rfm_score DESC, importe_total DESC;

GO

-- =====================================================
-- 2. DISTRIBUCIÓN DE SEGMENTOS RFM
-- =====================================================
PRINT '--- Distribución de clientes por segmento RFM ---';

DECLARE @fecha_referencia DATE = CAST(GETDATE() AS DATE);

WITH ClienteMetricas AS (
    SELECT 
        c.sk_cliente,
        DATEDIFF(DAY, MAX(d.fecha), @fecha_referencia) AS dias_ultima_compra,
        COUNT(DISTINCT f.id_venta) AS num_transacciones,
        SUM(f.importe) AS importe_total
    FROM dbo.FactVentas f
    JOIN dbo.DimCliente c ON c.sk_cliente = f.sk_cliente
    JOIN dbo.DimFecha d ON d.sk_fecha = f.sk_fecha
    WHERE c.sk_cliente > 0
    GROUP BY c.sk_cliente
),
ClienteQuintiles AS (
    SELECT 
        *,
        NTILE(5) OVER (ORDER BY dias_ultima_compra DESC) AS r_score,
        NTILE(5) OVER (ORDER BY num_transacciones ASC) AS f_score,
        NTILE(5) OVER (ORDER BY importe_total ASC) AS m_score
    FROM ClienteMetricas
),
ClienteRFM AS (
    SELECT 
        *,
        (r_score + f_score + m_score) AS rfm_score,
        CASE 
            WHEN (r_score + f_score + m_score) >= 13 THEN 'Champions'
            WHEN (r_score + f_score + m_score) >= 10 THEN 'Loyal Customers'
            WHEN (r_score + f_score + m_score) >= 8 AND r_score >= 4 THEN 'Potential Loyalists'
            WHEN (r_score + f_score + m_score) >= 8 THEN 'Recent Customers'
            WHEN (r_score + f_score + m_score) >= 6 AND f_score >= 3 THEN 'Promising'
            WHEN (r_score + f_score + m_score) >= 6 THEN 'Needing Attention'
            WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
            WHEN r_score <= 2 AND f_score <= 2 THEN 'Hibernating'
            WHEN r_score <= 2 THEN 'Lost'
            ELSE 'About to Sleep'
        END AS segmento_rfm
    FROM ClienteQuintiles
)
SELECT 
    segmento_rfm,
    COUNT(*) AS num_clientes,
    ROUND((CAST(COUNT(*) AS FLOAT) / (SELECT COUNT(*) FROM ClienteRFM)) * 100, 2) AS porcentaje_clientes,
    SUM(importe_total) AS importe_total_segmento,
    ROUND(AVG(importe_total), 2) AS importe_promedio,
    ROUND(AVG(CAST(dias_ultima_compra AS FLOAT)), 1) AS dias_promedio_ultima_compra
FROM ClienteRFM
GROUP BY segmento_rfm
ORDER BY importe_total_segmento DESC;

GO

-- =====================================================
-- 3. CLIENTES TOP POR CADA MÉTRICA RFM
-- =====================================================
PRINT '--- Top 10 clientes por cada métrica RFM ---';

DECLARE @fecha_referencia DATE = CAST(GETDATE() AS DATE);

-- Top 10 por Recency (compra más reciente)
PRINT 'Top 10 - Recency (compra más reciente):';
SELECT TOP 10
    c.nombre,
    c.apellido,
    MAX(d.fecha) AS ultima_compra,
    DATEDIFF(DAY, MAX(d.fecha), @fecha_referencia) AS dias_desde_ultima_compra,
    COUNT(DISTINCT f.id_venta) AS num_compras,
    SUM(f.importe) AS importe_total
FROM dbo.FactVentas f
JOIN dbo.DimCliente c ON c.sk_cliente = f.sk_cliente
JOIN dbo.DimFecha d ON d.sk_fecha = f.sk_fecha
WHERE c.sk_cliente > 0
GROUP BY c.nombre, c.apellido
ORDER BY ultima_compra DESC;

-- Top 10 por Frequency (más compras)
PRINT 'Top 10 - Frequency (más compras):';
SELECT TOP 10
    c.nombre,
    c.apellido,
    COUNT(DISTINCT f.id_venta) AS num_compras,
    SUM(f.importe) AS importe_total,
    ROUND(AVG(f.importe), 2) AS ticket_promedio,
    MAX(d.fecha) AS ultima_compra
FROM dbo.FactVentas f
JOIN dbo.DimCliente c ON c.sk_cliente = f.sk_cliente
JOIN dbo.DimFecha d ON d.sk_fecha = f.sk_fecha
WHERE c.sk_cliente > 0
GROUP BY c.nombre, c.apellido
ORDER BY num_compras DESC, importe_total DESC;

-- Top 10 por Monetary (mayor gasto)
PRINT 'Top 10 - Monetary (mayor gasto):';
SELECT TOP 10
    c.nombre,
    c.apellido,
    SUM(f.importe) AS importe_total,
    SUM(f.margen) AS margen_total,
    COUNT(DISTINCT f.id_venta) AS num_compras,
    ROUND(AVG(f.importe), 2) AS ticket_promedio,
    MAX(d.fecha) AS ultima_compra
FROM dbo.FactVentas f
JOIN dbo.DimCliente c ON c.sk_cliente = f.sk_cliente
JOIN dbo.DimFecha d ON d.sk_fecha = f.sk_fecha
WHERE c.sk_cliente > 0
GROUP BY c.nombre, c.apellido
ORDER BY importe_total DESC;

GO

-- =====================================================
-- 4. RECOMENDACIONES DE ACCIÓN POR SEGMENTO
-- =====================================================
PRINT '--- Estrategias recomendadas por segmento RFM ---';

SELECT 
    'Champions' AS segmento,
    'Recompensarlos, pedirles reseñas, ofrecer programas VIP' AS accion_recomendada
UNION ALL
SELECT 'Loyal Customers', 'Upselling, cross-selling, programas de lealtad'
UNION ALL
SELECT 'Potential Loyalists', 'Ofertas de membresía, programas de puntos'
UNION ALL
SELECT 'Recent Customers', 'Onboarding, educación de producto, soporte'
UNION ALL
SELECT 'Promising', 'Ofertas especiales, crear conciencia de marca'
UNION ALL
SELECT 'Needing Attention', 'Reactivación limitada, ofertas personalizadas'
UNION ALL
SELECT 'At Risk', 'Ganar de vuelta con ofertas agresivas, encuestas'
UNION ALL
SELECT 'Hibernating', 'Campañas de reactivación, descuentos especiales'
UNION ALL
SELECT 'Lost', 'Ignorar o campañas mínimas, enfoque en nuevos clientes'
UNION ALL
SELECT 'About to Sleep', 'Reactivación preventiva, recordatorios';

GO

PRINT '';
PRINT '=== Análisis RFM completado ===';
GO
