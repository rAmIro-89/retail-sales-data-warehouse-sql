# 🛠️ Scripts Auxiliares

Scripts de utilidad para testing y mantenimiento del proyecto DW.

## 📋 Scripts Disponibles

| Script | Propósito | Uso |
|--------|-----------|-----|
| `PROBAR_TODO.bat` | Ejecutar proyecto completo desde cero | Para demos y validación integral |
| `ALTAS_SIMPLES.sql` | Crear venta completa (producto+cliente+venta) | Testing de ETL incremental |
| `SOLO_PRODUCTOS.sql` | Agregar productos sin ventas | Preparar catálogo |
| `BAJA_PRODUCTO.sql` | Eliminar producto (si no tiene ventas) | Limpiar datos de prueba |
| `BAJAS_SIMPLES.sql` | Eliminar ventas del OLTP | Testing de sincronización |
| `ultimas_vtas.sql` | Ver últimas 10 ventas | Debugging rápido |

## 🚀 Uso Rápido

### Automatización Completa
```bash
cd 08_scripts_auxiliares
PROBAR_TODO.bat   # ⚠️ Destruye y recrea todo desde cero
```
Genera: `resultados_validacion.txt` y `resultados_consultas.txt`

### Testing Manual
```bash
# Editar variables en cada script y ejecutar:
sqlcmd -S localhost -E -i ALTAS_SIMPLES.sql     # Nueva venta
sqlcmd -S localhost -E -i SOLO_PRODUCTOS.sql    # Solo productos  
sqlcmd -S localhost -E -i ultimas_vtas.sql      # Ver últimas ventas

# Sincronizar cambios:
sqlcmd -S localhost -E -i ..\04_etl\05_reproceso_diario.sql
```

## ⚡ Scripts de Limpieza

```bash
sqlcmd -S localhost -E -i BAJAS_SIMPLES.sql     # Eliminar ventas
sqlcmd -S localhost -E -i BAJA_PRODUCTO.sql     # Eliminar productos (sin ventas)
```

## � Casos de Uso

- **Demo SCD2**: Agregar producto → modificar precio → sincronizar
- **Demo ETL**: Agregar ventas → reprocesar → validar incremento
- **Testing**: Crear datos → procesar → limpiar

---

**Nota**: Todos los scripts requieren sincronización DW posterior con `05_reproceso_diario.sql`
