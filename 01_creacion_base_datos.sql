-- =====================================================
-- SCRIPT DE CREACIÓN DE BASE DE DATOS - INNOVATECH CHILE
-- Proyecto: Fit Project / Ecosistema Digital
-- Motor: MySQL 8.0+ (Exclusivo)
-- Autor: Vania Alexandra Carvajal Salinas
-- Fecha: Mayo 2026
-- =====================================================

-- Crear base de datos principal para el ecosistema Innovatech
CREATE DATABASE IF NOT EXISTS innovatech_db 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

USE innovatech_db;

-- =====================================================
-- TABLA: usuarios
-- Gestión de colaboradores y usuarios finales (IE1, IE9)
-- =====================================================

CREATE TABLE IF NOT EXISTS usuarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    
    -- Atributos con nombres normalizados según requerimientos técnicos
    nombre VARCHAR(100) NOT NULL COMMENT 'Nombre completo del colaborador',
    email VARCHAR(150) NOT NULL UNIQUE COMMENT 'Correo electrónico corporativo',
    edad INT NULL COMMENT 'Edad del usuario (opcional)',
    
    -- Auditoría y trazabilidad
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Fecha de registro',
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Estado operativo
    estado ENUM('activo', 'inactivo') DEFAULT 'activo' COMMENT 'Estado del usuario en el sistema'
) ENGINE=InnoDB COMMENT 'Tabla central de usuarios del sistema Innovatech';

-- =====================================================
-- ÍNDICES (Optimización para AWS EC2 - IE4)
-- =====================================================

CREATE INDEX idx_usuarios_nombre ON usuarios(nombre);
CREATE INDEX idx_usuarios_estado ON usuarios(estado);
CREATE INDEX idx_usuarios_fecha_creacion ON usuarios(fecha_creacion);
CREATE INDEX idx_usuarios_nombre_estado ON usuarios(nombre, estado);

-- =====================================================
-- INSERCIÓN DE DATOS SEMILLA (Pruebas Funcionales - IE9)
-- =====================================================

INSERT INTO usuarios (nombre, email, edad, estado) VALUES
('Vania Carvajal', 'v.carvajal@innovatech.cl', 25, 'activo'),
('César Maldonado', 'c.maldonado@innovatech.cl', 30, 'activo'),
('Gino Fierro', 'g.fierro@innovatech.cl', 28, 'activo'),
('Paula Integrante', 'p.integrante@innovatech.cl', 22, 'activo')
ON DUPLICATE KEY UPDATE 
    nombre = VALUES(nombre),
    estado = VALUES(estado);

-- =====================================================
-- VISTAS (Reportabilidad Frontend - IE5)
-- =====================================================

CREATE OR REPLACE VIEW vista_usuarios_activos AS
SELECT id, nombre, email, edad, fecha_creacion
FROM usuarios 
WHERE estado = 'activo';

-- =====================================================
-- PROCEDIMIENTOS ALMACENADOS (Lógica Centralizada - IE6)
-- =====================================================

DELIMITER //
CREATE PROCEDURE sp_obtener_usuario_por_id(IN p_id INT)
BEGIN
    SELECT id, nombre, email, edad, estado, fecha_creacion, fecha_actualizacion
    FROM usuarios
    WHERE id = p_id;
END //

CREATE PROCEDURE sp_crear_usuario(
    IN p_nombre VARCHAR(100),
    IN p_email VARCHAR(150),
    IN p_edad INT,
    IN p_estado VARCHAR(10)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    INSERT INTO usuarios (nombre, email, edad, estado)
    VALUES (p_nombre, p_email, p_edad, p_estado);
    SELECT LAST_INSERT_ID() as usuario_id;
    COMMIT;
END //

-- Mantenimiento: Limpiar inactivos para optimizar almacenamiento en EC2 (IE8)
CREATE PROCEDURE sp_limpiar_usuarios_inactivos(IN p_dias INT)
BEGIN
    DELETE FROM usuarios 
    WHERE estado = 'inactivo' 
    AND fecha_actualizacion < DATE_SUB(NOW(), INTERVAL p_dias DAY);
END //
DELIMITER ;

-- =====================================================
-- VALIDACIÓN FINAL
-- =====================================================
-- El puerto por defecto para la conexión será el 3306.
-- Este script asegura la paridad entre desarrollo y producción en AWS.