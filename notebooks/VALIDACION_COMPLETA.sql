-- =============================================================================
-- SCRIPT DE VALIDACIÓN COMPLETA DEL PROYECTO DW CELULARES
-- Verifica que todo el proyecto cumpla con los requisitos del segundo parcial
-- =============================================================================

SET NOCOUNT ON;
PRINT '==========================================';
PRINT 'INICIANDO VALIDACIÓN COMPLETA DEL PROYECTO';
PRINT 'Fecha: ' + CONVERT(VARCHAR, GETDATE(), 120);
PRINT '==========================================';
PRINT '';

-- =============================================================================
-- 1. VALIDAR EXISTENCIA DE BASES DE DATOS
-- =============================================================================
PRINT '1. VALIDANDO BASES DE DATOS...';
PRINT '----------------------------------';

IF DB_ID('OLTP_Celulares') IS NOT NULL
    PRINT '✓ Base de datos OLTP_Celulares existe';
ELSE
    PRINT '✗ ERROR: Base de datos OLTP_Celulares NO existe';

IF DB_ID('DW_Celulares') IS NOT NULL
    PRINT '✓ Base de datos DW_Celulares existe';
ELSE
    PRINT '✗ ERROR: Base de datos DW_Celulares NO existe';

PRINT '';

-- =============================================================================
-- 2. VALIDAR ESTRUCTURA OLTP
-- =============================================================================
PRINT '2. VALIDANDO ESTRUCTURA OLTP...';
PRINT '----------------------------------';

USE OLTP_Celulares;

DECLARE @TablaOLTP NVARCHAR(100);
DECLARE @ExisteOLTP BIT;

-- Tablas esperadas en OLTP
DECLARE cur_oltp CURSOR FOR
SELECT 'Ciudades' UNION ALL
SELECT 'Locales' UNION ALL
SELECT 'Marcas' UNION ALL
SELECT 'Modelos' UNION ALL
SELECT 'Vendedores' UNION ALL
SELECT 'Clientes' UNION ALL
SELECT 'FormasPago' UNION ALL
SELECT 'Ventas' UNION ALL
SELECT 'DetalleVenta';

OPEN cur_oltp;
FETCH NEXT FROM cur_oltp INTO @TablaOLTP;

WHILE @@FETCH_STATUS = 0
BEGIN
    IF OBJECT_ID('dbo.' + @TablaOLTP, 'U') IS NOT NULL
        PRINT '✓ Tabla OLTP: ' + @TablaOLTP;
    ELSE
        PRINT '✗ ERROR: Tabla OLTP ' + @TablaOLTP + ' NO existe';
    
    FETCH NEXT FROM cur_oltp INTO @TablaOLTP;
END;

CLOSE cur_oltp;
DEALLOCATE cur_oltp;

PRINT '';

-- =============================================================================
-- 3. VALIDAR ESTRUCTURA DW
-- =============================================================================
PRINT '3. VALIDANDO ESTRUCTURA DW...';
PRINT '----------------------------------';

USE DW_Celulares;

-- Validar dimensiones
DECLARE @TablaDW NVARCHAR(100);

DECLARE cur_dw CURSOR FOR
SELECT 'DimFecha' UNION ALL
SELECT 'DimCliente' UNION ALL
SELECT 'DimProducto' UNION ALL
SELECT 'DimLocal' UNION ALL
SELECT 'DimVendedor' UNION ALL
SELECT 'DimFormaPago' UNION ALL
SELECT 'DimCanal' UNION ALL
SELECT 'DimMoneda' UNION ALL
SELECT 'FactVentas';

OPEN cur_dw;
FETCH NEXT FROM cur_dw INTO @TablaDW;

WHILE @@FETCH_STATUS = 0
BEGIN
    IF OBJECT_ID('dbo.' + @TablaDW, 'U') IS NOT NULL
        PRINT '✓ Tabla DW: ' + @TablaDW;
    ELSE
        PRINT '✗ ERROR: Tabla DW ' + @TablaDW + ' NO existe';
    
    FETCH NEXT FROM cur_dw INTO @TablaDW;
END;

CLOSE cur_dw;
DEALLOCATE cur_dw;

PRINT '';

-- =============================================================================
-- 4. VALIDAR DimFecha COMPLETA (Requisito obligatorio)
-- =============================================================================
PRINT '4. VALIDANDO DIMENSIÓN TIEMPO (DimFecha)...';
PRINT '---------------------------------------------';

