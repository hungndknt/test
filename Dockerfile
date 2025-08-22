# ---------- Build stage ----------
FROM icr.io/appcafe/ibm-semeru-runtimes:open-8-jdk-focal AS build-stage

RUN apt-get update && \
    apt-get install -y maven unzip && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /project
COPY ./pom.xml /project/
COPY ./src /project/src/

RUN mvn clean package -DskipTests && \
    mkdir -p /config/apps /sharedlibs && \
    cp ./src/main/liberty/config/* /config/ && \
    cp ./target/*.*ar /config/apps/ && \
    if [ -d "./src/main/liberty/lib" ] && [ "$(ls -A ./src/main/liberty/lib)" ]; then \
      cp -r ./src/main/liberty/lib/* /sharedlibs/; \
    fi

# ---------- Runtime stage ----------
FROM icr.io/appcafe/websphere-liberty:kernel-java8-openj9-ubi

USER root
RUN microdnf install -y curl && microdnf clean all && \
    mkdir -p /opt/ibm/wlp/usr/shared/config/lib/global

COPY --from=build-stage /config/ /config/
COPY --from=build-stage /sharedlibs/ /opt/ibm/wlp/usr/shared/config/lib/global/

# Liberty setup
RUN features.sh && configure.sh

# Không chạy as root
USER 1001

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -fsS http://localhost:9080/health || exit 1

EXPOSE 9080 9443
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -XX:+UseG1GC"
CMD ["/opt/ibm/wlp/bin/server","run","defaultServer"]
