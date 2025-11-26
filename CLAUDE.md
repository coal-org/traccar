# CLAUDE.md - Traccar GPS Tracking Server

## Project Overview

**Traccar** is an open-source GPS tracking server supporting 200+ GPS protocols and 2000+ device models. This is a production-grade Java application with an integrated React web frontend.

- **Version**: 6.10.0
- **License**: Apache License 2.0
- **Architecture**: Monolithic with embedded web server

## Technology Stack

### Backend (Java 17)
- **Build System**: Gradle 9.1.0
- **DI Framework**: Google Guice 7.0.0
- **Web Server**: Jetty 12.1.1 + Jersey 3.1.11 (REST API)
- **Network I/O**: Netty 4.2.6 (protocol handling)
- **Database**: HikariCP + Liquibase (supports H2, MySQL, MariaDB, PostgreSQL, MSSQL)
- **Serialization**: Jackson with Blackbird performance module

### Frontend (React)
- **Build Tool**: Vite 7.1.6
- **UI Library**: Material-UI 7.3.2
- **Mapping**: MapLibre GL 5.7.3
- **State**: Redux Toolkit 2.9.0

## Development Commands

### Backend Development

```bash
# Build the project
./gradlew assemble

# Run all tests
./gradlew test

# Full build (compile + test + package)
./gradlew build

# Run the server (requires config file)
java -jar target/traccar-6.10.0.jar debug.xml

# Code quality check
./gradlew checkstyleMain
```

### Frontend Development

```bash
cd traccar-web

# Install dependencies
npm install

# Development server with hot reload
npm run start

# Production build
npm run build
```

## Inicialización del Proyecto (Desarrollo Local)

Cuando el usuario solicite **"Inicializa el proyecto"**, ejecutar los siguientes pasos en orden:

### Arquitectura de Desarrollo

```
┌─────────────────────────────────────────────────────────────┐
│   localhost:3000 (Vite Dev Server) ← USAR PARA DESARROLLO  │
│   ├── Frontend React con Hot-Reload                        │
│   └── Proxy automático a backend:                          │
│       /api/*       → localhost:8082                        │
│       /api/socket  → localhost:8082 (WebSocket)            │
│                                                             │
│   localhost:8082 (Java Backend)                            │
│   ├── REST API (/api/*)                                    │
│   ├── WebSocket (/api/socket)                              │
│   └── Protocolos GPS (5001-5016)                           │
└─────────────────────────────────────────────────────────────┘
```

### Instrucciones para Claude Code

#### Paso 1: SSH Tunnel a PostgreSQL (Background)
```bash
# Leer credenciales de .env
# Ejecutar en background con run_in_background=true

while true; do
  export SSHPASS="<PASSWORD_FROM_ENV>" && sshpass -e ssh -N \
    -o StrictHostKeyChecking=no \
    -o ServerAliveInterval=30 \
    -o ServerAliveCountMax=3 \
    -o ExitOnForwardFailure=yes \
    -o TCPKeepAlive=yes \
    -L 5439:127.0.0.1:5436 coallinux1@45.190.180.78
  echo "PostgreSQL tunnel disconnected. Reconnecting in 2 seconds..."
  sleep 2
done
```

**Conexión local**: `localhost:5439` → PostgreSQL remoto (traccarocra_postgres:5436)
**Base de datos**: `traccarocra_dev`

#### Paso 2: Compilar Backend
```bash
./gradlew assemble
```

#### Paso 3: Instalar dependencias del Frontend
```bash
cd traccar-web && npm install && cd ..
```

#### Paso 4: Iniciar Backend (Background)
```bash
# Ejecutar en background con run_in_background=true
java -jar target/tracker-server.jar debug-local.xml
```

**Backend API en**: `http://localhost:8082`

#### Paso 5: Iniciar Frontend Dev Server (Background)
```bash
# Ejecutar en background con run_in_background=true
cd traccar-web && npm run start
```

**Frontend con Hot-Reload en**: `http://localhost:3000`

### Verificación Final

