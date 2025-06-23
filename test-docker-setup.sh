#!/bin/bash
# Test script per verificare il funzionamento dei MCP Servers Docker

set -e

# Colori
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

echo "🧪 Test MCP Servers Docker Setup"
echo "================================="

# Directory del progetto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Test 1: Verifica Docker
log_info "Test 1: Verifica Docker..."
if command -v docker >/dev/null 2>&1; then
    DOCKER_VERSION=$(docker --version)
    log_success "Docker trovato: $DOCKER_VERSION"
else
    log_error "Docker non trovato!"
    exit 1
fi

# Test 2: Verifica file necessari
log_info "Test 2: Verifica file necessari..."
required_files=("Dockerfile" "docker-mcp.sh" "docker-compose.yml" "build-docker.sh")
for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        log_success "✓ $file"
    else
        log_error "✗ $file mancante"
        exit 1
    fi
done

# Test 3: Verifica script eseguibili
log_info "Test 3: Verifica permessi script..."
if [ -x "docker-mcp.sh" ]; then
    log_success "✓ docker-mcp.sh eseguibile"
else
    log_warning "docker-mcp.sh non eseguibile, correggendo..."
    chmod +x docker-mcp.sh
fi

if [ -x "build-docker.sh" ]; then
    log_success "✓ build-docker.sh eseguibile"
else
    log_warning "build-docker.sh non eseguibile, correggendo..."
    chmod +x build-docker.sh
fi

# Test 4: Test help script
log_info "Test 4: Test comando help..."
if ./docker-mcp.sh help > /dev/null 2>&1; then
    log_success "✓ Script help funziona"
else
    log_error "✗ Script help fallito"
    exit 1
fi

# Test 5: Test generazione config
log_info "Test 5: Test generazione configurazione..."
./docker-mcp.sh config > /dev/null 2>&1
if [ -f "mcp-docker-config.json" ]; then
    log_success "✓ Configurazione MCP generata"
else
    log_error "✗ Generazione configurazione fallita"
    exit 1
fi

# Test 6: Verifica struttura progetto Maven
log_info "Test 6: Verifica struttura Maven..."
if [ -f "pom.xml" ]; then
    log_success "✓ pom.xml trovato"
else
    log_error "✗ pom.xml mancante"
    exit 1
fi

# Test 7: Verifica moduli
log_info "Test 7: Verifica moduli..."
modules=("jdbc" "filesystem" "jvminsight" "containers")
for module in "${modules[@]}"; do
    if [ -d "$module" ] && [ -f "$module/pom.xml" ]; then
        log_success "✓ Modulo $module"
    else
        log_warning "⚠ Modulo $module non trovato o incompleto"
    fi
done

# Test 8: Test Docker build (solo se richiesto)
if [ "$1" == "--build" ]; then
    log_info "Test 8: Test build Docker..."
    if docker build -t mcp-servers-test:latest . > /dev/null 2>&1; then
        log_success "✓ Build Docker completata"
        
        # Cleanup immagine di test
        docker rmi mcp-servers-test:latest > /dev/null 2>&1 || true
    else
        log_error "✗ Build Docker fallita"
        exit 1
    fi
else
    log_info "Test 8: Build Docker saltata (usa --build per includerla)"
fi

echo
log_success "🎉 Tutti i test passati!"
echo
echo "📋 Prossimi passi:"
echo "1. Esegui il build: ./build-docker.sh"
echo "2. Testa un server: ./docker-mcp.sh h2"
echo "3. Genera config: ./docker-mcp.sh config"
echo "4. Usa con Claude Desktop copiando la configurazione generata"
echo
echo "📖 Per maggiori informazioni: less README-DOCKER.md"