-- Verificar columnas adicionales
IF COL_LENGTH('dbo.DimFecha', 'dia_semana') IS NOT NULL
    PRINT '✓ DimFecha tiene columna dia_semana';
ELSE
    PRINT '✗ ERROR: DimFecha NO tiene columna dia_semana';

IF COL_LENGTH('dbo.DimFecha', 'nombre_mes') IS NOT NULL
    PRINT '✓ DimFecha tiene columna nombre_mes';
ELSE
    PRINT '✗ ERROR: DimFecha NO tiene columna nombre_mes';

IF COL_LENGTH('dbo.DimFecha', 'es_fin_semana') IS NOT NULL
    PRINT '✓ DimFecha tiene columna es_fin_semana';
ELSE
    PRINT '✗ ERROR: DimFecha NO tiene columna es_fin_semana';

IF COL_LENGTH('dbo.DimFecha', 'numero_semana') IS NOT NULL
    PRINT '✓ DimFecha tiene columna numero_semana';
ELSE
    PRINT '✗ ERROR: DimFecha NO tiene columna numero_semana';

-- Verificar datos
DECLARE @CantFechas INT = (SELECT COUNT(*) FROM dbo.DimFecha);
PRINT '  Total fechas cargadas: ' + CAST(@CantFechas AS VARCHAR);

IF @CantFechas >= 3650 -- Al menos 10 años
    PRINT '✓ DimFecha tiene suficientes fechas pre-cargadas';
ELSE
    PRINT '⚠ ADVERTENCIA: DimFecha tiene pocas fechas (' + CAST(@CantFechas AS VARCHAR) + ')';

PRINT '';

-- =============================================================================
-- 5. VALIDAR SCD TIPO 2 en DimProducto (Requisito obligatorio)
-- =============================================================================
PRINT '5. VALIDANDO SCD TIPO 2 EN DimProducto...';
PRINT '-------------------------------------------';

-- Verificar columnas SCD2
IF COL_LENGTH('dbo.DimProducto', 'fecha_inicio') IS NOT NULL
    PRINT '✓ DimProducto tiene columna fecha_inicio';
ELSE
    PRINT '✗ ERROR: DimProducto NO tiene columna fecha_inicio';

IF COL_LENGTH('dbo.DimProducto', 'fecha_fin') IS NOT NULL
    PRINT '✓ DimProducto tiene columna fecha_fin';
ELSE
    PRINT '✗ ERROR: DimProducto NO tiene columna fecha_fin';

IF COL_LENGTH('dbo.DimProducto', 'es_actual') IS NOT NULL
    PRINT '✓ DimProducto tiene columna es_actual';
ELSE
    PRINT '✗ ERROR: DimProducto NO tiene columna es_actual';

IF COL_LENGTH('dbo.DimProducto', 'version') IS NOT NULL
    PRINT '✓ DimProducto tiene columna version';
ELSE
    PRINT '✗ ERROR: DimProducto NO tiene columna version';

-- Verificar constraint único
IF EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE object_id = OBJECT_ID('dbo.DimProducto') 
    AND name = 'UQ_DimProducto_Actual'
)
    PRINT '✓ DimProducto tiene constraint UQ_DimProducto_Actual';
ELSE
    PRINT '✗ ERROR: DimProducto NO tiene constraint UQ_DimProducto_Actual';

-- Verificar versionado
DECLARE @ProductosMultiples INT = (
    SELECT COUNT(DISTINCT id_modelo_fuente) 
    FROM dbo.DimProducto 
    WHERE id_modelo_fuente IN (
        SELECT id_modelo_fuente 
        FROM dbo.DimProducto 
        GROUP BY id_modelo_fuente 
        HAVING COUNT(*) > 1
    )
);

IF @ProductosMultiples > 0
    PRINT '✓ Hay ' + CAST(@ProductosMultiples AS VARCHAR) + ' productos con múltiples versiones (SCD2 funciona)';
ELSE
    PRINT '⚠ ADVERTENCIA: Ningún producto tiene múltiples versiones aún';

PRINT '';

-- =============================================================================
-- 6. VALIDAR DimCanal (Dimensión Junk - Requisito obligatorio)
-- =============================================================================
PRINT '6. VALIDANDO DimCanal (Dimensión Junk)...';
PRINT '-------------------------------------------';

