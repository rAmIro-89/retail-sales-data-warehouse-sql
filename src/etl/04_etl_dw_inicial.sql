-- 04_etl_dw_inicial.sql
-- Cargar el DW desde el OLTP por primera vez
-- Incluye: DimFecha completa, DimCanal, SCD Tipo 2, registros Unknown
USE DW_Celulares;
GO

PRINT '=== Iniciando ETL inicial del Data Warehouse ===';
GO

-- =====================================================
-- 1. REGISTROS UNKNOWN (para manejo de claves huérfanas)
-- =====================================================
PRINT 'Insertando registros Unknown...';

-- Unknown en DimCliente
SET IDENTITY_INSERT dbo.DimCliente ON;
IF NOT EXISTS (SELECT 1 FROM dbo.DimCliente WHERE sk_cliente = -1)
BEGIN
    INSERT INTO dbo.DimCliente(sk_cliente, id_cliente_fuente, nombre, apellido, genero)
    VALUES (-1, -1, 'Desconocido', 'Desconocido', 'X');
END
SET IDENTITY_INSERT dbo.DimCliente OFF;

-- Unknown en DimProducto
SET IDENTITY_INSERT dbo.DimProducto ON;
IF NOT EXISTS (SELECT 1 FROM dbo.DimProducto WHERE sk_producto = -1)
BEGIN
    INSERT INTO dbo.DimProducto(sk_producto, id_modelo_fuente, marca, modelo, almacenamiento_gb, ram_gb)
    VALUES (-1, -1, 'Sin especificar', 'Sin especificar', 0, 0);
END
SET IDENTITY_INSERT dbo.DimProducto OFF;

-- Unknown en DimLocal
SET IDENTITY_INSERT dbo.DimLocal ON;
IF NOT EXISTS (SELECT 1 FROM dbo.DimLocal WHERE sk_local = -1)
BEGIN
    INSERT INTO dbo.DimLocal(sk_local, id_local_fuente, provincia, ciudad, local)
    VALUES (-1, -1, 'Desconocido', 'Desconocido', 'Desconocido');
END
SET IDENTITY_INSERT dbo.DimLocal OFF;

-- Unknown en DimVendedor
SET IDENTITY_INSERT dbo.DimVendedor ON;
IF NOT EXISTS (SELECT 1 FROM dbo.DimVendedor WHERE sk_vendedor = -1)
BEGIN
  INSERT INTO dbo.DimVendedor(sk_vendedor, id_vendedor_fuente, nombre, apellido, legajo, fecha_inicio, fecha_fin, es_actual, version, categoria_vendedor)
  VALUES (-1, -1, 'Desconocido', 'Desconocido', 'UNKNOWN', '1900-01-01', NULL, 1, 1, 'Inicial');
END
SET IDENTITY_INSERT dbo.DimVendedor OFF;

-- Unknown en DimFormaPago
SET IDENTITY_INSERT dbo.DimFormaPago ON;
IF NOT EXISTS (SELECT 1 FROM dbo.DimFormaPago WHERE sk_forma_pago = -1)
BEGIN
    INSERT INTO dbo.DimFormaPago(sk_forma_pago, id_forma_pago_fuente, forma_pago)
    VALUES (-1, -1, 'Desconocido');
END
SET IDENTITY_INSERT dbo.DimFormaPago OFF;

-- Unknown en DimCanal
SET IDENTITY_INSERT dbo.DimCanal ON;
IF NOT EXISTS (SELECT 1 FROM dbo.DimCanal WHERE sk_canal = -1)
BEGIN
    INSERT INTO dbo.DimCanal(sk_canal, canal, descripcion)
    VALUES (-1, 'Desconocido', 'Canal no especificado');
END
SET IDENTITY_INSERT dbo.DimCanal OFF;

-- Unknown en DimMoneda
SET IDENTITY_INSERT dbo.DimMoneda ON;
IF NOT EXISTS (SELECT 1 FROM dbo.DimMoneda WHERE sk_moneda = -1)
BEGIN
    INSERT INTO dbo.DimMoneda(sk_moneda, codigo_moneda, nombre, simbolo, es_moneda_base)
    VALUES (-1, 'XXX', 'Desconocido', '?', 0);
END
SET IDENTITY_INSERT dbo.DimMoneda OFF;

PRINT '✓ Registros Unknown insertados.';
GO

