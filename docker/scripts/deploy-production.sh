#!/bin/bash
# =============================================================================
# Traccarocra - Script de Deploy PRODUCCION
# =============================================================================
set -e

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}[Traccarocra] Deploy - PRODUCCION${NC}"
echo -e "${GREEN}=============================================${NC}"

# Configuración
BASE_DIR="/home/coallinux1/docker/traccarocra"
PROD_DIR="$BASE_DIR/production"
APP_DIR="$PROD_DIR/apps/traccar"
SHARED_DIR="$BASE_DIR/shared"

# CRITICO: COMPOSE_PROJECT_NAME único
export COMPOSE_PROJECT_NAME=traccarocra-prod

# -----------------------------------------------------------------------------
# 1. Verificar que PostgreSQL está corriendo
# -----------------------------------------------------------------------------
echo -e "\n${YELLOW}[1/5] Verificando PostgreSQL...${NC}"
if ! docker ps | grep -q traccarocra_postgres; then
    echo -e "${YELLOW}PostgreSQL no está corriendo. Iniciando...${NC}"
    cd "$SHARED_DIR"
    COMPOSE_PROJECT_NAME=traccarocra-shared docker-compose up -d
    sleep 10
fi
echo -e "${GREEN}✓ PostgreSQL OK${NC}"

# -----------------------------------------------------------------------------
# 2. Actualizar código fuente
# -----------------------------------------------------------------------------
echo -e "\n${YELLOW}[2/5] Actualizando código fuente...${NC}"
cd "$APP_DIR"
git fetch origin
git checkout master
git pull origin master
echo -e "${GREEN}✓ Código actualizado${NC}"

# -----------------------------------------------------------------------------
# 3. Rebuild y reiniciar contenedor
# -----------------------------------------------------------------------------
echo -e "\n${YELLOW}[3/5] Construyendo y reiniciando contenedor...${NC}"
cd "$PROD_DIR"
docker-compose up -d --build
echo -e "${GREEN}✓ Contenedor reiniciado${NC}"

# -----------------------------------------------------------------------------
# 4. Conectar a red webproxy
# -----------------------------------------------------------------------------
echo -e "\n${YELLOW}[4/5] Verificando conexión a webproxy...${NC}"
docker network connect webproxy traccarocra_prod_app 2>/dev/null || echo "Ya conectado a webproxy"
echo -e "${GREEN}✓ Conexión a webproxy OK${NC}"

# -----------------------------------------------------------------------------
# 5. Health check
# -----------------------------------------------------------------------------
echo -e "\n${YELLOW}[5/5] Esperando que el servicio esté listo (120s máx)...${NC}"
sleep 30

MAX_ATTEMPTS=6
ATTEMPT=1
while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
    if curl -sf http://localhost:8082/api/server > /dev/null 2>&1; then
        echo -e "\n${GREEN}=============================================${NC}"
        echo -e "${GREEN}✓ Traccar PRODUCCION desplegado exitosamente${NC}"
        echo -e "${GREEN}=============================================${NC}"
        echo -e "URL: https://avl.ocraplus.coal.mx"
        echo -e "Puertos GPS: 5101-5116"
        exit 0
    fi
    echo "Intento $ATTEMPT/$MAX_ATTEMPTS - Esperando 15s..."
    sleep 15
    ATTEMPT=$((ATTEMPT + 1))
done

echo -e "\n${RED}=============================================${NC}"
echo -e "${RED}✗ El servicio no respondió después de 120 segundos${NC}"
echo -e "${RED}=============================================${NC}"
echo -e "Revisar logs: docker logs traccarocra_prod_app"
exit 1
