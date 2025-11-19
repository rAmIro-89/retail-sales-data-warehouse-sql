-- 03_ddl_dw.sql
USE DW_Celulares;
GO

-- Dimensiones
IF OBJECT_ID('dbo.DimFecha', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.DimFecha(
        sk_fecha INT IDENTITY(1,1) PRIMARY KEY,
        fecha DATE NOT NULL UNIQUE,
        anio INT NOT NULL,
        mes INT NOT NULL,
        trimestre INT NOT NULL,
        dia_semana NVARCHAR(20) NOT NULL,
        nombre_mes NVARCHAR(20) NOT NULL,
        es_fin_semana BIT NOT NULL,
        numero_semana INT NOT NULL,
        dia_mes INT NOT NULL,
        dia_anio INT NOT NULL
    );
END
GO

IF OBJECT_ID('dbo.DimCliente', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.DimCliente(
        sk_cliente INT IDENTITY(1,1) PRIMARY KEY,
        id_cliente_fuente INT NOT NULL UNIQUE,
        nombre NVARCHAR(100),
        apellido NVARCHAR(100),
        genero CHAR(1)
    );
END
GO

IF OBJECT_ID('dbo.DimProducto', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.DimProducto(
        sk_producto INT IDENTITY(1,1) PRIMARY KEY,
        id_modelo_fuente INT NOT NULL UNIQUE,
        marca NVARCHAR(100),
        modelo NVARCHAR(150),
        almacenamiento_gb INT,
        ram_gb INT
    );
END
GO

IF OBJECT_ID('dbo.DimLocal', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.DimLocal(
        sk_local INT IDENTITY(1,1) PRIMARY KEY,
        id_local_fuente INT NOT NULL UNIQUE,
        provincia NVARCHAR(100),
        ciudad NVARCHAR(100),
        local NVARCHAR(150)
    );
END
GO

IF OBJECT_ID('dbo.DimVendedor', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.DimVendedor(
        sk_vendedor INT IDENTITY(1,1) PRIMARY KEY,
        id_vendedor_fuente INT NOT NULL,
        nombre NVARCHAR(100),
        apellido NVARCHAR(100),
        legajo NVARCHAR(50),
        -- Columnas SCD Tipo 2 para trazabilidad del vendedor
        fecha_inicio DATE NOT NULL DEFAULT '1900-01-01',
        fecha_fin DATE NULL,
        es_actual BIT NOT NULL DEFAULT 1,
        version INT NOT NULL DEFAULT 1,
        -- Clasificación del vendedor por desempeño (derivada por períodos)
        categoria_vendedor NVARCHAR(20) NOT NULL DEFAULT 'Inicial',
        CONSTRAINT UQ_DimVendedor_Actual UNIQUE(id_vendedor_fuente, es_actual, fecha_fin)
    );
END
GO

IF OBJECT_ID('dbo.DimFormaPago', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.DimFormaPago(
        sk_forma_pago INT IDENTITY(1,1) PRIMARY KEY,
        id_forma_pago_fuente INT NOT NULL UNIQUE,
        forma_pago NVARCHAR(100)
    );
END
GO

IF OBJECT_ID('dbo.DimCanal', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.DimCanal(
        sk_canal INT IDENTITY(1,1) PRIMARY KEY,
        canal NVARCHAR(30) NOT NULL UNIQUE,
        descripcion NVARCHAR(200)
    );
END
GO

IF OBJECT_ID('dbo.DimMoneda', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.DimMoneda(
        sk_moneda INT IDENTITY(1,1) PRIMARY KEY,
        codigo_moneda NVARCHAR(3) NOT NULL UNIQUE,
        nombre NVARCHAR(100) NOT NULL,
        simbolo NVARCHAR(10) NOT NULL,
        es_moneda_base BIT NOT NULL DEFAULT 0
    );
END
GO

-- Tabla de tipos de cambio (por mes) referenciada a DimMoneda
IF OBJECT_ID('dbo.DimExchangeRate', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.DimExchangeRate(
        sk_exchange INT IDENTITY(1,1) PRIMARY KEY,
        sk_moneda INT NOT NULL,
        fecha DATE NOT NULL,
        codigo_moneda NVARCHAR(3) NOT NULL,
        tasa_ars_por_unidad DECIMAL(18,6) NOT NULL,
        fuente NVARCHAR(100) NULL,
        CONSTRAINT UQ_DimExchangeRate UNIQUE(sk_moneda, fecha),
        CONSTRAINT FK_DimExchangeRate_DimMoneda FOREIGN KEY(sk_moneda) REFERENCES dbo.DimMoneda(sk_moneda)
    );
END
GO

-- Hechos
IF OBJECT_ID('dbo.FactVentas', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.FactVentas(
        id_venta INT NOT NULL,
        id_detalle INT NOT NULL,
        sk_fecha INT NOT NULL,
        sk_cliente INT NOT NULL,
        sk_producto INT NOT NULL,
        sk_local INT NOT NULL,
        sk_vendedor INT NOT NULL,
        sk_forma_pago INT NOT NULL,
        sk_canal INT NOT NULL,
        sk_moneda INT NOT NULL,
        cantidad INT NOT NULL,
        precio_unitario DECIMAL(12,2) NOT NULL,
        costo_unitario DECIMAL(12,2) NOT NULL,
        importe DECIMAL(14,2) NOT NULL,
        margen DECIMAL(14,2) NOT NULL,
        margen_porcentaje DECIMAL(5,2) NOT NULL,
        tipo_cambio DECIMAL(10,4) NOT NULL DEFAULT 1.0000,
        CONSTRAINT PK_FactVentas PRIMARY KEY(id_venta, id_detalle),
        CONSTRAINT FK_FactVentas_DimFecha FOREIGN KEY(sk_fecha) REFERENCES dbo.DimFecha(sk_fecha),
        CONSTRAINT FK_FactVentas_DimCliente FOREIGN KEY(sk_cliente) REFERENCES dbo.DimCliente(sk_cliente),
        CONSTRAINT FK_FactVentas_DimProducto FOREIGN KEY(sk_producto) REFERENCES dbo.DimProducto(sk_producto),
        CONSTRAINT FK_FactVentas_DimLocal FOREIGN KEY(sk_local) REFERENCES dbo.DimLocal(sk_local),
        CONSTRAINT FK_FactVentas_DimVendedor FOREIGN KEY(sk_vendedor) REFERENCES dbo.DimVendedor(sk_vendedor),
        CONSTRAINT FK_FactVentas_DimFormaPago FOREIGN KEY(sk_forma_pago) REFERENCES dbo.DimFormaPago(sk_forma_pago),
        CONSTRAINT FK_FactVentas_DimCanal FOREIGN KEY(sk_canal) REFERENCES dbo.DimCanal(sk_canal),
        CONSTRAINT FK_FactVentas_DimMoneda FOREIGN KEY(sk_moneda) REFERENCES dbo.DimMoneda(sk_moneda)
    );
END
GO
