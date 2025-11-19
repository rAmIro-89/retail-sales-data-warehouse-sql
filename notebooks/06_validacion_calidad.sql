-- 06_validacion_calidad.sql
-- Script de validación de calidad de datos del Data Warehouse
-- Detecta problemas de integridad, duplicados, outliers y valores nulos

USE DW_Celulares;
GO

PRINT '=== VALIDACIÓN DE CALIDAD DE DATOS - Data Warehouse ===';
PRINT CONCAT('Fecha de ejecución: ', GETDATE());
PRINT '';
GO

-- =====================================================
-- 1. VALIDACIÓN DE CLAVES HUÉRFANAS
-- =====================================================
PRINT '--- 1. Validación de claves huérfanas ---';

-- Hechos con claves -1 (Unknown)
SELECT 
    'FactVentas con Cliente Unknown' AS problema,
    COUNT(*) AS cantidad
FROM dbo.FactVentas
WHERE sk_cliente = -1
UNION ALL
SELECT 
    'FactVentas con Producto Unknown',
    COUNT(*)
FROM dbo.FactVentas
WHERE sk_producto = -1
UNION ALL
SELECT 
    'FactVentas con Local Unknown',
    COUNT(*)
FROM dbo.FactVentas
WHERE sk_local = -1
UNION ALL
SELECT 
    'FactVentas con Vendedor Unknown',
    COUNT(*)
FROM dbo.FactVentas
WHERE sk_vendedor = -1
UNION ALL
SELECT 
    'FactVentas con FormaPago Unknown',
    COUNT(*)
FROM dbo.FactVentas
WHERE sk_forma_pago = -1
UNION ALL
SELECT 
    'FactVentas con Canal Unknown',
    COUNT(*)
FROM dbo.FactVentas
WHERE sk_canal = -1
UNION ALL
SELECT 
    'FactVentas con Moneda Unknown',
    COUNT(*)
FROM dbo.FactVentas
WHERE sk_moneda = -1;

PRINT '';
GO

-- =====================================================
-- 2. VALIDACIÓN DE DUPLICADOS
-- =====================================================
PRINT '--- 2. Validación de duplicados ---';

-- Duplicados en FactVentas (PK)
SELECT 
    'Duplicados en FactVentas (id_venta + id_detalle)' AS problema,
    COUNT(*) AS cantidad
FROM (
    SELECT id_venta, id_detalle, COUNT(*) AS cnt
    FROM dbo.FactVentas
    GROUP BY id_venta, id_detalle
    HAVING COUNT(*) > 1
) dup;

-- Duplicados en DimCliente (business key)
SELECT 
    'Duplicados en DimCliente (id_cliente_fuente)' AS problema,
    COUNT(*) AS cantidad
FROM (
    SELECT id_cliente_fuente, COUNT(*) AS cnt
    FROM dbo.DimCliente
    WHERE sk_cliente > 0
    GROUP BY id_cliente_fuente
    HAVING COUNT(*) > 1
) dup;

-- Múltiples versiones activas en DimProducto (SCD2)
SELECT 
    'Productos con múltiples versiones activas (error SCD2)' AS problema,
    COUNT(*) AS cantidad
FROM (
    SELECT id_modelo_fuente, COUNT(*) AS cnt
    FROM dbo.DimProducto
    WHERE es_actual = 1 AND sk_producto > 0
    GROUP BY id_modelo_fuente
    HAVING COUNT(*) > 1
) dup;

PRINT '';
GO

-- =====================================================
-- 3. VALIDACIÓN DE INTEGRIDAD REFERENCIAL
-- =====================================================
PRINT '--- 3. Validación de integridad referencial ---';

-- FactVentas sin dimensión válida (además de -1)
DECLARE @errores_fk INT = 0;

SELECT @errores_fk = COUNT(*)
FROM dbo.FactVentas f
LEFT JOIN dbo.DimFecha df ON df.sk_fecha = f.sk_fecha
WHERE df.sk_fecha IS NULL AND f.sk_fecha != -1;

IF @errores_fk > 0
    PRINT CONCAT('ERROR: ', @errores_fk, ' registros en FactVentas con sk_fecha inválido');
