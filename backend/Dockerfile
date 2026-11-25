# syntax=docker/dockerfile:1

###############################################
# Stage 1 — Build du jar avec Maven + JDK 21  #
###############################################
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /build

# Dépôt Maven DANS l'image, pas dans un `--mount=type=cache` : le cache de
# couches de la CI (cache-to: type=gha) ne sauvegarde pas les montages de
# cache. Avec eux, l'étape go-offline était reprise du cache mais le dépôt
# arrivait vide, et `package` retéléchargeait tout depuis Maven Central à
# chaque build, jusqu'à se faire limiter (HTTP 429 Too Many Requests).
# Les options de nouvelle tentative absorbent un 429 passager.
ENV MAVEN_ARGS="-B -Dmaven.repo.local=/build/.m2 \
    -Daether.connector.http.retryHandler.count=5 \
    -Daether.connector.http.retryHandler.interval=10000"

# 1) Résolution des dépendances dans une couche cachée : tant que pom.xml ne
#    change pas, elle est reprise telle quelle, dépendances comprises.
COPY pom.xml .
RUN mvn -q dependency:go-offline

# 2) Compilation et packaging (tests ignorés ici : à exécuter dans la CI)
COPY src ./src
RUN mvn -q clean package -DskipTests

# 3) Extraction des couches Spring Boot pour optimiser le cache d'image runtime
RUN mkdir -p target/extracted \
    && java -Djarmode=layertools -jar target/*.jar extract --destination target/extracted

###############################################
# Stage 2 — Image runtime légère (JRE 21)     #
###############################################
FROM eclipse-temurin:21-jre-alpine AS runtime

# curl pour le HEALTHCHECK ; utilisateur non-root pour la sécurité
RUN apk add --no-cache curl \
    && addgroup -S app && adduser -S app -G app

WORKDIR /app

# Copie des couches extraites (les moins volatiles d'abord)
COPY --from=build /build/target/extracted/dependencies/ ./
COPY --from=build /build/target/extracted/spring-boot-loader/ ./
COPY --from=build /build/target/extracted/snapshot-dependencies/ ./
COPY --from=build /build/target/extracted/application/ ./

USER app

EXPOSE 8082

ENV JAVA_OPTS="-XX:MaxRAMPercentage=75.0 -XX:+UseG1GC" \
    SPRING_PROFILES_ACTIVE=prod

# Healthcheck via l'endpoint Actuator
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
    CMD curl -fsS http://localhost:8082/actuator/health || exit 1

ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS org.springframework.boot.loader.launch.JarLauncher"]
