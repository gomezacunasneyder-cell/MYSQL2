-- =========================================================
-- Reto: Transferencia Bancaria Segura con Procedimientos Almacenados
-- =========================================================

DROP DATABASE IF EXISTS BancoDB;
CREATE DATABASE BancoDB;
USE BancoDB;

-- Paso 2: Crear las tablas
CREATE TABLE cuentas (
    id_cuenta INT PRIMARY KEY,
    titular VARCHAR(100),
    saldo DECIMAL(10,2)
);

CREATE TABLE historial_transferencias (
    id_transferencia INT AUTO_INCREMENT PRIMARY KEY,
    cuenta_origen INT,
    cuenta_destino INT,
    monto DECIMAL(10,2),
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Paso 3: Insertar datos de prueba
INSERT INTO cuentas (id_cuenta, titular, saldo) VALUES
(1, 'Ana López', 5000.00),
(2, 'Carlos Pérez', 3000.00);

-- Paso 4: Procedimiento TransferirFondos
DELIMITER $$

CREATE PROCEDURE TransferirFondos(
    IN  p_origen INT,
    IN  p_destino INT,
    IN  p_monto DECIMAL(10,2),
    OUT p_codigo_respuesta INT
)
BEGIN
    DECLARE v_saldo_origen DECIMAL(10,2);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_codigo_respuesta = 500;
    END;

    START TRANSACTION;

    SELECT saldo INTO v_saldo_origen
        FROM cuentas
        WHERE id_cuenta = p_origen
        FOR UPDATE;

    IF v_saldo_origen >= p_monto THEN
        UPDATE cuentas SET saldo = saldo - p_monto WHERE id_cuenta = p_origen;
        UPDATE cuentas SET saldo = saldo + p_monto WHERE id_cuenta = p_destino;

        INSERT INTO historial_transferencias (cuenta_origen, cuenta_destino, monto)
        VALUES (p_origen, p_destino, p_monto);

        COMMIT;
        SET p_codigo_respuesta = 200;
    ELSE
        ROLLBACK;
        SET p_codigo_respuesta = 400;
    END IF;
END$$

DELIMITER ;