IF OBJECT_ID('dbo.DimCanal', 'U') IS NOT NULL
BEGIN
    PRINT '✓ DimCanal existe';
    
    DECLARE @CantCanales INT = (SELECT COUNT(*) FROM dbo.DimCanal);
    PRINT '  Total canales: ' + CAST(@CantCanales AS VARCHAR);
    
    IF @CantCanales >= 2
        PRINT '✓ DimCanal tiene datos cargados';
    ELSE
        PRINT '✗ ERROR: DimCanal NO tiene datos suficientes';
END
ELSE
    PRINT '✗ ERROR: DimCanal NO existe';

PRINT '';

-- =============================================================================
-- 7. VALIDAR DimMoneda (Nueva dimensión)
-- =============================================================================
PRINT '7. VALIDANDO DimMoneda (Nueva dimensión)...';
PRINT '---------------------------------------------';

IF OBJECT_ID('dbo.DimMoneda', 'U') IS NOT NULL
BEGIN
    PRINT '✓ DimMoneda existe';
    
    DECLARE @CantMonedas INT = (SELECT COUNT(*) FROM dbo.DimMoneda);
    PRINT '  Total monedas: ' + CAST(@CantMonedas AS VARCHAR);
    
    IF @CantMonedas >= 4
        PRINT '✓ DimMoneda tiene al menos 4 monedas (ARS, USD, EUR, BRL)';
    ELSE
        PRINT '⚠ ADVERTENCIA: DimMoneda tiene pocas monedas';
    
    -- Verificar moneda base
    IF EXISTS (SELECT 1 FROM dbo.DimMoneda WHERE es_moneda_base = 1)
        PRINT '✓ Hay una moneda marcada como base';
    ELSE
        PRINT '✗ ERROR: NO hay moneda base definida';
END
ELSE
    PRINT '✗ ERROR: DimMoneda NO existe';

PRINT '';

-- =============================================================================
-- 8. VALIDAR FactVentas
-- =============================================================================
PRINT '8. VALIDANDO FactVentas...';
PRINT '----------------------------';

IF OBJECT_ID('dbo.FactVentas', 'U') IS NOT NULL
BEGIN
    PRINT '✓ FactVentas existe';
    
    -- Verificar columnas de moneda
    IF COL_LENGTH('dbo.FactVentas', 'sk_moneda') IS NOT NULL
        PRINT '✓ FactVentas tiene columna sk_moneda';
    ELSE
        PRINT '✗ ERROR: FactVentas NO tiene columna sk_moneda';
    
    IF COL_LENGTH('dbo.FactVentas', 'tipo_cambio') IS NOT NULL
        PRINT '✓ FactVentas tiene columna tipo_cambio';
    ELSE
        PRINT '✗ ERROR: FactVentas NO tiene columna tipo_cambio';
    
    -- Verificar datos
    DECLARE @CantVentas INT = (SELECT COUNT(*) FROM dbo.FactVentas);
    PRINT '  Total registros: ' + CAST(@CantVentas AS VARCHAR);
    
    IF @CantVentas > 0
    BEGIN
        PRINT '✓ FactVentas tiene datos cargados';
        
        -- Verificar integridad referencial
        IF NOT EXISTS (SELECT 1 FROM dbo.FactVentas WHERE sk_fecha NOT IN (SELECT sk_fecha FROM dbo.DimFecha))
            PRINT '✓ Todas las ventas tienen sk_fecha válido';
        ELSE
            PRINT '✗ ERROR: Hay ventas con sk_fecha inválido';
        
        IF NOT EXISTS (SELECT 1 FROM dbo.FactVentas WHERE sk_moneda NOT IN (SELECT sk_moneda FROM dbo.DimMoneda))
            PRINT '✓ Todas las ventas tienen sk_moneda válido';
        ELSE
            PRINT '✗ ERROR: Hay ventas con sk_moneda inválido';
    END
    ELSE
        PRINT '✗ ERROR: FactVentas NO tiene datos';
END
ELSE
    PRINT '✗ ERROR: FactVentas NO existe';

PRINT '';

-- =============================================================================
-- 9. VALIDAR DATOS EN OLTP
-- =============================================================================
PRINT '9. VALIDANDO DATOS EN OLTP...';
PRINT '--------------------------------';

USE OLTP_Celulares;

