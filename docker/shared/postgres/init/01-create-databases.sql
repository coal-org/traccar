-- =============================================================================
-- Traccarocra - Script de inicialización de bases de datos
-- =============================================================================
-- Este script se ejecuta automáticamente cuando el contenedor PostgreSQL
-- se inicia por primera vez.
-- =============================================================================

-- Crear base de datos para desarrollo
CREATE DATABASE traccarocra_dev
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.utf8'
    LC_CTYPE = 'en_US.utf8'
    TEMPLATE = template0;

-- Crear base de datos para producción
CREATE DATABASE traccarocra_prod
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.utf8'
    LC_CTYPE = 'en_US.utf8'
    TEMPLATE = template0;

-- Mensaje de confirmación
\echo '============================================='
\echo 'Bases de datos creadas exitosamente:'
\echo '  - traccarocra_dev (desarrollo)'
\echo '  - traccarocra_prod (produccion)'
\echo '============================================='