-- =====================================================
-- 2. DIMENSIÓN FECHA COMPLETA (2020-2030)
-- =====================================================
PRINT 'Poblando DimFecha con rango completo 2020-2030...';

DECLARE @FechaInicio DATE = '2020-01-01';
DECLARE @FechaFin DATE = '2030-12-31';
DECLARE @FechaActual DATE = @FechaInicio;

WHILE @FechaActual <= @FechaFin
BEGIN
    IF NOT EXISTS (SELECT 1 FROM dbo.DimFecha WHERE fecha = @FechaActual)
    BEGIN
        INSERT INTO dbo.DimFecha(
            fecha, 
            anio, 
            mes, 
            trimestre, 
            dia_semana, 
            nombre_mes, 
            es_fin_semana, 
            numero_semana,
            dia_mes,
            dia_anio
        )
        VALUES (
            @FechaActual,
            YEAR(@FechaActual),
            MONTH(@FechaActual),
            DATEPART(QUARTER, @FechaActual),
            CASE DATEPART(WEEKDAY, @FechaActual)
                WHEN 1 THEN 'Domingo'
                WHEN 2 THEN 'Lunes'
                WHEN 3 THEN 'Martes'
                WHEN 4 THEN 'Miércoles'
                WHEN 5 THEN 'Jueves'
                WHEN 6 THEN 'Viernes'
                WHEN 7 THEN 'Sábado'
            END,
            CASE MONTH(@FechaActual)
                WHEN 1 THEN 'Enero'
                WHEN 2 THEN 'Febrero'
                WHEN 3 THEN 'Marzo'
                WHEN 4 THEN 'Abril'
                WHEN 5 THEN 'Mayo'
                WHEN 6 THEN 'Junio'
                WHEN 7 THEN 'Julio'
                WHEN 8 THEN 'Agosto'
                WHEN 9 THEN 'Septiembre'
                WHEN 10 THEN 'Octubre'
                WHEN 11 THEN 'Noviembre'
                WHEN 12 THEN 'Diciembre'
            END,
            CASE WHEN DATEPART(WEEKDAY, @FechaActual) IN (1, 7) THEN 1 ELSE 0 END,
            DATEPART(WEEK, @FechaActual),
            DAY(@FechaActual),
            DATEPART(DAYOFYEAR, @FechaActual)
        );
    END
    
    SET @FechaActual = DATEADD(DAY, 1, @FechaActual);
END

DECLARE @CountFecha INT = (SELECT COUNT(*) FROM dbo.DimFecha);
PRINT CONCAT('✓ DimFecha poblada. Total registros: ', @CountFecha);
GO

-- =====================================================
-- 3. DIMENSIÓN MONEDA
-- =====================================================
PRINT 'Poblando DimMoneda...';

-- Insertar monedas principales con ARS como moneda base
IF NOT EXISTS (SELECT 1 FROM dbo.DimMoneda WHERE codigo_moneda = 'ARS')
BEGIN
  INSERT INTO dbo.DimMoneda(codigo_moneda, nombre, simbolo, es_moneda_base)
  VALUES ('ARS', N'Peso Argentino', N'$', 1);
END

IF NOT EXISTS (SELECT 1 FROM dbo.DimMoneda WHERE codigo_moneda = 'USD')
BEGIN
  INSERT INTO dbo.DimMoneda(codigo_moneda, nombre, simbolo, es_moneda_base)
  VALUES ('USD', N'Dólar Estadounidense', N'US$', 0);
END

IF NOT EXISTS (SELECT 1 FROM dbo.DimMoneda WHERE codigo_moneda = 'EUR')
BEGIN
  INSERT INTO dbo.DimMoneda(codigo_moneda, nombre, simbolo, es_moneda_base)
  VALUES ('EUR', N'Euro', N'€', 0);
END

IF NOT EXISTS (SELECT 1 FROM dbo.DimMoneda WHERE codigo_moneda = 'BRL')
BEGIN
  INSERT INTO dbo.DimMoneda(codigo_moneda, nombre, simbolo, es_moneda_base)
  VALUES ('BRL', N'Real Brasileño', N'R$', 0);
END
IF NOT EXISTS (SELECT 1 FROM dbo.DimMoneda WHERE codigo_moneda = 'CNY')
BEGIN
  INSERT INTO dbo.DimMoneda(codigo_moneda, nombre, simbolo, es_moneda_base)
  VALUES ('CNY', N'Yuan Chino', N'¥', 0);
END


