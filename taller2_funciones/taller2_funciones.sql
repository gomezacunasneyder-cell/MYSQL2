-- =============================================================================
-- SOLUCIONARIO TALLER 2: FUNCIONES DEFINIDAS POR EL USUARIO (MYSQL)
-- Dominio: Sistema Bancario ("BancoTaller")
-- =============================================================================

CREATE DATABASE IF NOT EXISTS BancoDB;
USE BancoDB;

CREATE TABLE Cuentas (
    cuenta_id INT PRIMARY KEY,
    titular VARCHAR(100),
    saldo DECIMAL(12,2)
);

CREATE TABLE Transacciones (
    transaccion_id INT AUTO_INCREMENT PRIMARY KEY,
    cuenta_id INT,
    tipo_transaccion VARCHAR(20),
    monto DECIMAL(12,2),
    fecha DATETIME
);

INSERT INTO Cuentas (cuenta_id, titular, saldo) VALUES
(1, 'Ana López', 2500000.00),
(2, 'Carlos Pérez', 800000.00),
(3, 'Luis Rojas', 100000.00);

INSERT INTO Transacciones (cuenta_id, tipo_transaccion, monto, fecha) VALUES
(1, 'Retiro', 300000.00, '2026-01-05 10:00:00'),
(1, 'Retiro', 200000.00, '2026-01-20 15:00:00'),
(1, 'Deposito', 500000.00, '2026-02-01 09:00:00'),
(2, 'Retiro', 100000.00, '2026-01-10 12:00:00');

-- EJERCICIO 1: Cálculo del Impuesto 4x1000 (GMF)
DROP FUNCTION IF EXISTS CalcularImpuestoGMF;

DELIMITER //

CREATE FUNCTION CalcularImpuestoGMF(
    p_monto DECIMAL(12,2),
    p_es_exenta BOOLEAN
)
RETURNS DECIMAL(12,2)
DETERMINISTIC
BEGIN
    DECLARE v_impuesto DECIMAL(12,2);

    IF p_es_exenta THEN
        SET v_impuesto = 0.00;
    ELSE
        SET v_impuesto = p_monto * 0.004;
    END IF;

    RETURN v_impuesto;
END //

DELIMITER ;

-- EJERCICIO 2: Total de Retiros en Rango de Fechas
DROP FUNCTION IF EXISTS ObtenerTotalRetirosPeriodo;

DELIMITER //

CREATE FUNCTION ObtenerTotalRetirosPeriodo(
        p_cuenta_id INT,
        p_fecha_inicio DATE,
        p_fecha_fin DATE
)
RETURNS DECIMAL(12,2)
READS SQL DATA
BEGIN
        DECLARE v_total_retiros DECIMAL(12,2);

        SELECT IFNULL(SUM(monto), 0.00)
        INTO v_total_retiros
        FROM Transacciones
        WHERE cuenta_id = p_cuenta_id
            AND tipo_transaccion = 'Retiro'
            AND DATE(fecha) BETWEEN p_fecha_inicio AND p_fecha_fin;

        RETURN v_total_retiros;
END //

DELIMITER ;
