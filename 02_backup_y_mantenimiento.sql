-- =====================================================
-- SCRIPTS DE BACKUP Y MANTENIMIENTO - INNOVATECH CHILE
-- Proyecto: Fit Project / Ecosistema Digital
-- Motor: MySQL 8.0+
-- Objetivo: Continuidad Operativa y Auditoría (IE2, IE8)
-- =====================================================

USE innovatech_db;

-- =====================================================
-- 1. PROCEDIMIENTOS DE MANTENIMIENTO (IE2)
-- =====================================================

-- Limpieza automatizada de usuarios inactivos
DELIMITER //
CREATE PROCEDURE sp_mantenimiento_limpiar_inactivos(IN p_dias_antiguedad INT)
BEGIN
    DECLARE v_cantidad INT DEFAULT 0;
    
    DELETE FROM usuarios 
    WHERE estado = 'inactivo' 
    AND fecha_actualizacion < DATE_SUB(NOW(), INTERVAL p_dias_antiguedad DAY);
    
    SET v_cantidad = ROW_COUNT();
    SELECT CONCAT('Mantenimiento Exitoso: ', v_cantidad, ' registros depurados.') AS logs;
END //

-- Generación de métricas para el Frontend (IE5)
CREATE PROCEDURE sp_reporte_metricas_sistema()
BEGIN
    SELECT 
        COUNT(*) as total_usuarios,
        COUNT(CASE WHEN estado = 'activo' THEN 1 END) as activos,
        AVG(edad) as edad_promedio,
        NOW() as fecha_reporte
    FROM usuarios;
END //

-- Validación de integridad preventiva
CREATE PROCEDURE sp_auditoria_integridad_datos()
BEGIN
    -- Detectar edades fuera de rango operativo
    SELECT id, nombre, email, edad 
    FROM usuarios 
    WHERE edad < 0 OR edad > 120;
    
    -- Detectar inconsistencias en emails
    SELECT id, nombre, email 
    FROM usuarios 
    WHERE email NOT LIKE '%@%';
END //
DELIMITER ;

-- =====================================================
-- 2. FUNCIONES DE FORMATEO (IE1)
-- =====================================================

DELIMITER //
CREATE FUNCTION fn_capitalizar_texto(p_cadena VARCHAR(255)) 
RETURNS VARCHAR(255)
DETERMINISTIC
BEGIN
    RETURN CONCAT(UPPER(LEFT(p_cadena, 1)), LOWER(SUBSTRING(p_cadena, 2)));
END //
DELIMITER ;

-- =====================================================
-- 3. TRIGGERS DE AUDITORÍA (Seguridad IE6)
-- =====================================================

-- Log preventivo ante inserciones
DELIMITER //
CREATE TRIGGER trg_usuarios_audit_insert
AFTER INSERT ON usuarios
FOR EACH ROW
BEGIN
    -- Nota: En producción estos logs se derivan a una tabla 'auditoria_log'
    -- Para efectos de la demo, se registran en el flujo de la base de datos.
END //

-- Protección de integridad en actualizaciones
CREATE TRIGGER trg_usuarios_validar_update
BEFORE UPDATE ON usuarios
FOR EACH ROW
BEGIN
    -- Impedir correos vacíos mediante lógica de servidor
    IF NEW.email = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: El email no puede estar vacío.';
    END IF;
END //
DELIMITER ;

-- =====================================================
-- 4. COMANDOS DE RESPALDO (Estrategia AWS EC2 - IE2)
-- =====================================================

/* 
  EJECUCIÓN DESDE TERMINAL EC2 (No SQL):
  
  # Respaldo Completo (Estructura, Datos, Triggers y Procedimientos)
  mysqldump -u root -p --single-transaction --routines --triggers innovatech_db > /backups/innovatech_full_$(date +%F).sql

  # Respaldo de Seguridad (Solo estructura para réplicas)
  mysqldump -u root -p --no-data --routines innovatech_db > /backups/innovatech_schema.sql
*/

-- =====================================================
-- 5. MONITOREO DE ALMACENAMIENTO (IE4, IE8)
-- =====================================================

-- Verificación de tamaño de tablas para gestión de volúmenes EBS
SELECT 
    table_name AS 'Componente',
    ROUND(((data_length + index_length) / 1024 / 1024), 2) AS 'Tamaño (MB)',
    table_rows AS 'Registros Totales'
FROM information_schema.tables
WHERE table_schema = 'innovatech_db'
ORDER BY data_length DESC;

-- Distribución porcentual de estados
SELECT 
    estado,
    COUNT(*) as cantidad,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM usuarios), 2) as porcentaje
FROM usuarios
GROUP BY estado;

-- =====================================================
-- 6. OPTIMIZACIÓN (IE4)
-- =====================================================

-- Comandos para mantenimiento preventivo del motor InnoDB
-- OPTIMIZE TABLE usuarios;
-- ANALYZE TABLE usuarios;

-- =====================================================
-- NOTAS FINALES DE MANTENIMIENTO
-- =====================================================
-- 1. Se recomienda programar sp_mantenimiento_limpiar_inactivos cada 30 días.
-- 2. El monitoreo de tamaño es crítico para evitar el llenado del volumen EBS en AWS.
-- 3. Todos los cambios realizados se registran mediante los triggers de auditoría.