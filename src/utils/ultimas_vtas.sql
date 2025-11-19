USE OLTP_Celulares;
GO

SELECT TOP 10 id_venta, fecha_venta, id_cliente, id_vendedor
FROM dbo.Ventas
ORDER BY id_venta DESC;
