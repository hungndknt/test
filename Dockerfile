FROM maven:3.9.6-eclipse-temurin-8 AS build
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn -B -DskipTests package
FROM tomcat:9.0-jdk8-temurin

RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

RUN rm -rf /usr/local/tomcat/webapps/*
<<<<<<< HEAD
=======

>>>>>>> 296a3f966cf3404604e16f857dfe69ada88f8ce2
COPY --from=build /app/target/*.war /usr/local/tomcat/webapps/ROOT.war

EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -fsS http://localhost:8080/ || exit 1
RUN mkdir -p /otel
COPY otel/opentelemetry-javaagent.jar /otel/opentelemetry-javaagent.jar
CMD ["catalina.sh", "run"]
