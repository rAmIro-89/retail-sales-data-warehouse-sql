-- 00_reset_dw.sql
-- Script para resetear SOLO el Data Warehouse (no toca OLTP)
-- Uso: Cuando necesites limpiar el DW y volver a cargarlo desde cero

USE master;
GO

-- Verificar que no haya conexiones activas al DW
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DW_Celulares')
BEGIN
    PRINT 'Cerrando conexiones activas a DW_Celulares...';
    
    ALTER DATABASE DW_Celulares SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    
    PRINT 'Eliminando DW_Celulares...';
    DROP DATABASE DW_Celulares;
    
    PRINT '✓ DW_Celulares eliminado correctamente.';
END
ELSE
BEGIN
    PRINT '⚠️ DW_Celulares no existe (no hay nada que resetear).';
END
GO

-- Crear base limpia
PRINT 'Creando DW_Celulares vacío...';
CREATE DATABASE DW_Celulares;
GO

PRINT '';
PRINT '========================================';
PRINT 'RESET COMPLETADO';
PRINT '========================================';
PRINT '';
PRINT 'Próximos pasos:';
PRINT '1. Ejecutá: 03_datawarehouse/03_ddl_dw.sql';
PRINT '2. Ejecutá: 04_etl/04_etl_dw_inicial.sql';
PRINT '';
GO
