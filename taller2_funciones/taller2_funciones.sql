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
