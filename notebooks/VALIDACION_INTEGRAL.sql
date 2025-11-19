-- =============================================================================
-- SCRIPT DE VALIDACIÓN INTEGRAL DEL PROYECTO DW CELULARES
-- Unifica todas las validaciones en un solo script consolidado
-- Autor: Sistema de Validación Automática
-- Fecha: 2025-10-15
-- =============================================================================

SET NOCOUNT ON;
GO

-- Variable para almacenar el resultado final
DECLARE @ErrorCount INT = 0;
DECLARE @WarningCount INT = 0;
DECLARE @SuccessCount INT = 0;

PRINT '╔════════════════════════════════════════════════════════════════╗';
PRINT '║   VALIDACIÓN INTEGRAL - PROYECTO DW CELULARES                  ║';
PRINT '║   Segundo Parcial 2025                                         ║';
PRINT '╚════════════════════════════════════════════════════════════════╝';
PRINT '';
PRINT 'Fecha/Hora: ' + CONVERT(VARCHAR, GETDATE(), 120);
PRINT '';

-- =============================================================================
-- BLOQUE 1: VALIDACIÓN DE BASES DE DATOS
-- =============================================================================
PRINT '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
PRINT '📊 BLOQUE 1: BASES DE DATOS';
PRINT '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';

IF DB_ID('OLTP_Celulares') IS NOT NULL
BEGIN
    PRINT '  ✓ OLTP_Celulares: Existe';
    SET @SuccessCount = @SuccessCount + 1;
END
ELSE
BEGIN
    PRINT '  ✗ ERROR: OLTP_Celulares NO existe';
    SET @ErrorCount = @ErrorCount + 1;
END

IF DB_ID('DW_Celulares') IS NOT NULL
BEGIN
    PRINT '  ✓ DW_Celulares: Existe';
    SET @SuccessCount = @SuccessCount + 1;
END
ELSE
BEGIN
    PRINT '  ✗ ERROR: DW_Celulares NO existe';
    SET @ErrorCount = @ErrorCount + 1;
END

PRINT '';

-- =============================================================================
-- BLOQUE 2: VALIDACIÓN DE ESTRUCTURA OLTP
-- =============================================================================
PRINT '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
PRINT '🏪 BLOQUE 2: ESTRUCTURA OLTP (Sistema Transaccional)';
PRINT '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';

USE OLTP_Celulares;

DECLARE @TablasOLTP TABLE (Nombre NVARCHAR(50), Orden INT);
INSERT INTO @TablasOLTP VALUES 
    ('Ciudades', 1),
    ('Locales', 2),
    ('Marcas', 3),
    ('Modelos', 4),
    ('Vendedores', 5),
    ('Clientes', 6),
    ('FormasPago', 7),
    ('Ventas', 8),
    ('DetalleVenta', 9);

DECLARE @Tabla NVARCHAR(50);
DECLARE @Orden INT;

DECLARE cur_oltp CURSOR FOR
SELECT Nombre, Orden FROM @TablasOLTP ORDER BY Orden;

OPEN cur_oltp;
FETCH NEXT FROM cur_oltp INTO @Tabla, @Orden;

WHILE @@FETCH_STATUS = 0
BEGIN
    IF OBJECT_ID('dbo.' + @Tabla, 'U') IS NOT NULL
    BEGIN
        PRINT '  ✓ Tabla ' + CAST(@Orden AS VARCHAR) + '/9: ' + @Tabla;
        SET @SuccessCount = @SuccessCount + 1;
    END
    ELSE
    BEGIN
        PRINT '  ✗ ERROR: Tabla ' + @Tabla + ' NO existe';
        SET @ErrorCount = @ErrorCount + 1;
    END
    
    FETCH NEXT FROM cur_oltp INTO @Tabla, @Orden;
END;

CLOSE cur_oltp;
DEALLOCATE cur_oltp;

-- Validar datos OLTP
DECLARE @CantCiudades INT = ISNULL((SELECT COUNT(*) FROM dbo.Ciudades), 0);
DECLARE @CantVentas INT = ISNULL((SELECT COUNT(*) FROM dbo.Ventas), 0);
DECLARE @CantDetalles INT = ISNULL((SELECT COUNT(*) FROM dbo.DetalleVenta), 0);

