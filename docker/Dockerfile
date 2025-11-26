# =============================================================================
# Traccar GPS Tracking Server - Multi-stage Dockerfile
# Compila desde código fuente usando Gradle
# =============================================================================

# -----------------------------------------------------------------------------
# Stage 1: Build
# -----------------------------------------------------------------------------
FROM eclipse-temurin:17-jdk AS builder

WORKDIR /build

# Copiar archivos de Gradle primero (para cache de dependencias)
COPY gradlew .
COPY gradle gradle
COPY build.gradle settings.gradle ./

# Dar permisos y descargar dependencias
RUN chmod +x gradlew && ./gradlew dependencies --no-daemon

# Copiar código fuente
COPY src src
COPY schema schema
COPY templates templates

# Compilar el proyecto
RUN ./gradlew assemble --no-daemon

# -----------------------------------------------------------------------------
# Stage 2: Runtime
# -----------------------------------------------------------------------------
FROM eclipse-temurin:17-jre-alpine

LABEL maintainer="COAL <edwin.cruz@coal.com.mx>"
LABEL description="Traccar GPS Tracking Server"

WORKDIR /opt/traccar

# Instalar tini para manejo correcto de señales y wget para healthcheck
RUN apk add --no-cache tini wget && rm -rf /var/cache/apk/*

# Copiar artefactos compilados desde builder
COPY --from=builder /build/target/*.jar tracker-server.jar
COPY --from=builder /build/target/lib lib
COPY --from=builder /build/schema schema
COPY --from=builder /build/templates templates

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
