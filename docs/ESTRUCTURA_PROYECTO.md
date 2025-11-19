# 📊 Estructura del Proyecto - Data Warehouse de Ventas de Celulares

Este documento describe la organización profesional del repositorio.

## 📂 Estructura de Directorios

```
proyecto_dw_celulares/
│
├── 📁 data/                          # Datos del proyecto
│   ├── raw/                         # Datos crudos sin procesar
│   └── processed/                   # Datos procesados y limpios
│       └── DW_Dataset_Aplanado.xlsx
│
├── 📁 sql/                           # Scripts SQL organizados
│   ├── ddl/                         # Data Definition Language
│   │   ├── 00_creacion_bases.sql   # Crear bases OLTP y DW
│   │   ├── 00_reset_databases.sql  # Reset completo
│   │   ├── 00_reset_dw.sql         # Reset solo DW
│   │   ├── 01_ddl_oltp.sql         # Estructura OLTP
│   │   ├── 03_ddl_dw.sql           # Estructura DW (Star Schema)
│   │   ├── create_dimensions.sql   # Template dimensiones
│   │   └── create_facts.sql        # Template hechos
│   │
│   ├── dml/                         # Data Manipulation Language
│   │   ├── 02_carga_oltp.sql       # Carga de datos OLTP
│   │   └── load_sample_data.sql    # Datos de ejemplo
│   │
│   └── views/                       # Consultas analíticas y vistas
│       ├── 01_marca_mas_vendida.sql
│       ├── 02_vendedor_mas_ventas.sql
│       ├── 03_local_mas_ganancia.sql
│       ├── 04_metodo_pago_mas_usado.sql
│       ├── 05_trimestre_mas_bajo.sql
│       ├── 06_trimestre_mas_alto.sql
│       ├── 07_modelo_mas_vendido.sql
│       ├── 07_dataset_aplanado.sql
│       ├── 08_analisis_temporal.sql      # YoY, MoM
│       ├── 09_analisis_abc_pareto.sql    # Segmentación 80/20
│       ├── 10_analisis_rfm.sql           # RFM Analysis
│       ├── consultas_dw.sql              # Consultas auxiliares
│       ├── create_views.sql              # Template vistas
│       └── README_CONSULTAS.md           # Documentación consultas
│
├── 📁 src/                           # Código fuente
│   ├── etl/                         # Pipeline ETL
│   │   ├── 04_etl_dw_inicial.sql   # ETL inicial completo
│   │   ├── 05_reproceso_diario.sql # ETL incremental
│   │   ├── 06_completar_exchange_rate.sql
│   │   ├── extract.py              # Módulo extracción (Python)
│   │   ├── transform.py            # Módulo transformación
│   │   └── load.py                 # Módulo carga
│   │
│   └── utils/                       # Utilidades y helpers
│       ├── ALTAS_SIMPLES.sql       # Testing: crear ventas
│       ├── BAJAS_SIMPLES.sql       # Testing: eliminar ventas
│       ├── BAJA_PRODUCTO.sql       # Testing: eliminar productos
│       ├── SOLO_PRODUCTOS.sql      # Testing: agregar productos
│       ├── ultimas_vtas.sql        # Debugging: ver últimas ventas
│       ├── PROBAR_TODO.bat         # Automatización completa
│       ├── db_connection.py        # Conexión DB (Python)
│       └── README.md               # Guía de scripts auxiliares
│
├── 📁 notebooks/                     # Análisis y validación
│   ├── Notebook_Estadistica_Ventas.ipynb    # ⭐ Análisis principal
│   ├── 01_exploratory_analysis.ipynb        # Template EDA
│   ├── 02_reporting_kpis.ipynb              # Template KPIs
│   ├── 06_validacion_calidad.sql            # QA integridad
│   ├── VALIDACION_COMPLETA.sql              # Validación integral
│   └── VALIDACION_INTEGRAL.sql              # Tests exhaustivos
│
├── 📁 docs/                          # Documentación
│   ├── architecture.md              # Arquitectura del sistema
│   ├── star_schema.png              # Diagrama del modelo
│   ├── OLTP_Normalizado.xlsx        # Diagrama OLTP
│   ├── Presentacion_Proyecto_DW_Celulares.pptx
│   └── Proyecto_Final_DW_Celulares.pptx
│
├── 📁 [01-09]_*/                     # ⚠️ Carpetas originales (referencia)
│   └── ...                           # Archivos fuente originales
│
├── .gitignore                        # Exclusiones de Git
├── LICENSE                           # Licencia MIT
├── README.md                         # Documentación principal
└── requirements.txt                  # Dependencias Python

```

