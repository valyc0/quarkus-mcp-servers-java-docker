#!/bin/bash
# MCP Servers Runner - Standalone Java version
# This script builds and runs MCP servers without JBang dependency

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

show_usage() {
    cat << EOF
Usage: $0 <server-name> [server-args...]

Available servers:
  jdbc        - JDBC database server
  filesystem  - Filesystem server
  jvminsight  - JVM inspection server
  kubernetes  - Kubernetes server
  containers  - Docker containers server
  jfx         - JavaFX GUI server

Examples:
  $0 jdbc --jdbc.url="jdbc:h2:mem:testdb" --jdbc.user="sa" --jdbc.password=""
  $0 filesystem /tmp /home/user/documents
  $0 jvminsight
  $0 kubernetes
  $0 containers

Options:
  --build     Build the project before running
  --dev       Run in development mode (quarkus:dev)
  --native    Run native executable (must be built first)
  --help      Show this help message

EOF
}

build_project() {
    log_info "Building project..."
    cd "$PROJECT_ROOT"
    if mvn clean install -q; then
        log_success "Project built successfully"
    else
        log_error "Failed to build project"
        exit 1
    fi
}

run_server() {
    local server=$1
    shift
    local args=("$@")
    
    local server_dir="$PROJECT_ROOT/$server"
    
    if [[ ! -d "$server_dir" ]]; then
        log_error "Server '$server' not found. Available servers: jdbc, filesystem, jvminsight, kubernetes, containers, jfx"
        exit 1
    fi
    
    cd "$server_dir"
    
    # Check for special flags
    local build_flag=false
    local dev_flag=false
    local native_flag=false
    local filtered_args=()
    
    for arg in "${args[@]}"; do
        case $arg in
            --build)
                build_flag=true
                ;;
            --dev)
                dev_flag=true
                ;;
            --native)
                native_flag=true
                ;;
            --help)
                show_usage
                exit 0
                ;;
            *)
                filtered_args+=("$arg")
                ;;
        esac
    done
    
    if [[ "$build_flag" == true ]]; then
        build_project
    fi
    
    log_info "Starting $server server..."
    
    if [[ "$dev_flag" == true ]]; then
        log_info "Running in development mode..."
        mvn quarkus:dev -Dquarkus.args="${filtered_args[*]}"
    elif [[ "$native_flag" == true ]]; then
        local native_exec="target/mcp-server-$server-999-SNAPSHOT-runner"
        if [[ ! -f "$native_exec" ]]; then
            log_error "Native executable not found. Build it first with: mvn package -Pnative"
            exit 1
        fi
        log_info "Running native executable..."
        "$native_exec" "${filtered_args[@]}"
    else
        # Check if JAR exists, build if not
        local jar_file="target/mcp-server-$server-universal-999-SNAPSHOT.jar"
        if [[ ! -f "$jar_file" ]]; then
            log_info "JAR not found, building..."
            mvn package -q
        fi
        
        log_info "Running JAR..."
        java -jar "$jar_file" "${filtered_args[@]}"
    fi
}

# Main script logic
if [[ $# -eq 0 ]]; then
    show_usage
    exit 1
fi

case $1 in
    --help|-h|help)
        show_usage
        exit 0
        ;;
    jdbc|filesystem|jvminsight|kubernetes|containers|jfx)
        run_server "$@"
        ;;
    *)
        log_error "Unknown server or option: $1"
        show_usage
        exit 1
        ;;
esac
