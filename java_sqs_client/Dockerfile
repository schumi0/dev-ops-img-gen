
FROM maven:3.8.6-eclipse-temurin-17 AS builder

#Set dir
WORKDIR /app
COPY ./java_sqs_client/pom.xml .
COPY ./java_sqs_client/src ./src

#?MVNcool
RUN mvn package -DskipTests
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=builder /app/target/*.jar app.jar

ENTRYPOINT ["java", "-jar", "app.jar"]
