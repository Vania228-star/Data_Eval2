# Base de Datos - MySQL

## Descripción
Módulo de persistencia basado en MySQL 8.0 diseñado para el ecosistema digital de Innovatech. Esta solución garantiza la integridad y disponibilidad de los datos de usuarios mediante el uso de contenedores Docker y políticas de persistencia robustas aplicadas en la arquitectura de AWS.

## Versiones y Herramientas Requeridas

### Motor de Base de Datos
- **MySQL**: Versión 8.0 o superior

### Herramientas de Administración
- **MySQL Client**: Para ejecución de scripts desde línea de comandos
- **phpMyAdmin**: Opcional, para administración web
- **MySQL Workbench**: Opcional, para diseño y administración gráfica

## Estructura de Archivos
Para asegurar la portabilidad y el cumplimiento del flujo CI/CD, el repositorio se organiza de la siguiente manera:

```
database/
├── .github/workflows/database-deploy.yml
├── 01_creacion_base_datos.sql    # Estructura central, Vistas y SP de aplicación.
├── 02_backup_y_mantenimiento.sql # Triggers de auditoría, funciones y protocolos de backup.
├── docker-compose.yml            # Orquestación y configuración de volúmenes
├── Dockerfile
└── README.md                     # Documentación técnica
```
## Persistencia de Datos
Se ha implementado una estrategia de persistencia mediante Volúmenes Docker para asegurar que la información crítica no se pierda al reiniciar contenedores:

- **Tipo de Volumen**: Se utiliza innovatech_data:/var/lib/mysql

- **Justificación**: A diferencia de los bind mounts, los volúmenes nombrados permiten a Docker gestionar los permisos de escritura de forma óptima en el entorno Linux de la instancia EC2, evitando errores de acceso denegado y facilitando la migración de datos.

- **Continuidad Operativa**: El volumen asegura la persistencia de las tablas de usuarios y configuraciones del Backend.

Nota técnica: Se optó por Named Volumes en lugar de Bind Mounts porque los primeros son gestionados íntegramente por Docker, lo que evita problemas de permisos de usuario en la instancia EC2 de AWS y garantiza que los datos persistan incluso si la estructura de directorios del host cambia.

## Instalación y Configuración

Existen dos modalidades para preparar el entorno de base de datos de Innovatech. Para el despliegue en la instancia EC2 de AWS, se prioriza el uso de contenedores.

### Despliegue con Docker

Esta opción automatiza la instalación y configuración del motor de base de datos, garantizando la paridad entre el entorno de desarrollo y producción.

```bash
# Iniciar el contenedor de base de datos con persistencia (IE2)
docker-compose up -d db

# Verificar que el contenedor esté corriendo (IE4)
docker ps
```

### 1. Instalar MySQL Server

En caso de requerir una instalación nativa para pruebas locales, siga estos comandos según su sistema operativo:

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install mysql-server

# CentOS/RHEL
sudo yum install mysql-server

# Windows
# Descargar desde https://dev.mysql.com/downloads/mysql/
```

### 2. Configurar MySQL

Una vez instalado el motor de forma nativa, es crítico asegurar la instancia:

```bash
# Iniciar servicio MySQL
sudo systemctl start mysql
sudo systemctl enable mysql

# Configurar seguridad (recomendado)
sudo mysql_secure_installation
```

### 3. Crear Base de Datos

Para cargar la estructura de tablas y los datos semilla necesarios para la demostración funcional, ejecute los scripts proporcionados en la carpeta database/:

```bash
# Ejecutar script de creación
mysql -u root -p < 01_creacion_base_datos.sql