Confirmar que los 4 servicios están activos:
1. **SSH Tunnel**: `lsof -i :5439` debe mostrar conexión activa
2. **Backend API**: `curl -s http://localhost:8082/api/server | python3 -m json.tool`
3. **Frontend Dev**: `curl -s http://localhost:3000` debe responder
4. **Abrir navegador**: `http://localhost:3000` (NO usar 8082 para desarrollo)

### Archivos de Configuración

| Archivo | Propósito |
|---------|-----------|
| `debug-local.xml` | Config desarrollo local (PostgreSQL via tunnel) |
| `debug.xml` | Config original (MySQL externo - NO USAR) |
| `.env` | Credenciales SSH |

### Notas Importantes

- **No afecta ambientes remotos**: `debug-local.xml` es independiente de las configuraciones en el servidor
- **Base de datos compartida**: El desarrollo local usa `traccarocra_dev` (misma BD que dev-avl.ocraplus.coal.mx)
- **Puertos GPS locales**: 5001-5016 (mismos que desarrollo remoto)

### Lecciones Aprendidas (Desarrollo Local)

1. **Directorio de trabajo CRÍTICO**: El backend DEBE ejecutarse desde la raíz del proyecto (`/Users/edwin/code/traccar`). Si se ejecuta desde otro directorio (ej: `traccar-web`), Liquibase falla con:
   ```
   The file ./schema/changelog-master.xml was not found
   ```

2. **Niveles de logger**: Traccar usa niveles de Java logging, NO usar `debug`. Valores válidos:
   - `all` (más verbose)
   - `info`
   - `warn`
   - `error`

3. **Orden de compilación**: Siempre compilar el frontend (`npm run build`) ANTES de iniciar el backend si se quiere servir el frontend compilado desde el backend.

4. **Limpieza de node_modules**: Si `npm run build` falla con errores de binarios corruptos (rollup, esbuild), limpiar completamente:
   ```bash
   rm -rf node_modules package-lock.json && npm install
   ```

5. **Desarrollo con Hot-Reload**: Para cambios en el frontend, siempre usar `http://localhost:3000` (Vite dev server) en lugar de `:8082`. Los cambios en React/CSS se reflejan instantáneamente sin recompilar. El puerto 8082 solo debe usarse para testing final o desarrollo exclusivo de backend.

## Project Structure

```
traccar/
├── src/main/java/org/traccar/
│   ├── Main.java              # Entry point
│   ├── MainModule.java        # Guice DI configuration
│   ├── protocol/              # 200+ GPS protocol implementations
│   ├── api/resource/          # REST API endpoints
│   ├── model/                 # Data models (Position, Device, User, etc.)
│   ├── handler/               # Event processing pipeline
│   ├── storage/               # Persistence layer
│   ├── config/Keys.java       # All configuration options (500+)
│   ├── geocoder/              # 27 geocoding providers
│   └── helper/                # Utility classes
│
├── src/test/java/org/traccar/
│   └── protocol/              # 373+ protocol tests
│
├── schema/                    # Liquibase database migrations
├── templates/                 # Email & report templates
├── docker/                    # Dockerfile variants
├── traccar-web/               # React frontend
├── debug.xml                  # Development configuration
├── openapi.yaml               # API documentation
└── build.gradle               # Build configuration
```

## Key Entry Points

| File | Purpose |
|------|---------|
| `src/main/java/org/traccar/Main.java` | Application entry point |
| `src/main/java/org/traccar/MainModule.java` | Dependency injection setup |
| `src/main/java/org/traccar/config/Keys.java` | All configuration keys |
| `src/main/java/org/traccar/protocol/` | Protocol implementations |
| `src/main/java/org/traccar/api/resource/` | REST API endpoints |

## Architecture Patterns

### Protocol Implementation Pattern

Each GPS protocol follows this structure:
```
protocol/
├── ProtocolName.java                    # Protocol registration
├── ProtocolNameProtocolDecoder.java     # Message parsing
├── ProtocolNameProtocolEncoder.java     # Command encoding
└── ProtocolNameFrameDecoder.java        # Frame boundary detection
```

