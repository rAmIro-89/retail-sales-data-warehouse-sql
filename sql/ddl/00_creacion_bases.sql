-- 00_creacion_bases.sql
-- Crea las bases de datos OLTP y DW (SQL Server)
IF DB_ID('OLTP_Celulares') IS NULL
BEGIN
    CREATE DATABASE OLTP_Celulares;
END;
GO

IF DB_ID('DW_Celulares') IS NULL
BEGIN
    CREATE DATABASE DW_Celulares;
END;
GO