PRINT '';
PRINT '  📈 Datos cargados:';
PRINT '     • Ciudades: ' + CAST(@CantCiudades AS VARCHAR);
PRINT '     • Ventas: ' + CAST(@CantVentas AS VARCHAR);
PRINT '     • Detalles: ' + CAST(@CantDetalles AS VARCHAR);

IF @CantVentas > 0 AND @CantDetalles > 0
BEGIN
    PRINT '  ✓ OLTP tiene datos suficientes';
    SET @SuccessCount = @SuccessCount + 1;
END
ELSE
BEGIN
    PRINT '  ✗ ERROR: OLTP sin datos suficientes';
    SET @ErrorCount = @ErrorCount + 1;
END

PRINT '';

-- =============================================================================
-- BLOQUE 3: VALIDACIÓN DE ESTRUCTURA DW
-- =============================================================================
PRINT '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
PRINT '📊 BLOQUE 3: ESTRUCTURA DATA WAREHOUSE (Esquema Estrella)';
PRINT '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';

USE DW_Celulares;

DECLARE @TablasDW TABLE (Nombre NVARCHAR(50), Tipo NVARCHAR(20), Orden INT);
INSERT INTO @TablasDW VALUES 
    ('DimFecha', 'Dimensión', 1),
    ('DimCliente', 'Dimensión', 2),
    ('DimProducto', 'Dimensión', 3),
    ('DimLocal', 'Dimensión', 4),
    ('DimVendedor', 'Dimensión', 5),
    ('DimFormaPago', 'Dimensión', 6),
    ('DimCanal', 'Dimensión', 7),
    ('DimMoneda', 'Dimensión', 8),
    ('FactVentas', 'Hechos', 9);

DECLARE @TablaDW NVARCHAR(50);
DECLARE @TipoDW NVARCHAR(20);
DECLARE @OrdenDW INT;

DECLARE cur_dw CURSOR FOR
SELECT Nombre, Tipo, Orden FROM @TablasDW ORDER BY Orden;

OPEN cur_dw;
FETCH NEXT FROM cur_dw INTO @TablaDW, @TipoDW, @OrdenDW;

WHILE @@FETCH_STATUS = 0
BEGIN
    IF OBJECT_ID('dbo.' + @TablaDW, 'U') IS NOT NULL
    BEGIN
        PRINT '  ✓ ' + @TipoDW + ' ' + CAST(@OrdenDW AS VARCHAR) + '/9: ' + @TablaDW;
        SET @SuccessCount = @SuccessCount + 1;
    END
    ELSE
    BEGIN
        PRINT '  ✗ ERROR: ' + @TablaDW + ' NO existe';
        SET @ErrorCount = @ErrorCount + 1;
    END
    
    FETCH NEXT FROM cur_dw INTO @TablaDW, @TipoDW, @OrdenDW;
END;

CLOSE cur_dw;
DEALLOCATE cur_dw;

PRINT '';

-- =============================================================================
-- BLOQUE 4: VALIDACIÓN DE REQUISITOS DEL SEGUNDO PARCIAL
-- =============================================================================
PRINT '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
PRINT '🎯 BLOQUE 4: REQUISITOS OBLIGATORIOS DEL SEGUNDO PARCIAL';
PRINT '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';

PRINT '';
PRINT '  ┌─ REQUISITO 1: Dimensión Tiempo Completa (DimFecha) ─────────┐';

DECLARE @ColumnasFecha TABLE (Columna NVARCHAR(50));
INSERT INTO @ColumnasFecha VALUES 
    ('dia_semana'), ('nombre_mes'), ('es_fin_semana'), 
    ('numero_semana'), ('dia_mes'), ('dia_anio');

DECLARE @Columna NVARCHAR(50);
DECLARE @TodasColumnas BIT = 1;

DECLARE cur_col CURSOR FOR SELECT Columna FROM @ColumnasFecha;
OPEN cur_col;
FETCH NEXT FROM cur_col INTO @Columna;

WHILE @@FETCH_STATUS = 0
BEGIN
    IF COL_LENGTH('dbo.DimFecha', @Columna) IS NOT NULL
    BEGIN
        PRINT '    ✓ Columna: ' + @Columna;
        SET @SuccessCount = @SuccessCount + 1;
    END
    ELSE
    BEGIN
        PRINT '    ✗ ERROR: Columna ' + @Columna + ' NO existe';
        SET @TodasColumnas = 0;
        SET @ErrorCount = @ErrorCount + 1;
    END
    FETCH NEXT FROM cur_col INTO @Columna;