## 🎯 Flujo de Trabajo Recomendado

### 1️⃣ Setup Inicial (Primera Vez)

```sql
-- Paso 1: Crear bases de datos
sql/ddl/00_creacion_bases.sql

-- Paso 2: Crear estructura OLTP
sql/ddl/01_ddl_oltp.sql

-- Paso 3: Cargar datos en OLTP
sql/dml/02_carga_oltp.sql

-- Paso 4: Crear estructura DW
sql/ddl/03_ddl_dw.sql

-- Paso 5: ETL inicial (OLTP → DW)
src/etl/04_etl_dw_inicial.sql
```

### 2️⃣ Actualización Incremental

```sql
-- Agregar nuevas ventas (testing)
src/utils/ALTAS_SIMPLES.sql

-- Ejecutar ETL incremental
src/etl/05_reproceso_diario.sql
```

### 3️⃣ Análisis

```sql
-- Ejecutar consultas analíticas
sql/views/08_analisis_temporal.sql
sql/views/09_analisis_abc_pareto.sql
sql/views/10_analisis_rfm.sql

-- O usar el notebook principal
notebooks/Notebook_Estadistica_Ventas.ipynb
```

### 4️⃣ Validación

```sql
-- Verificar calidad de datos
notebooks/06_validacion_calidad.sql
notebooks/VALIDACION_COMPLETA.sql
```

## 📊 Componentes Clave

### SQL Scripts

| Carpeta | Propósito | Archivos Principales |
|---------|-----------|---------------------|
| `sql/ddl/` | Definición de tablas | `01_ddl_oltp.sql`, `03_ddl_dw.sql` |
| `sql/dml/` | Carga de datos | `02_carga_oltp.sql` |
| `sql/views/` | Análisis y reportes | `08-10_analisis_*.sql` |

### Python Modules

| Módulo | Descripción |
|--------|-------------|
| `src/etl/extract.py` | Extracción desde CSV, DB, APIs |
| `src/etl/transform.py` | Limpieza y transformaciones |
| `src/etl/load.py` | Carga a DW con SCD |
| `src/utils/db_connection.py` | Gestión de conexiones |

### Notebooks

| Notebook | Contenido |
|----------|-----------|
| `Notebook_Estadistica_Ventas.ipynb` | Análisis completo multi-moneda + validación SQL vs Python |
| `01_exploratory_analysis.ipynb` | Template para EDA |
| `02_reporting_kpis.ipynb` | Template para KPIs |

## 🔧 Mantenimiento

### Reset Completo

```sql
sql/ddl/00_reset_databases.sql  -- Elimina OLTP + DW
-- Luego ejecutar setup inicial (pasos 1-5)
```

### Reset Solo DW

```sql
sql/ddl/00_reset_dw.sql         -- Mantiene OLTP intacto
sql/ddl/03_ddl_dw.sql           -- Re-crear estructura
src/etl/04_etl_dw_inicial.sql   -- Re-cargar datos
```

### Testing Automatizado

```bash
# Windows
src/utils/PROBAR_TODO.bat
```

## 📚 Documentación Adicional

- **Arquitectura**: `docs/architecture.md`
- **Consultas**: `sql/views/README_CONSULTAS.md`
- **Scripts Auxiliares**: `src/utils/README.md`
- **README Principal**: `README.md`

## ⚠️ Notas Importantes

1. **Carpetas `01-09_*`**: Son las carpetas originales del proyecto, mantenidas como referencia. Los archivos activos están en la estructura nueva.

2. **Orden de Ejecución**: Siempre seguir el flujo: DDL → DML → ETL → Análisis

3. **Multi-moneda**: Todas las consultas soportan conversión automática a USD, EUR, BRL, CNY.

4. **SCD Tipo 2**: Implementado en `DimVendedor` con versionado histórico.

## 🚀 Quick Start

```bash
# 1. Clonar repositorio
git clone https://github.com/rAmIro-89/retail-sales-data-warehouse-sql.git

# 2. Instalar dependencias Python
pip install -r requirements.txt

# 3. Ejecutar scripts SQL en orden (SSMS)
# Ver sección "Setup Inicial"

# 4. Abrir notebook de análisis
jupyter notebook notebooks/Notebook_Estadistica_Ventas.ipynb
```

---

**Última actualización**: Noviembre 2025  
**Versión**: 2.1  
**Autor**: Ramiro Ottone Villar