DECLARE @CountMoneda INT = (SELECT COUNT(*) FROM dbo.DimMoneda WHERE sk_moneda > 0);
PRINT CONCAT('✓ DimMoneda poblada. Total registros: ', @CountMoneda);
GO

-- =====================================================
-- 3.b TABLA DimExchangeRate (mensual, se une a DimMoneda para símbolo)
-- =====================================================
PRINT 'Poblando DimExchangeRate (tipos de cambio mensuales sintéticos)...';

-- CORRECCIÓN: Generar TODOS los meses del rango, no solo los que tienen ventas
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

DECLARE @CountEx INT = (SELECT COUNT(*) FROM dbo.DimExchangeRate);
PRINT CONCAT('✓ DimExchangeRate poblada. Total registros: ', @CountEx);
PRINT '  (24 meses x 5 monedas = 120 registros esperados para 2023-2024)';
GO

-- =====================================================
-- 4. DIMENSIÓN CANAL
-- =====================================================
PRINT 'Poblando DimCanal...';

MERGE dbo.DimCanal AS tgt
USING (
    SELECT DISTINCT canal FROM OLTP_Celulares.dbo.Ventas
) AS src(canal)
ON tgt.canal = src.canal
WHEN NOT MATCHED THEN
    INSERT (canal, descripcion)
    VALUES (src.canal, 'Venta por canal ' + src.canal);

DECLARE @CountCanal INT = (SELECT COUNT(*) FROM dbo.DimCanal WHERE sk_canal > 0);
PRINT CONCAT('✓ DimCanal poblada. Total registros: ', @CountCanal);
GO

-- =====================================================
-- 5. DIMENSIÓN CLIENTE (SCD Tipo 1)
-- =====================================================
PRINT 'Poblando DimCliente...';

MERGE dbo.DimCliente AS tgt
USING (
  SELECT c.id_cliente, c.nombre, c.apellido, c.genero
  FROM OLTP_Celulares.dbo.Clientes c
) AS src(id_cliente, nombre, apellido, genero)
ON tgt.id_cliente_fuente = src.id_cliente
WHEN NOT MATCHED THEN
  INSERT (id_cliente_fuente, nombre, apellido, genero)
  VALUES (src.id_cliente, src.nombre, src.apellido, src.genero)
WHEN MATCHED THEN
  UPDATE SET nombre = src.nombre, apellido = src.apellido, genero = src.genero;

DECLARE @CountCliente INT = (SELECT COUNT(*) FROM dbo.DimCliente WHERE sk_cliente > 0);
PRINT CONCAT('✓ DimCliente poblada. Total registros: ', @CountCliente);
GO

-- =====================================================
-- 6. DIMENSIÓN PRODUCTO (SCD Tipo 1 - actualización simple)
-- =====================================================
PRINT 'Poblando DimProducto...';

MERGE dbo.DimProducto AS tgt
USING (
  SELECT m.id_modelo, ma.marca, m.modelo, m.almacenamiento_gb, m.ram_gb
  FROM OLTP_Celulares.dbo.Modelos m
  JOIN OLTP_Celulares.dbo.Marcas ma ON ma.id_marca = m.id_marca
) AS src(id_modelo, marca, modelo, almacenamiento_gb, ram_gb)
ON tgt.id_modelo_fuente = src.id_modelo
WHEN NOT MATCHED THEN
  INSERT (id_modelo_fuente, marca, modelo, almacenamiento_gb, ram_gb)
  VALUES (src.id_modelo, src.marca, src.modelo, src.almacenamiento_gb, src.ram_gb)
WHEN MATCHED THEN
  UPDATE SET marca = src.marca, modelo = src.modelo, almacenamiento_gb = src.almacenamiento_gb, ram_gb = src.ram_gb;

DECLARE @CountProducto INT = (SELECT COUNT(*) FROM dbo.DimProducto WHERE sk_producto > 0);
PRINT CONCAT('✓ DimProducto poblada. Total registros: ', @CountProducto);
GO

-- =====================================================
-- 7. DIMENSIÓN LOCAL (SCD Tipo 1)
-- =====================================================
PRINT 'Poblando DimLocal...';

MERGE dbo.DimLocal AS tgt
USING (
  SELECT l.id_local, c.provincia, c.ciudad, l.nombre_local AS local
  FROM OLTP_Celulares.dbo.Locales l
  JOIN OLTP_Celulares.dbo.Ciudades c ON c.id_ciudad = l.id_ciudad
) AS src(id_local, provincia, ciudad, local)
ON tgt.id_local_fuente = src.id_local
WHEN NOT MATCHED THEN
  INSERT (id_local_fuente, provincia, ciudad, local)
  VALUES (src.id_local, src.provincia, src.ciudad, src.local)