Base classes:
- `BaseProtocol` - Protocol registration
- `BaseProtocolDecoder` - Message decoding
- `BaseProtocolEncoder` - Command encoding

### Handler Pipeline

Event processing follows a chain pattern in `handler/`:
1. `FilterHandler` - Apply filters
2. `GeocoderHandler` - Reverse geocoding
3. `DistanceHandler` - Calculate distance
4. `GeofenceHandler` - Geofence detection
5. `MotionHandler` - Motion detection
6. `DatabaseHandler` - Persist to database
7. `PositionForwardingHandler` - Forward to external systems

### Storage Layer

- `Storage` interface - Abstract query API
- `DatabaseStorage` - SQL implementation with HikariCP
- `QueryBuilder` - Dynamic SQL generation

## Configuration

Configuration uses XML format. Key file: `debug.xml`

### Common Configuration Keys

```xml
<!-- Web Server -->
<entry key='web.port'>8082</entry>
<entry key='web.address'>0.0.0.0</entry>

<!-- Database -->
<entry key='database.driver'>com.mysql.cj.jdbc.Driver</entry>
<entry key='database.url'>jdbc:mysql://localhost/traccar</entry>

<!-- Logging -->
<entry key='logger.console'>true</entry>
<entry key='logger.level'>debug</entry>

<!-- Protocol ports (example: GPS103) -->
<entry key='gps103.port'>5001</entry>
```

Full configuration reference: `src/main/java/org/traccar/config/Keys.java`

## Database Schema

Managed via Liquibase migrations in `schema/`.

### Core Tables
- `tc_positions` - GPS location data
- `tc_devices` - Tracked devices
- `tc_users` - User accounts
- `tc_events` - System events
- `tc_commands` - Device commands
- `tc_geofences` - Geo-fence areas
- `tc_notifications` - Alert rules

## REST API

**Base Path**: `/api/*`

**Documentation**: `openapi.yaml`

### Main Endpoints
| Endpoint | Purpose |
|----------|---------|
| `/api/session` | Authentication |
| `/api/devices` | Device management |
| `/api/positions` | GPS locations |
| `/api/commands` | Device commands |
| `/api/users` | User management |
| `/api/reports` | Generate reports |
| `/api/geofences` | Geo-fence management |

**Default Port**: 8082

## Testing

### Framework
- JUnit 5 (Jupiter)
- 409 test files total
- 373+ protocol decoder tests

### Running Tests

```bash
# All tests
./gradlew test

# Specific test class
./gradlew test --tests "org.traccar.protocol.Gt06ProtocolDecoderTest"
```

### Protocol Test Pattern

```java
public class ExampleProtocolDecoderTest extends ProtocolTest {
    @Test
    public void testDecode() throws Exception {
        var decoder = inject(new ExampleProtocolDecoder(null));

        verifyPosition(decoder, binary(
            "78780d010123456789012345..."
        ));
    }
}
```

## Adding a New Protocol

1. Create protocol class extending `BaseProtocol`
2. Create decoder extending `BaseProtocolDecoder`
3. Create encoder extending `BaseProtocolEncoder` (if needed)
4. Create frame decoder if using custom framing
5. Register protocol in `META-INF/services/org.traccar.Protocol`
6. Add configuration key in `Keys.java`
7. Create test class with sample data

## Docker Deployment (COAL Server)

Este proyecto está configurado para despliegue en el servidor compartido de COAL usando arquitectura de **Nginx Central**.

### Instrucciones para Claude Code

Cuando el usuario solicite **"haz un deploy en desarrollo"** o **"haz un deploy en producción"**, seguir estos pasos:

#### Deploy en DESARROLLO
```bash
# 1. Leer credenciales SSH del archivo .env en la raíz del proyecto
# SSH_SERVER=coallinux1@45.190.180.78
# SSH_PASSWORD=<ver .env>

# 2. Ejecutar script de deploy
sshpass -p '<PASSWORD>' ssh -o StrictHostKeyChecking=no coallinux1@45.190.180.78 \
  "/home/coallinux1/docker/traccarocra/scripts/deploy-develop.sh"

# 3. Verificar que el servicio responde
curl -s https://dev-avl.ocraplus.coal.mx/api/server | python3 -m json.tool
```

