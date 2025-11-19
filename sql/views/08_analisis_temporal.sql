-- 08_analisis_temporal.sql
-- Consultas analíticas avanzadas: análisis temporal Year-over-Year y Month-over-Month

USE DW_Celulares;
GO

-- =====================================================
-- 1. ANÁLISIS YEAR-OVER-YEAR (YoY)
-- =====================================================
PRINT '--- Year-over-Year (YoY) Analysis ---';

WITH VentasAnuales AS (
    SELECT 
        d.anio,
        SUM(f.importe) AS importe_total,
        SUM(f.margen) AS margen_total,
        COUNT(DISTINCT f.id_venta) AS num_ventas,
        SUM(f.cantidad) AS unidades_vendidas
    FROM dbo.FactVentas f
    JOIN dbo.DimFecha d ON d.sk_fecha = f.sk_fecha
    GROUP BY d.anio
)
SELECT 
    anio,
    importe_total,
    margen_total,
    num_ventas,
    unidades_vendidas,
    LAG(importe_total, 1) OVER (ORDER BY anio) AS importe_anio_anterior,
    CASE 
        WHEN LAG(importe_total, 1) OVER (ORDER BY anio) IS NOT NULL 
        THEN ROUND(((importe_total - LAG(importe_total, 1) OVER (ORDER BY anio)) / LAG(importe_total, 1) OVER (ORDER BY anio)) * 100, 2)
        ELSE NULL
    END AS variacion_yoy_porcentaje,
    importe_total - LAG(importe_total, 1) OVER (ORDER BY anio) AS variacion_yoy_absoluta
FROM VentasAnuales
ORDER BY anio;

GO

-- =====================================================
-- 2. ANÁLISIS MONTH-OVER-MONTH (MoM)
-- =====================================================
PRINT '--- Month-over-Month (MoM) Analysis ---';

WITH VentasMensuales AS (
    SELECT 
        d.anio,
        d.mes,
        d.nombre_mes,
        SUM(f.importe) AS importe_total,
        SUM(f.margen) AS margen_total,
        COUNT(DISTINCT f.id_venta) AS num_ventas
    FROM dbo.FactVentas f
    JOIN dbo.DimFecha d ON d.sk_fecha = f.sk_fecha
    GROUP BY d.anio, d.mes, d.nombre_mes
)
SELECT 
    anio,
    mes,
    nombre_mes,
    importe_total,
    margen_total,
    num_ventas,
    LAG(importe_total, 1) OVER (ORDER BY anio, mes) AS importe_mes_anterior,
    CASE 
        WHEN LAG(importe_total, 1) OVER (ORDER BY anio, mes) IS NOT NULL AND LAG(importe_total, 1) OVER (ORDER BY anio, mes) > 0
        THEN ROUND(((importe_total - LAG(importe_total, 1) OVER (ORDER BY anio, mes)) / LAG(importe_total, 1) OVER (ORDER BY anio, mes)) * 100, 2)
        ELSE NULL
    END AS variacion_mom_porcentaje,
    importe_total - LAG(importe_total, 1) OVER (ORDER BY anio, mes) AS variacion_mom_absoluta
FROM VentasMensuales
ORDER BY anio, mes;

GO

-- =====================================================
-- 3. ANÁLISIS DE TENDENCIA CON PROMEDIOS MÓVILES
-- =====================================================
PRINT '--- Promedios Móviles (3 meses) ---';

