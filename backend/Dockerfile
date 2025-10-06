FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /src

COPY pom.xml .
RUN mvn -q -e -DskipTests dependency:go-offline

COPY src ./src
RUN mvn -q -DskipTests package

FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

RUN addgroup -S app && adduser -S app -G app
USER app

COPY --from=build /src/target/*.jar /app/app.jar

ENV JAVA_OPTS="-Xms256m -Xmx512m" \
    SERVER_PORT=8080
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --retries=3 CMD \
  wget -qO- http://127.0.0.1:${SERVER_PORT}/api/health >/dev/null || exit 1

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar /app/app.jar --server.port=${SERVER_PORT}"]
