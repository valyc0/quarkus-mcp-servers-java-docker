#!/bin/bash
# Quick setup script for standalone Java MCP servers

set -e

echo "=== Quarkus MCP Servers - Standalone Java Setup ==="
echo

# Check Java version
if command -v java >/dev/null 2>&1; then
    JAVA_VERSION=$(java -version 2>&1 | head -n 1 | awk -F '"' '{print $2}' | awk -F '.' '{print $1}')
    if [ "$JAVA_VERSION" -ge 17 ]; then
        echo "✓ Java $JAVA_VERSION detected (minimum Java 17 required)"
    else
        echo "✗ Java 17 or higher is required (found Java $JAVA_VERSION)"
        exit 1
    fi
else
    echo "✗ Java not found. Please install Java 17 or higher"
    exit 1
fi

# Check Maven
if command -v mvn >/dev/null 2>&1; then
    MVN_VERSION=$(mvn -version | head -n 1 | awk '{print $3}')
    echo "✓ Maven $MVN_VERSION detected"
else
    echo "✗ Maven not found. Please install Maven 3.8.1 or higher"
    exit 1
fi

echo
echo "=== Building all MCP server modules ==="
echo

# Build the project
mvn clean install

if [ $? -eq 0 ]; then
    echo
    echo "✓ Build completed successfully!"
    echo
    echo "=== Available MCP Servers ==="
    echo
    echo "1. JDBC Server - Database connectivity"
    echo "   Usage: ./run-server.sh jdbc --jdbc.url=\"jdbc:h2:mem:testdb\" --jdbc.user=\"sa\" --jdbc.password=\"\""
    echo
    echo "2. Filesystem Server - File system access"
    echo "   Usage: ./run-server.sh filesystem /path/to/serve"
    echo
    echo "3. JVM Insight Server - JVM monitoring"
    echo "   Usage: ./run-server.sh jvminsight"
    echo
    echo "4. Kubernetes Server - Kubernetes cluster management"
    echo "   Usage: ./run-server.sh kubernetes"
    echo
    echo "5. Containers Server - Docker container management"
    echo "   Usage: ./run-server.sh containers"
    echo
    echo "6. JavaFX Server - GUI applications"
    echo "   Usage: ./run-server.sh jfx"
    echo
    echo "=== Quick Test ==="
    echo "Try running the filesystem server:"
    echo "./run-server.sh filesystem --dev /tmp"
    echo
    echo "Or the JDBC server with H2:"
    echo "./run-server.sh jdbc --jdbc.url=\"jdbc:h2:mem:testdb\" --jdbc.user=\"sa\" --jdbc.password=\"\""
    echo
    echo "For more options, run: ./run-server.sh --help"
else
    echo "✗ Build failed. Please check the errors above."
    exit 1
fi