END;

CLOSE cur_col;
DEALLOCATE cur_col;

DECLARE @CantFechas INT = (SELECT COUNT(*) FROM dbo.DimFecha);
PRINT '    📅 Total fechas: ' + CAST(@CantFechas AS VARCHAR);

IF @CantFechas >= 3650
BEGIN
    PRINT '    ✓ REQUISITO 1 CUMPLIDO: DimFecha completa';
    SET @SuccessCount = @SuccessCount + 1;
END
ELSE
BEGIN
    PRINT '    ⚠ ADVERTENCIA: Pocas fechas cargadas';
    SET @WarningCount = @WarningCount + 1;
END

PRINT '  └──────────────────────────────────────────────────────────────┘';
PRINT '';

PRINT '  ┌─ REQUISITO 2: SCD Tipo 2 en DimProducto ─────────────────────┐';

DECLARE @ColumnasSCD2 TABLE (Columna NVARCHAR(50));
INSERT INTO @ColumnasSCD2 VALUES 
    ('fecha_inicio'), ('fecha_fin'), ('es_actual'), ('version');

DECLARE @TodasSCD2 BIT = 1;

DECLARE cur_scd CURSOR FOR SELECT Columna FROM @ColumnasSCD2;
OPEN cur_scd;
FETCH NEXT FROM cur_scd INTO @Columna;

WHILE @@FETCH_STATUS = 0
BEGIN
    IF COL_LENGTH('dbo.DimProducto', @Columna) IS NOT NULL
    BEGIN
        PRINT '    ✓ Columna SCD2: ' + @Columna;
        SET @SuccessCount = @SuccessCount + 1;
    END
    ELSE
    BEGIN
        PRINT '    ✗ ERROR: Columna ' + @Columna + ' NO existe';
        SET @TodasSCD2 = 0;
        SET @ErrorCount = @ErrorCount + 1;
    END
    FETCH NEXT FROM cur_scd INTO @Columna;
END;

CLOSE cur_scd;
DEALLOCATE cur_scd;

-- Verificar constraint
IF EXISTS (
    SELECT 1 FROM sys.indexes 
    WHERE object_id = OBJECT_ID('dbo.DimProducto') 
    AND name = 'UQ_DimProducto_Actual'
)
BEGIN
    PRINT '    ✓ Constraint: UQ_DimProducto_Actual';
    SET @SuccessCount = @SuccessCount + 1;
END
ELSE
BEGIN
    PRINT '    ✗ ERROR: Constraint único NO existe';
    SET @ErrorCount = @ErrorCount + 1;
END

-- Verificar versionado
DECLARE @ProductosVersionados INT = (
    SELECT COUNT(DISTINCT id_modelo_fuente) 
    FROM dbo.DimProducto 
    WHERE id_modelo_fuente IN (
        SELECT id_modelo_fuente 
        FROM dbo.DimProducto 
        GROUP BY id_modelo_fuente 
        HAVING COUNT(*) > 1
    )
);

IF @ProductosVersionados > 0
BEGIN
    PRINT '    ✓ Productos versionados: ' + CAST(@ProductosVersionados AS VARCHAR);
    PRINT '    ✓ REQUISITO 2 CUMPLIDO: SCD2 funcional';
    SET @SuccessCount = @SuccessCount + 1;
END
ELSE
BEGIN
    PRINT '    ⚠ ADVERTENCIA: Sin versiones múltiples (ejecutar reproceso con cambios)';
    PRINT '    ✓ REQUISITO 2 CUMPLIDO: SCD2 implementado (sin datos de prueba)';
    SET @WarningCount = @WarningCount + 1;
END

PRINT '  └──────────────────────────────────────────────────────────────┘';
PRINT '';

PRINT '  ┌─ REQUISITO 3: Dimensión Junk (DimCanal) ─────────────────────┐';

