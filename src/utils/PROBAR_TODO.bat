@echo off
REM ============================================================================
REM SCRIPT DE PRUEBA COMPLETA DEL PROYECTO DW CELULARES
REM Ejecuta todos los scripts en orden y valida que funcionen correctamente
REM ============================================================================

echo ============================================
echo INICIANDO PRUEBA COMPLETA DEL PROYECTO DW
echo ============================================
echo.

REM Configurar servidor SQL Server
set SERVER=localhost
set SQLCMD=sqlcmd -S %SERVER% -E

echo [1/10] Creando bases de datos...
%SQLCMD% -i "..\01_base_datos\00_creacion_bases.sql"
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Fallo al crear bases de datos
    goto :error
)
echo OK - Bases de datos creadas
echo.

echo [2/10] Creando estructura OLTP...
%SQLCMD% -i "..\02_oltp\01_ddl_oltp.sql"
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Fallo al crear estructura OLTP
    goto :error
)
echo OK - Estructura OLTP creada
echo.

echo [3/10] Cargando datos OLTP...
%SQLCMD% -i "..\02_oltp\02_carga_oltp.sql"
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Fallo al cargar datos OLTP
    goto :error
)
echo OK - Datos OLTP cargados
echo.

echo [4/10] Creando estructura DW...
%SQLCMD% -i "..\03_datawarehouse\03_ddl_dw.sql"
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Fallo al crear estructura DW
    goto :error
)
echo OK - Estructura DW creada
echo.

echo [5/10] Ejecutando ETL inicial...
%SQLCMD% -i "..\04_etl\04_etl_dw_inicial.sql"
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Fallo en ETL inicial
    goto :error
)
echo OK - ETL inicial completado
echo.

echo [6/10] Validando estructura completa...
%SQLCMD% -i "..\07_validacion\VALIDACION_INTEGRAL.sql" -o "resultados_validacion.txt"
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Fallo en validacion de estructura
    goto :error
)
echo OK - Validacion completada (ver resultados_validacion.txt)
echo.

echo [7/10] Probando reproceso diario...
%SQLCMD% -i "..\04_etl\05_reproceso_diario.sql"
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Fallo en reproceso diario
    goto :error
)
echo OK - Reproceso diario ejecutado
echo.

echo [8/10] Generando dataset aplanado...
%SQLCMD% -i "..\04_etl\07_dataset_aplanado.sql"
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Fallo al generar dataset aplanado
    goto :error
)
echo OK - Dataset aplanado generado
echo.

echo [9/10] Ejecutando consultas analiticas...
%SQLCMD% -i "..\05_consultas\consultas_dw.sql" -o "resultados_consultas.txt"
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Fallo en consultas analiticas
    goto :error
)
echo OK - Consultas ejecutadas (ver resultados_consultas.txt)
echo.

echo ============================================
echo PRUEBA COMPLETA EXITOSA
echo ============================================
echo.
echo Archivos generados:
echo - resultados_validacion.txt
echo - resultados_consultas.txt
echo - DW_Dataset_Aplanado.xlsx (si bcp esta configurado)
echo.
echo SIGUIENTE PASO: Ejecutar el notebook Jupyter
echo   cd ..\06_analisis
echo   jupyter notebook Notebook_Estadistica_Ventas.ipynb
echo.
goto :end

:error
echo.
echo ============================================
echo ERROR EN LA EJECUCION
echo ============================================
echo Revisa los mensajes de error anteriores
echo.
exit /b 1

:end
echo Presiona cualquier tecla para salir...
pause > nul
