# Traccarocra - Documentación de Deployment

Este documento describe la infraestructura y configuración del proyecto **Traccarocra** desplegado en el servidor compartido de COAL.

## Resumen Ejecutivo

| Concepto | Valor |
|----------|-------|
| **Proyecto** | Traccarocra (Traccar GPS Tracking Server) |
| **Versión** | 6.10.0 |
| **Servidor** | 45.190.180.78 (coallinux1) |
| **Fecha Deploy** | 26 Nov 2025 |
| **Arquitectura** | Docker + Nginx Central |

---

## URLs de Acceso

| Ambiente | URL | Estado |
|----------|-----|--------|
| **Desarrollo** | https://dev-avl.ocraplus.coal.mx | Activo |
| **Producción** | https://avl.ocraplus.coal.mx | Activo |

### API Endpoint
```bash
# Verificar estado del servidor
curl https://dev-avl.ocraplus.coal.mx/api/server
curl https://avl.ocraplus.coal.mx/api/server
```

---

## Puertos GPS

### Desarrollo (5001-5016)

| Puerto | Protocolo | Dispositivos Compatibles |
|--------|-----------|--------------------------|
| 5001 | gps103 | Coban TK103, GPS103 |
| 5002 | tk103 | TK103B, TK104, TK106 |
| 5003 | gt06 | Concox GT06N, GT06E, JM01 |
| 5004 | h02 | Sinotrack ST-901, ST-906 |
| 5005 | teltonika | Teltonika FMB120, FMB920, FMB140 |
| 5006 | gl200 | Queclink GL200, GL300, GV55 |
| 5007 | watch | Relojes GPS para niños |
| 5008 | suntech | Suntech ST300, ST310, ST340 |
| 5009 | t55 | Dispositivos T55 genéricos |
| 5010 | meitrack | Meitrack T1, T333, MVT600 |
| 5011 | ruptela | Ruptela FM-Eco4, FM-Pro4 |
| 5012 | atrack | ATrack AK1, AK7, AX5 |
| 5013 | wialon | Protocolo Wialon IPS |
| 5014 | huabao | JT/T 808 (estándar chino) |
| 5015 | jt600 | JT600, JT700, JT800 |
| 5016 | osmand | **Traccar Client App** (Android/iOS) |

### Producción (5101-5116)

Mismos protocolos que desarrollo, pero en rango +100:
- gps103: 5101
- tk103: 5102
- ...
- osmand: 5116

### Puertos UDP
Algunos protocolos usan UDP además de TCP:
- **5001/5003/5005** (dev) - UDP
- **5101/5103/5105** (prod) - UDP

---

## Contenedores Docker

### Contenedores Activos

| Contenedor | Imagen | Estado | Puertos |
|------------|--------|--------|---------|
| `traccarocra_postgres` | postgres:17-alpine | Healthy | 127.0.0.1:5436→5432 |
| `traccarocra_dev_app` | traccarocra:develop | Healthy | 5001-5016 (TCP/UDP) |
| `traccarocra_prod_app` | traccarocra:production | Healthy | 5101-5116 (TCP/UDP) |

### Verificar Estado
```bash
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' | grep traccarocra
```

---

## Redes Docker

| Red | Tipo | Propósito |
|-----|------|-----------|
| `traccarocra_shared` | bridge | Comunicación PostgreSQL ↔ Traccar |
| `traccarocra_dev` | bridge | Red interna de desarrollo |
| `traccarocra_prod` | bridge | Red interna de producción |
| `webproxy` | bridge | Conexión con Nginx Central (obligatoria) |

### Verificar Redes
```bash
docker network ls | grep traccarocra
```

---

## Estructura de Archivos en Servidor

```
/home/coallinux1/docker/traccarocra/
├── Dockerfile                      # Multi-stage build (Java + React)
├── shared/
│   ├── docker-compose.yml          # PostgreSQL 17
│   ├── .env                        # COMPOSE_PROJECT_NAME=traccarocra-shared
│   └── postgres/
│       ├── init/                   # Scripts de inicialización
│       └── data/                   # Datos persistentes (NO TOCAR)
├── develop/
│   ├── docker-compose.yml          # Traccar desarrollo
│   ├── Dockerfile                  # Copia del Dockerfile raíz
│   ├── .env                        # COMPOSE_PROJECT_NAME=traccarocra-dev
│   ├── conf/
│   │   └── traccar.xml             # Configuración Traccar (puertos 5001-5016)
│   ├── data/                       # Datos persistentes
│   ├── logs/                       # Logs de aplicación
│   └── apps/
│       └── traccar/                # Código fuente (branch develop)
├── production/
│   ├── docker-compose.yml          # Traccar producción
│   ├── Dockerfile                  # Copia del Dockerfile raíz
│   ├── .env                        # COMPOSE_PROJECT_NAME=traccarocra-prod
│   ├── conf/
│   │   └── traccar.xml             # Configuración Traccar (puertos 5101-5116)
│   ├── data/                       # Datos persistentes
│   ├── logs/                       # Logs de aplicación
│   └── apps/
│       └── traccar/                # Código fuente (branch master)
├── scripts/
│   ├── deploy-develop.sh           # Script de deploy desarrollo
│   ├── deploy-production.sh        # Script de deploy producción
│   ├── backup-develop.sh           # Backup desarrollo
│   ├── backup-production.sh        # Backup producción
│   ├── start-all.sh                # Iniciar todos los servicios
│   └── stop-all.sh                 # Detener todos los servicios
├── nginx/
│   ├── traccarocra.conf            # Config HTTPS final
│   ├── traccarocra-http.conf       # Config HTTP (temporal)
│   └── traccarocra-dev-https.conf  # Config solo desarrollo
└── backups/
    ├── develop/                    # Backups de desarrollo
    └── production/                 # Backups de producción
```

