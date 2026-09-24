-- TALLER PRÁCTICO: OPTIMIZACIÓN DE CONSULTAS Y RENDIMIENTO EN MYSQL (BancoDB)
-- ==============================================================================
-- Objetivo: Que los estudiantes diagnostiquen consultas lentas usando EXPLAIN ANALYZE,
-- identifiquen lecturas completas de tabla (Table Scans), reescriban consultas
-- de forma sargable y apliquen índices compuestos y cubrientes sobre la base de datos bancaria.
-- ==============================================================================

CREATE DATABASE IF NOT EXISTS BancoDB;
USE BancoDB;

-- ------------------------------------------------------------------------------
-- PARTE 0: ESTRUCTURA DE TABLAS E POBLAMIENTO DE DATOS MASIVOS
-- ------------------------------------------------------------------------------

DROP TABLE IF EXISTS historial_transferencias;
DROP TABLE IF EXISTS cuentas;

CREATE TABLE cuentas (
    id_cuenta INT PRIMARY KEY AUTO_INCREMENT,
    titular VARCHAR(100) NOT NULL,
    tipo_cuenta VARCHAR(20) NOT NULL DEFAULT 'Ahorros',
    saldo DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    estado VARCHAR(20) NOT NULL DEFAULT 'Activa',
    fecha_apertura DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE historial_transferencias (
    id_transferencia INT AUTO_INCREMENT PRIMARY KEY,
    cuenta_origen INT NOT NULL,
    cuenta_destino INT NOT NULL,
    monto DECIMAL(12, 2) NOT NULL,
    estado_transferencia VARCHAR(20) NOT NULL DEFAULT 'Exitosa',
    fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (cuenta_origen) REFERENCES cuentas(id_cuenta),
    FOREIGN KEY (cuenta_destino) REFERENCES cuentas(id_cuenta)
);

-- Procedimiento auxiliar para generar un volumen masivo de prueba (para notar diferencias de tiempo)
DELIMITER //
CREATE PROCEDURE CargarDatosPrueba()
BEGIN
    DECLARE i INT DEFAULT 1;

    -- Insertar 1,000 cuentas
    WHILE i <= 1000 DO
        INSERT INTO cuentas (titular, tipo_cuenta, saldo, estado, fecha_apertura)
        VALUES (
            CONCAT('Cliente_', i),
            IF(i % 2 = 0, 'Ahorros', 'Corriente'),
            ROUND(RAND() * 10000000, 2),
            IF(i % 10 = 0, 'Bloqueada', 'Activa'),
            DATE_SUB(NOW(), INTERVAL FLOOR(RAND() * 365) DAY)
        );
        SET i = i + 1;
    END WHILE;

    -- Insertar 10,000 transferencias
    SET i = 1;
    WHILE i <= 10000 DO
        INSERT INTO historial_transferencias (cuenta_origen, cuenta_destino, monto, estado_transferencia, fecha)
        VALUES (
            FLOOR(1 + RAND() * 999),
            FLOOR(1 + RAND() * 999),
            ROUND(1000 + RAND() * 500000, 2),
            IF(i % 15 = 0, 'Fallida', 'Exitosa'),
            DATE_SUB(NOW(), INTERVAL FLOOR(RAND() * 180) DAY)
        );
        SET i = i + 1;
    END WHILE;
END //
DELIMITER ;

-- Ejecutar la carga masiva
CALL CargarDatosPrueba();
DROP PROCEDURE IF EXISTS CargarDatosPrueba;


-- ==============================================================================
-- PARTE 1: DEMOSTRACIÓN GUIADA EN CLASE (PROFESOR)
-- ==============================================================================

EXPLAIN ANALYZE
SELECT id_transferencia, cuenta_origen, monto, fecha
FROM historial_transferencias
WHERE estado_transferencia = 'Exitosa'
  AND fecha >= '2026-01-01 00:00:00';

CREATE INDEX idx_transf_estado_fecha ON historial_transferencias(estado_transferencia, fecha);

EXPLAIN ANALYZE
SELECT id_transferencia, cuenta_origen, monto, fecha
FROM historial_transferencias
WHERE estado_transferencia = 'Exitosa'
  AND fecha >= '2026-01-01 00:00:00';


-- ==============================================================================
-- PARTE 2: EJERCICIOS PRÁCTICOS PARA LOS ESTUDIANTES
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- EJERCICIO 1: Diagnóstico de "Non-Sargable Query" (Uso de Funciones en WHERE)
-- ------------------------------------------------------------------------------
EXPLAIN ANALYZE
SELECT *
FROM historial_transferencias
WHERE DATE(fecha) = '2026-02-15';

-- SOLUCIÓN EJERCICIO 1:

-- 1. EXPLICACIÓN:
-- El índice idx_transf_estado_fecha NO se usa porque la consulta aplica la función
-- DATE() sobre la columna 'fecha'. MySQL no puede usar un índice B-Tree normal
-- para resolver una comparación sobre el resultado de una función aplicada a la
-- columna; tendría que calcular DATE(fecha) para cada fila, forzando un Full Table Scan.

-- 2. REESCRITURA SARGABLE:
EXPLAIN ANALYZE
SELECT *
FROM historial_transferencias
WHERE fecha >= '2026-02-15 00:00:00'
  AND fecha <  '2026-02-16 00:00:00';

-- 3. COMPARACIÓN:
-- La versión con DATE(fecha) muestra "Table scan on historial_transferencias".
-- La versión reescrita muestra "Index range scan" usando idx_transf_estado_fecha,
-- reduciendo drásticamente las filas examinadas.


-- ------------------------------------------------------------------------------
-- EJERCICIO 2: Optimización mediante Índices Cubrientes (Covering Index)
-- ------------------------------------------------------------------------------
EXPLAIN ANALYZE
SELECT titular, saldo, tipo_cuenta
FROM cuentas
WHERE estado = 'Activa';

-- SOLUCIÓN EJERCICIO 2:

-- 1. ANÁLISIS:
-- Con SELECT * (o columnas fuera del índice), MySQL hace un "bookmark lookup":
-- usa el índice para encontrar filas, pero va a la tabla base por el resto de
-- columnas, generando I/O extra. Seleccionando solo columnas cubiertas por el
-- índice, MySQL resuelve todo leyendo únicamente el índice.

-- 2. ÍNDICE CUBRIENTE:
CREATE INDEX idx_cuentas_estado_covering
ON cuentas(estado, titular, saldo, tipo_cuenta);

-- 3. VERIFICACIÓN:
EXPLAIN ANALYZE
SELECT titular, saldo, tipo_cuenta
FROM cuentas
WHERE estado = 'Activa';
-- Se espera ver "Using index" en el plan.


-- ------------------------------------------------------------------------------
-- EJERCICIO 3: Optimización de Filtros Combinados y JOINs
-- ------------------------------------------------------------------------------
EXPLAIN ANALYZE
SELECT c.id_cuenta, c.titular, ht.id_transferencia, ht.monto, ht.fecha
FROM cuentas c
JOIN historial_transferencias ht ON c.id_cuenta = ht.cuenta_origen
WHERE c.estado = 'Activa'
  AND ht.monto > 300000.00;

-- SOLUCIÓN EJERCICIO 3:

-- 1. DIAGNÓSTICO:
-- La tabla escaneada por completo es 'historial_transferencias', ya que no hay
-- índice sobre 'monto' ni sobre 'cuenta_origen' combinado con 'monto'.

-- 2. ÍNDICES A CREAR:
CREATE INDEX idx_ht_origen_monto ON historial_transferencias(cuenta_origen, monto);
CREATE INDEX idx_cuentas_estado ON cuentas(estado);

EXPLAIN ANALYZE
SELECT c.id_cuenta, c.titular, ht.id_transferencia, ht.monto, ht.fecha
FROM cuentas c
JOIN historial_transferencias ht ON c.id_cuenta = ht.cuenta_origen
WHERE c.estado = 'Activa'
  AND ht.monto > 300000.00;

-- 3. JUSTIFICACIÓN DEL ORDEN DE COLUMNAS:
-- En idx_ht_origen_monto, 'cuenta_origen' va primero por ser condición de
-- igualdad en el JOIN. 'monto' va después por ser condición de RANGO (> 300000):
-- la regla es "igualdad primero, rango al final", ya que una vez que el motor
-- entra en modo rango sobre una columna, deja de aprovechar el orden de las
-- columnas siguientes del índice. En idx_cuentas_estado se indexa 'estado' por
-- ser la columna de filtro de igualdad usada en el WHERE de 'cuentas'.

-- ==============================================================================
-- FIN DEL TALLER
-- ==============================================================================