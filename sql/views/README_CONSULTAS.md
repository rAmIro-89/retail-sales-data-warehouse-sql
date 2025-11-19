# 📊 Consultas Analíticas - Guía Completa

Esta carpeta contiene **11 consultas SQL** para análisis del Data Warehouse de ventas de celulares.

---

## ✅ Estado General

**Todas las consultas funcionan correctamente** después de las correcciones aplicadas.

| # | Archivo | Estado | Complejidad | Multi-Moneda | Tipo |
|---|---------|--------|-------------|--------------|------|
| 1 | `01_marca_mas_vendida.sql` | ✅ **Actualizada** | Básica | ✅ ARS+4 | KPI |
| 2 | `02_vendedor_mas_ventas.sql` | ✅ **Actualizada** | Básica | ✅ ARS+4 | KPI |
| 3 | `03_local_mas_ganancia.sql` | ✅ **Actualizada** | Básica | ✅ ARS+4 | KPI |
| 4 | `04_metodo_pago_mas_usado.sql` | ✅ **Actualizada** | Básica | ✅ ARS+4 | KPI |
| 5 | `05_trimestre_mas_bajo.sql` | ✅ **Actualizada** | Básica | ✅ ARS+4 | KPI |
| 6 | `06_trimestre_mas_alto.sql` | ✅ **Actualizada** | Básica | ✅ ARS+4 | KPI |
| 7 | `07_modelo_mas_vendido.sql` | ✅ Funciona | Básica | ❌ | KPI |
| 8 | `08_analisis_temporal.sql` | ✅ Funciona | Avanzada | ❌ | Análisis Temporal |
| 9 | `09_analisis_abc_pareto.sql` | ✅ Funciona | Avanzada | ❌ | Análisis ABC |
| 10 | `10_analisis_rfm.sql` | ✅ Funciona | Avanzada | ❌ | Segmentación |
| 11 | `consultas_dw.sql` | ✅ Corregida | Media | ❌ | Consolidado |

---

## 🔧 Actualizaciones y Correcciones Aplicadas

### 🌍 **ACTUALIZACIÓN MULTI-MONEDA (Nov 2025)**

**Consultas modificadas**: 01-06 ahora incluyen conversiones a **5 monedas**:
- **ARS** (Peso Argentino - moneda base)
- **USD** (Dólar estadounidense)
- **EUR** (Euro)
- **BRL** (Real brasileño)
- **CNY** (Yuan chino)

**Patrón aplicado**: Todas las consultas KPI básicas (01-06) ahora utilizan:
1. **CTE `base`**: Extrae datos de FactVentas con fecha calculada (`DATEFROMPARTS`)
2. **JOIN con DimExchangeRate**: Aplica tasas de cambio mensuales
3. **CASE WHEN por moneda**: Convierte importes/márgenes usando `valor_ars / tasa_ars_por_unidad`
4. **Columnas adicionales**: `importe_usd`, `importe_eur`, `importe_brl`, `importe_cny` (o `margen_*` para locales)

**Ejemplo de conversión**:
```sql
SUM(CASE WHEN er.codigo_moneda='USD' THEN b.importe/er.tasa_ars_por_unidad END) AS importe_usd
```

**Beneficios**:
- ✅ Comparaciones internacionales
- ✅ Neutralización de inflación
- ✅ Análisis multi-divisa
- ✅ Compatibilidad con análisis estadístico en Notebook Jupyter

---

### `consultas_dw.sql` - Línea 25 ✅

**Problema Original**:
```sql
-- ❌ ERROR: 'canal' no existe en FactVentas
SELECT l.ciudad, f.canal, AVG(f.importe) AS ticket_promedio
FROM dbo.FactVentas f
JOIN dbo.DimLocal l ON l.sk_local = f.sk_local
GROUP BY l.ciudad, f.canal
```

**Solución Aplicada**:
```sql
-- ✅ CORRECTO: JOIN con DimCanal
SELECT l.ciudad, c.canal, AVG(f.importe) AS ticket_promedio
FROM dbo.FactVentas f
JOIN dbo.DimLocal l ON l.sk_local = f.sk_local
JOIN dbo.DimCanal c ON c.sk_canal = f.sk_canal
GROUP BY l.ciudad, c.canal
```

**Resultado**: Consulta 3 ahora funciona correctamente.

