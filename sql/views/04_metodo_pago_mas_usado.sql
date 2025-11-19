/*
  04_metodo_pago_mas_usado.sql
  KPI: Método de pago más utilizado (por cantidad de transacciones e importe en múltiples monedas)
*/
WITH base AS (
  SELECT 
    fp.forma_pago,
    f.importe,
    DATEFROMPARTS(d.anio, d.mes, 1) AS mes
  FROM DW_Celulares.dbo.FactVentas AS f
  JOIN DW_Celulares.dbo.DimFormaPago AS fp
    ON fp.sk_forma_pago = f.sk_forma_pago
  JOIN DW_Celulares.dbo.DimFecha AS d
    ON d.sk_fecha = f.sk_fecha
),
agregado AS (
  SELECT 
    forma_pago,
    COUNT(*) AS transacciones,
    SUM(importe) AS importe_ars,
    mes
  FROM base
  GROUP BY forma_pago, mes
)
SELECT TOP 1
    a.forma_pago,
    SUM(a.transacciones) AS transacciones,
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
GROUP BY a.forma_pago
ORDER BY transacciones DESC;
