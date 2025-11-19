-- 05_reproceso_diario.sql
-- Reprocesa incrementos por fecha de venta con SCD Tipo 2
-- VERSIÓN CORREGIDA: Variables consolidadas + Transacción completa
USE DW_Celulares;
GO

-- =====================================================
-- CONFIGURACIÓN: Cambiar fecha aquí para reprocesar
-- =====================================================
DECLARE @fecha_proceso DATE = CAST(GETDATE() AS DATE); -- ← MODIFICAR ESTA LÍNEA si se reprocesa otra fecha (ej: '2024-11-15')
DECLARE @mes_inicio DATE = DATEFROMPARTS(YEAR(@fecha_proceso), MONTH(@fecha_proceso), 1);
DECLARE @mes_fin DATE = EOMONTH(@mes_inicio);

PRINT CONCAT('=== Reprocesando fecha: ', @fecha_proceso, ' ===');
PRINT CONCAT('    Ventana mensual SCD2: ', @mes_inicio, ' al ', @mes_fin);

BEGIN TRY
    BEGIN TRANSACTION;
    
-- =====================================================
-- VALIDACIÓN DE DimFecha
-- =====================================================
-- La fecha ya debe existir (se pre-cargó en ETL inicial)
-- Pero por seguridad, verificamos

    IF NOT EXISTS (SELECT 1 FROM dbo.DimFecha WHERE fecha = @fecha_proceso)
    BEGIN
        PRINT 'ADVERTENCIA: La fecha no existe en DimFecha. Insertando...';
        INSERT INTO dbo.DimFecha(
            fecha, anio, mes, trimestre, dia_semana, nombre_mes, es_fin_semana, numero_semana, dia_mes, dia_anio
        )
        VALUES (
            @fecha_proceso,
            YEAR(@fecha_proceso),
            MONTH(@fecha_proceso),
            DATEPART(QUARTER, @fecha_proceso),
            CASE DATEPART(WEEKDAY, @fecha_proceso)
                WHEN 1 THEN 'Domingo' WHEN 2 THEN 'Lunes' WHEN 3 THEN 'Martes'
                WHEN 4 THEN 'Miércoles' WHEN 5 THEN 'Jueves' WHEN 6 THEN 'Viernes' WHEN 7 THEN 'Sábado'
            END,
            CASE MONTH(@fecha_proceso)
                WHEN 1 THEN 'Enero' WHEN 2 THEN 'Febrero' WHEN 3 THEN 'Marzo' WHEN 4 THEN 'Abril'
                WHEN 5 THEN 'Mayo' WHEN 6 THEN 'Junio' WHEN 7 THEN 'Julio' WHEN 8 THEN 'Agosto'
                WHEN 9 THEN 'Septiembre' WHEN 10 THEN 'Octubre' WHEN 11 THEN 'Noviembre' WHEN 12 THEN 'Diciembre'
            END,
            CASE WHEN DATEPART(WEEKDAY, @fecha_proceso) IN (1, 7) THEN 1 ELSE 0 END,
            DATEPART(WEEK, @fecha_proceso),
            DAY(@fecha_proceso),
            DATEPART(DAYOFYEAR, @fecha_proceso)
        );
    END

    -- =====================================================
    -- DIMENSIONES SCD TIPO 1 (actualización simple)
    -- =====================================================
    PRINT 'Actualizando dimensiones SCD Tipo 1...';

    -- DimCliente
    MERGE dbo.DimCliente AS tgt
    USING (SELECT c.id_cliente, c.nombre, c.apellido, c.genero
           FROM OLTP_Celulares.dbo.Clientes c) AS src(id_cliente, nombre, apellido, genero)
    ON tgt.id_cliente_fuente = src.id_cliente
    WHEN NOT MATCHED THEN INSERT(id_cliente_fuente,nombre,apellido,genero) VALUES(src.id_cliente,src.nombre,src.apellido,src.genero)
    WHEN MATCHED THEN UPDATE SET nombre=src.nombre, apellido=src.apellido, genero=src.genero;

    PRINT '✓ DimCliente actualizada';

    -- DimProducto (SCD Tipo 1 - actualización simple)
    MERGE dbo.DimProducto AS tgt
    USING (SELECT m.id_modelo, ma.marca, m.modelo, m.almacenamiento_gb, m.ram_gb
           FROM OLTP_Celulares.dbo.Modelos m JOIN OLTP_Celulares.dbo.Marcas ma ON ma.id_marca = m.id_marca) AS src(id_modelo,marca,modelo,almacenamiento_gb,ram_gb)
    ON tgt.id_modelo_fuente = src.id_modelo
    WHEN NOT MATCHED THEN INSERT(id_modelo_fuente,marca,modelo,almacenamiento_gb,ram_gb) VALUES(src.id_modelo,src.marca,src.modelo,src.almacenamiento_gb,src.ram_gb)
    WHEN MATCHED THEN UPDATE SET marca=src.marca, modelo=src.modelo, almacenamiento_gb=src.almacenamiento_gb, ram_gb=src.ram_gb;

    PRINT '✓ DimProducto actualizada';

    -- DimLocal
    MERGE dbo.DimLocal AS tgt
    USING (SELECT l.id_local, c.provincia, c.ciudad, l.nombre_local AS local
           FROM OLTP_Celulares.dbo.Locales l JOIN OLTP_Celulares.dbo.Ciudades c ON c.id_ciudad=l.id_ciudad) AS src(id_local,provincia,ciudad,local)
    ON tgt.id_local_fuente = src.id_local
    WHEN NOT MATCHED THEN INSERT(id_local_fuente,provincia,ciudad,local) VALUES(src.id_local,src.provincia,src.ciudad,src.local)
    WHEN MATCHED THEN UPDATE SET provincia=src.provincia, ciudad=src.ciudad, local=src.local;

    PRINT '✓ DimLocal actualizada';

    -- =====================================================
    -- DimVendedor - SCD TIPO 2 (actualización versionada)
    -- =====================================================
    -- Actualización de datos de referencia en versión activa (SCD1 dentro de SCD2)
    UPDATE dv
    SET dv.nombre = src.nombre,
            dv.apellido = src.apellido,
            dv.legajo = src.legajo
    FROM dbo.DimVendedor dv
    JOIN (
        SELECT id_vendedor, nombre, apellido, legajo FROM OLTP_Celulares.dbo.Vendedores
    ) src ON src.id_vendedor = dv.id_vendedor_fuente
    WHERE dv.es_actual = 1
        AND (ISNULL(dv.nombre,'') <> ISNULL(src.nombre,'')
            OR ISNULL(dv.apellido,'') <> ISNULL(src.apellido,'')
            OR ISNULL(dv.legajo,'') <> ISNULL(src.legajo,''));

    -- Insertar vendedores nuevos con versión base
    INSERT INTO dbo.DimVendedor(id_vendedor_fuente, nombre, apellido, legajo, fecha_inicio, fecha_fin, es_actual, version, categoria_vendedor)
    SELECT src.id_vendedor, src.nombre, src.apellido, src.legajo, '1900-01-01', NULL, 1, 1, 'Inicial'
    FROM (
        SELECT id_vendedor, nombre, apellido, legajo FROM OLTP_Celulares.dbo.Vendedores
    ) src
    LEFT JOIN dbo.DimVendedor dv ON dv.id_vendedor_fuente = src.id_vendedor AND dv.es_actual = 1
    WHERE dv.sk_vendedor IS NULL;

    PRINT '✓ DimVendedor actualizado datos base';

    -- SCD Tipo 2 por categoría mensual del vendedor
    PRINT CONCAT('Clasificando vendedores por desempeño del ', CONVERT(VARCHAR(10), @mes_inicio, 120), ' al ', CONVERT(VARCHAR(10), @mes_fin, 120), '...');

    -- Cerrar versión anterior si corresponde y crear/actualizar versión del mes actual
    DECLARE @tmp TABLE(id_vendedor INT, categoria NVARCHAR(20));
    INSERT INTO @tmp(id_vendedor, categoria)
    SELECT v.id_vendedor,
                 ISNULL(
                     CASE 
                         WHEN vm.monto_usd_mes IS NULL THEN 'SinVentas'
                         ELSE CASE 
                             WHEN vm.ntile_val = 1 THEN 'Top'
                             WHEN vm.ntile_val IN (2,3) THEN 'Medio'
                             ELSE 'Bajo'
                         END 
                     END,
                     'SinVentas'
                 ) AS categoria
    FROM OLTP_Celulares.dbo.Vendedores v
    LEFT JOIN (
        SELECT x.id_vendedor, x.monto_usd_mes,
                     NTILE(5) OVER (ORDER BY x.monto_usd_mes DESC) AS ntile_val
            FROM (
                SELECT v.id_vendedor, 
                       SUM((d.precio_unitario * d.cantidad) / 1000.0) AS monto_usd_mes
                FROM OLTP_Celulares.dbo.Ventas v
                JOIN OLTP_Celulares.dbo.DetalleVenta d ON d.id_venta = v.id_venta
                WHERE v.fecha_venta BETWEEN @mes_inicio AND @mes_fin
                GROUP BY v.id_vendedor
            ) x
        ) vm ON vm.id_vendedor = v.id_vendedor;
    
    -- Si ya existe una versión activa con fecha_inicio = @mes_inicio, actualizamos la categoría (no creamos nueva versión)
    UPDATE dv
    SET dv.categoria_vendedor = t.categoria
    FROM dbo.DimVendedor dv
    JOIN @tmp t ON t.id_vendedor = dv.id_vendedor_fuente
    WHERE dv.es_actual = 1 AND dv.fecha_inicio = @mes_inicio
        AND ISNULL(dv.categoria_vendedor,'') <> ISNULL(t.categoria,'');

    -- Para los que no tienen versión activa del mes actual, cerramos la anterior y abrimos una nueva
    ;WITH pendientes AS (
        SELECT t.id_vendedor, t.categoria
        FROM @tmp t
        LEFT JOIN dbo.DimVendedor dv
            ON dv.id_vendedor_fuente = t.id_vendedor AND dv.es_actual = 1 AND dv.fecha_inicio = @mes_inicio
        WHERE dv.sk_vendedor IS NULL
    )
    UPDATE dv
    SET dv.fecha_fin = DATEADD(DAY, -1, @mes_inicio), dv.es_actual = 0
    FROM dbo.DimVendedor dv
    JOIN pendientes p ON p.id_vendedor = dv.id_vendedor_fuente
    WHERE dv.es_actual = 1 AND dv.fecha_inicio < @mes_inicio;

    INSERT INTO dbo.DimVendedor(id_vendedor_fuente, nombre, apellido, legajo, fecha_inicio, fecha_fin, es_actual, version, categoria_vendedor)
    SELECT 
        p.id_vendedor,
        src.nombre,
        src.apellido,
        src.legajo,
        @mes_inicio,
        NULL,
        1,
        ISNULL((SELECT MAX(version) FROM dbo.DimVendedor WHERE id_vendedor_fuente = p.id_vendedor), 0) + 1,
        p.categoria
    FROM pendientes p
    JOIN OLTP_Celulares.dbo.Vendedores src ON src.id_vendedor = p.id_vendedor;

    PRINT '✓ DimVendedor versionado por categoría mensual';

    -- DimFormaPago
    MERGE dbo.DimFormaPago AS tgt
    USING (SELECT id_forma_pago, descripcion AS forma_pago FROM OLTP_Celulares.dbo.FormasPago) AS src(id_forma_pago,forma_pago)
    ON tgt.id_forma_pago_fuente = src.id_forma_pago
    WHEN NOT MATCHED THEN INSERT(id_forma_pago_fuente,forma_pago) VALUES(src.id_forma_pago,src.forma_pago)
    WHEN MATCHED THEN UPDATE SET forma_pago=src.forma_pago;

    PRINT '✓ DimFormaPago actualizada';

    -- DimCanal
    MERGE dbo.DimCanal AS tgt
    USING (SELECT DISTINCT canal FROM OLTP_Celulares.dbo.Ventas) AS src(canal)
    ON tgt.canal = src.canal
    WHEN NOT MATCHED THEN INSERT(canal, descripcion) VALUES(src.canal, 'Venta por canal ' + src.canal);

    PRINT '✓ DimCanal actualizada';

    -- DimMoneda (normalmente no cambia, pero por completitud)
    PRINT '✓ DimMoneda sin cambios (catálogo estático)';

    -- =====================================================
    -- TABLA DE HECHOS
    -- =====================================================
    PRINT 'Procesando FactVentas...';

    -- Eliminar registros huérfanos del DW (que ya no existen en OLTP)
    -- NOTA: Esta operación sincroniza borrados del OLTP. Si se requiere historización completa, comentar este DELETE.
    DELETE fv 
    FROM dbo.FactVentas fv
    LEFT JOIN OLTP_Celulares.dbo.Ventas v ON v.id_venta = fv.id_venta
    WHERE v.id_venta IS NULL;

    PRINT '✓ Registros huérfanos eliminados';

    -- Insertar/actualizar hechos de la fecha
    -- NOTA: Usamos MERGE para permitir actualización si ya existen
    MERGE dbo.FactVentas AS tgt
    USING (
        SELECT
          dv.id_venta,
          dv.id_detalle,
          ISNULL(df.sk_fecha, -1) AS sk_fecha,
          ISNULL(dc.sk_cliente, -1) AS sk_cliente,
          ISNULL(dp.sk_producto, -1) AS sk_producto,
          ISNULL(dl.sk_local, -1) AS sk_local,
          ISNULL(dvend.sk_vendedor, -1) AS sk_vendedor,
          ISNULL(dfp.sk_forma_pago, -1) AS sk_forma_pago,
          ISNULL(dcanal.sk_canal, -1) AS sk_canal,
          ISNULL(dmon.sk_moneda, (SELECT sk_moneda FROM dbo.DimMoneda WHERE codigo_moneda = 'ARS')) AS sk_moneda,
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
        JOIN OLTP_Celulares.dbo.Ventas v ON v.id_venta = dv.id_venta
        LEFT JOIN dbo.DimFecha df ON df.fecha = v.fecha_venta
        LEFT JOIN dbo.DimCliente dc ON dc.id_cliente_fuente = v.id_cliente
        LEFT JOIN dbo.DimProducto dp ON dp.id_modelo_fuente = dv.id_modelo
        LEFT JOIN dbo.DimLocal dl ON dl.id_local_fuente = v.id_local
        LEFT JOIN dbo.DimVendedor dvend ON dvend.id_vendedor_fuente = v.id_vendedor AND v.fecha_venta BETWEEN dvend.fecha_inicio AND ISNULL(dvend.fecha_fin, '9999-12-31')
        LEFT JOIN dbo.DimFormaPago dfp ON dfp.id_forma_pago_fuente = v.id_forma_pago
        LEFT JOIN dbo.DimCanal dcanal ON dcanal.canal = v.canal
        LEFT JOIN dbo.DimMoneda dmon ON dmon.codigo_moneda = 'ARS'
        WHERE v.fecha_venta = @fecha_proceso
        ) AS src(id_venta, id_detalle, sk_fecha, sk_cliente, sk_producto, sk_local, sk_vendedor, sk_forma_pago, sk_canal, sk_moneda, cantidad, precio_unitario, costo_unitario, importe, margen, margen_porcentaje, tipo_cambio)
    ON tgt.id_venta = src.id_venta AND tgt.id_detalle = src.id_detalle
    WHEN NOT MATCHED THEN
        INSERT (id_venta, id_detalle, sk_fecha, sk_cliente, sk_producto, sk_local, sk_vendedor, sk_forma_pago, sk_canal, sk_moneda, cantidad, precio_unitario, costo_unitario, importe, margen, margen_porcentaje, tipo_cambio)
        VALUES (src.id_venta, src.id_detalle, src.sk_fecha, src.sk_cliente, src.sk_producto, src.sk_local, src.sk_vendedor, src.sk_forma_pago, src.sk_canal, src.sk_moneda, src.cantidad, src.precio_unitario, src.costo_unitario, src.importe, src.margen, src.margen_porcentaje, src.tipo_cambio)
    WHEN MATCHED THEN
        UPDATE SET 
            sk_fecha = src.sk_fecha,
            sk_cliente = src.sk_cliente,
            sk_producto = src.sk_producto,
            sk_local = src.sk_local,
            sk_vendedor = src.sk_vendedor,
            sk_forma_pago = src.sk_forma_pago,
            sk_canal = src.sk_canal,
            sk_moneda = src.sk_moneda,
            cantidad = src.cantidad,
            precio_unitario = src.precio_unitario,
            costo_unitario = src.costo_unitario,
            importe = src.importe,
            margen = src.margen,
            margen_porcentaje = src.margen_porcentaje,
            tipo_cambio = src.tipo_cambio;

    DECLARE @CountFactVentasReproceso INT = (SELECT COUNT(*) FROM dbo.FactVentas);
    PRINT CONCAT('✓ FactVentas procesada para fecha: ', @fecha_proceso);
    PRINT CONCAT('  Total registros en FactVentas: ', @CountFactVentasReproceso);
    
    COMMIT TRANSACTION;
    PRINT '=== ✅ Reproceso completado exitosamente ===';
    
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    
    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
    DECLARE @ErrorState INT = ERROR_STATE();
    
    PRINT '=== ❌ ERROR EN REPROCESO ===';
    PRINT CONCAT('Mensaje: ', @ErrorMessage);
    PRINT CONCAT('Severidad: ', @ErrorSeverity);
    PRINT CONCAT('Estado: ', @ErrorState);
    PRINT 'Transacción revertida (ROLLBACK).';
    
    RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
END CATCH
GO