---

## Base de Datos

### PostgreSQL

| Parámetro | Valor |
|-----------|-------|
| **Host** | traccarocra_postgres |
| **Puerto interno** | 5432 |
| **Puerto externo** | 5436 (127.0.0.1 only) |
| **Usuario** | postgres |
| **Password** | Ver `/home/coallinux1/docker/traccarocra/shared/.env` |
| **DB Desarrollo** | traccarocra_dev |
| **DB Producción** | traccarocra_prod |

### Conexión desde contenedor
```bash
docker exec -it traccarocra_postgres psql -U postgres -d traccarocra_dev
```

### Tablas principales
- `tc_positions` - Posiciones GPS
- `tc_devices` - Dispositivos registrados
- `tc_users` - Usuarios del sistema
- `tc_events` - Eventos y alertas
- `tc_geofences` - Geocercas

---

## Nginx Central

### Ubicación de configuración
```
/home/coallinux1/docker/nginx-central/nginx/sites-enabled/traccarocra.conf
```

### Recargar configuración
```bash
docker exec nginx_central nginx -t && docker exec nginx_central nginx -s reload
```

---

## SSL Certificates

### Certificados Let's Encrypt

| Dominio | Vencimiento |
|---------|-------------|
| dev-avl.ocraplus.coal.mx | 24 Feb 2026 |
| avl.ocraplus.coal.mx | 24 Feb 2026 |

### Ubicación
```
/home/coallinux1/docker/nginx-central/ssl/certbot/conf/live/
├── dev-avl.ocraplus.coal.mx/
│   ├── fullchain.pem
│   └── privkey.pem
└── avl.ocraplus.coal.mx/
    ├── fullchain.pem
    └── privkey.pem
```

### Renovar certificados
```bash
docker run --rm \
  -v /home/coallinux1/docker/nginx-central/ssl/certbot/conf:/etc/letsencrypt \
  -v /home/coallinux1/docker/nginx-central/ssl/certbot/www:/var/www/certbot \
  certbot/certbot renew
```

---

## Comandos de Operación

### Deploy

```bash
# Desarrollo
/home/coallinux1/docker/traccarocra/scripts/deploy-develop.sh

# Producción
/home/coallinux1/docker/traccarocra/scripts/deploy-production.sh
```

### Backup

```bash
# Desarrollo (retención: 7 días)
/home/coallinux1/docker/traccarocra/scripts/backup-develop.sh

# Producción (retención: 30 días)
/home/coallinux1/docker/traccarocra/scripts/backup-production.sh
```

### Logs

```bash
# Ver logs en tiempo real
docker logs -f traccarocra_dev_app
docker logs -f traccarocra_prod_app

# Últimas 100 líneas
docker logs --tail 100 traccarocra_dev_app
```

### Reiniciar servicios

```bash
# Desarrollo
cd /home/coallinux1/docker/traccarocra/develop
COMPOSE_PROJECT_NAME=traccarocra-dev docker-compose restart

# Producción
cd /home/coallinux1/docker/traccarocra/production
COMPOSE_PROJECT_NAME=traccarocra-prod docker-compose restart
```

---

## Configurar un Dispositivo GPS

### Usando Traccar Client App (Recomendado para pruebas)

1. Descargar **Traccar Client** desde Play Store / App Store
2. Configurar:
   - **Device identifier**: Un ID único (ej: `ABC123`)
   - **Server URL**: `https://avl.ocraplus.coal.mx` (o dev)
   - **Location accuracy**: High
   - **Frequency**: 60 segundos

### Configurar GPS físico

1. Acceder a la interfaz web: https://avl.ocraplus.coal.mx
2. Crear usuario administrador (primera vez)
3. Agregar dispositivo con el identificador único
4. Configurar el GPS para enviar datos a:
   - **IP**: 45.190.180.78
   - **Puerto**: Según protocolo (ver tabla de puertos)

---

## Troubleshooting

### El contenedor no inicia

```bash
# Ver logs de error
docker logs traccarocra_dev_app

# Causas comunes:
# - /opt/traccar/web no existe → Dockerfile incorrecto
# - Database connection refused → PostgreSQL no está corriendo
```

### No puedo acceder a la URL

```bash
# Verificar nginx
docker exec nginx_central nginx -t

# Verificar que el contenedor esté en webproxy
docker network inspect webproxy | grep traccarocra

# Conectar manualmente si falta
docker network connect webproxy traccarocra_dev_app
```

### GPS no conecta

```bash
# Verificar que el puerto está escuchando
netstat -tlnp | grep 5001

# Verificar logs del protocolo específico
docker logs traccarocra_dev_app 2>&1 | grep -i "gps103"
```

### Certificado SSL expirado

```bash
# Verificar vencimiento
docker run --rm \
  -v /home/coallinux1/docker/nginx-central/ssl/certbot/conf:/etc/letsencrypt \
  certbot/certbot certificates

# Renovar
docker run --rm \
  -v /home/coallinux1/docker/nginx-central/ssl/certbot/conf:/etc/letsencrypt \
  -v /home/coallinux1/docker/nginx-central/ssl/certbot/www:/var/www/certbot \
  certbot/certbot renew

# Recargar nginx
docker exec nginx_central nginx -s reload
```

---

## Contacto

- **Proyecto**: Traccarocra
- **Organización**: COAL
- **Email técnico**: edwin.cruz@coal.com.mx
- **Servidor**: coallinux1@45.190.180.78