ELSE
    PRINT '✓ Todas las foreign keys a DimFecha son válidas';

SELECT @errores_fk = COUNT(*)
FROM dbo.FactVentas f
LEFT JOIN dbo.DimCliente dc ON dc.sk_cliente = f.sk_cliente
WHERE dc.sk_cliente IS NULL AND f.sk_cliente != -1;

IF @errores_fk > 0
    PRINT CONCAT('ERROR: ', @errores_fk, ' registros en FactVentas con sk_cliente inválido');
ELSE
    PRINT '✓ Todas las foreign keys a DimCliente son válidas';

SELECT @errores_fk = COUNT(*)
FROM dbo.FactVentas f
LEFT JOIN dbo.DimProducto dp ON dp.sk_producto = f.sk_producto
WHERE dp.sk_producto IS NULL AND f.sk_producto != -1;

IF @errores_fk > 0
    PRINT CONCAT('ERROR: ', @errores_fk, ' registros en FactVentas con sk_producto inválido');
ELSE
    PRINT '✓ Todas las foreign keys a DimProducto son válidas';

SELECT @errores_fk = COUNT(*)
FROM dbo.FactVentas f
LEFT JOIN dbo.DimMoneda dm ON dm.sk_moneda = f.sk_moneda
WHERE dm.sk_moneda IS NULL AND f.sk_moneda != -1;

IF @errores_fk > 0
    PRINT CONCAT('ERROR: ', @errores_fk, ' registros en FactVentas con sk_moneda inválido');
ELSE
    PRINT '✓ Todas las foreign keys a DimMoneda son válidas';

PRINT '';
GO

-- =====================================================
-- 4. VALIDACIÓN DE VALORES NULOS EN MÉTRICAS
-- =====================================================
PRINT '--- 4. Validación de valores nulos ---';

SELECT 
    'FactVentas.importe IS NULL' AS problema,
    COUNT(*) AS cantidad
FROM dbo.FactVentas
WHERE importe IS NULL
UNION ALL
SELECT 
    'FactVentas.margen IS NULL',
    COUNT(*)
FROM dbo.FactVentas
WHERE margen IS NULL
UNION ALL
SELECT 
    'FactVentas.cantidad IS NULL o <= 0',
    COUNT(*)
FROM dbo.FactVentas
WHERE cantidad IS NULL OR cantidad <= 0
UNION ALL
SELECT 
    'FactVentas.precio_unitario IS NULL o <= 0',
    COUNT(*)
FROM dbo.FactVentas
WHERE precio_unitario IS NULL OR precio_unitario <= 0;

PRINT '';
GO

-- =====================================================
-- 5. DETECCIÓN DE OUTLIERS
-- =====================================================
PRINT '--- 5. Detección de outliers (valores anómalos) ---';

-- Ventas con precio unitario extremadamente alto
SELECT 
    'Ventas con precio_unitario > $1,000,000' AS outlier,
    COUNT(*) AS cantidad
FROM dbo.FactVentas
WHERE precio_unitario > 1000000
UNION ALL
-- Ventas con margen negativo mayor a -50%
SELECT 
    'Ventas con margen_porcentaje < -50%',
    COUNT(*)
FROM dbo.FactVentas
WHERE margen_porcentaje < -50
UNION ALL
-- Ventas con cantidad anormalmente alta
SELECT 
    'Ventas con cantidad > 100 unidades',
    COUNT(*)
FROM dbo.FactVentas
WHERE cantidad > 100
UNION ALL
-- Ventas con margen mayor a 90%
SELECT 
    'Ventas con margen_porcentaje > 90%',
    COUNT(*)
FROM dbo.FactVentas
WHERE margen_porcentaje > 90;

PRINT '';
GO

-- =====================================================
-- 6. VALIDACIÓN DE CONSISTENCIA TEMPORAL
-- =====================================================
PRINT '--- 6. Validación de consistencia temporal ---';

-- Productos con fecha_fin anterior a fecha_inicio (error SCD2)
SELECT 
    'Productos con fecha_fin < fecha_inicio' AS problema,
    COUNT(*) AS cantidad
