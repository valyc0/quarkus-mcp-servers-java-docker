#!/bin/bash
# Script per buildare e avviare MCP Servers con Docker
# Crea automaticamente la configurazione MCP per Claude Desktop

set -e

# Colori per output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_header() {
    echo -e "${CYAN}=== $1 ===${NC}"
}

# Directory del progetto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"

# Nome dell'immagine Docker
DOCKER_IMAGE="mcp-servers:latest"

# File di configurazione MCP per Claude Desktop
MCP_CONFIG_FILE="$PROJECT_DIR/mcp-docker-config.json"

show_usage() {
    cat << EOF
Uso: $0 [COMANDO] [OPZIONI]

COMANDI:
  build       - Builda l'immagine Docker
  run         - Avvia un server MCP
  config      - Genera configurazione MCP per Claude Desktop
  oracle      - Avvia server JDBC per Oracle (richiede Oracle in localhost:1521)
  h2          - Avvia server JDBC per H2 in memoria
  filesystem  - Avvia server filesystem
  help        - Mostra questo aiuto

ESEMPI:
  $0 build                    # Builda l'immagine Docker
  $0 run jdbc --jdbc.url="jdbc:h2:mem:testdb" --jdbc.user="sa"
  $0 oracle                   # Per database Oracle locale
  $0 h2                       # Per database H2 in memoria
  $0 filesystem /tmp          # Server filesystem
  $0 config                   # Genera config MCP

EOF
}

build_docker_image() {
    log_header "Building Docker Image"
    
    cd "$PROJECT_DIR"
    
    log_info "Building MCP Servers Docker image..."
    docker build -t "$DOCKER_IMAGE" .
    
    if [ $? -eq 0 ]; then
        log_success "Docker image '$DOCKER_IMAGE' built successfully!"
    else
        log_error "Failed to build Docker image"
        exit 1
    fi
}

check_docker_image() {
    if ! docker images | grep -q "mcp-servers"; then
        log_warning "Docker image not found. Building it now..."
        build_docker_image
    fi
}

run_oracle_server() {
    log_header "Starting MCP JDBC Server for Oracle"
    
    check_docker_image
    
    local oracle_url="jdbc:oracle:thin:@localhost:1521:xe"
    local oracle_user="ORACLEUSR"
    local oracle_password="ORACLEUSR"
    
    log_info "Starting JDBC server for Oracle database..."
    log_info "Database URL: $oracle_url"
    log_info "User: $oracle_user"
    
    docker run -it --rm --network host "$DOCKER_IMAGE" jdbc \
        --jdbc.url="$oracle_url" \
        --jdbc.user="$oracle_user" \
        --jdbc.password="$oracle_password"
}

run_h2_server() {
    log_header "Starting MCP JDBC Server for H2"
    
    check_docker_image
    
    log_info "Starting JDBC server for H2 in-memory database..."
    
    docker run -it --rm -p 3000:3000 "$DOCKER_IMAGE" jdbc \
        --jdbc.url="jdbc:h2:mem:testdb" \
        --jdbc.user="sa" \
        --jdbc.password=""
}

run_filesystem_server() {
    log_header "Starting MCP Filesystem Server"
    
    check_docker_image
    
    local mount_path=${1:-"/tmp"}
    
    log_info "Starting filesystem server for path: $mount_path"
    
    docker run -it --rm -v "$mount_path:/mnt/shared" "$DOCKER_IMAGE" filesystem /mnt/shared
}

run_generic_server() {
    log_header "Starting MCP Server"
    
    check_docker_image
    
    log_info "Running: docker run -it --rm --network host $DOCKER_IMAGE $@"
    
    docker run -it --rm --network host "$DOCKER_IMAGE" "$@"
}

generate_mcp_config() {
    log_header "Generating MCP Configuration"
    
    cat > "$MCP_CONFIG_FILE" << 'EOF'
{
  "mcpServers": {
    "jdbc-oracle-docker": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm", "--network", "host",
        "mcp-servers:latest", "jdbc",
        "--jdbc.url=jdbc:oracle:thin:@localhost:1521:xe",
        "--jdbc.user=ORACLEUSR",
        "--jdbc.password=ORACLEUSR"
      ]
    },
    "jdbc-h2-docker": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm", "-p", "3000:3000",
        "mcp-servers:latest", "jdbc",
        "--jdbc.url=jdbc:h2:mem:testdb",
        "--jdbc.user=sa",
        "--jdbc.password="
      ]
    },
    "filesystem-docker": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm", "-v", "/tmp:/mnt/shared",
        "mcp-servers:latest", "filesystem", "/mnt/shared"
      ]
    },
    "jvminsight-docker": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "mcp-servers:latest", "jvminsight"
      ]
    },
    "containers-docker": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm", "-v", "/var/run/docker.sock:/var/run/docker.sock",
        "mcp-servers:latest", "containers"
      ]
    }
  }
}
EOF

    log_success "MCP configuration saved to: $MCP_CONFIG_FILE"
    echo
    log_info "Per usare con Claude Desktop, copia il contenuto di questo file in:"
    log_info "  macOS: ~/Library/Application Support/Claude/claude_desktop_config.json"
    log_info "  Windows: %APPDATA%/Claude/claude_desktop_config.json"
    log_info "  Linux: ~/.config/claude/claude_desktop_config.json"
    echo
    log_warning "Nota: Assicurati che l'immagine Docker 'mcp-servers:latest' sia stata buildata con: $0 build"
}

# Main logic
case "${1:-help}" in
    "build")
        build_docker_image
        ;;
    "run")
        shift
        run_generic_server "$@"
        ;;
    "oracle")
        run_oracle_server
        ;;
    "h2")
        run_h2_server
        ;;
    "filesystem")
        shift
        run_filesystem_server "$@"
        ;;
    "config")
        generate_mcp_config
        ;;
    "help"|*)
        show_usage
        ;;
esac