#### Deploy en PRODUCCIÓN
```bash
# 1. Leer credenciales SSH del archivo .env en la raíz del proyecto

# 2. Ejecutar script de deploy
sshpass -p '<PASSWORD>' ssh -o StrictHostKeyChecking=no coallinux1@45.190.180.78 \
  "/home/coallinux1/docker/traccarocra/scripts/deploy-production.sh"

# 3. Verificar que el servicio responde
curl -s https://avl.ocraplus.coal.mx/api/server | python3 -m json.tool
```

#### Sincronizar cambios locales antes del deploy
Si se modificaron archivos en `docker/`, sincronizar primero:
```bash
sshpass -p '<PASSWORD>' rsync -avz --exclude='data/' --exclude='logs/' --exclude='apps/' \
  docker/ coallinux1@45.190.180.78:/home/coallinux1/docker/traccarocra/
```

### Lecciones Aprendidas del Deploy Inicial

1. **Puerto PostgreSQL**: El servidor tiene múltiples instancias de PostgreSQL. Siempre verificar puertos disponibles con `docker ps | grep postgres`. El proyecto usa puerto **5436**.

2. **Dockerfile con Frontend**: El Dockerfile DEBE incluir el stage de frontend (traccar-web) o el servidor crasheará con `NoSuchFileException: /opt/traccar/web`. El Dockerfile correcto tiene 3 stages: builder (Java), frontend-builder (React), y runtime.

3. **COMPOSE_PROJECT_NAME**: Es CRÍTICO que cada ambiente tenga un nombre único. Sin esto, los contenedores se sobrescriben entre ambientes.

4. **Red webproxy**: Los contenedores DEBEN estar conectados a la red `webproxy` para que nginx_central pueda enrutarlos. El docker-compose ya lo configura, pero si falla, conectar manualmente:
   ```bash
   docker network connect webproxy traccarocra_dev_app
   docker network connect webproxy traccarocra_prod_app
   ```

5. **Conflictos de puertos GPS**: Los warnings de "Port disabled due to conflict" son normales dentro del contenedor y no afectan la funcionalidad. Los puertos importantes son los expuestos al host (5001-5016 dev, 5101-5116 prod).

6. **SSL Certificates**: Los certificados se generan con certbot_central. Si expiran, regenerar:
   ```bash
   docker run --rm \
     -v /home/coallinux1/docker/nginx-central/ssl/certbot/conf:/etc/letsencrypt \
     -v /home/coallinux1/docker/nginx-central/ssl/certbot/www:/var/www/certbot \
     certbot/certbot certonly --webroot \
     --webroot-path=/var/www/certbot \
     --email edwin.cruz@coal.com.mx \
     --agree-tos --no-eff-email \
     -d dev-avl.ocraplus.coal.mx
   ```

7. **Servidor compartido**: NUNCA borrar ni modificar contenedores/redes que no sean de traccarocra. Verificar antes de cualquier operación destructiva.

### URLs

| Ambiente | URL | Puertos GPS |
|----------|-----|-------------|
| Desarrollo | `https://dev-avl.ocraplus.coal.mx` | 5001-5016 |
| Producción | `https://avl.ocraplus.coal.mx` | 5101-5116 |

### Estructura Docker

```
docker/
├── Dockerfile                 # Multi-stage build desde código fuente
├── shared/                    # PostgreSQL compartido
│   ├── docker-compose.yml
│   └── postgres/init/
├── develop/                   # Ambiente desarrollo
│   ├── docker-compose.yml
│   └── conf/traccar.xml
├── production/                # Ambiente producción
│   ├── docker-compose.yml
│   └── conf/traccar.xml
├── scripts/                   # Scripts de deploy y backup
└── nginx/                     # Configuración nginx central
```

### COMPOSE_PROJECT_NAME (CRÍTICO)