FROM dbo.DimProducto
WHERE fecha_fin IS NOT NULL AND fecha_fin < fecha_inicio;

-- Productos activos con fecha_fin no nula
SELECT 
    'Productos activos con fecha_fin no NULL' AS problema,
    COUNT(*) AS cantidad
FROM dbo.DimProducto
WHERE es_actual = 1 AND fecha_fin IS NOT NULL;

-- Productos inactivos sin fecha_fin
SELECT 
    'Productos inactivos sin fecha_fin' AS problema,
    COUNT(*) AS cantidad
FROM dbo.DimProducto
WHERE es_actual = 0 AND fecha_fin IS NULL;

PRINT '';
GO

-- =====================================================
-- 7. RESUMEN DE CARDINALIDAD
-- =====================================================
PRINT '--- 7. Resumen de cardinalidad ---';

SELECT 
    'DimFecha' AS dimension,
    COUNT(*) AS total_registros,
    MIN(fecha) AS fecha_min,
    MAX(fecha) AS fecha_max
FROM dbo.DimFecha
UNION ALL
SELECT 
    'DimCliente',
    COUNT(*),
    NULL,
    NULL
FROM dbo.DimCliente
WHERE sk_cliente > 0
UNION ALL
SELECT 
    'DimProducto (versiones activas)',
    COUNT(*),
    NULL,
    NULL
FROM dbo.DimProducto
WHERE es_actual = 1 AND sk_producto > 0
UNION ALL
SELECT 
    'DimProducto (todas las versiones)',
    COUNT(*),
    NULL,
    NULL
FROM dbo.DimProducto
WHERE sk_producto > 0
UNION ALL
SELECT 
    'DimLocal',
    COUNT(*),
    NULL,
    NULL
FROM dbo.DimLocal
WHERE sk_local > 0
UNION ALL
SELECT 
    'DimVendedor',
    COUNT(*),
    NULL,
    NULL
FROM dbo.DimVendedor
WHERE sk_vendedor > 0
UNION ALL
SELECT 
    'DimFormaPago',
    COUNT(*),
    NULL,
    NULL
FROM dbo.DimFormaPago
WHERE sk_forma_pago > 0
UNION ALL
SELECT 
    'DimCanal',
    COUNT(*),
    NULL,
    NULL
FROM dbo.DimCanal
WHERE sk_canal > 0
UNION ALL
SELECT 
    'DimMoneda',
    COUNT(*),
    NULL,
    NULL
FROM dbo.DimMoneda
WHERE sk_moneda > 0
UNION ALL
SELECT 
    'FactVentas',
    COUNT(*),
    NULL,
    NULL
FROM dbo.FactVentas;

PRINT '';
GO

-- =====================================================
-- 8. VALIDACIÓN DE MÉTRICAS CALCULADAS
-- =====================================================
PRINT '--- 8. Validación de métricas calculadas ---';

-- Verificar que importe = cantidad * precio_unitario
SELECT 
    'Inconsistencias en cálculo de importe' AS problema,
    COUNT(*) AS cantidad
FROM dbo.FactVentas
WHERE ABS(importe - (cantidad * precio_unitario)) > 0.01;

-- Verificar que margen = cantidad * (precio_unitario - costo_unitario)
SELECT 
    'Inconsistencias en cálculo de margen' AS problema,
    COUNT(*) AS cantidad
FROM dbo.FactVentas
WHERE ABS(margen - (cantidad * (precio_unitario - costo_unitario))) > 0.01;

-- Verificar que margen_porcentaje está bien calculado
SELECT 
    'Inconsistencias en cálculo de margen_porcentaje' AS problema,
    COUNT(*) AS cantidad
FROM dbo.FactVentas
WHERE precio_unitario > 0 
  AND ABS(margen_porcentaje - (((precio_unitario - costo_unitario) / precio_unitario) * 100)) > 0.1;

PRINT '';
GO

PRINT '=== Validación de calidad completada ===';
PRINT 'Revisa los resultados anteriores para detectar problemas.';
PRINT 'Los valores en 0 indican que no se encontraron problemas en esa categoría.';
GO
