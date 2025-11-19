-- =====================================================
-- COMPLETAR TIPOS DE CAMBIO FALTANTES
-- =====================================================
-- Aplica la corrección del ETL a una base de datos ya existente
-- Genera tipos de cambio para TODOS los meses 2023-2024
-- =====================================================

USE DW_Celulares;
GO

PRINT '=== COMPLETANDO TIPOS DE CAMBIO PARA TODOS LOS MESES ===';

-- Mostrar estado actual
PRINT 'Estado ANTES de la corrección:';
SELECT 
    YEAR(fecha) AS anio,
    MONTH(fecha) AS mes,
    COUNT(DISTINCT codigo_moneda) AS monedas_disponibles
FROM dbo.DimExchangeRate
WHERE YEAR(fecha) IN (2023, 2024)
GROUP BY YEAR(fecha), MONTH(fecha)
ORDER BY anio, mes;

PRINT '';
PRINT 'Insertando tipos de cambio faltantes...';

-- CORRECCIÓN: Generar TODOS los meses del rango
;WITH Meses AS (
  -- Generar secuencia completa de meses desde 2023-01 hasta 2024-12
  SELECT DATEADD(MONTH, n, '2023-01-01') AS fecha_mes
  FROM (
    SELECT 0 AS n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 
    UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 
    UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11
    UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15
    UNION ALL SELECT 16 UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19
    UNION ALL SELECT 20 UNION ALL SELECT 21 UNION ALL SELECT 22 UNION ALL SELECT 23
  ) AS Numeros
  WHERE DATEADD(MONTH, n, '2023-01-01') <= '2024-12-01'
),
Monedas AS (
  SELECT codigo_moneda, sk_moneda,
       CASE codigo_moneda
        WHEN 'ARS' THEN CAST(1.0000 AS DECIMAL(18,6))
        WHEN 'USD' THEN CAST(350.0000 AS DECIMAL(18,6))
        WHEN 'EUR' THEN CAST(380.0000 AS DECIMAL(18,6))
        WHEN 'BRL' THEN CAST(70.0000  AS DECIMAL(18,6))
        WHEN 'CNY' THEN CAST(50.0000  AS DECIMAL(18,6))
        ELSE CAST(1.0000 AS DECIMAL(18,6))
       END AS base_rate
  FROM dbo.DimMoneda
  WHERE codigo_moneda IN ('ARS','USD','EUR','BRL','CNY')
)
INSERT INTO dbo.DimExchangeRate (sk_moneda, fecha, codigo_moneda, tasa_ars_por_unidad, fuente)
SELECT m.sk_moneda,
     ms.fecha_mes,
     m.codigo_moneda,
     CAST(ROUND(m.base_rate * POWER(1.01, ROW_NUMBER() OVER (PARTITION BY m.codigo_moneda ORDER BY ms.fecha_mes) - 1), 4) AS DECIMAL(18,6)) AS tasa_ars_por_unidad,
     N'Fuente sintética (demo)'
FROM Meses ms
CROSS JOIN Monedas m
WHERE NOT EXISTS (
  SELECT 1 FROM dbo.DimExchangeRate ex
  WHERE ex.sk_moneda = m.sk_moneda AND ex.fecha = ms.fecha_mes
);

DECLARE @TotalRegistros INT = (SELECT COUNT(*) FROM dbo.DimExchangeRate);
PRINT CONCAT('✓ Registros insertados. Total ahora: ', @TotalRegistros);
PRINT '  (Deberían ser 120 registros = 24 meses x 5 monedas)';

-- Mostrar estado final
PRINT '';
PRINT 'Estado DESPUÉS de la corrección:';
SELECT 
    YEAR(fecha) AS anio,
    MONTH(fecha) AS mes,
    COUNT(DISTINCT codigo_moneda) AS monedas_disponibles
FROM dbo.DimExchangeRate
WHERE YEAR(fecha) IN (2023, 2024)
GROUP BY YEAR(fecha), MONTH(fecha)
ORDER BY anio, mes;

-- Verificar específicamente el Trimestre 2 de 2024
PRINT '';
PRINT '📊 TRIMESTRE 2 de 2024 (el que estaba faltando):';
SELECT 
    FORMAT(fecha, 'yyyy-MM') AS mes,
    codigo_moneda,
    tasa_ars_por_unidad
FROM dbo.DimExchangeRate
WHERE YEAR(fecha) = 2024 
  AND MONTH(fecha) BETWEEN 4 AND 6
ORDER BY fecha, codigo_moneda;

PRINT '';
PRINT '=== CORRECCIÓN COMPLETADA ===';
PRINT '✓ Ahora TODOS los meses de 2023-2024 tienen las 5 monedas';
PRINT '✓ El notebook mostrará correctamente los gráficos multimoneda';
GO
