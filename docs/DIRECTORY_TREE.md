# 📊 Data Warehouse - Árbol de Directorios

## Estructura Profesional Organizada

```
proyecto_dw_celulares/
│
├── 📁 data/                                    # DATOS
│   ├── raw/                                   # Datos sin procesar
│   └── processed/                             # Datos procesados
│       └── DW_Dataset_Aplanado.xlsx
│
├── 📁 sql/                                     # SCRIPTS SQL
│   ├── ddl/                                   # ⚙️ CREATE TABLES
│   │   ├── 00_creacion_bases.sql             # Crear OLTP + DW
│   │   ├── 00_reset_databases.sql            # Reset completo
│   │   ├── 00_reset_dw.sql                   # Reset solo DW
│   │   ├── 01_ddl_oltp.sql                   # ⭐ Estructura OLTP
│   │   ├── 03_ddl_dw.sql                     # ⭐ Star Schema DW
│   │   ├── create_dimensions.sql             # Template
│   │   └── create_facts.sql                  # Template
│   │
│   ├── dml/                                   # 📥 INSERT/UPDATE
│   │   ├── 02_carga_oltp.sql                 # ⭐ Datos iniciales
│   │   └── load_sample_data.sql              # Datos ejemplo
│   │
│   └── views/                                 # 📊 ANÁLISIS & CONSULTAS
│       ├── 01_marca_mas_vendida.sql
│       ├── 02_vendedor_mas_ventas.sql
│       ├── 03_local_mas_ganancia.sql
│       ├── 04_metodo_pago_mas_usado.sql
│       ├── 05_trimestre_mas_bajo.sql
│       ├── 06_trimestre_mas_alto.sql
│       ├── 07_modelo_mas_vendido.sql
│       ├── 07_dataset_aplanado.sql           # Vista desnormalizada
│       ├── 08_analisis_temporal.sql          # ⭐ YoY, MoM
│       ├── 09_analisis_abc_pareto.sql        # ⭐ Segmentación 80/20
│       ├── 10_analisis_rfm.sql               # ⭐ RFM Customer Analysis
│       ├── consultas_dw.sql
│       ├── create_views.sql                  # Template
│       └── README_CONSULTAS.md
│
├── 📁 src/                                     # CÓDIGO FUENTE
│   ├── etl/                                   # 🔄 PIPELINE ETL
│   │   ├── 04_etl_dw_inicial.sql             # ⭐ ETL completo inicial
│   │   ├── 05_reproceso_diario.sql           # ⭐ ETL incremental
│   │   ├── 06_completar_exchange_rate.sql    # Exchange rates
│   │   ├── extract.py                        # Python: Extracción
│   │   ├── transform.py                      # Python: Transformación
│   │   ├── load.py                           # Python: Carga
│   │   └── __init__.py
│   │
│   └── utils/                                 # 🛠️ UTILIDADES
│       ├── ALTAS_SIMPLES.sql                 # Testing: crear ventas
│       ├── BAJAS_SIMPLES.sql                 # Testing: eliminar ventas
│       ├── BAJA_PRODUCTO.sql                 # Testing: eliminar productos
│       ├── SOLO_PRODUCTOS.sql                # Testing: agregar productos
│       ├── ultimas_vtas.sql                  # Debugging
│       ├── PROBAR_TODO.bat                   # ⭐ Automatización completa
│       ├── db_connection.py                  # Python: Conexión DB
│       ├── README.md
│       └── __init__.py
│
├── 📁 notebooks/                               # 📓 JUPYTER NOTEBOOKS
│   ├── Notebook_Estadistica_Ventas.ipynb     # ⭐⭐⭐ PRINCIPAL
│   ├── 01_exploratory_analysis.ipynb         # Template EDA
│   ├── 02_reporting_kpis.ipynb               # Template KPIs
│   ├── 06_validacion_calidad.sql             # ⭐ Validación QA
│   ├── VALIDACION_COMPLETA.sql               # Validación integral
│   └── VALIDACION_INTEGRAL.sql               # Tests exhaustivos
│
├── 📁 docs/                                    # 📚 DOCUMENTACIÓN
│   ├── architecture.md                        # ⭐ Arquitectura sistema
│   ├── ESTRUCTURA_PROYECTO.md                 # ⭐ Esta guía
│   ├── star_schema.png                        # Diagrama modelo
│   ├── OLTP_Normalizado.xlsx                  # Diagrama OLTP
│   ├── Presentacion_Proyecto_DW_Celulares.pptx
│   └── Proyecto_Final_DW_Celulares.pptx
│
├── 📁 [01-09]_carpetas_originales/            # ⚠️ ARCHIVOS FUENTE (referencia)
│   ├── 01_base_datos/
│   ├── 02_oltp/
│   ├── 03_datawarehouse/
│   ├── 04_etl/
│   ├── 05_consultas/
│   ├── 06_analisis/
│   ├── 07_validacion/
│   ├── 08_scripts_auxiliares/
│   └── 09_documentacion/
│
├── .gitignore                                  # Exclusiones Git
├── LICENSE                                     # MIT License
├── README.md                                   # ⭐ Documentación principal
└── requirements.txt                            # Dependencias Python

```

## 🎯 Archivos Más Importantes

### 🔥 Imprescindibles para Ejecutar el Proyecto

1. **`sql/ddl/01_ddl_oltp.sql`** - Estructura OLTP
2. **`sql/ddl/03_ddl_dw.sql`** - Star Schema completo
3. **`sql/dml/02_carga_oltp.sql`** - Datos iniciales
4. **`src/etl/04_etl_dw_inicial.sql`** - ETL completo
5. **`src/etl/05_reproceso_diario.sql`** - ETL incremental
6. **`notebooks/Notebook_Estadistica_Ventas.ipynb`** - Análisis completo

### 📊 Análisis Avanzado

7. **`sql/views/08_analisis_temporal.sql`** - YoY, MoM, tendencias
8. **`sql/views/09_analisis_abc_pareto.sql`** - Segmentación 80/20
9. **`sql/views/10_analisis_rfm.sql`** - RFM customer segmentation

### 🛠️ Utilidades

10. **`src/utils/PROBAR_TODO.bat`** - Automatización completa
11. **`notebooks/06_validacion_calidad.sql`** - Validación QA

## 🚦 Orden de Ejecución (Setup)

```
1️⃣ sql/ddl/00_creacion_bases.sql       # Crear bases vacías
2️⃣ sql/ddl/01_ddl_oltp.sql            # Estructura OLTP
3️⃣ sql/dml/02_carga_oltp.sql          # Cargar datos
4️⃣ sql/ddl/03_ddl_dw.sql              # Star Schema DW
5️⃣ src/etl/04_etl_dw_inicial.sql      # Poblar DW
6️⃣ notebooks/Notebook_*.ipynb          # Análisis
```

## 🎨 Convenciones

- ⭐ = Archivo crítico del proyecto
- ⭐⭐⭐ = Archivo principal/más importante
- 🔄 = Proceso ETL
- 📊 = Análisis/Reportes
- 🛠️ = Herramientas/Utilidades
- 📚 = Documentación

## 📝 Notas

- Las carpetas `01-09_*` contienen los archivos fuente originales
- Los archivos activos están en la estructura nueva (`sql/`, `src/`, etc.)
- Todos los archivos originales se mantienen como referencia

---

**Versión**: 2.1  
**Fecha**: Noviembre 2025  
**Autor**: Ramiro Ottone Villar
