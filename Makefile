# Makefile for Quarkus MCP Servers - Standalone Java Version
.PHONY: help build clean run-jdbc run-filesystem run-jvminsight run-kubernetes run-containers run-jfx package-all native-all

# Default target
help:
	@echo "Quarkus MCP Servers - Standalone Java Build"
	@echo ""
	@echo "Available targets:"
	@echo "  build           - Build all modules"
	@echo "  clean           - Clean all modules"
	@echo "  package-all     - Package all modules as JARs"
	@echo "  native-all      - Build native executables (requires GraalVM)"
	@echo ""
	@echo "Run targets:"
	@echo "  run-jdbc        - Run JDBC server (requires JDBC_URL)"
	@echo "  run-filesystem  - Run filesystem server"
	@echo "  run-jvminsight  - Run JVM insight server"
	@echo "  run-kubernetes  - Run Kubernetes server"
	@echo "  run-containers  - Run containers server"
	@echo "  run-jfx         - Run JavaFX server"
	@echo ""
	@echo "Example:"
	@echo "  make build"
	@echo "  JDBC_URL='jdbc:h2:mem:testdb' JDBC_USER='sa' make run-jdbc"
	@echo "  make run-filesystem PATHS='/tmp,/home'"

# Build all modules
build:
	@echo "Building all MCP server modules..."
	mvn clean install

# Clean all modules
clean:
	@echo "Cleaning all modules..."
	mvn clean

# Package all modules
package-all:
	@echo "Packaging all modules..."
	mvn package

# Build native executables
native-all:
	@echo "Building native executables (requires GraalVM)..."
	mvn package -Pnative

# Run JDBC server
run-jdbc:
	@if [ -z "$(JDBC_URL)" ]; then \
		echo "Error: JDBC_URL is required"; \
		echo "Usage: JDBC_URL='jdbc:h2:mem:testdb' JDBC_USER='sa' JDBC_PASSWORD='' make run-jdbc"; \
		exit 1; \
	fi
	@echo "Starting JDBC server with URL: $(JDBC_URL)"
	cd jdbc && java -jar target/quarkus-app/quarkus-run.jar \
		--jdbc.url="$(JDBC_URL)" \
		$(if $(JDBC_USER),--jdbc.user="$(JDBC_USER)") \
		$(if $(JDBC_PASSWORD),--jdbc.password="$(JDBC_PASSWORD)")

# Run filesystem server
run-filesystem:
	@echo "Starting filesystem server..."
	@if [ -n "$(PATHS)" ]; then \
		echo "Serving paths: $(PATHS)"; \
		cd filesystem && java -jar target/quarkus-app/quarkus-run.jar $(shell echo $(PATHS) | tr ',' ' '); \
	else \
		echo "No paths specified, serving current directory"; \
		cd filesystem && java -jar target/quarkus-app/quarkus-run.jar .; \
	fi

# Run JVM insight server
run-jvminsight:
	@echo "Starting JVM insight server..."
	cd jvminsight && java -jar target/quarkus-app/quarkus-run.jar

# Run Kubernetes server
run-kubernetes:
	@echo "Starting Kubernetes server..."
	cd kubernetes && java -jar target/quarkus-app/quarkus-run.jar

# Run containers server
run-containers:
	@echo "Starting containers server..."
	cd containers && java -jar target/quarkus-app/quarkus-run.jar

# Run JavaFX server
run-jfx:
	@echo "Starting JavaFX server..."
	cd jfx && java -jar target/quarkus-app/quarkus-run.jar

# Development mode targets
dev-jdbc:
	@echo "Starting JDBC server in development mode..."
	cd jdbc && mvn quarkus:dev

dev-filesystem:
	@echo "Starting filesystem server in development mode..."
	cd filesystem && mvn quarkus:dev

dev-jvminsight:
	@echo "Starting JVM insight server in development mode..."
	cd jvminsight && mvn quarkus:dev

dev-kubernetes:
	@echo "Starting Kubernetes server in development mode..."
	cd kubernetes && mvn quarkus:dev

dev-containers:
	@echo "Starting containers server in development mode..."
	cd containers && mvn quarkus:dev

dev-jfx:
	@echo "Starting JavaFX server in development mode..."
	cd jfx && mvn quarkus:dev