# O desde MySQL console:
mysql -u root -p
source 01_creacion_base_datos.sql;
```

## Esquema de la Base de Datos

Para que esta sección cumpla con el estándar de Innovatech Chile, debe reflejar la estructura técnica exacta que has definido en tus scripts y archivos de configuración. Es fundamental que los nombres de las columnas coincidan con los que usas en tu código (como fecha_inicio) para asegurar la trazabilidad.

Aquí tienes cómo debe verse esta parte:

Esquema de la Base de Datos
Tabla Principal: usuarios
Esta tabla centraliza la información de los colaboradores de Innovatech y es consumida por el microservicio de Backend.

### Tabla Principal: `usuarios`

Centraliza la información de los colaboradores. La estructura incluye auditoría automática:

| Columna | Tipo | Nulo | Default | Descripción |
|---------|------|------|---------|-------------|
| `id` | INT AUTO_INCREMENT | No | - | ID único del usuario (PK) |
| `nombre` | VARCHAR(100) | No | - | Nombre completo del usuario |
| `email` | VARCHAR(150) | No | - | Email único del usuario |
| `edad` | INT | Sí | NULL | Edad del usuario (opcional) |
| `fecha_creacion` | TIMESTAMP | No | CURRENT_TIMESTAMP | Fecha de creación |
| `fecha_actualizacion` | TIMESTAMP | No | CURRENT_TIMESTAMP ON UPDATE | Última actualización |
| `estado` | ENUM('activo','inactivo') | No | 'activo' | Estado del usuario |

### Índices

Se han implementado índices estratégicos para garantizar una respuesta rápida en la instancia EC2 de AWS:

- `PRIMARY KEY` en `id` # Para búsquedas directas y relaciones.
- `UNIQUE INDEX` en `email` # Evita duplicidad de cuentas y acelera el login.
- `INDEX` en `nombre` # Optimiza búsquedas por texto.
- `INDEX` en `estado` # Mejora el filtrado de usuarios operativos.
- `INDEX` en `fecha_creacion` # Útil para reportes cronológicos.
- `INDEX COMPUESTO` en `nombre, estado` # Optimiza consultas complejas del Frontend.

### Vistas Disponibles
- `vista_usuarios_activos`: Proporciona datos filtrados listos para el consumo de la API.
- `sp_crear_usuario`: Encapsula la lógica de inserción con manejo de transacciones para evitar datos corruptos

## Comandos Básicos

### Conexión a la Base de Datos
Para interactuar con el contenedor de base de datos desde la terminal de la instancia EC2:

```bash
# Conectar como root
mysql -u root -p

# Conectar a la base de datos específica
mysql -u root -p innovatech_db
```

### Consultas Útiles
Comandos esenciales para validar el despliegue funcional en la subred privada:

```sql
-- Ver todas las tablas
SHOW TABLES;

-- Describir estructura de tabla
DESCRIBE usuarios;

-- Ver todos los usuarios
SELECT * FROM usuarios;

-- Ver usuarios activos
SELECT * FROM vista_usuarios_activos;

-- Ver estadísticas
SELECT * FROM vista_estadisticas_usuarios;
```

## Procedimientos Almacenados
Se han implementado procedimientos almacenados para encapsular la lógica de base de datos, mejorando la seguridad y reduciendo la latencia entre el Backend y la base de datos en la red privada de AWS.

### `sp_obtener_usuario_por_id(id)`
Recupera el perfil completo de un usuario mediante su identificador único.

```sql
CALL sp_obtener_usuario_por_id(1);
```

### `sp_crear_usuario(nombre, email, edad, estado)`
Registra un nuevo usuario en el sistema y devuelve el ID generado. Centraliza la validación de datos antes de la inserción.

```sql
CALL sp_crear_usuario('Nuevo Usuario', 'nuevo@ejemplo.com', 25, 'activo');
```

### `sp_limpiar_usuarios_inactivos(dias)`
Optimiza el rendimiento del sistema eliminando registros inactivos con una antigüedad superior a los días especificados.

```sql
CALL sp_limpiar_usuarios_inactivos(90);
```

### `sp_actualizar_estadisticas()`
Genera métricas en tiempo real sobre el estado de la plataforma para el consumo del Frontend.

```sql
CALL sp_actualizar_estadisticas();
```

## Backup y Restauración
Para garantizar que la información crítica no se pierda ante fallos en la instancia EC2, se definen los siguientes protocolos de respaldo utilizando mysqldump.

### Backup Completo
Este comando incluye los procedimientos almacenados y disparadores necesarios para la reconstrucción total del sistema.

```bash
# Backup con fecha
mysqldump -u root -p --single-transaction --routines --triggers innovatech_db > backup_$(date +%Y%m%d_%H%M%S).sql

