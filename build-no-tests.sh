#!/bin/bash
# Build script per MCP Servers - Solo compilazione senza test

set -e

echo "=== Building Quarkus MCP Servers (senza test) ==="
echo

# Controlla se esiste Java
if ! command -v java >/dev/null 2>&1; then
    echo "❌ Java non trovato. Installare Java 17 o superiore"
    exit 1
fi

# Controlla se esiste Maven
if ! command -v mvn >/dev/null 2>&1; then
    echo "❌ Maven non trovato. Installare Maven 3.8.1 o superiore"
    exit 1
fi

echo "🔨 Eseguendo mvn clean install -DskipTests..."
echo

# Esegue la build senza test
mvn clean install -DskipTests

if [ $? -eq 0 ]; then
    echo
    echo "✅ Build completata con successo!"
    echo
    echo "📁 JAR universale creato in:"
    echo "   jdbc/target/mcp-server-jdbc-universal-999-SNAPSHOT.jar"
    echo
    echo "🚀 Per testare il server JDBC:"
    echo "   ./run-server.sh jdbc --jdbc.url=\"jdbc:h2:mem:testdb\" --jdbc.user=\"sa\" --jdbc.password=\"\""
    echo
else
    echo "❌ Build fallita!"
    exit 1
fi
