/*
  07_modelo_mas_vendido.sql
  KPI: Modelo más vendido (por unidades)
*/
SELECT TOP 1
    p.marca,
    p.modelo,
    SUM(f.cantidad) AS unidades
FROM DW_Celulares.dbo.FactVentas AS f
JOIN DW_Celulares.dbo.DimProducto AS p
  ON p.sk_producto = f.sk_producto
GROUP BY p.marca, p.modelo
ORDER BY unidades DESC;
