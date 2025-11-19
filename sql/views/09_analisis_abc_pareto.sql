-- 09_analisis_abc_pareto.sql
-- Análisis ABC (Pareto) de productos, clientes y vendedores

USE DW_Celulares;
GO

-- =====================================================
-- 1. ANÁLISIS ABC DE PRODUCTOS (80/20)
-- =====================================================
PRINT '--- Análisis ABC de Productos (Pareto 80/20) ---';

WITH ProductoVentas AS (
    SELECT 
        p.marca,
        p.modelo,
        SUM(f.importe) AS importe_total,
        SUM(f.margen) AS margen_total,
        SUM(f.cantidad) AS unidades_vendidas,
        COUNT(DISTINCT f.id_venta) AS num_transacciones
    FROM dbo.FactVentas f
    JOIN dbo.DimProducto p ON p.sk_producto = f.sk_producto
    WHERE p.es_actual = 1
    GROUP BY p.marca, p.modelo
),
ProductoRanking AS (
    SELECT 
        *,
        SUM(importe_total) OVER () AS importe_global,
        ROW_NUMBER() OVER (ORDER BY importe_total DESC) AS ranking,
        SUM(importe_total) OVER (ORDER BY importe_total DESC) AS importe_acumulado
    FROM ProductoVentas
)
SELECT 
    ranking,
    marca,
    modelo,
    importe_total,
    margen_total,
    unidades_vendidas,
    num_transacciones,
    ROUND((importe_total / importe_global) * 100, 2) AS porcentaje_ventas,
    ROUND((importe_acumulado / importe_global) * 100, 2) AS porcentaje_acumulado,
    CASE 
        WHEN (importe_acumulado / importe_global) <= 0.80 THEN 'A (Top 80%)'
        WHEN (importe_acumulado / importe_global) <= 0.95 THEN 'B (80-95%)'
        ELSE 'C (95-100%)'
    END AS categoria_abc
FROM ProductoRanking
ORDER BY ranking;

GO

-- =====================================================
-- 2. ANÁLISIS ABC DE CLIENTES
-- =====================================================
PRINT '--- Análisis ABC de Clientes ---';

WITH ClienteVentas AS (
    SELECT 
        c.nombre,
        c.apellido,
        c.genero,
        SUM(f.importe) AS importe_total,
        SUM(f.margen) AS margen_total,
        COUNT(DISTINCT f.id_venta) AS num_compras,
        AVG(f.importe) AS ticket_promedio
    FROM dbo.FactVentas f
    JOIN dbo.DimCliente c ON c.sk_cliente = f.sk_cliente
    WHERE c.sk_cliente > 0
    GROUP BY c.nombre, c.apellido, c.genero
),
ClienteRanking AS (
    SELECT 
        *,
        SUM(importe_total) OVER () AS importe_global,
        ROW_NUMBER() OVER (ORDER BY importe_total DESC) AS ranking,
        SUM(importe_total) OVER (ORDER BY importe_total DESC) AS importe_acumulado
    FROM ClienteVentas
)
SELECT 
    ranking,
    nombre,
    apellido,
    genero,
    importe_total,
    margen_total,
    num_compras,
    ROUND(ticket_promedio, 2) AS ticket_promedio,
    ROUND((importe_total / importe_global) * 100, 2) AS porcentaje_ventas,
    ROUND((importe_acumulado / importe_global) * 100, 2) AS porcentaje_acumulado,
    CASE 
        WHEN (importe_acumulado / importe_global) <= 0.80 THEN 'A (VIP)'
        WHEN (importe_acumulado / importe_global) <= 0.95 THEN 'B (Regular)'
        ELSE 'C (Ocasional)'
    END AS categoria_abc
FROM ClienteRanking
ORDER BY ranking;

GO

-- =====================================================
-- 3. ANÁLISIS ABC DE VENDEDORES
-- =====================================================
PRINT '--- Análisis ABC de Vendedores ---';

