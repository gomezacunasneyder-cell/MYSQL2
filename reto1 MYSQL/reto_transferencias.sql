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