WHEN MATCHED THEN
  UPDATE SET provincia = src.provincia, ciudad = src.ciudad, local = src.local;

DECLARE @CountLocal INT = (SELECT COUNT(*) FROM dbo.DimLocal WHERE sk_local > 0);
PRINT CONCAT('✓ DimLocal poblada. Total registros: ', @CountLocal);
GO

-- =====================================================
-- 8. DIMENSIÓN VENDEDOR (SCD Tipo 1)
-- =====================================================
PRINT 'Poblando DimVendedor (SCD Tipo 2 - versión base)...';

-- 1) Actualizar datos de referencia (SCD Tipo 1 sobre la versión activa)
UPDATE dv
SET dv.nombre = src.nombre,
    dv.apellido = src.apellido,
    dv.legajo = src.legajo
FROM dbo.DimVendedor dv
JOIN (
  SELECT id_vendedor, nombre, apellido, legajo
  FROM OLTP_Celulares.dbo.Vendedores
) src ON src.id_vendedor = dv.id_vendedor_fuente
WHERE dv.es_actual = 1
  AND (ISNULL(dv.nombre,'') <> ISNULL(src.nombre,'')
    OR ISNULL(dv.apellido,'') <> ISNULL(src.apellido,'')
    OR ISNULL(dv.legajo,'') <> ISNULL(src.legajo,''));

-- 2) Insertar versión base para vendedores que aún no existen en la dimensión
INSERT INTO dbo.DimVendedor(id_vendedor_fuente, nombre, apellido, legajo, fecha_inicio, fecha_fin, es_actual, version, categoria_vendedor)
SELECT 
  src.id_vendedor,
  src.nombre,
  src.apellido,
  src.legajo,
  '1900-01-01',
  NULL,
  1,
  1,
  'Inicial'
FROM (
  SELECT id_vendedor, nombre, apellido, legajo
  FROM OLTP_Celulares.dbo.Vendedores
) AS src
LEFT JOIN dbo.DimVendedor dv 
  ON dv.id_vendedor_fuente = src.id_vendedor AND dv.es_actual = 1
WHERE dv.sk_vendedor IS NULL;

DECLARE @CountVendedor INT = (SELECT COUNT(*) FROM dbo.DimVendedor WHERE sk_vendedor > 0);
PRINT CONCAT('✓ DimVendedor poblada (SCD2 base). Total registros: ', @CountVendedor);
GO

-- =====================================================
-- 9. DIMENSIÓN FORMA DE PAGO (SCD Tipo 1)
-- =====================================================
PRINT 'Poblando DimFormaPago...';

MERGE dbo.DimFormaPago AS tgt
USING (
  SELECT id_forma_pago, descripcion AS forma_pago
  FROM OLTP_Celulares.dbo.FormasPago
) AS src(id_forma_pago, forma_pago)
ON tgt.id_forma_pago_fuente = src.id_forma_pago
WHEN NOT MATCHED THEN
  INSERT (id_forma_pago_fuente, forma_pago)
  VALUES (src.id_forma_pago, src.forma_pago)
WHEN MATCHED THEN
  UPDATE SET forma_pago = src.forma_pago;

DECLARE @CountFormaPago INT = (SELECT COUNT(*) FROM dbo.DimFormaPago WHERE sk_forma_pago > 0);
PRINT CONCAT('✓ DimFormaPago poblada. Total registros: ', @CountFormaPago);
GO

-- =====================================================
-- 10. TABLA DE HECHOS (FactVentas)
-- =====================================================
PRINT 'Poblando FactVentas con métricas completas...';

