/*
  01_marca_mas_vendida.sql
  KPI: Marca más vendida (por unidades, ventas e importe en múltiples monedas)
  Nota: nombres calificados — no depende de USE.
*/
WITH base AS (
  SELECT 
    p.marca,
    f.id_venta,
    f.cantidad,
    f.importe,
    DATEFROMPARTS(d.anio, d.mes, 1) AS mes
  FROM DW_Celulares.dbo.FactVentas AS f
  JOIN DW_Celulares.dbo.DimProducto AS p
    ON p.sk_producto = f.sk_producto
  JOIN DW_Celulares.dbo.DimFecha AS d
    ON d.sk_fecha = f.sk_fecha
),
agregado AS (
  SELECT 
    marca,
    COUNT(DISTINCT id_venta) AS ventas,
    SUM(cantidad) AS unidades,
    SUM(importe) AS importe_ars,
    mes
  FROM base
  GROUP BY marca, mes
)
SELECT TOP 1
    a.marca,
    SUM(a.ventas) AS ventas,
    SUM(a.unidades) AS unidades,
    SUM(a.importe_ars) AS importe_ars,
    SUM(a.importe_ars / er_usd.tasa_ars_por_unidad) AS importe_usd,
    SUM(a.importe_ars / er_eur.tasa_ars_por_unidad) AS importe_eur,
    SUM(a.importe_ars / er_brl.tasa_ars_por_unidad) AS importe_brl,
    SUM(a.importe_ars / er_cny.tasa_ars_por_unidad) AS importe_cny
FROM agregado a
LEFT JOIN DW_Celulares.dbo.DimExchangeRate er_usd 
  ON er_usd.fecha = a.mes AND er_usd.codigo_moneda = 'USD'
LEFT JOIN DW_Celulares.dbo.DimExchangeRate er_eur 
  ON er_eur.fecha = a.mes AND er_eur.codigo_moneda = 'EUR'
LEFT JOIN DW_Celulares.dbo.DimExchangeRate er_brl 
  ON er_brl.fecha = a.mes AND er_brl.codigo_moneda = 'BRL'
LEFT JOIN DW_Celulares.dbo.DimExchangeRate er_cny 
  ON er_cny.fecha = a.mes AND er_cny.codigo_moneda = 'CNY'
GROUP BY a.marca
ORDER BY unidades DESC;