WITH VendedorVentas AS (
    SELECT 
        v.nombre,
        v.apellido,
        v.legajo,
        SUM(f.importe) AS importe_total,
        SUM(f.margen) AS margen_total,
        COUNT(DISTINCT f.id_venta) AS num_ventas,
        AVG(f.importe) AS ticket_promedio,
        ROUND(AVG(f.margen_porcentaje), 2) AS margen_promedio_porcentaje
    FROM dbo.FactVentas f
    JOIN dbo.DimVendedor v ON v.sk_vendedor = f.sk_vendedor
    WHERE v.sk_vendedor > 0
    GROUP BY v.nombre, v.apellido, v.legajo
),
VendedorRanking AS (
    SELECT 
        *,
        SUM(importe_total) OVER () AS importe_global,
        ROW_NUMBER() OVER (ORDER BY importe_total DESC) AS ranking,
        SUM(importe_total) OVER (ORDER BY importe_total DESC) AS importe_acumulado
    FROM VendedorVentas
)
SELECT 
    ranking,
    nombre,
    apellido,
    legajo,
    importe_total,
    margen_total,
    num_ventas,
    ticket_promedio,
    margen_promedio_porcentaje,
    ROUND((importe_total / importe_global) * 100, 2) AS porcentaje_ventas,
    ROUND((importe_acumulado / importe_global) * 100, 2) AS porcentaje_acumulado,
    CASE 
        WHEN (importe_acumulado / importe_global) <= 0.80 THEN 'A (Top performer)'
        WHEN (importe_acumulado / importe_global) <= 0.95 THEN 'B (Performer promedio)'
        ELSE 'C (Bajo desempeño)'
    END AS categoria_abc
FROM VendedorRanking
ORDER BY ranking;

GO

-- =====================================================
-- 4. ANÁLISIS ABC DE LOCALES
-- =====================================================
PRINT '--- Análisis ABC de Locales ---';

WITH LocalVentas AS (
    SELECT 
        l.provincia,
        l.ciudad,
        l.local,
        SUM(f.importe) AS importe_total,
        SUM(f.margen) AS margen_total,
        COUNT(DISTINCT f.id_venta) AS num_ventas
    FROM dbo.FactVentas f
    JOIN dbo.DimLocal l ON l.sk_local = f.sk_local
    WHERE l.sk_local > 0
    GROUP BY l.provincia, l.ciudad, l.local
),
LocalRanking AS (
    SELECT 
        *,
        SUM(importe_total) OVER () AS importe_global,
        ROW_NUMBER() OVER (ORDER BY importe_total DESC) AS ranking,
        SUM(importe_total) OVER (ORDER BY importe_total DESC) AS importe_acumulado
    FROM LocalVentas
)
SELECT 
    ranking,
    provincia,
    ciudad,
    local,
    importe_total,
    margen_total,
    num_ventas,
    ROUND((importe_total / importe_global) * 100, 2) AS porcentaje_ventas,
    ROUND((importe_acumulado / importe_global) * 100, 2) AS porcentaje_acumulado,
    CASE 
        WHEN (importe_acumulado / importe_global) <= 0.80 THEN 'A (Estratégico)'
        WHEN (importe_acumulado / importe_global) <= 0.95 THEN 'B (Importante)'
        ELSE 'C (Complementario)'
    END AS categoria_abc
FROM LocalRanking
ORDER BY ranking;

GO

-- =====================================================
-- 5. RESUMEN VISUAL DE CATEGORÍAS ABC
-- =====================================================
PRINT '--- Resumen de Distribución ABC ---';

WITH ProductoVentas AS (
    SELECT 
        p.marca + ' ' + p.modelo AS producto,
        SUM(f.importe) AS importe_total
    FROM dbo.FactVentas f
    JOIN dbo.DimProducto p ON p.sk_producto = f.sk_producto
    WHERE p.es_actual = 1
    GROUP BY p.marca, p.modelo
),
ProductoRanking AS (
    SELECT 
        *,
        SUM(importe_total) OVER () AS importe_global,
        SUM(importe_total) OVER (ORDER BY importe_total DESC) AS importe_acumulado
    FROM ProductoVentas
),
ProductoCategoria AS (
    SELECT 
        CASE 
            WHEN (importe_acumulado / importe_global) <= 0.80 THEN 'A'
            WHEN (importe_acumulado / importe_global) <= 0.95 THEN 'B'
            ELSE 'C'
        END AS categoria
    FROM ProductoRanking
)
SELECT 
    categoria,
    COUNT(*) AS cantidad_productos,
    ROUND((CAST(COUNT(*) AS FLOAT) / (SELECT COUNT(*) FROM ProductoCategoria)) * 100, 2) AS porcentaje_productos
FROM ProductoCategoria
GROUP BY categoria
ORDER BY categoria;

GO