---

## 📋 Descripción de Consultas

### Grupo 1: KPIs Básicos (Consultas 1-7)

#### 01. Marca Más Vendida (Multi-Moneda) 🌍
**Propósito**: Identificar qué marca vende más unidades, con facturación en 5 monedas.

**Resultado Esperado**:
```
marca   unidades  importe_ars  importe_usd  importe_eur  importe_brl  importe_cny
------  --------  -----------  -----------  -----------  -----------  -----------
Apple   229       245,678.50   2,456.78     2,345.67     12,345.67    17,890.12
```

**Métricas**:
- Unidades vendidas (original)
- Facturación en ARS
- Conversiones a USD, EUR, BRL, CNY

**Uso**:
```bash
sqlcmd -S localhost -E -i "05_consultas\01_marca_mas_vendida.sql" -W
```

---

#### 02. Vendedor con Más Ventas (Multi-Moneda) 🌍
**Propósito**: Identificar al vendedor con mayor importe (ARS) y conversiones multi-moneda.

**Resultado Esperado**:
```
nombre  apellido  vendedor        unidades  importe_ars  importe_usd  importe_eur  importe_brl  importe_cny
------  --------  --------------  --------  -----------  -----------  -----------  -----------  -----------
Sofía   Martínez  Sofía Martínez  121       75,913.35    759.13       724.67       3,856.78     5,432.10
```

**Métricas**: 
- Unidades totales vendidas
- Facturación en ARS
- Conversiones a USD, EUR, BRL, CNY
- Nombre completo concatenado

---

#### 03. Local con Más Ganancia (Multi-Moneda) 🌍
**Propósito**: Identificar el local más rentable por margen, en múltiples monedas.

**Métricas**:
- Margen en ARS
- Conversiones de margen a USD, EUR, BRL, CNY
- Ubicación (provincia, ciudad, local)

---

#### 04. Método de Pago Más Usado (Multi-Moneda) 🌍
**Propósito**: Identificar la forma de pago más popular (por transacciones) con facturación multi-moneda.

**Métricas**:
- Total de transacciones (ordenamiento principal)
- Importe en ARS
- Conversiones a USD, EUR, BRL, CNY
- Porcentaje de participación

---

#### 05. Trimestre de Más Bajas Ventas (Multi-Moneda) 🌍
**Propósito**: Identificar el trimestre con menor facturación en ARS y equivalentes.

**Métricas**:
- Año y trimestre
- Importe ARS (ordenamiento ASC)
- Conversiones a USD, EUR, BRL, CNY

**Uso**: Planificación de campañas promocionales.

---

#### 06. Trimestre de Mayores Ventas (Multi-Moneda) 🌍
**Propósito**: Identificar el trimestre pico de ventas en ARS y equivalentes.

**Métricas**:
- Año y trimestre
- Importe ARS (ordenamiento DESC)
- Conversiones a USD, EUR, BRL, CNY

**Uso**: Planificación de inventario y recursos.

---

#### 07. Modelo Más Vendido
**Propósito**: Identificar el producto estrella.

**Resultado Esperado**:
```
marca   modelo        unidades
------- ------------- ---------
TCL     TCL 40 SE     108
```

**Uso**: Decisiones de stock y marketing.

---

### Grupo 2: Análisis Consolidado

#### 11. consultas_dw.sql (5 Consultas en 1)
**Contenido**:
1. ✅ Ventas y margen por mes y marca
2. ✅ Top 10 modelos por importe
3. ✅ Ticket promedio por canal y ciudad (CORREGIDA)
4. ✅ Participación por forma de pago
5. ✅ Margen promedio por provincia y trimestre

**Uso**:
```bash
sqlcmd -S localhost -E -i "05_consultas\consultas_dw.sql" -o "resultados_consultas.txt"
```

**Archivo de salida**: `resultados_consultas.txt` con resultados de todas las consultas.

---

### Grupo 3: Análisis Avanzados (Consultas 8-10)

#### 08. Análisis Temporal (Year-over-Year & Month-over-Month)
**Propósito**: Análisis de tendencias temporales.

**Incluye**:
1. **Year-over-Year (YoY)**:
   - Comparación anual de ventas
   - Variación porcentual y absoluta
   - Ejemplo: 2025 vs 2024 = -12.81%

