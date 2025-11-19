/*
  03_local_mas_ganancia.sql
  KPI: Local con mayor margen de ganancia acumulado (en múltiples monedas)
*/
WITH base AS (
  SELECT 
    l.provincia,
    l.ciudad,
    l.local,
    f.id_venta,
    f.importe,
    f.margen,
    DATEFROMPARTS(d.anio, d.mes, 1) AS mes
  FROM DW_Celulares.dbo.FactVentas AS f
  JOIN DW_Celulares.dbo.DimLocal AS l
    ON l.sk_local = f.sk_local
  JOIN DW_Celulares.dbo.DimFecha AS d
    ON d.sk_fecha = f.sk_fecha
),
agregado AS (
  SELECT 
    provincia,
    ciudad,
    local,
    COUNT(DISTINCT id_venta) AS ventas,
    SUM(importe) AS importe_ars,
    SUM(margen) AS margen_ars,
    mes
  FROM base
  GROUP BY provincia, ciudad, local, mes
)
SELECT TOP 1
    a.provincia,
    a.ciudad,
    a.local,
    SUM(a.ventas) AS ventas,
    SUM(a.importe_ars) AS importe_ars,
    SUM(a.margen_ars) AS margen_ars,
    SUM(a.margen_ars / er_usd.tasa_ars_por_unidad) AS margen_usd,
    SUM(a.margen_ars / er_eur.tasa_ars_por_unidad) AS margen_eur,
    SUM(a.margen_ars / er_brl.tasa_ars_por_unidad) AS margen_brl,
    SUM(a.margen_ars / er_cny.tasa_ars_por_unidad) AS margen_cny
FROM agregado a
LEFT JOIN DW_Celulares.dbo.DimExchangeRate er_usd 
  ON er_usd.fecha = a.mes AND er_usd.codigo_moneda = 'USD'
LEFT JOIN DW_Celulares.dbo.DimExchangeRate er_eur 
  ON er_eur.fecha = a.mes AND er_eur.codigo_moneda = 'EUR'
LEFT JOIN DW_Celulares.dbo.DimExchangeRate er_brl 
  ON er_brl.fecha = a.mes AND er_brl.codigo_moneda = 'BRL'
LEFT JOIN DW_Celulares.dbo.DimExchangeRate er_cny 
  ON er_cny.fecha = a.mes AND er_cny.codigo_moneda = 'CNY'
GROUP BY a.provincia, a.ciudad, a.local
ORDER BY margen_ars DESC;
