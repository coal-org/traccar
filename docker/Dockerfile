# =============================================================================
# Traccar GPS Tracking Server - Multi-stage Dockerfile
# Compila backend Java + frontend React desde código fuente
# =============================================================================

# -----------------------------------------------------------------------------
# Stage 1: Build Backend (Java)
# -----------------------------------------------------------------------------
FROM eclipse-temurin:17-jdk AS builder

WORKDIR /build

# Copiar archivos de Gradle primero (para cache de dependencias)
COPY gradlew .
COPY gradle gradle
COPY build.gradle settings.gradle ./

# Dar permisos y descargar dependencias
RUN chmod +x gradlew && ./gradlew dependencies --no-daemon

# Copiar código fuente backend
COPY src src
COPY schema schema
COPY templates templates

# Compilar el backend
RUN ./gradlew assemble --no-daemon

# -----------------------------------------------------------------------------
# Stage 2: Build Frontend (React)
# -----------------------------------------------------------------------------
FROM node:20-alpine AS frontend-builder

WORKDIR /frontend

# Clonar frontend desde repositorio COAL (con personalizaciones OCRA)
RUN apk add --no-cache git && \
    git clone --depth 1 https://github.com/coal-org/traccar-web.git .

# Instalar dependencias y compilar
WORKDIR /frontend/modern
RUN npm ci && npm run build

# -----------------------------------------------------------------------------
# Stage 3: Runtime
# -----------------------------------------------------------------------------
FROM eclipse-temurin:17-jre-alpine

LABEL maintainer="COAL <edwin.cruz@coal.com.mx>"
LABEL description="Traccar GPS Tracking Server - AVL OCRA"

WORKDIR /opt/traccar

# Instalar tini para manejo correcto de señales y wget para healthcheck
RUN apk add --no-cache tini wget && rm -rf /var/cache/apk/*

# Copiar artefactos compilados desde builder
COPY --from=builder /build/target/*.jar tracker-server.jar
COPY --from=builder /build/target/lib lib
COPY --from=builder /build/schema schema
COPY --from=builder /build/templates templates

# Copiar frontend compilado
COPY --from=frontend-builder /frontend/modern/dist web

# Crear directorios necesarios
RUN mkdir -p conf logs data

# Volúmenes para persistencia
VOLUME ["/opt/traccar/conf", "/opt/traccar/logs", "/opt/traccar/data"]

# Puerto web (8082) + rango de protocolos GPS
EXPOSE 8082
EXPOSE 5001-5016
EXPOSE 5101-5116

# Health check - verifica que el servidor web responda
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
    CMD wget -q --spider http://localhost:8082/api/server || exit 1

# Usar tini como init para manejo correcto de procesos
ENTRYPOINT ["/sbin/tini", "--"]

# Comando por defecto
CMD ["java", "-Xms512m", "-Xmx1024m", "-jar", "tracker-server.jar", "conf/traccar.xml"]
