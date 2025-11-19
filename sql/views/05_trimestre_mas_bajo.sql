/*
  05_trimestre_mas_bajo.sql
  KPI: Trimestre con menor importe total (en múltiples monedas)
  CORRECCIÓN: Usa promedio de tipos de cambio por trimestre (no por mes exacto)
*/
WITH ventas_trimestre AS (
  SELECT 
    d.anio,
    d.trimestre,
    SUM(f.importe) AS importe_ars,
    COUNT(DISTINCT f.id_venta) AS total_ventas,
    SUM(f.cantidad) AS unidades
  FROM DW_Celulares.dbo.FactVentas AS f
  JOIN DW_Celulares.dbo.DimFecha AS d
    ON d.sk_fecha = f.sk_fecha
  GROUP BY d.anio, d.trimestre
),
tipos_cambio_trimestre AS (
  SELECT 
    DATEPART(QUARTER, er.fecha) AS trimestre,
    er.codigo_moneda,
    AVG(er.tasa_ars_por_unidad) AS tasa_promedio
  FROM DW_Celulares.dbo.DimExchangeRate er
  GROUP BY DATEPART(QUARTER, er.fecha), er.codigo_moneda
)
SELECT TOP 1
    vt.anio,
    vt.trimestre,
    vt.total_ventas,
    vt.unidades,
    vt.importe_ars,
    vt.importe_ars / tc_usd.tasa_promedio AS importe_usd,
    vt.importe_ars / tc_eur.tasa_promedio AS importe_eur,
    vt.importe_ars / tc_brl.tasa_promedio AS importe_brl,
    vt.importe_ars / tc_cny.tasa_promedio AS importe_cny
FROM ventas_trimestre vt
LEFT JOIN tipos_cambio_trimestre tc_usd 
  ON tc_usd.trimestre = vt.trimestre AND tc_usd.codigo_moneda = 'USD'
LEFT JOIN tipos_cambio_trimestre tc_eur 
  ON tc_eur.trimestre = vt.trimestre AND tc_eur.codigo_moneda = 'EUR'
LEFT JOIN tipos_cambio_trimestre tc_brl 
  ON tc_brl.trimestre = vt.trimestre AND tc_brl.codigo_moneda = 'BRL'
LEFT JOIN tipos_cambio_trimestre tc_cny 
  ON tc_cny.trimestre = vt.trimestre AND tc_cny.codigo_moneda = 'CNY'
ORDER BY vt.importe_ars ASC;
