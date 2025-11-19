-- 07_dataset_aplanado.sql
-- Query del modelo estrella aplanado para análisis
-- INSTRUCCIONES PARA EXPORTAR A EXCEL:
-- 1. Ejecutar este script en SSMS
-- 2. En la segunda query (dataset completo), seleccionar todos los resultados
-- 3. Clic derecho → "Save Results As..." 
-- 4. Cambiar "Save as type" a "Excel Files (*.xls)" o "All Files (*.*)" y agregar .xlsx
-- 5. Guardar como "DW_Dataset_Aplanado.xlsx"

USE DW_Celulares;
GO

-- Conteo rápido
SELECT COUNT(*) AS total_registros FROM dbo.FactVentas;

-- Dataset aplanado completo con todas las dimensiones y métricas
SELECT
  -- Dimensión Tiempo (expandida)
  d.fecha AS fecha_venta,
  d.anio, 
  d.mes, 
  d.trimestre,
  d.dia_semana,
  d.nombre_mes,
  d.es_fin_semana,
  d.numero_semana,
  d.dia_mes,
  d.dia_anio,
  
  -- Dimensión Local
  l.provincia, 
  l.ciudad, 
  l.local,
  
  -- Dimensión Canal (Junk)
  canal.canal,
  
  -- Dimensión Moneda
  mon.codigo_moneda,
  mon.nombre AS nombre_moneda,
  mon.simbolo AS simbolo_moneda,
  
  -- Dimensión Producto
  p.marca, 
  p.modelo, 
  p.almacenamiento_gb, 
  p.ram_gb,
  
  -- Dimensión Vendedor
  v.nombre AS nombre_vendedor, 
  v.apellido AS apellido_vendedor, 
  v.legajo,
  v.categoria_vendedor,
  
  -- Dimensión Forma de Pago
  fp.forma_pago,
  
  -- Dimensión Cliente
  c.nombre AS nombre_cliente,
  c.apellido AS apellido_cliente,
  c.genero AS genero_cliente,
  
  -- Métricas
  f.cantidad, 
  f.precio_unitario, 
  f.costo_unitario, 
  f.importe, 
  f.margen,
  f.margen_porcentaje,
  f.tipo_cambio,
  
  -- Métricas derivadas adicionales
  CASE WHEN f.margen > 0 THEN 'Positivo' WHEN f.margen < 0 THEN 'Negativo' ELSE 'Cero' END AS tipo_margen,
  CASE 
    WHEN f.cantidad <= 2 THEN '1-2 unidades'
    WHEN f.cantidad <= 5 THEN '3-5 unidades'
    WHEN f.cantidad <= 10 THEN '6-10 unidades'
    ELSE 'Más de 10 unidades'
  END AS rango_cantidad,
  CASE 
    WHEN f.importe < 100000 THEN 'Bajo (<$100k)'
    WHEN f.importe < 500000 THEN 'Medio ($100k-$500k)'
    WHEN f.importe < 1000000 THEN 'Alto ($500k-$1M)'
    ELSE 'Muy Alto (>$1M)'
  END AS rango_importe
  
FROM dbo.FactVentas f
JOIN dbo.DimFecha d      ON d.sk_fecha = f.sk_fecha
JOIN dbo.DimProducto p   ON p.sk_producto = f.sk_producto
JOIN dbo.DimLocal l      ON l.sk_local = f.sk_local
JOIN dbo.DimVendedor v   ON v.sk_vendedor = f.sk_vendedor
JOIN dbo.DimFormaPago fp ON fp.sk_forma_pago = f.sk_forma_pago
JOIN dbo.DimCanal canal  ON canal.sk_canal = f.sk_canal
JOIN dbo.DimMoneda mon   ON mon.sk_moneda = f.sk_moneda
JOIN dbo.DimCliente c    ON c.sk_cliente = f.sk_cliente
ORDER BY d.fecha DESC, f.id_venta, f.id_detalle;

