#!/bin/bash
# Script di cleanup e manutenzione per MCP Servers Docker

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

show_usage() {
    cat << EOF
Uso: $0 [COMANDO]

COMANDI:
  clean-all     - Pulizia completa (container, immagini, volumi)
  clean-images  - Rimuove solo le immagini MCP
  clean-containers - Ferma e rimuove container MCP
  clean-volumes - Rimuove volumi Docker non utilizzati
  clean-build   - Pulisce i file di build Maven
  logs          - Mostra i log dei container attivi
  status        - Mostra lo stato dei container MCP
  update        - Aggiorna l'immagine Docker
  help          - Mostra questo aiuto

ESEMPI:
  $0 clean-all       # Pulizia completa
  $0 status          # Stato container
  $0 logs            # Log container
  $0 update          # Aggiorna immagine

EOF
}

clean_build_artifacts() {
    log_info "Pulizia artifacts di build Maven..."
    
    if [ -f "pom.xml" ]; then
        mvn clean -q || log_warning "Maven clean fallito"
        log_success "Build artifacts puliti"
    else
        log_warning "pom.xml non trovato, skip Maven clean"
    fi
    
    # Rimuove file di configurazione generati
    if [ -f "mcp-docker-config.json" ]; then
        rm -f mcp-docker-config.json
        log_success "Configurazione MCP generata rimossa"
    fi
}

clean_docker_containers() {
    log_info "Ferma e rimuove container MCP..."
    
    # Ferma container docker-compose se esistono
    if [ -f "docker-compose.yml" ]; then
        docker-compose down 2>/dev/null || true
    fi
    
    # Rimuove container MCP specifici
    containers=$(docker ps -a --filter "name=mcp-" --format "{{.Names}}" 2>/dev/null || true)
    if [ -n "$containers" ]; then
        echo "$containers" | xargs docker rm -f 2>/dev/null || true
        log_success "Container MCP rimossi"
    else
        log_info "Nessun container MCP trovato"
    fi
}

clean_docker_images() {
    log_info "Rimozione immagini Docker MCP..."
    
    # Rimuove immagine principale
    docker rmi mcp-servers:latest 2>/dev/null || log_info "Immagine mcp-servers:latest non trovata"
    
    # Rimuove immagini dangling
    dangling=$(docker images -f "dangling=true" -q 2>/dev/null || true)
    if [ -n "$dangling" ]; then
        echo "$dangling" | xargs docker rmi 2>/dev/null || true
        log_success "Immagini dangling rimosse"
    fi
    
    log_success "Immagini Docker pulite"
}

clean_docker_volumes() {
    log_info "Rimozione volumi Docker non utilizzati..."
    
    docker volume prune -f 2>/dev/null || true
    log_success "Volumi Docker puliti"
}

show_container_status() {
    log_info "Stato container MCP:"
    echo
    
    # Cerca container MCP
    containers=$(docker ps -a --filter "name=mcp-" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || true)
    
    if [ -n "$containers" ]; then
        echo "$containers"
    else
        log_info "Nessun container MCP trovato"
    fi
    
    echo
    log_info "Immagini MCP disponibili:"
    docker images | grep -E "(mcp-servers|REPOSITORY)" || log_info "Nessuna immagine MCP trovata"
}

show_container_logs() {
    log_info "Log container MCP:"
    echo
    
    containers=$(docker ps --filter "name=mcp-" --format "{{.Names}}" 2>/dev/null || true)
    
    if [ -n "$containers" ]; then
        for container in $containers; do
            log_info "=== Log per $container ==="
            docker logs --tail=20 "$container" 2>/dev/null || log_warning "Impossibile leggere log per $container"
            echo
        done
    else
        log_info "Nessun container MCP attivo"
    fi
}

update_docker_image() {
    log_info "Aggiornamento immagine Docker MCP..."
    
    # Rimuove immagine esistente
    docker rmi mcp-servers:latest 2>/dev/null || true
    
    # Rebuild
    log_info "Rebuilding immagine..."
    if [ -f "build-docker.sh" ]; then
        ./build-docker.sh
    else
        docker build -t mcp-servers:latest .
    fi
    
    log_success "Immagine aggiornata"
}

# Main logic
case "${1:-help}" in
    "clean-all")
        log_warning "Pulizia completa in corso..."
        clean_docker_containers
        clean_docker_images
        clean_docker_volumes
        clean_build_artifacts
        log_success "Pulizia completa terminata"
        ;;
    "clean-images")
        clean_docker_images
        ;;
    "clean-containers")
        clean_docker_containers
        ;;
    "clean-volumes")
        clean_docker_volumes
        ;;
    "clean-build")
        clean_build_artifacts
        ;;
    "logs")
        show_container_logs
        ;;
    "status")
        show_container_status
        ;;
    "update")
        update_docker_image
        ;;
    "help"|*)
        show_usage
        ;;
esac
