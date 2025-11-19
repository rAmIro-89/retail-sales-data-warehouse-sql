-- 06_consultas_dw.sql
USE DW_Celulares;
GO

-- 1) Ventas y margen por mes y marca
SELECT d.anio, d.mes, p.marca,
       SUM(f.importe) AS importe_total,
       SUM(f.margen) AS margen_total,
       AVG(f.precio_unitario) AS precio_promedio,
       STDEV(f.precio_unitario) AS precio_desvio
FROM dbo.FactVentas f
JOIN dbo.DimFecha d ON d.sk_fecha = f.sk_fecha
JOIN dbo.DimProducto p ON p.sk_producto = f.sk_producto
GROUP BY d.anio, d.mes, p.marca
ORDER BY d.anio, d.mes, p.marca;

-- 2) Top 10 modelos por importe
SELECT TOP 10 p.marca, p.modelo, SUM(f.importe) AS importe_total, SUM(f.cantidad) AS unidades
FROM dbo.FactVentas f
JOIN dbo.DimProducto p ON p.sk_producto = f.sk_producto
GROUP BY p.marca, p.modelo
ORDER BY importe_total DESC;

-- 3) Ticket promedio por canal y ciudad
SELECT l.ciudad, c.canal, AVG(f.importe) AS ticket_promedio
FROM dbo.FactVentas f
JOIN dbo.DimLocal l ON l.sk_local = f.sk_local
JOIN dbo.DimCanal c ON c.sk_canal = f.sk_canal
GROUP BY l.ciudad, c.canal
ORDER BY l.ciudad, c.canal;

-- 4) Participación por forma de pago
SELECT fp.forma_pago,
       COUNT(*) AS transacciones,
       100.0 * COUNT(*) / SUM(COUNT(*)) OVER() AS porcentaje
FROM dbo.FactVentas f
JOIN dbo.DimFormaPago fp ON fp.sk_forma_pago = f.sk_forma_pago
GROUP BY fp.forma_pago
ORDER BY transacciones DESC;

-- 5) Margen promedio por provincia y trimestre
SELECT d.anio, d.trimestre, l.provincia,
       AVG(f.margen) AS margen_promedio,
       MIN(f.margen) AS margen_min,
       MAX(f.margen) AS margen_max
FROM dbo.FactVentas f
JOIN dbo.DimFecha d ON d.sk_fecha = f.sk_fecha
JOIN dbo.DimLocal l ON l.sk_local = f.sk_local
GROUP BY d.anio, d.trimestre, l.provincia
ORDER BY d.anio, d.trimestre, l.provincia;

-- 6) Variación mensual del importe total (LAG)
WITH mensual AS (
  SELECT d.anio, d.mes, SUM(f.importe) AS importe_total
  FROM dbo.FactVentas f
  JOIN dbo.DimFecha d ON d.sk_fecha = f.sk_fecha
  GROUP BY d.anio, d.mes
)
SELECT anio, mes, importe_total,
       LAG(importe_total) OVER (ORDER BY anio, mes) AS importe_prev,
       CASE WHEN LAG(importe_total) OVER (ORDER BY anio, mes) = 0 THEN NULL
            ELSE (importe_total - LAG(importe_total) OVER (ORDER BY anio, mes)) * 100.0 / LAG(importe_total) OVER (ORDER BY anio, mes) END
         AS variacion_pct
FROM mensual
ORDER BY anio, mes;