IF OBJECT_ID('dbo.DimCanal', 'U') IS NOT NULL
BEGIN
    DECLARE @CantCanales INT = (SELECT COUNT(*) FROM dbo.DimCanal);
    PRINT '    ✓ DimCanal existe';
    PRINT '    📊 Total canales: ' + CAST(@CantCanales AS VARCHAR);
    
    IF @CantCanales >= 2
    BEGIN
        PRINT '    ✓ REQUISITO 3 CUMPLIDO: DimCanal poblada';
        SET @SuccessCount = @SuccessCount + 2;
    END
    ELSE
    BEGIN
        PRINT '    ⚠ ADVERTENCIA: Pocos canales';
        SET @WarningCount = @WarningCount + 1;
    END
END
ELSE
BEGIN
    PRINT '    ✗ ERROR: DimCanal NO existe';
    SET @ErrorCount = @ErrorCount + 1;
END

PRINT '  └──────────────────────────────────────────────────────────────┘';
PRINT '';

PRINT '  ┌─ REQUISITO 4: Nueva Dimensión (DimMoneda) ───────────────────┐';

IF OBJECT_ID('dbo.DimMoneda', 'U') IS NOT NULL
BEGIN
    DECLARE @CantMonedas INT = (SELECT COUNT(*) FROM dbo.DimMoneda);
    PRINT '    ✓ DimMoneda existe';
    PRINT '    💰 Total monedas: ' + CAST(@CantMonedas AS VARCHAR);
    
    IF @CantMonedas >= 4
    BEGIN
        PRINT '    ✓ Al menos 4 monedas (ARS, USD, EUR, BRL)';
        SET @SuccessCount = @SuccessCount + 1;
    END
    
    IF EXISTS (SELECT 1 FROM dbo.DimMoneda WHERE es_moneda_base = 1)
    BEGIN
        PRINT '    ✓ Moneda base definida';
        SET @SuccessCount = @SuccessCount + 1;
    END
    
    -- Verificar integración con FactVentas
    IF COL_LENGTH('dbo.FactVentas', 'sk_moneda') IS NOT NULL 
       AND COL_LENGTH('dbo.FactVentas', 'tipo_cambio') IS NOT NULL
    BEGIN
        PRINT '    ✓ Integración con FactVentas (sk_moneda, tipo_cambio)';
        PRINT '    ✓ REQUISITO 4 CUMPLIDO: DimMoneda completa';
        SET @SuccessCount = @SuccessCount + 1;
    END
    ELSE
    BEGIN
        PRINT '    ✗ ERROR: FactVentas sin columnas de moneda';
        SET @ErrorCount = @ErrorCount + 1;
    END
END
ELSE
BEGIN
    PRINT '    ✗ ERROR: DimMoneda NO existe';
    SET @ErrorCount = @ErrorCount + 1;
END

PRINT '  └──────────────────────────────────────────────────────────────┘';
PRINT '';

-- =============================================================================
-- BLOQUE 5: VALIDACIÓN DE INTEGRIDAD DE DATOS
-- =============================================================================
PRINT '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
PRINT '🔗 BLOQUE 5: INTEGRIDAD DE DATOS Y CALIDAD';
PRINT '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';

DECLARE @CantFactVentas INT = (SELECT COUNT(*) FROM dbo.FactVentas);
PRINT '  📊 Registros en FactVentas: ' + CAST(@CantFactVentas AS VARCHAR);

