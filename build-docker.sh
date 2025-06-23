#!/bin/bash
# Script di build rapido per Docker MCP Servers

set -e

echo "🔨 Build Rapido Docker MCP Servers"
echo "=================================="

# Controlla che Docker sia installato
if ! command -v docker >/dev/null 2>&1; then
    echo "❌ Docker non trovato. Installa Docker prima di continuare."
    exit 1
fi

# Directory del progetto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "📁 Directory di lavoro: $SCRIPT_DIR"

# Build dell'immagine Docker
echo "🐳 Building Docker image 'mcp-servers:latest'..."
docker build -t mcp-servers:latest .

if [ $? -eq 0 ]; then
    echo "✅ Build completata con successo!"
    echo
    echo "🚀 Comandi disponibili:"
    echo "  ./docker-mcp.sh oracle     # Server JDBC Oracle"
    echo "  ./docker-mcp.sh h2         # Server JDBC H2"
    echo "  ./docker-mcp.sh filesystem # Server Filesystem"
    echo "  ./docker-mcp.sh config     # Genera config MCP"
    echo
    echo "📋 Per vedere tutti i comandi: ./docker-mcp.sh help"
else
    echo "❌ Build fallita!"
    exit 1
fi