DECLARE @CantVentasOLTP INT = (SELECT COUNT(*) FROM dbo.Ventas);
DECLARE @CantDetallesOLTP INT = (SELECT COUNT(*) FROM dbo.DetalleVenta);
DECLARE @CantClientesOLTP INT = (SELECT COUNT(*) FROM dbo.Clientes);

PRINT '  Ventas: ' + CAST(@CantVentasOLTP AS VARCHAR);
PRINT '  Detalles: ' + CAST(@CantDetallesOLTP AS VARCHAR);
PRINT '  Clientes: ' + CAST(@CantClientesOLTP AS VARCHAR);

IF @CantVentasOLTP > 0 AND @CantDetallesOLTP > 0 AND @CantClientesOLTP > 0
    PRINT '✓ OLTP tiene datos cargados';
ELSE
    PRINT '✗ ERROR: OLTP NO tiene suficientes datos';

PRINT '';

-- =============================================================================
-- 10. VALIDAR CORRESPONDENCIA OLTP <-> DW
-- =============================================================================
PRINT '10. VALIDANDO CORRESPONDENCIA OLTP <-> DW...';
PRINT '----------------------------------------------';

USE DW_Celulares;

-- Comparar totales de registros
DECLARE @CantClientesDW INT = (SELECT COUNT(*) FROM dbo.DimCliente);
DECLARE @CantVentasDW INT = (SELECT COUNT(*) FROM dbo.FactVentas);

PRINT '  Clientes OLTP: ' + CAST(@CantClientesOLTP AS VARCHAR);
PRINT '  Clientes DW: ' + CAST(@CantClientesDW AS VARCHAR);

IF @CantClientesOLTP = @CantClientesDW
    PRINT '✓ Cantidad de clientes coincide';
ELSE
    PRINT '⚠ ADVERTENCIA: Diferencia en cantidad de clientes';

PRINT '  Detalles OLTP: ' + CAST(@CantDetallesOLTP AS VARCHAR);
PRINT '  Ventas DW: ' + CAST(@CantVentasDW AS VARCHAR);

IF @CantDetallesOLTP = @CantVentasDW
    PRINT '✓ Cantidad de registros de ventas coincide';
ELSE
    PRINT '⚠ ADVERTENCIA: Diferencia en cantidad de ventas';

PRINT '';

-- =============================================================================
-- 11. RESUMEN FINAL
-- =============================================================================
PRINT '==========================================';
PRINT 'RESUMEN DE VALIDACIÓN';
PRINT '==========================================';

-- Contar éxitos y fallos
DECLARE @Validaciones TABLE (
    Componente NVARCHAR(100),
    Estado VARCHAR(10)
);

INSERT INTO @Validaciones VALUES 
    ('Bases de datos', CASE WHEN DB_ID('OLTP_Celulares') IS NOT NULL AND DB_ID('DW_Celulares') IS NOT NULL THEN 'OK' ELSE 'ERROR' END),
    ('DimFecha completa', CASE WHEN COL_LENGTH('dbo.DimFecha', 'dia_semana') IS NOT NULL THEN 'OK' ELSE 'ERROR' END),
    ('SCD2 en DimProducto', CASE WHEN COL_LENGTH('dbo.DimProducto', 'fecha_inicio') IS NOT NULL THEN 'OK' ELSE 'ERROR' END),
    ('DimCanal (Junk)', CASE WHEN OBJECT_ID('dbo.DimCanal', 'U') IS NOT NULL THEN 'OK' ELSE 'ERROR' END),
    ('DimMoneda', CASE WHEN OBJECT_ID('dbo.DimMoneda', 'U') IS NOT NULL THEN 'OK' ELSE 'ERROR' END),
    ('FactVentas con moneda', CASE WHEN COL_LENGTH('dbo.FactVentas', 'sk_moneda') IS NOT NULL THEN 'OK' ELSE 'ERROR' END);

SELECT 
    COUNT(*) AS [Total Validaciones],
    SUM(CASE WHEN Estado = 'OK' THEN 1 ELSE 0 END) AS [Exitosas],
    SUM(CASE WHEN Estado = 'ERROR' THEN 1 ELSE 0 END) AS [Con Errores]
FROM @Validaciones;

PRINT '';
PRINT 'Detalle:';
SELECT Componente, Estado FROM @Validaciones ORDER BY Estado DESC, Componente;

PRINT '';
PRINT '==========================================';
PRINT 'FIN DE VALIDACIÓN';
PRINT '==========================================';

SET NOCOUNT OFF;
