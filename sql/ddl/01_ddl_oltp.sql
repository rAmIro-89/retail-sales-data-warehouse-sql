-- 01_ddl_oltp.sql
USE OLTP_Celulares;
GO

-- Catálogos y tablas normalizadas
IF OBJECT_ID('dbo.Ciudades', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Ciudades(
        id_ciudad INT PRIMARY KEY,
        ciudad NVARCHAR(100) NOT NULL,
        provincia NVARCHAR(100) NOT NULL
    );
END
GO

IF OBJECT_ID('dbo.Locales', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Locales(
        id_local INT PRIMARY KEY,
        id_ciudad INT NOT NULL,
        nombre_local NVARCHAR(150) NOT NULL,
        direccion NVARCHAR(200) NOT NULL,
        CONSTRAINT FK_Locales_Ciudades FOREIGN KEY(id_ciudad) REFERENCES dbo.Ciudades(id_ciudad)
    );
END
GO

IF OBJECT_ID('dbo.Marcas', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Marcas(
        id_marca INT PRIMARY KEY,
        marca NVARCHAR(100) NOT NULL
    );
END
GO

IF OBJECT_ID('dbo.Modelos', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Modelos(
        id_modelo INT PRIMARY KEY,
        id_marca INT NOT NULL,
        modelo NVARCHAR(150) NOT NULL,
        almacenamiento_gb INT NOT NULL,
        ram_gb INT NOT NULL,
        CONSTRAINT FK_Modelos_Marcas FOREIGN KEY(id_marca) REFERENCES dbo.Marcas(id_marca)
    );
END
GO

IF OBJECT_ID('dbo.Vendedores', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Vendedores(
        id_vendedor INT PRIMARY KEY,
        nombre NVARCHAR(100) NOT NULL,
        apellido NVARCHAR(100) NOT NULL,
        legajo NVARCHAR(50) NOT NULL UNIQUE
    );
END
GO

IF OBJECT_ID('dbo.Clientes', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Clientes(
        id_cliente INT PRIMARY KEY,
        nombre NVARCHAR(100) NOT NULL,
        apellido NVARCHAR(100) NOT NULL,
        dni BIGINT NOT NULL UNIQUE,
        genero CHAR(1) NOT NULL,
        fecha_nacimiento DATE NOT NULL
    );
END
GO

IF OBJECT_ID('dbo.FormasPago', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.FormasPago(
        id_forma_pago INT PRIMARY KEY,
        descripcion NVARCHAR(100) NOT NULL
    );
END
GO

IF OBJECT_ID('dbo.Ventas', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Ventas(
        id_venta INT PRIMARY KEY,
        fecha_venta DATE NOT NULL,
        id_local INT NOT NULL,
        id_cliente INT NOT NULL,
        id_vendedor INT NOT NULL,
        id_forma_pago INT NOT NULL,
        canal NVARCHAR(30) NOT NULL CHECK (canal IN ('Salón','Online')),
        CONSTRAINT FK_Ventas_Locales FOREIGN KEY(id_local) REFERENCES dbo.Locales(id_local),
        CONSTRAINT FK_Ventas_Clientes FOREIGN KEY(id_cliente) REFERENCES dbo.Clientes(id_cliente),
        CONSTRAINT FK_Ventas_Vendedores FOREIGN KEY(id_vendedor) REFERENCES dbo.Vendedores(id_vendedor),
        CONSTRAINT FK_Ventas_FormasPago FOREIGN KEY(id_forma_pago) REFERENCES dbo.FormasPago(id_forma_pago)
    );
END
GO

IF OBJECT_ID('dbo.DetalleVenta', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.DetalleVenta(
        id_detalle INT PRIMARY KEY,
        id_venta INT NOT NULL,
        id_modelo INT NOT NULL,
        cantidad INT NOT NULL CHECK (cantidad > 0),
        precio_unitario DECIMAL(12,2) NOT NULL CHECK (precio_unitario > 0),
        costo_unitario DECIMAL(12,2) NOT NULL CHECK (costo_unitario > 0),
        CONSTRAINT FK_DetalleVenta_Ventas FOREIGN KEY(id_venta) REFERENCES dbo.Ventas(id_venta),
        CONSTRAINT FK_DetalleVenta_Modelos FOREIGN KEY(id_modelo) REFERENCES dbo.Modelos(id_modelo)
    );
END
GO
