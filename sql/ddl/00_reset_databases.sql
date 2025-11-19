-- 00_reset_databases.sql
-- Script para eliminar completamente las bases de datos OLTP y DW
-- Útil para reiniciar el proyecto desde cero

USE master;
GO

PRINT '=== Iniciando reset de bases de datos ===';
GO

-- Eliminar base OLTP_Celulares
IF DB_ID('OLTP_Celulares') IS NOT NULL
BEGIN
    PRINT 'Eliminando base de datos OLTP_Celulares...';
    ALTER DATABASE OLTP_Celulares SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE OLTP_Celulares;
    PRINT '✓ OLTP_Celulares eliminada exitosamente.';
END
ELSE
BEGIN
    PRINT '○ OLTP_Celulares no existe (ya eliminada o nunca creada).';
END
GO

-- Eliminar base DW_Celulares
IF DB_ID('DW_Celulares') IS NOT NULL
BEGIN
    PRINT 'Eliminando base de datos DW_Celulares...';
    ALTER DATABASE DW_Celulares SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DW_Celulares;
    PRINT '✓ DW_Celulares eliminada exitosamente.';
END
ELSE
BEGIN
    PRINT '○ DW_Celulares no existe (ya eliminada o nunca creada).';
END
GO

PRINT '=== Reset completado ===';
PRINT 'Ahora puedes ejecutar en orden:';
PRINT '  1. 00_creacion_bases.sql';
PRINT '  2. 01_ddl_oltp.sql';
PRINT '  3. 02_carga_oltp.sql';
PRINT '  4. 03_ddl_dw.sql';
PRINT '  5. 04_etl_dw_inicial.sql';
GO