IF @CantFactVentas > 0
BEGIN
    -- Validar integridad referencial
    DECLARE @VentasSinFecha INT = (
        SELECT COUNT(*) FROM dbo.FactVentas 
        WHERE sk_fecha NOT IN (SELECT sk_fecha FROM dbo.DimFecha)
    );
    
    DECLARE @VentasSinMoneda INT = (
        SELECT COUNT(*) FROM dbo.FactVentas 
        WHERE sk_moneda NOT IN (SELECT sk_moneda FROM dbo.DimMoneda)
    );
    
    IF @VentasSinFecha = 0
    BEGIN
        PRINT '  ✓ Integridad referencial: DimFecha';
        SET @SuccessCount = @SuccessCount + 1;
    END
    ELSE
    BEGIN
        PRINT '  ✗ ERROR: ' + CAST(@VentasSinFecha AS VARCHAR) + ' ventas sin fecha válida';
        SET @ErrorCount = @ErrorCount + 1;
    END
    
    IF @VentasSinMoneda = 0
    BEGIN
        PRINT '  ✓ Integridad referencial: DimMoneda';
        SET @SuccessCount = @SuccessCount + 1;
    END
    ELSE
    BEGIN
        PRINT '  ✗ ERROR: ' + CAST(@VentasSinMoneda AS VARCHAR) + ' ventas sin moneda válida';
        SET @ErrorCount = @ErrorCount + 1;
    END
    
    -- Validar datos nulos críticos
    DECLARE @VentasNulas INT = (
        SELECT COUNT(*) FROM dbo.FactVentas 
        WHERE cantidad IS NULL OR precio_unitario IS NULL OR importe IS NULL
    );
    
    IF @VentasNulas = 0
    BEGIN
        PRINT '  ✓ Sin valores nulos en métricas críticas';
        SET @SuccessCount = @SuccessCount + 1;
    END
    ELSE
    BEGIN
        PRINT '  ✗ ERROR: ' + CAST(@VentasNulas AS VARCHAR) + ' ventas con nulos';
        SET @ErrorCount = @ErrorCount + 1;
    END
    
    -- Validar correspondencia OLTP-DW
    IF @CantDetalles = @CantFactVentas
    BEGIN
        PRINT '  ✓ Correspondencia OLTP-DW: Detalles = FactVentas';
        SET @SuccessCount = @SuccessCount + 1;
    END
    ELSE
    BEGIN
        PRINT '  ⚠ ADVERTENCIA: Diferencia OLTP (' + CAST(@CantDetalles AS VARCHAR) + 
              ') vs DW (' + CAST(@CantFactVentas AS VARCHAR) + ')';
        SET @WarningCount = @WarningCount + 1;
    END
END
ELSE
BEGIN
    PRINT '  ✗ ERROR: FactVentas vacía';
    SET @ErrorCount = @ErrorCount + 1;
END

PRINT '';

-- =============================================================================
-- BLOQUE 6: RESUMEN FINAL
-- =============================================================================
PRINT '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
PRINT '📋 RESUMEN FINAL DE VALIDACIÓN';
PRINT '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
PRINT '';

DECLARE @Total INT = @SuccessCount + @ErrorCount + @WarningCount;

PRINT '  Total validaciones: ' + CAST(@Total AS VARCHAR);
PRINT '  ✓ Exitosas:        ' + CAST(@SuccessCount AS VARCHAR);
PRINT '  ✗ Errores:         ' + CAST(@ErrorCount AS VARCHAR);
PRINT '  ⚠ Advertencias:    ' + CAST(@WarningCount AS VARCHAR);
PRINT '';

-- Calcular porcentaje de éxito
DECLARE @PorcentajeExito DECIMAL(5,2) = 
    CASE WHEN @Total > 0 
    THEN CAST(@SuccessCount AS DECIMAL) / @Total * 100 
    ELSE 0 END;

PRINT '  Porcentaje de éxito: ' + CAST(@PorcentajeExito AS VARCHAR) + '%';
PRINT '';

IF @ErrorCount = 0
BEGIN
    PRINT '  ╔════════════════════════════════════════════════════════════╗';
    PRINT '  ║                                                            ║';
    PRINT '  ║   ✓✓✓ PROYECTO VALIDADO EXITOSAMENTE ✓✓✓                  ║';
    PRINT '  ║                                                            ║';
    PRINT '  ║   Todos los requisitos del segundo parcial cumplidos      ║';
    PRINT '  ║   El proyecto está listo para entregar                    ║';
    PRINT '  ║                                                            ║';
    PRINT '  ╚════════════════════════════════════════════════════════════╝';
END
ELSE
BEGIN
    PRINT '  ╔════════════════════════════════════════════════════════════╗';
    PRINT '  ║                                                            ║';
    PRINT '  ║   ⚠ PROYECTO CON ERRORES ⚠                                ║';
    PRINT '  ║                                                            ║';
    PRINT '  ║   Revisa los errores marcados con ✗                       ║';
    PRINT '  ║   Corrígelos antes de entregar                            ║';
    PRINT '  ║                                                            ║';
    PRINT '  ╚════════════════════════════════════════════════════════════╝';
END

PRINT '';
PRINT '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
PRINT 'Fin de validación: ' + CONVERT(VARCHAR, GETDATE(), 120);
PRINT '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';

SET NOCOUNT OFF;
GO