# Backup comprimido
mysqldump -u root -p --single-transaction --routines --triggers innovatech_db | gzip > backup_$(date +%Y%m%d_%H%M%S).sql.gz
```

### Backup Selectivo
Útil para migraciones rápidas o auditorías específicas de datos.

```bash
# Solo datos
mysqldump -u root -p --no-create-info --single-transaction innovatech_db > backup_datos.sql

# Solo estructura
mysqldump -u root -p --no-data --routines --triggers innovatech_db > backup_estructura.sql

# Tabla específica
mysqldump -u root -p --single-transaction innovatech_db usuarios > backup_usuarios.sql
```

### Restauración
Procedimientos para restablecer el servicio ante una pérdida de datos en la infraestructura de AWS.

```bash
# Restaurar backup completo
mysql -u root -p innovatech_db < backup_20240430_120000.sql

# Restaurar desde archivo comprimido
gunzip < backup_20240430_120000.sql.gz | mysql -u root -p innovatech_db
```

## Mantenimiento
La solución no es solo una base de datos, es un entorno mantenible:

- **Auditoría**: Se incluyen Triggers (trg_usuarios_audit_insert) que monitorean cambios en tiempo real, vital para la trazabilidad exigida por Innovatech.

- **Limpieza Proactiva**: El procedimiento sp_mantenimiento_limpiar_inactivos permite purgar datos antiguos, optimizando el uso de disco en el volumen EBS de AWS.

- **Funciones Especializadas**: Como fn_capitalizar_texto, que asegura que la presentación de datos en el Frontend sea profesional y uniforme.

### Optimización Periódica
```sql
-- Optimizar tabla
OPTIMIZE TABLE usuarios;

-- Actualizar estadísticas
ANALYZE TABLE usuarios;

-- Verificar integridad
CHECK TABLE usuarios;
```

### Monitoreo
Consultas críticas para supervisar el rendimiento en la instancia EC2.

```sql
-- Ver tamaño de la base de datos
SELECT 
    table_schema as 'Base de Datos',
    ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Tamaño (MB)'
FROM information_schema.tables
WHERE table_schema = 'innovatech_db'
GROUP BY table_schema;

-- Ver conexiones activas
SHOW PROCESSLIST;

-- Ver estado del servidor
SHOW STATUS;
```

## Puertos Requeridos

### Para funcionamiento en contenedor:
- **Puerto 3306**: Puerto estándar de MySQL para conexiones cliente-servidor

### Explicación de puertos:
- **3306**: Es el puerto por defecto donde MySQL escucha conexiones TCP/IP desde clientes externos

## Configuración de Red
Configuración necesaria para permitir la comunicación segura entre el Frontend y el Backend dentro de la arquitectura de AWS.

### Puertos Requeridos
- **Puerto 3306**: Puerto estándar de MySQL utilizado para la comunicación interna entre el contenedor del Backend y la base de datos.

El puerto 3306 debe estar abierto en el Security Group de la instancia de Base de Datos, permitiendo únicamente el tráfico entrante desde el Security Group de la instancia del Backend (Regla de entrada restringida).

### Acceso Remoto
Siguiendo las buenas prácticas, el Backend no debe usar la cuenta root. Se crea un usuario específico para la aplicación.

```sql
-- Crear usuario para acceso remoto
CREATE USER 'app_user'@'%' IDENTIFIED BY 'contraseña_segura';
GRANT SELECT, INSERT, UPDATE, DELETE ON innovatech_db.* TO 'app_user'@'%';
FLUSH PRIVILEGES;
```

### Configuración de MySQL Server
Ajustes para permitir la escucha de peticiones dentro de la red privada de Docker.

En `/etc/mysql/mysql.conf.d/mysqld.cnf` (Linux) o my.ini (Windows):
```ini
[mysqld]
# Permitir conexiones desde cualquier IP
bind-address = 0.0.0.0

# Puerto personalizado (opcional)
port = 3306

