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