Cada ambiente DEBE tener nombre único:
```bash
# Shared (PostgreSQL)
COMPOSE_PROJECT_NAME=traccarocra-shared

# Desarrollo
COMPOSE_PROJECT_NAME=traccarocra-dev

# Producción
COMPOSE_PROJECT_NAME=traccarocra-prod
```

### Comandos de Deploy

```bash
# Desarrollo
sshpass -p "PASSWORD" ssh coallinux1@45.190.180.78 \
  "/home/coallinux1/docker/traccarocra/scripts/deploy-develop.sh"

# Producción
sshpass -p "PASSWORD" ssh coallinux1@45.190.180.78 \
  "/home/coallinux1/docker/traccarocra/scripts/deploy-production.sh"
```

### Protocolos GPS Habilitados (16)

| Puerto Dev | Puerto Prod | Protocolo | Dispositivos |
|------------|-------------|-----------|--------------|
| 5001 | 5101 | gps103 | Coban TK103 |
| 5002 | 5102 | tk103 | TK103B |
| 5003 | 5103 | gt06 | Concox GT06 |
| 5004 | 5104 | h02 | Sinotrack ST-901 |
| 5005 | 5105 | teltonika | Teltonika FMB |
| 5006 | 5106 | gl200 | Queclink |
| 5007 | 5107 | watch | Relojes GPS |
| 5008 | 5108 | suntech | Suntech |
| 5009 | 5109 | t55 | T55 genéricos |
| 5010 | 5110 | meitrack | Meitrack |
| 5011 | 5111 | ruptela | Ruptela |
| 5012 | 5112 | atrack | Atrack |
| 5013 | 5113 | wialon | Wialon IPS |
| 5014 | 5114 | huabao | JT/T 808 |
| 5015 | 5115 | jt600 | JT600 |
| 5016 | 5116 | osmand | Traccar Client App |

### Redes Docker

| Red | Propósito |
|-----|-----------|
| `traccarocra_shared` | PostgreSQL ↔ Traccar |
| `traccarocra_dev` | Red interna desarrollo |
| `traccarocra_prod` | Red interna producción |
| `webproxy` | Nginx central (obligatoria) |

### Flujo de Trabajo

**NUNCA editar docker-compose directamente en servidor**:

```bash
# 1. Editar localmente
nano docker/develop/docker-compose.yml

# 2. Versionar
git add docker/ && git commit -m "..." && git push

# 3. Sincronizar al servidor
rsync -avz --exclude='data/' --exclude='logs/' \
  docker/ coallinux1@45.190.180.78:/home/coallinux1/docker/traccarocra/

# 4. Ejecutar deploy
ssh coallinux1@45.190.180.78 "/home/coallinux1/docker/traccarocra/scripts/deploy-develop.sh"
```

### Dockerfiles Originales (Traccar Oficial)

Available Dockerfiles: Alpine, Debian, Ubuntu
```bash
docker build -t traccar -f docker/Dockerfile.alpine .
docker-compose -f docker/compose/traccar-mysql.yaml up
```

## Integrations

- **Geocoders**: Google, OpenStreetMap, Nominatim, Bing, etc. (27 providers)
- **SMS**: HTTP API, AWS SNS
- **Messaging**: MQTT, Kafka, RabbitMQ, AMQP
- **Auth**: LDAP, OpenID Connect
- **Storage**: Forward to external systems via HTTP, MQTT, Kafka

## Development Tips

### Debugging Protocols

1. Enable protocol logging in `debug.xml`:
   ```xml
   <entry key='logger.level'>all</entry>
   ```

2. Use Netty's logging handler for raw data inspection

3. Test with protocol-specific test files in `src/test/`

### Common Issues

- **Port conflicts**: Each protocol needs a unique port
- **Database connections**: Check HikariCP pool settings
- **Memory**: Adjust JVM heap for large deployments

### Code Style

Uses Checkstyle with `gradle/checkstyle.xml`. Run `./gradlew checkstyleMain` before committing.

## Useful Links

- [Official Documentation](https://www.traccar.org/documentation/)
- [Protocol List](https://www.traccar.org/devices/)
- [API Reference](https://www.traccar.org/api-reference/)