# Configuración de caracteres
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
```

## Variables de Entorno para Aplicaciones
Para garantizar la portabilidad entre entornos de desarrollo y producción (AWS EC2), la conexión se gestiona mediante variables de entorno que deben configurarse en el archivo docker-compose.yml o a través de GitHub Secrets.

| Variable | Descripción | Valor por Defecto |
|----------|-------------|-------------------|
| `DB_HOST` | Host del servidor MySQL | localhost |
| `DB_PORT` | Puerto de MySQL | 3306 |
| `DB_USER` | Usuario de la base de datos | app_user |
| `DB_PASSWORD` | Contraseña del usuario | (tu contraseña) |
| `DB_NAME` | Nombre de la base de datos | innovatech_db |

Las variables DB_PASSWORD y DB_ROOT_PASSWORD no deben declararse en texto plano. Se configuran como GitHub Secrets y se inyectan en el contenedor durante el paso de despliegue del pipeline CI/CD en la rama deploy

## Seguridad

### Variables de Entorno (Secrets)
Para el despliegue vía GitHub Actions en la rama deploy, las credenciales NUNCA se suben al código. Se inyectan mediante secretos:

# Fragmento del docker-compose.yml

```yaml
services:
  db:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: ${DB_ROOT_PASSWORD}
      MYSQL_DATABASE: innovatech_db
      MYSQL_USER: ${DB_USER}
      MYSQL_PASSWORD: ${DB_PASSWORD}
```

### Buenas Prácticas de Innovatech Chile

- **No usar root en producción**: Se deben crear usuarios específicos con privilegios limitados para el Backend.

- **Contraseñas seguras**: Implementar políticas de complejidad y rotación periódica.

- **Acceso limitado (Aislamiento de Red)**: Configurar los Security Groups en AWS para permitir tráfico únicamente desde la instancia del Frontend hacia el puerto 3306.

- **Backups regulares**: Programar tareas automatizadas para asegurar la continuidad operativa (IE2).

- **Auditoría y Logs**: Habilitar el registro de consultas para trazabilidad de errores y accesos no autorizados.

### Configuración SSL (Opcional)
Para proteger la comunicación entre microservicios, se puede requerir el uso de certificados SSL:

```sql
-- Requerir SSL para conexiones
CREATE USER 'secure_user'@'%' IDENTIFIED BY 'contraseña' REQUIRE SSL;
GRANT SELECT, INSERT, UPDATE, DELETE ON innovatech_db.* TO 'secure_user'@'%';
```

## Protocolo de Red
En la infraestructura de AWS, el acceso al puerto 3306 está estrictamente limitado por el Security Group, permitiendo tráfico únicamente desde el contenedor del Backend.

## Troubleshooting
En caso de fallos en la comunicación Front-Back:

- **Verificar Red**: docker network inspect [nombre_red] para asegurar que el host db es visible.

- **Verificar Logs**: docker logs [container_id] para identificar bloqueos de transacciones o errores de privilegios.

- **Integridad**: Ejecutar CALL sp_auditoria_integridad_datos() para detectar registros inconsistentes que puedan romper el Backend.

### Problemas Comunes
Si el Frontend no logra comunicarse con la base de datos, verifique:

#### Error de conexión
```bash
# Verificar que MySQL está corriendo
sudo systemctl status mysql

# Verificar puerto
netstat -tlnp | grep 3306

# Revisar logs
sudo tail -f /var/log/mysql/error.log
```

#### Error de permisos
Si la aplicación recibe un error de "Access Denied":

```sql
-- Verificar permisos del usuario
SHOW GRANTS FOR 'app_user'@'%';

-- Otorgar permisos necesarios
GRANT ALL PRIVILEGES ON innovatech_db.* TO 'app_user'@'%';
FLUSH PRIVILEGES;
```

#### Problemas con caracteres
Para asegurar que los nombres y datos se visualicen correctamente en el Frontend:

```sql
-- Verificar configuración de caracteres
SHOW VARIABLES LIKE 'character_set%';
SHOW VARIABLES LIKE 'collation%';
```