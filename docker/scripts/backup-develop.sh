#!/bin/bash
# =============================================================================
# Traccarocra - Script de Backup DESARROLLO
# =============================================================================
set -e

# Configuración
DATE=$(date +%Y%m%d_%H%M%S)
PROJECT="traccarocra"
ENV="develop"
BASE_DIR="/home/coallinux1/docker/$PROJECT"
BACKUP_DIR="$BASE_DIR/backups/$ENV"
RETENTION_DAYS=7

# Crear directorio de backups si no existe
mkdir -p "$BACKUP_DIR"

echo "============================================="
echo "[Traccarocra] Backup DESARROLLO - $DATE"
echo "============================================="

# -----------------------------------------------------------------------------
# 1. Backup de base de datos
# -----------------------------------------------------------------------------
echo "[1/2] Respaldando base de datos..."
DB_BACKUP="$BACKUP_DIR/db-${ENV}-${DATE}.sql"
docker exec ${PROJECT}_postgres pg_dump -U postgres -d ${PROJECT}_dev > "$DB_BACKUP"
gzip "$DB_BACKUP"
echo "✓ Base de datos respaldada: ${DB_BACKUP}.gz"

# -----------------------------------------------------------------------------
# 2. Backup de datos de Traccar
# -----------------------------------------------------------------------------
echo "[2/2] Respaldando datos de Traccar..."
DATA_BACKUP="$BACKUP_DIR/data-${ENV}-${DATE}.tar.gz"
tar -czf "$DATA_BACKUP" \
    -C "$BASE_DIR/$ENV" \
    --exclude='logs/*.log' \
    data/ conf/
echo "✓ Datos respaldados: $DATA_BACKUP"

# -----------------------------------------------------------------------------
# 3. Limpieza de backups antiguos
# -----------------------------------------------------------------------------
echo "Limpiando backups mayores a $RETENTION_DAYS días..."
find "$BACKUP_DIR" -name "*.gz" -mtime +$RETENTION_DAYS -delete
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +$RETENTION_DAYS -delete

echo "============================================="
echo "✓ Backup desarrollo completado: $DATE"
echo "============================================="