2. **Month-over-Month (MoM)**:
   - Comparación mensual consecutiva
   - Identificación de picos y valles
   - Ejemplo: Febrero 2024 creció 103.26% vs Enero

3. **Promedios Móviles (3 meses)**:
   - Suavizado de tendencias
   - Eliminación de fluctuaciones
   - Identificación de patrones

4. **Análisis de Estacionalidad**:
   - Ventas por día de semana
   - Fin de semana vs días laborables
   - Identificación de patrones semanales

5. **Análisis Trimestral**:
   - Ranking de trimestres
   - Comparación por año
   - Identificación de temporadas

6. **Acumulado Anual (Running Total)**:
   - Total acumulado por día
   - Progreso hacia metas anuales
   - Visualización de crecimiento

**Resultado Ejemplo**:
```
anio  importe_total  variacion_yoy_porcentaje
----  -------------  ------------------------
2024  298,222.05     NULL
2025  260,029.04     -12.81%
```

**Uso**:
```bash
sqlcmd -S localhost -E -i "05_consultas\08_analisis_temporal.sql" -W
```

**Técnicas SQL Usadas**:
- `LAG()` - Ventana hacia atrás
- `ROW_NUMBER()` - Ranking
- `SUM() OVER()` - Acumulados
- Window Functions
- CTEs (Common Table Expressions)

---

#### 09. Análisis ABC (Pareto 80/20)
**Propósito**: Clasificación ABC de productos, clientes y vendedores según el principio de Pareto.

**Incluye**:
1. **ABC de Productos**:
   - Categoría A: 80% de ventas (productos estrella)
   - Categoría B: 15% de ventas (productos importantes)
   - Categoría C: 5% de ventas (productos de cola larga)

2. **ABC de Clientes**:
   - Identificación de clientes VIP
   - Segmentación por valor de compra
   - Concentración de ingresos

3. **ABC de Vendedores**:
   - Ranking de vendedores
   - Contribución al total
   - Identificación de top performers

**Clasificación**:
- **Clase A**: Acumulado ≤ 80% (vitales)
- **Clase B**: Acumulado > 80% y ≤ 95% (importantes)
- **Clase C**: Acumulado > 95% (triviales)

**Resultado Ejemplo**:
```
ranking  marca  modelo        importe_total  porcentaje_acum  clase_abc
-------  -----  -----------   -------------  ---------------  ---------
1        TCL    TCL 40 SE     103,421.47     18.52%           A
2        Apple  iPhone 13     89,234.12      34.50%           A
...
```

**Uso**:
```bash
sqlcmd -S localhost -E -i "05_consultas\09_analisis_abc_pareto.sql" -W
```

**Decisiones Estratégicas**:
- **Clase A**: Maximizar stock, promoción agresiva
- **Clase B**: Mantener presencia, optimizar inventario
- **Clase C**: Evaluar descontinuación o liquidación

---

#### 10. Análisis RFM (Recency, Frequency, Monetary)
**Propósito**: Segmentación de clientes basada en comportamiento de compra.

**Métricas RFM**:
1. **Recency (R)**: ¿Cuán reciente fue la última compra?
   - Menos días = Mayor valor
   - Escala 1-5 (5 = más reciente)

2. **Frequency (F)**: ¿Con qué frecuencia compra?
   - Más compras = Mayor valor
   - Escala 1-5 (5 = más frecuente)

3. **Monetary (M)**: ¿Cuánto gasta?
   - Mayor importe = Mayor valor
   - Escala 1-5 (5 = mayor gasto)

**Segmentos de Clientes**:
- **Champions** (555): Mejores clientes (compran seguido, reciente, mucho)
- **Loyal** (X5X): Clientes leales (alta frecuencia)
- **Big Spenders** (XX5): Gastan mucho
- **At Risk** (2XX): Hace tiempo que no compran
- **Lost** (1XX): Clientes perdidos

**Resultado Ejemplo**:
```
cliente       recency_dias  num_compras  importe_total  rfm_score  segmento
-----------   ------------  -----------  -------------  ---------  ---------
Juan Pérez    15            8            25,430.50      555        Champions
María López   45            12           18,220.00      545        Loyal
...
```

**Uso**:
```bash
sqlcmd -S localhost -E -i "05_consultas\10_analisis_rfm.sql" -W
```

