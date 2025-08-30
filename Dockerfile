# ---------- Build stage ----------
FROM maven:3.9.6-eclipse-temurin-8 AS build
WORKDIR /app

# copy code và build
COPY pom.xml .
COPY src ./src
RUN mvn -B -DskipTests package

# ---------- Runtime stage ----------
FROM tomcat:9.0-jdk8-temurin

# (tuỳ chọn) có curl cho healthcheck
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# dọn default apps
RUN rm -rf /usr/local/tomcat/webapps/*
COPY --from=build /app/target/*.war /usr/local/tomcat/webapps/ROOT.war

EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -fsS http://localhost:8080/ || exit 1
RUN mkdir -p /otel
COPY otel/opentelemetry-javaagent.jar /otel/opentelemetry-javaagent.jar
CMD ["catalina.sh", "run"]
