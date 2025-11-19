/*
  02_vendedor_mas_ventas.sql
  KPI: Vendedor con más ventas (por ventas, unidades e importe en múltiples monedas)
*/
WITH base AS (
  SELECT 
    v.nombre,
    v.apellido,
    (v.nombre + ' ' + v.apellido) AS vendedor,
    f.id_venta,
    f.importe,
    f.cantidad,
    DATEFROMPARTS(d.anio, d.mes, 1) AS mes
  FROM DW_Celulares.dbo.FactVentas AS f
  JOIN DW_Celulares.dbo.DimVendedor AS v
    ON v.sk_vendedor = f.sk_vendedor
  JOIN DW_Celulares.dbo.DimFecha AS d
    ON d.sk_fecha = f.sk_fecha
),
agregado AS (
  SELECT 
    nombre,
    apellido,
    vendedor,
    COUNT(DISTINCT id_venta) AS ventas,
    SUM(cantidad) AS unidades,
    SUM(importe) AS importe_ars,
    mes
  FROM base
  GROUP BY nombre, apellido, vendedor, mes
)
SELECT TOP 1
    a.nombre,
    a.apellido,
    a.vendedor,
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
GROUP BY a.nombre, a.apellido, a.vendedor
ORDER BY importe_ars DESC;
