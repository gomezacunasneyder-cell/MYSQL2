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

CREATE TABLE auditoria_operaciones (
    id_auditoria INT AUTO_INCREMENT PRIMARY KEY,
    usuario_responsable VARCHAR(100),
    cuenta_origen INT,
    cuenta_destino INT,
    monto DECIMAL(10,2),
    codigo_resultado INT,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Paso 4: Procedimiento TransferirFondos
DELIMITER $$

CREATE PROCEDURE TransferirFondos(
    IN  p_origen INT,
    IN  p_destino INT,
    IN  p_monto DECIMAL(10,2),
    IN  p_usuario VARCHAR(100),
    OUT p_codigo_respuesta INT,
    OUT p_titular_origen VARCHAR(100)
)
proc_block: BEGIN
    DECLARE v_saldo_origen DECIMAL(10,2);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_codigo_respuesta = 500;

        INSERT INTO auditoria_operaciones
            (usuario_responsable, cuenta_origen, cuenta_destino, monto, codigo_resultado)
        VALUES (p_usuario, p_origen, p_destino, p_monto, 500);
    END;

    -- Desafío extra: validar que el monto sea mayor que cero
    IF p_monto <= 0 THEN
        SET p_codigo_respuesta = 401;
        SELECT titular INTO p_titular_origen
            FROM cuentas WHERE id_cuenta = p_origen;

        INSERT INTO auditoria_operaciones
            (usuario_responsable, cuenta_origen, cuenta_destino, monto, codigo_resultado)
        VALUES (p_usuario, p_origen, p_destino, p_monto, 401);
        LEAVE proc_block;
    END IF;

    START TRANSACTION;

    SELECT saldo, titular INTO v_saldo_origen, p_titular_origen
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

        INSERT INTO auditoria_operaciones
            (usuario_responsable, cuenta_origen, cuenta_destino, monto, codigo_resultado)
        VALUES (p_usuario, p_origen, p_destino, p_monto, 200);
    ELSE
        ROLLBACK;
        SET p_codigo_respuesta = 400;

        INSERT INTO auditoria_operaciones
            (usuario_responsable, cuenta_origen, cuenta_destino, monto, codigo_resultado)
        VALUES (p_usuario, p_origen, p_destino, p_monto, 400);
    END IF;
END$$

DELIMITER ;
