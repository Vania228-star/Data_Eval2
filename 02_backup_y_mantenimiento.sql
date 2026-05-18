USE innovatech_db;

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

CREATE PROCEDURE sp_reporte_metricas_sistema()
BEGIN
    SELECT 
        COUNT(*) as total_usuarios,
        COUNT(CASE WHEN estado = 'activo' THEN 1 END) as activos,
        AVG(edad) as edad_promedio,
        NOW() as fecha_reporte
    FROM usuarios;
END //

CREATE PROCEDURE sp_auditoria_integridad_datos()
BEGIN
    SELECT id, nombre, email, edad 
    FROM usuarios 
    WHERE edad < 0 OR edad > 120;
    
    SELECT id, nombre, email 
    FROM usuarios 
    WHERE email NOT LIKE '%@%';
END //
DELIMITER ;

DELIMITER //
CREATE FUNCTION fn_capitalizar_texto(p_cadena VARCHAR(255)) 
RETURNS VARCHAR(255)
DETERMINISTIC
BEGIN
    RETURN CONCAT(UPPER(LEFT(p_cadena, 1)), LOWER(SUBSTRING(p_cadena, 2)));
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER trg_usuarios_audit_insert
AFTER INSERT ON usuarios
FOR EACH ROW
BEGIN
END //

CREATE TRIGGER trg_usuarios_validar_update
BEFORE UPDATE ON usuarios
FOR EACH ROW
BEGIN
    IF NEW.email = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: El email no puede estar vacío.';
    END IF;
END //
DELIMITER ;

SELECT 
    table_name AS 'Componente',
    ROUND(((data_length + index_length) / 1024 / 1024), 2) AS 'Tamaño (MB)',
    table_rows AS 'Registros Totales'
FROM information_schema.tables
WHERE table_schema = 'innovatech_db'
ORDER BY data_length DESC;

SELECT 
    estado,
    COUNT(*) as cantidad,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM usuarios), 2) as porcentaje
FROM usuarios
GROUP BY estado;