INSERT INTO dbo.FactVentas
(id_venta, id_detalle, sk_fecha, sk_cliente, sk_producto, sk_local, sk_vendedor, sk_forma_pago, sk_canal, sk_moneda, cantidad, precio_unitario, costo_unitario, importe, margen, margen_porcentaje, tipo_cambio)
SELECT
  dv.id_venta,
  dv.id_detalle,
  ISNULL(df.sk_fecha, -1),
  ISNULL(dc.sk_cliente, -1),
  ISNULL(dp.sk_producto, -1),
  ISNULL(dl.sk_local, -1),
  ISNULL(dvend.sk_vendedor, -1),
  ISNULL(dfp.sk_forma_pago, -1),
  ISNULL(dcanal.sk_canal, -1),
  ISNULL(dmon.sk_moneda, (SELECT sk_moneda FROM dbo.DimMoneda WHERE codigo_moneda = 'ARS')),
  dv.cantidad,
  dv.precio_unitario,
  dv.costo_unitario,
  (dv.cantidad * dv.precio_unitario) AS importe,
  (dv.cantidad * (dv.precio_unitario - dv.costo_unitario)) AS margen,
  CASE 
    WHEN dv.precio_unitario > 0 THEN ROUND(((dv.precio_unitario - dv.costo_unitario) / dv.precio_unitario) * 100, 2)
    ELSE 0 
  END AS margen_porcentaje,
  1.0000 AS tipo_cambio
FROM OLTP_Celulares.dbo.DetalleVenta dv
JOIN OLTP_Celulares.dbo.Ventas v            ON v.id_venta = dv.id_venta
LEFT JOIN dbo.DimFecha df                    ON df.fecha = v.fecha_venta
LEFT JOIN dbo.DimCliente dc                  ON dc.id_cliente_fuente = v.id_cliente
LEFT JOIN dbo.DimProducto dp                 ON dp.id_modelo_fuente = dv.id_modelo
LEFT JOIN dbo.DimLocal dl                    ON dl.id_local_fuente = v.id_local
LEFT JOIN dbo.DimVendedor dvend              ON dvend.id_vendedor_fuente = v.id_vendedor AND v.fecha_venta BETWEEN dvend.fecha_inicio AND ISNULL(dvend.fecha_fin, '9999-12-31')
LEFT JOIN dbo.DimFormaPago dfp               ON dfp.id_forma_pago_fuente = v.id_forma_pago
LEFT JOIN dbo.DimCanal dcanal                ON dcanal.canal = v.canal
LEFT JOIN dbo.DimMoneda dmon                 ON dmon.codigo_moneda = 'ARS';

DECLARE @CountFactVentas INT = (SELECT COUNT(*) FROM dbo.FactVentas);
PRINT CONCAT('✓ FactVentas poblada. Total registros: ', @CountFactVentas);
GO

PRINT '=== ETL inicial completado exitosamente ===';
PRINT 'Resumen:';

DECLARE @CountFechaFinal INT = (SELECT COUNT(*) FROM dbo.DimFecha);
DECLARE @CountClienteFinal INT = (SELECT COUNT(*) FROM dbo.DimCliente WHERE sk_cliente > 0);
DECLARE @CountProductoFinal INT = (SELECT COUNT(*) FROM dbo.DimProducto WHERE sk_producto > 0);
DECLARE @CountLocalFinal INT = (SELECT COUNT(*) FROM dbo.DimLocal WHERE sk_local > 0);
DECLARE @CountVendedorFinal INT = (SELECT COUNT(*) FROM dbo.DimVendedor WHERE sk_vendedor > 0);
DECLARE @CountFormaPagoFinal INT = (SELECT COUNT(*) FROM dbo.DimFormaPago WHERE sk_forma_pago > 0);
DECLARE @CountCanalFinal INT = (SELECT COUNT(*) FROM dbo.DimCanal WHERE sk_canal > 0);
DECLARE @CountMonedaFinal INT = (SELECT COUNT(*) FROM dbo.DimMoneda WHERE sk_moneda > 0);
DECLARE @CountFactVentasFinal INT = (SELECT COUNT(*) FROM dbo.FactVentas);

PRINT CONCAT('  - DimFecha: ', @CountFechaFinal, ' fechas');
PRINT CONCAT('  - DimCliente: ', @CountClienteFinal, ' clientes');
PRINT CONCAT('  - DimProducto: ', @CountProductoFinal, ' productos');
PRINT CONCAT('  - DimLocal: ', @CountLocalFinal, ' locales');
PRINT CONCAT('  - DimVendedor: ', @CountVendedorFinal, ' vendedores');
PRINT CONCAT('  - DimFormaPago: ', @CountFormaPagoFinal, ' formas de pago');
PRINT CONCAT('  - DimCanal: ', @CountCanalFinal, ' canales');
PRINT CONCAT('  - DimMoneda: ', @CountMonedaFinal, ' monedas');
PRINT CONCAT('  - FactVentas: ', @CountFactVentasFinal, ' registros de ventas');
GO
