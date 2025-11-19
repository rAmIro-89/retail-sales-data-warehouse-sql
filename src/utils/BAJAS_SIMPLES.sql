/*
  BAJAS_SIMPLES.sql - Eliminar ventas y sincronizar DW
  Cambiar solo las variables al inicio
*/
USE OLTP_Celulares;
GO

-- CONFIGURAR AQUÍ ↓↓↓
DECLARE @CantidadUltimas INT = 2;        -- Para eliminar las N últimas ventas
DECLARE @IdVentaEspecifica INT = NULL;   -- O especificar ID de venta (ej: 1005)
-- ↑↑↑ CAMBIAR SOLO ESTO

SET XACT_ABORT ON;
BEGIN TRAN;

IF @IdVentaEspecifica IS NOT NULL
BEGIN
    -- Eliminar venta específica
    PRINT CONCAT('Eliminando venta ID: ', @IdVentaEspecifica);
    DELETE FROM dbo.DetalleVenta WHERE id_venta = @IdVentaEspecifica;
    DELETE FROM dbo.Ventas WHERE id_venta = @IdVentaEspecifica;
END
ELSE
BEGIN
    -- Eliminar últimas N ventas
    PRINT CONCAT('Eliminando últimas ', @CantidadUltimas, ' ventas...');
    
    ;WITH Ultimas AS (
        SELECT TOP (@CantidadUltimas) id_venta 
        FROM dbo.Ventas 
        ORDER BY fecha_venta DESC, id_venta DESC
    )
    DELETE d FROM dbo.DetalleVenta d 
    JOIN Ultimas u ON d.id_venta = u.id_venta;
    
    ;WITH Ultimas AS (
        SELECT TOP (@CantidadUltimas) id_venta 
        FROM dbo.Ventas 
        ORDER BY fecha_venta DESC, id_venta DESC
    )
    DELETE v FROM dbo.Ventas v 
    JOIN Ultimas u ON v.id_venta = u.id_venta;
END

COMMIT;
PRINT '✅ Baja realizada en OLTP';
PRINT '💡 Para sincronizar DW ejecutar: 05_reproceso_diario.sql';