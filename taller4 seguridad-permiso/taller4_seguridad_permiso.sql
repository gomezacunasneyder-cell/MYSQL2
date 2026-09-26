DROP USER IF EXISTS 'app_backend'@'localhost';

-- 1. Usuario Administrador local
CREATE USER 'admin_banco'@'localhost' IDENTIFIED BY 'AdminBank2026!#';

-- 2. Usuario Cajero (Acceso restringido)
CREATE USER 'cajero_app'@'localhost' IDENTIFIED BY 'CajeroPass2026!';

-- 3. Usuario Auditor (Acceso remoto de consulta)
CREATE USER 'auditor_consulta'@'%' IDENTIFIED BY 'AuditorPass2026!';

-- 4. Usuario Aplicación Backend
CREATE USER 'app_backend'@'localhost' IDENTIFIED BY 'AppBackend2026!Sec';

-- ----------------------------------------------------------------------------
-- PASO 3: Asignación Granular de Privilegios (GRANT)
-- ----------------------------------------------------------------------------
-- A) Administrador: Privilegios totales sobre la base de datos del banco
GRANT ALL PRIVILEGES ON BancoBD.* TO 'admin_banco'@'localhost' WITH GRANT OPTION;

-- B) Aplicación Backend: Operaciones DML (Lectura, Inserción y Actualización)
GRANT SELECT, INSERT, UPDATE ON BancoBD.* TO 'app_backend'@'localhost';

-- C) Cajero: Restricción a columnas específicas de la tabla cuentas
-- Solo puede ver id_cuenta, titular y saldo
GRANT SELECT (id_cuenta, titular, saldo), UPDATE (saldo) ON BancoBD.cuentas TO 'cajero_app'@'localhost';

-- D) Auditor: Privilegio de solo lectura sobre todo el esquema
GRANT SELECT ON BancoBD.* TO 'auditor_consulta'@'%';

-- Aplicar cambios en la tabla de privilegios
FLUSH PRIVILEGES;

-- ----------------------------------------------------------------------------
-- PASO 4: Verificación y Revocación de Privilegios (REVOKE & SHOW GRANTS)
-- ----------------------------------------------------------------------------
-- Consultar privilegios otorgados
SHOW GRANTS FOR 'cajero_app'@'localhost';
SHOW GRANTS FOR 'app_backend'@'localhost';

-- Revocar permiso de actualización al cajero
REVOKE UPDATE ON BancoBD.cuentas FROM 'cajero_app'@'localhost';
FLUSH PRIVILEGES;

-- ----------------------------------------------------------------------------
-- PASO 5: Prevención de SQL Injection con Sentencias Preparadas (PREPARE)
-- ----------------------------------------------------------------------------
-- Declaración de la sentencia preparada con marcadores de posición '?'
PREPARE stmt_buscar_cuenta FROM
'SELECT id_cuenta, titular, saldo, estado FROM cuentas WHERE id_cuenta = ? AND estado = ?';

-- Definición de variables de sesión
SET @id_busqueda = 1;
SET @estado_busqueda = 'Activa';

-- Ejecución segura de la consulta
EXECUTE stmt_buscar_cuenta USING @id_busqueda, @estado_busqueda;

-- Liberar la sentencia de memoria
DEALLOCATE PREPARE stmt_buscar_cuenta;