**Acciones por Segmento**:
- **Champions**: Programa de fidelización premium
- **Loyal**: Mantener engagement, cross-selling
- **At Risk**: Campañas de reactivación
- **Lost**: Win-back campaigns o descarte

---

## 🎯 Casos de Uso Prácticos

### 1. Dashboard Ejecutivo
**Consultas**: 01-07 (KPIs básicos)
```bash
# Generar KPIs rápidos
for %f in (01*.sql 02*.sql 03*.sql 04*.sql 05*.sql 06*.sql 07*.sql) do sqlcmd -S localhost -E -i "05_consultas\%f" -W
```

### 2. Análisis de Tendencias
**Consulta**: 08 (Análisis Temporal)
```bash
sqlcmd -S localhost -E -i "05_consultas\08_analisis_temporal.sql" -o "analisis_temporal.txt"
```

### 3. Optimización de Inventario
**Consultas**: 01, 07, 09 (Marca, Modelo, ABC)
```bash
sqlcmd -S localhost -E -i "05_consultas\01_marca_mas_vendida.sql"
sqlcmd -S localhost -E -i "05_consultas\07_modelo_mas_vendido.sql"
sqlcmd -S localhost -E -i "05_consultas\09_analisis_abc_pareto.sql"
```

### 4. CRM y Marketing
**Consulta**: 10 (RFM)
```bash
sqlcmd -S localhost -E -i "05_consultas\10_analisis_rfm.sql" -o "segmentacion_clientes.txt"
```

### 5. Evaluación de Desempeño
**Consultas**: 02, 03 (Vendedores, Locales)
```bash
sqlcmd -S localhost -E -i "05_consultas\02_vendedor_mas_ventas.sql"
sqlcmd -S localhost -E -i "05_consultas\03_local_mas_ganancia.sql"
```

---

## 🔍 Verificación Completa

### Script de Prueba Rápida:
```bash
# Ejecutar todas las consultas básicas
cd 05_consultas
for %f in (01*.sql 02*.sql 03*.sql 04*.sql 05*.sql 06*.sql 07*.sql) do (
  echo Testing %f...
  sqlcmd -S localhost -E -i "%f" -W
)
```

### Script de Prueba Completa:
```bash
# Ejecutar consolidado con resultado en archivo
sqlcmd -S localhost -E -i "consultas_dw.sql" -o "../resultados_consultas.txt"

# Ejecutar análisis avanzados
sqlcmd -S localhost -E -i "08_analisis_temporal.sql" -W > "../analisis_temporal.txt"
sqlcmd -S localhost -E -i "09_analisis_abc_pareto.sql" -W > "../analisis_abc.txt"
sqlcmd -S localhost -E -i "10_analisis_rfm.sql" -W > "../analisis_rfm.txt"
```

---

## 📊 Métricas Cubiertas

### Dimensión Temporal:
- ✅ Año
- ✅ Mes
- ✅ Trimestre
- ✅ Día de semana
- ✅ Fin de semana vs Laborable
- ✅ Comparaciones YoY/MoM
- ✅ Promedios móviles
- ✅ Acumulados

### Dimensión Producto:
- ✅ Marca
- ✅ Modelo
- ✅ Clasificación ABC
- ✅ Top productos

### Dimensión Cliente:
- ✅ Segmentación RFM
- ✅ Clasificación ABC
- ✅ Comportamiento de compra

### Dimensión Geográfica:
- ✅ Ciudad
- ✅ Provincia
- ✅ Local

### Dimensión Vendedor:
- ✅ Desempeño individual
- ✅ Clasificación ABC
- ✅ Comparativas

### Métricas de Negocio:
- ✅ Importe total
- ✅ Margen
- ✅ Cantidad de ventas
- ✅ Ticket promedio
- ✅ Unidades vendidas
- ✅ Porcentajes de participación

---

## 🎓 Técnicas SQL Demostradas

### Básicas:
- `SELECT`, `FROM`, `JOIN`
- `GROUP BY`, `ORDER BY`
- `SUM()`, `AVG()`, `COUNT()`
- `TOP N`

### Intermedias:
- CTEs (`WITH ... AS`)
- `CASE WHEN`
- Subconsultas
- `HAVING`

