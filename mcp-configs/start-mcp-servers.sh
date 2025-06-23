#!/bin/bash

# Script di avvio per MCP Servers
export JAVA_HOME="/workspace/db-ready/quarkus-mcp-servers/jdk17"
export PATH="$JAVA_HOME/bin:$PATH"

echo "Avvio MCP Servers con JDK 17..."
echo "JAVA_HOME: $JAVA_HOME"
echo "Java Version: $(java -version 2>&1 | head -n 1)"

# Avvia il server JDBC con H2 in-memory
echo "Avvio JDBC Server..."
"/workspace/db-ready/quarkus-mcp-servers/jdk17/bin/java" -jar "/workspace/db-ready/quarkus-mcp-servers/jdbc/target/quarkus-app/quarkus-run.jar" \
    --jdbc.url=jdbc:h2:mem:testdb \
    --jdbc.user=sa \
    --jdbc.password= &

# Avvia il filesystem server
echo "Avvio Filesystem Server..."
"/workspace/db-ready/quarkus-mcp-servers/jdk17/bin/java" -jar "/workspace/db-ready/quarkus-mcp-servers/filesystem/target/quarkus-app/quarkus-run.jar" /tmp &

echo "MCP Servers avviati!"
echo "Premi Ctrl+C per fermarli"

wait