WITH VentasMensuales AS (
    SELECT 
        d.anio,
        d.mes,
        d.nombre_mes,
        SUM(f.importe) AS importe_total,
        SUM(f.margen) AS margen_total
    FROM dbo.FactVentas f
    JOIN dbo.DimFecha d ON d.sk_fecha = f.sk_fecha
    GROUP BY d.anio, d.mes, d.nombre_mes
)
SELECT 
    anio,
    mes,
    nombre_mes,
    importe_total,
    margen_total,
    AVG(importe_total) OVER (ORDER BY anio, mes ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS promedio_movil_3meses,
    AVG(margen_total) OVER (ORDER BY anio, mes ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS promedio_movil_margen_3meses
FROM VentasMensuales
ORDER BY anio, mes;

GO

-- =====================================================
-- 4. ESTACIONALIDAD POR DÍA DE SEMANA
-- =====================================================
PRINT '--- Análisis de Estacionalidad por Día de Semana ---';

SELECT 
    d.dia_semana,
    COUNT(DISTINCT f.id_venta) AS num_ventas,
    SUM(f.importe) AS importe_total,
    AVG(f.importe) AS importe_promedio,
    SUM(f.margen) AS margen_total,
    ROUND(AVG(f.margen_porcentaje), 2) AS margen_porcentaje_promedio,
    SUM(f.cantidad) AS unidades_vendidas
FROM dbo.FactVentas f
JOIN dbo.DimFecha d ON d.sk_fecha = f.sk_fecha
GROUP BY d.dia_semana
ORDER BY 
    CASE d.dia_semana
        WHEN 'Lunes' THEN 1
        WHEN 'Martes' THEN 2
        WHEN 'Miércoles' THEN 3
        WHEN 'Jueves' THEN 4
        WHEN 'Viernes' THEN 5
        WHEN 'Sábado' THEN 6
        WHEN 'Domingo' THEN 7
    END;

GO

-- =====================================================
-- 5. COMPARACIÓN FIN DE SEMANA VS DÍA LABORABLE
-- =====================================================
PRINT '--- Fin de Semana vs. Días Laborables ---';

SELECT 
    CASE WHEN d.es_fin_semana = 1 THEN 'Fin de semana' ELSE 'Día laborable' END AS tipo_dia,
    COUNT(DISTINCT f.id_venta) AS num_ventas,
    SUM(f.importe) AS importe_total,
    AVG(f.importe) AS ticket_promedio,
    SUM(f.margen) AS margen_total,
    ROUND(AVG(f.margen_porcentaje), 2) AS margen_porcentaje_promedio
FROM dbo.FactVentas f
JOIN dbo.DimFecha d ON d.sk_fecha = f.sk_fecha
GROUP BY d.es_fin_semana;

GO

-- =====================================================
-- 6. ANÁLISIS DE TRIMESTRES CON RANKING
-- =====================================================
PRINT '--- Análisis Trimestral con Ranking ---';

WITH VentasTrimestrales AS (
    SELECT 
        d.anio,
        d.trimestre,
        SUM(f.importe) AS importe_total,
        SUM(f.margen) AS margen_total,
        COUNT(DISTINCT f.id_venta) AS num_ventas
    FROM dbo.FactVentas f
    JOIN dbo.DimFecha d ON d.sk_fecha = f.sk_fecha
    GROUP BY d.anio, d.trimestre
)
SELECT 
    anio,
    trimestre,
    importe_total,
    margen_total,
    num_ventas,
    RANK() OVER (ORDER BY importe_total DESC) AS ranking_importe,
    DENSE_RANK() OVER (PARTITION BY anio ORDER BY importe_total DESC) AS ranking_anual
FROM VentasTrimestrales
ORDER BY anio, trimestre;

GO

-- =====================================================
-- 7. ACUMULADO ANUAL (Running Total)
-- =====================================================
PRINT '--- Acumulado Anual (Running Total) ---';

WITH VentasDiarias AS (
    SELECT 
        d.fecha,
        d.anio,
        d.mes,
        SUM(f.importe) AS importe_diario
    FROM dbo.FactVentas f
    JOIN dbo.DimFecha d ON d.sk_fecha = f.sk_fecha
    GROUP BY d.fecha, d.anio, d.mes
)
SELECT 
    fecha,
    anio,
    mes,
    importe_diario,
    SUM(importe_diario) OVER (PARTITION BY anio ORDER BY fecha) AS acumulado_anual,
    SUM(importe_diario) OVER (PARTITION BY anio, mes ORDER BY fecha) AS acumulado_mensual
FROM VentasDiarias
ORDER BY fecha DESC;

GO
