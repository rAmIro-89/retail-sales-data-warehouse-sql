/*
  ALTAS_SIMPLES.sql - Crear nueva venta
  Cambiar solo los datos al inicio
*/
USE OLTP_Celulares;
GO

-- DATOS DE LA NUEVA VENTA ↓↓↓
DECLARE
    @MarcaNombre      nvarchar(60)  = N'Apple',
    @ModeloNombre     nvarchar(150) = N'iPhone 17',
    @AlmacenamientoGB int           = 256,
    @RamGB            int           = 8,
    @DNI_Cliente      bigint        = 34309632,
    @NombreCliente    nvarchar(100) = N'Ramiro',
    @ApellidoCliente  nvarchar(100) = N'Ottone Villar',
    @IdLocal          int           = 1,             -- debe existir en Locales
    @LegajoVendedor   nvarchar(50)  = N'VEN-1008',  -- debe existir en Vendedores
    @FormaPagoDesc    nvarchar(30)  = N'Efectivo',  -- debe existir en FormasPago
    @Cantidad         int           = 1,
    @PrecioUnitario   decimal(12,2) = 829.00,
    @CostoUnitario    decimal(12,2) = 600.00;
-- ↑↑↑ CAMBIAR SOLO ESTO

-- Crear marca si no existe
DECLARE @id_marca int = (SELECT id_marca FROM dbo.Marcas WHERE marca=@MarcaNombre);
IF @id_marca IS NULL
BEGIN
  SET @id_marca = (SELECT ISNULL(MAX(id_marca),0)+1 FROM dbo.Marcas);
  INSERT INTO dbo.Marcas (id_marca, marca) VALUES (@id_marca, @MarcaNombre);
  PRINT CONCAT('✅ Marca creada: ', @MarcaNombre);
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
  PRINT CONCAT('✅ Modelo creado: ', @ModeloNombre);
END

-- Crear cliente si no existe
DECLARE @id_cliente int = (SELECT id_cliente FROM dbo.Clientes WHERE dni=@DNI_Cliente);
IF @id_cliente IS NULL
BEGIN
  SET @id_cliente = (SELECT ISNULL(MAX(id_cliente),0)+1 FROM dbo.Clientes);
  INSERT INTO dbo.Clientes (id_cliente, nombre, apellido, dni, genero, fecha_nacimiento)
  VALUES (@id_cliente, @NombreCliente, @ApellidoCliente, @DNI_Cliente, 'M', '1990-01-01');
  PRINT CONCAT('✅ Cliente creado: ', @NombreCliente, ' ', @ApellidoCliente);
END

-- Validar referencias
DECLARE @id_local int = (SELECT id_local FROM dbo.Locales WHERE id_local=@IdLocal);
DECLARE @id_vendedor int = (SELECT id_vendedor FROM dbo.Vendedores WHERE legajo=@LegajoVendedor);
DECLARE @id_forma int = (SELECT id_forma_pago FROM dbo.FormasPago WHERE descripcion=@FormaPagoDesc);

IF @id_local IS NULL OR @id_vendedor IS NULL OR @id_forma IS NULL
BEGIN
    PRINT '❌ Error: Local, Vendedor o Forma de Pago no encontrados';
    RETURN;
END

-- Crear venta
DECLARE @new_id_venta   int = (SELECT ISNULL(MAX(id_venta),0)+1 FROM dbo.Ventas);
DECLARE @new_id_detalle int = (SELECT ISNULL(MAX(id_detalle),0)+1 FROM dbo.DetalleVenta);

SET XACT_ABORT ON;
BEGIN TRAN;
  INSERT INTO dbo.Ventas (id_venta, fecha_venta, id_local, id_cliente, id_vendedor, id_forma_pago, canal)
  VALUES (@new_id_venta, CAST(GETDATE() AS DATE), @id_local, @id_cliente, @id_vendedor, @id_forma, 'Salón');

  INSERT INTO dbo.DetalleVenta (id_detalle, id_venta, id_modelo, cantidad, precio_unitario, costo_unitario)
  VALUES (@new_id_detalle, @new_id_venta, @id_modelo, @Cantidad, @PrecioUnitario, @CostoUnitario);
COMMIT;

PRINT CONCAT('✅ Venta creada - ID: ', @new_id_venta);
PRINT '💡 Para sincronizar DW usar: REFRESCAR_DW.sql';