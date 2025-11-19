/*
  BAJA_PRODUCTO.sql - Eliminar un producto (modelo) del OLTP
  - Borra el modelo solo si NO tiene ventas asociadas
  - Si la marca queda sin modelos, también elimina la marca
  - Útil para revertir un alta hecha con SOLO_PRODUCTOS.sql

  PASOS:
  1) Configura las variables de identificación del producto
  2) Ejecuta este script en OLTP_Celulares
  3) Luego sincroniza el DW ejecutando: etl/05_reproceso_diario.sql
*/

USE OLTP_Celulares;
GO

-- CONFIGURAR ↓↓↓
DECLARE
    @MarcaNombre      nvarchar(60)  = N'PAPURRI',
    @ModeloNombre     nvarchar(150) = N'Cantero 3000',
    @AlmacenamientoGB int           = 256,
    @RamGB            int           = 12;
-- ↑↑↑ CAMBIAR SOLO ESTO

SET NOCOUNT ON;

-- Buscar marca
DECLARE @id_marca int = (SELECT id_marca FROM dbo.Marcas WHERE marca = @MarcaNombre);
IF @id_marca IS NULL
BEGIN
    PRINT CONCAT('❌ Marca no encontrada: ', @MarcaNombre);
    RETURN;
END

-- Buscar modelo específico
DECLARE @id_modelo int = (
    SELECT id_modelo FROM dbo.Modelos
    WHERE id_marca=@id_marca AND modelo=@ModeloNombre
      AND almacenamiento_gb=@AlmacenamientoGB AND ram_gb=@RamGB
);
IF @id_modelo IS NULL
BEGIN
    PRINT CONCAT('❌ Modelo no encontrado: ', @ModeloNombre, ' ', @AlmacenamientoGB, 'GB/', @RamGB, 'GB RAM');
    RETURN;
END

-- Verificar que NO tenga ventas asociadas
IF EXISTS (SELECT 1 FROM dbo.DetalleVenta WHERE id_modelo = @id_modelo)
BEGIN
    PRINT '❌ No se puede eliminar: el modelo tiene ventas asociadas en DetalleVenta.';
    PRINT '💡 Elimina primero esas ventas con BAJAS_SIMPLES.sql (o cambia de modelo).';
    RETURN;
END

-- Eliminar el modelo (y marca si queda huérfana)
SET XACT_ABORT ON;
BEGIN TRAN;
    DELETE FROM dbo.Modelos WHERE id_modelo = @id_modelo;
    PRINT CONCAT('✅ Modelo eliminado: ', @ModeloNombre, ' ', @AlmacenamientoGB, 'GB/', @RamGB, 'GB RAM');

    IF NOT EXISTS (SELECT 1 FROM dbo.Modelos WHERE id_marca = @id_marca)
    BEGIN
        DELETE FROM dbo.Marcas WHERE id_marca = @id_marca;
        PRINT CONCAT('ℹ️  Marca eliminada por quedar sin modelos: ', @MarcaNombre);
    END
COMMIT;

PRINT '✅ Baja de producto realizada en OLTP.';
PRINT '💡 Ejecuta luego etl/05_reproceso_diario.sql para sincronizar el DW.';