/*
  SOLO_PRODUCTOS.sql - Agregar solo productos (marca + modelos) sin crear ventas
  Cambiar solo los datos al inicio
*/
USE OLTP_Celulares;
GO

-- DATOS DEL NUEVO PRODUCTO ↓↓↓
DECLARE
    @MarcaNombre      nvarchar(60)  = N'PAPURRI',
    @ModeloNombre     nvarchar(150) = N'Cantero 3000',
    @AlmacenamientoGB int           = 256,
    @RamGB            int           = 12;
-- ↑↑↑ CAMBIAR SOLO ESTO

-- Crear marca si no existe
DECLARE @id_marca int = (SELECT id_marca FROM dbo.Marcas WHERE marca=@MarcaNombre);
IF @id_marca IS NULL
BEGIN
  SET @id_marca = (SELECT ISNULL(MAX(id_marca),0)+1 FROM dbo.Marcas);
  INSERT INTO dbo.Marcas (id_marca, marca) VALUES (@id_marca, @MarcaNombre);
  PRINT CONCAT('✅ Marca creada: ', @MarcaNombre, ' (ID: ', @id_marca, ')');
END
ELSE
BEGIN
  PRINT CONCAT('ℹ️  Marca ya existe: ', @MarcaNombre, ' (ID: ', @id_marca, ')');
END

-- Crear modelo si no existe
DECLARE @id_modelo int = (
  SELECT id_modelo FROM dbo.Modelos
  WHERE id_marca=@id_marca AND modelo=@ModeloNombre 
    AND almacenamiento_gb=@AlmacenamientoGB AND ram_gb=@RamGB
);
IF @id_modelo IS NULL
BEGIN
  SET @id_modelo = (SELECT ISNULL(MAX(id_modelo),0)+1 FROM dbo.Modelos);
  INSERT INTO dbo.Modelos (id_modelo, id_marca, modelo, almacenamiento_gb, ram_gb)
  VALUES (@id_modelo, @id_marca, @ModeloNombre, @AlmacenamientoGB, @RamGB);
  PRINT CONCAT('✅ Modelo creado: ', @ModeloNombre, ' ', @AlmacenamientoGB, 'GB/', @RamGB, 'GB RAM (ID: ', @id_modelo, ')');
END
ELSE
BEGIN
  PRINT CONCAT('ℹ️  Modelo ya existe: ', @ModeloNombre, ' ', @AlmacenamientoGB, 'GB/', @RamGB, 'GB RAM (ID: ', @id_modelo, ')');
END

PRINT '✅ Proceso completado - Solo se agregaron productos, no ventas';
PRINT '💡 Para sincronizar DW usar: REFRESCAR_DW.sql';
PRINT '💡 Para agregar una venta de este producto, usar ALTAS_SIMPLES.sql';