### Avanzadas:
- Window Functions:
  - `LAG()`, `LEAD()`
  - `ROW_NUMBER()`, `RANK()`
  - `SUM() OVER()`, `AVG() OVER()`
- Particiones (`PARTITION BY`)
- Frames (`ROWS BETWEEN`)
- Percentiles (`NTILE()`)

---

## ⚠️ Notas Importantes

1. **Rendimiento**: 
   - Las consultas 08, 09, 10 son más pesadas
   - Usar `-W` para mejor formato de salida
   - Considerar exportar a archivo para análisis

2. **Datos Requeridos**:
   - ETL debe estar ejecutado
   - DW debe tener datos cargados
   - Dimensiones deben estar pobladas

3. **Mantenimiento**:
   - Si agregas dimensiones, actualiza JOINs
   - Si cambias estructura, verifica consultas
   - Ejecutar después de cambios en DW

---

## 📁 Archivos de Salida

Los resultados se pueden guardar en:
```
proyecto_dw_celulares/
├── resultados_consultas.txt       ← consultas_dw.sql
├── analisis_temporal.txt          ← 08_analisis_temporal.sql
├── analisis_abc.txt               ← 09_analisis_abc_pareto.sql
└── analisis_rfm.txt               ← 10_analisis_rfm.sql
```

---

## ✅ Checklist de Validación

- [x] ✅ Todas las consultas básicas (01-07) ejecutan sin error
- [x] ✅ Consulta consolidada (11) corregida y funciona
- [x] ✅ Consultas avanzadas (08-10) funcionan correctamente
- [x] ✅ Resultados son coherentes con datos cargados
- [x] ✅ Sin errores de sintaxis SQL
- [x] ✅ Sin columnas inexistentes
- [x] ✅ JOINs correctos con todas las dimensiones

---

## 🚀 Integración con Otras Fases

### Después de ETL (Fase 04):
```bash
# 1. Cargar datos
sqlcmd -S localhost -E -i "04_etl\04_etl_dw_inicial.sql"

# 2. Ejecutar consultas
sqlcmd -S localhost -E -i "05_consultas\consultas_dw.sql" -o "resultados.txt"
```

### Con Notebook Jupyter (Fase 06):
Las consultas pueden exportarse como CSV/Excel para análisis estadístico en Python.

### Con Validación (Fase 07):
```bash
# Validar primero
sqlcmd -S localhost -E -i "07_validacion\VALIDACION_INTEGRAL.sql"

# Si OK (100%), ejecutar consultas
sqlcmd -S localhost -E -i "05_consultas\consultas_dw.sql"
```

---

## 🌍 Detalles de Implementación Multi-Moneda

### Tabla `DimExchangeRate` (Tasas de Cambio)
**Estructura**:
```sql
sk_exchange_rate    INT            -- Surrogate key
fecha               DATE           -- Primer día del mes
codigo_moneda       VARCHAR(3)     -- USD, EUR, BRL, CNY
tasa_ars_por_unidad DECIMAL(18,6)  -- Cuántos ARS = 1 unidad de moneda extranjera
```

### Fórmula de Conversión
```
valor_extranjero = valor_ars / tasa_ars_por_unidad
```

**Ejemplo**: Si 1 USD = 350 ARS (tasa_ars_por_unidad = 350)
- Importe ARS: 35,000
- Importe USD: 35,000 / 350 = 100 USD

### Monedas Soportadas
| Código | Moneda | Región |
|--------|--------|--------|
| ARS | Peso Argentino | Base (sin conversión) |
| USD | Dólar estadounidense | Internacional |
| EUR | Euro | Europa |
| BRL | Real brasileño | Brasil |
| CNY | Yuan chino | China |

### Consideraciones
- **Granularidad**: Tasas mensuales (primer día del mes)
- **Join**: Por `DATEFROMPARTS(anio, mes, 1) = DimExchangeRate.fecha`
- **Nulls**: Manejar con `ISNULL()` o `COALESCE()` si falta tasa
- **Inflación**: USD/EUR neutralizan inflación argentina para análisis temporal

---

**Última actualización**: 6 de Noviembre de 2025  
**Versión**: 3.0 - Soporte multi-moneda agregado (6 consultas actualizadas)  
**Correcciones aplicadas**: 2 (consultas_dw.sql línea 25, multi-moneda 01-06)
