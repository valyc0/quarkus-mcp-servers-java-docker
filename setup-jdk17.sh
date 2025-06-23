#!/bin/bash

# Script per il setup automatico di JDK 17 e configurazione MCP
# Autore: Setup Script per Quarkus MCP Servers
# Data: $(date)

set -e

# Colori per output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variabili
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JDK_DIR="$SCRIPT_DIR/jdk17"
JDK_VERSION="17.0.11"
JDK_BUILD="9"

# Detect architecture and OS
detect_platform() {
    local arch=$(uname -m)
    local os=$(uname -s)
    
    case "$arch" in
        x86_64|amd64)
            ARCH="x64"
            ;;
        aarch64|arm64)
            ARCH="aarch64"
            ;;
        *)
            echo -e "${RED}Architettura non supportata: $arch${NC}"
            exit 1
            ;;
    esac
    
    case "$os" in
        Linux)
            OS="linux"
            # Usa Eclipse Temurin come alternativa più affidabile
            JDK_URL="https://github.com/adoptium/temurin17-binaries/releases/download/jdk-${JDK_VERSION}%2B${JDK_BUILD}/OpenJDK17U-jdk_${ARCH}_${OS}_hotspot_${JDK_VERSION}_${JDK_BUILD}.tar.gz"
            JDK_ARCHIVE="OpenJDK17U-jdk_${ARCH}_${OS}_hotspot_${JDK_VERSION}_${JDK_BUILD}.tar.gz"
            ;;
        Darwin)
            OS="mac"
            JDK_URL="https://github.com/adoptium/temurin17-binaries/releases/download/jdk-${JDK_VERSION}%2B${JDK_BUILD}/OpenJDK17U-jdk_${ARCH}_${OS}_hotspot_${JDK_VERSION}_${JDK_BUILD}.tar.gz"
            JDK_ARCHIVE="OpenJDK17U-jdk_${ARCH}_${OS}_hotspot_${JDK_VERSION}_${JDK_BUILD}.tar.gz"
            ;;
        *)
            echo -e "${RED}Sistema operativo non supportato: $os${NC}"
            exit 1
            ;;
    esac
}

# Funzione per scaricare JDK 17
download_jdk() {
    echo -e "${BLUE}Scaricamento JDK 17...${NC}"
    
    # Array di URL alternativi
    local urls=(
        "https://github.com/adoptium/temurin17-binaries/releases/download/jdk-${JDK_VERSION}%2B${JDK_BUILD}/OpenJDK17U-jdk_${ARCH}_${OS}_hotspot_${JDK_VERSION}_${JDK_BUILD}.tar.gz"
        "https://download.java.net/java/GA/jdk17.0.2/dfd4a8d0985749f896bed50d7138ee7f/8/GPL/openjdk-17.0.2_${OS}-${ARCH}_bin.tar.gz"
    )
    
    # Prova ogni URL fino a che uno non funziona
    local success=false
    for url in "${urls[@]}"; do
        echo -e "${BLUE}Tentativo download da: $url${NC}"
        JDK_URL="$url"
        JDK_ARCHIVE=$(basename "$url" | sed 's/%2B/+/g')
        
        # Crea directory temporanea
        local temp_dir=$(mktemp -d)
        cd "$temp_dir"
        
        # Scarica JDK
        echo -e "${BLUE}Download in corso...${NC}"
        if command -v wget >/dev/null 2>&1; then
            if wget --progress=bar:force -O "$JDK_ARCHIVE" "$JDK_URL" 2>/dev/null; then
                success=true
                break
            fi
        elif command -v curl >/dev/null 2>&1; then
            if curl -L -o "$JDK_ARCHIVE" "$JDK_URL" --progress-bar --fail 2>/dev/null; then
                success=true
                break
            fi
        else
            echo -e "${RED}Errore: wget o curl non trovati${NC}"
            exit 1
        fi
        
        echo -e "${YELLOW}Download fallito, provo URL alternativo...${NC}"
        rm -rf "$temp_dir"
    done
    
    if [[ "$success" != "true" ]]; then
        echo -e "${RED}Errore: Tutti i download sono falliti${NC}"
        echo -e "${YELLOW}Prova a scaricare manualmente JDK 17 da:${NC}"
        echo -e "https://adoptium.net/temurin/releases/?version=17"
        exit 1
    fi
    
    # Verifica download
    if [[ ! -f "$JDK_ARCHIVE" ]]; then
        echo -e "${RED}Errore: Download fallito${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Download completato!${NC}"
    
    # Estrai JDK
    echo -e "${BLUE}Estrazione JDK...${NC}"
    mkdir -p "$JDK_DIR"
    
    # Estrai e rileva la struttura del JDK
    tar -xzf "$JDK_ARCHIVE" -C "$JDK_DIR"
    
    # Trova la directory JDK effettiva (potrebbe essere annidata)
    local bin_dir=$(find "$JDK_DIR" -maxdepth 2 -name "bin" -type d | head -n 1)
    
    if [[ -n "$bin_dir" ]]; then
        local jdk_extracted_dir=$(dirname "$bin_dir")
        
        if [[ "$jdk_extracted_dir" != "$JDK_DIR" ]]; then
            echo -e "${BLUE}Riorganizzazione directory JDK...${NC}"
            # Crea directory temporanea per lo spostamento
            local temp_move_dir=$(mktemp -d)
            
            # Sposta tutto dal subdirectory alla directory temporanea
            mv "$jdk_extracted_dir"/* "$temp_move_dir"/ 2>/dev/null || true
            
            # Rimuovi la directory estratta originale
            rm -rf "$jdk_extracted_dir"
            
            # Sposta tutto dalla directory temporanea al JDK_DIR
            mv "$temp_move_dir"/* "$JDK_DIR"/ 2>/dev/null || true
            
            # Pulizia directory temporanea
            rm -rf "$temp_move_dir"
        fi
    else
        echo -e "${YELLOW}Struttura JDK non standard rilevata, tentativo di riorganizzazione...${NC}"
        # Se non trova bin, prova a cercare il primo subdirectory che potrebbe essere il JDK
        local first_subdir=$(find "$JDK_DIR" -maxdepth 1 -type d ! -path "$JDK_DIR" | head -n 1)
        if [[ -n "$first_subdir" && -d "$first_subdir/bin" ]]; then
            echo -e "${BLUE}Trovato JDK in: $first_subdir${NC}"
            # Crea directory temporanea per lo spostamento
            local temp_move_dir=$(mktemp -d)
            
            # Sposta tutto dal subdirectory alla directory temporanea
            mv "$first_subdir"/* "$temp_move_dir"/ 2>/dev/null || true
            
            # Rimuovi la directory estratta originale
            rm -rf "$first_subdir"
            
            # Sposta tutto dalla directory temporanea al JDK_DIR
            mv "$temp_move_dir"/* "$JDK_DIR"/ 2>/dev/null || true
            
            # Pulizia directory temporanea
            rm -rf "$temp_move_dir"
        fi
    fi
    
    # Pulizia
    rm -rf "$temp_dir"
    
    echo -e "${GREEN}JDK 17 installato in: $JDK_DIR${NC}"
}

# Funzione per creare configurazioni MCP
create_mcp_config() {
    local java_bin="$1"
    local config_dir="$SCRIPT_DIR/mcp-configs"
    
    echo -e "${BLUE}Creazione configurazioni MCP...${NC}"
    
    mkdir -p "$config_dir"
    
    # Configurazione completa con JAR files
    cat > "$config_dir/mcp-config-jar.json" << EOF
{
  "mcpServers": {
    "jdbc": {
      "command": "$java_bin",
      "args": [
        "-jar",
        "$SCRIPT_DIR/jdbc/target/quarkus-app/quarkus-run.jar",
        "--jdbc.url=jdbc:h2:mem:testdb",
        "--jdbc.user=sa",
        "--jdbc.password="
      ]
    },
    "filesystem": {
      "command": "$java_bin",
      "args": [
        "-jar",
        "$SCRIPT_DIR/filesystem/target/quarkus-app/quarkus-run.jar",
        "/tmp"
      ]
    },
    "jvminsight": {
      "command": "$java_bin",
      "args": [
        "-jar",
        "$SCRIPT_DIR/jvminsight/target/quarkus-app/quarkus-run.jar"
      ]
    },
    "kubernetes": {
      "command": "$java_bin",
      "args": [
        "-jar",
        "$SCRIPT_DIR/kubernetes/target/quarkus-app/quarkus-run.jar"
      ]
    },
    "containers": {
      "command": "$java_bin",
      "args": [
        "-jar",
        "$SCRIPT_DIR/containers/target/quarkus-app/quarkus-run.jar"
      ]
    }
  }
}
EOF

    # Configurazione con eseguibili nativi (se esistono)
    cat > "$config_dir/mcp-config-native.json" << EOF
{
  "mcpServers": {
    "jdbc": {
      "command": "$SCRIPT_DIR/jdbc/target/mcp-server-jdbc-999-SNAPSHOT-runner",
      "args": [
        "--jdbc.url=jdbc:h2:mem:testdb",
        "--jdbc.user=sa",
        "--jdbc.password="
      ]
    },
    "filesystem": {
      "command": "$SCRIPT_DIR/filesystem/target/mcp-server-filesystem-999-SNAPSHOT-runner",
      "args": [
        "/tmp"
      ]
    },
    "jvminsight": {
      "command": "$SCRIPT_DIR/jvminsight/target/mcp-server-jvminsight-999-SNAPSHOT-runner"
    },
    "kubernetes": {
      "command": "$SCRIPT_DIR/kubernetes/target/mcp-server-kubernetes-999-SNAPSHOT-runner"
    },
    "containers": {
      "command": "$SCRIPT_DIR/containers/target/mcp-server-containers-999-SNAPSHOT-runner"
    }
  }
}
EOF

    # Configurazione per PostgreSQL
    cat > "$config_dir/mcp-config-postgresql.json" << EOF
{
  "mcpServers": {
    "jdbc": {
      "command": "$java_bin",
      "args": [
        "-jar",
        "$SCRIPT_DIR/jdbc/target/quarkus-app/quarkus-run.jar",
        "--jdbc.url=jdbc:postgresql://localhost:5432/mydb",
        "--jdbc.user=username",
        "--jdbc.password=password"
      ]
    }
  }
}
EOF

    # Configurazione per MySQL
    cat > "$config_dir/mcp-config-mysql.json" << EOF
{
  "mcpServers": {
    "jdbc": {
      "command": "$java_bin",
      "args": [
        "-jar",
        "$SCRIPT_DIR/jdbc/target/quarkus-app/quarkus-run.jar",
        "--jdbc.url=jdbc:mysql://localhost:3306/mydb",
        "--jdbc.user=username",
        "--jdbc.password=password"
      ]
    }
  }
}
EOF

    # Script di avvio rapido
    cat > "$config_dir/start-mcp-servers.sh" << EOF
#!/bin/bash

# Script di avvio per MCP Servers
export JAVA_HOME="$JDK_DIR"
export PATH="\$JAVA_HOME/bin:\$PATH"

echo "Avvio MCP Servers con JDK 17..."
echo "JAVA_HOME: \$JAVA_HOME"
echo "Java Version: \$(java -version 2>&1 | head -n 1)"

# Avvia il server JDBC con H2 in-memory
echo "Avvio JDBC Server..."
"$java_bin" -jar "$SCRIPT_DIR/jdbc/target/quarkus-app/quarkus-run.jar" \\
    --jdbc.url=jdbc:h2:mem:testdb \\
    --jdbc.user=sa \\
    --jdbc.password= &

# Avvia il filesystem server
echo "Avvio Filesystem Server..."
"$java_bin" -jar "$SCRIPT_DIR/filesystem/target/quarkus-app/quarkus-run.jar" /tmp &

echo "MCP Servers avviati!"
echo "Premi Ctrl+C per fermarli"

wait
EOF

    chmod +x "$config_dir/start-mcp-servers.sh"
    
    echo -e "${GREEN}Configurazioni MCP create in: $config_dir${NC}"
}

# Funzione per compilare il progetto
compile_project() {
    local java_bin="$1"
    local java_home="$(dirname "$(dirname "$java_bin")")"
    
    echo -e "\n${BLUE}=== COMPILAZIONE PROGETTO ===${NC}"
    echo -e "${BLUE}Avvio compilazione Maven con JDK 17...${NC}"
    
    # Imposta le variabili d'ambiente per Maven
    export JAVA_HOME="$java_home"
    export PATH="$java_home/bin:$PATH"
    
    echo -e "${GREEN}JAVA_HOME: $JAVA_HOME${NC}"
    echo -e "${GREEN}Java Version: $("$java_bin" -version 2>&1 | head -n 1)${NC}"
    
    # Cambia nella directory del progetto
    cd "$SCRIPT_DIR"
    
    # Controlla se Maven è disponibile
    if ! command -v mvn >/dev/null 2>&1; then
        echo -e "${YELLOW}Maven non trovato, uso il wrapper Maven incluso...${NC}"
        if [[ -f "./mvnw" ]]; then
            chmod +x ./mvnw
            MVN_CMD="./mvnw"
        else
            echo -e "${RED}Errore: Maven e mvnw non trovati${NC}"
            return 1
        fi
    else
        MVN_CMD="mvn"
    fi
    
    echo -e "${BLUE}Esecuzione: $MVN_CMD clean install -DskipTests${NC}"
    
    # Compila il progetto saltando i test per velocità
    if $MVN_CMD clean install -DskipTests; then
        echo -e "${GREEN}✅ Compilazione completata con successo!${NC}"
        return 0
    else
        echo -e "${RED}❌ Errore durante la compilazione${NC}"
        echo -e "${YELLOW}Prova a compilare manualmente con:${NC}"
        echo -e "export JAVA_HOME=\"$java_home\""
        echo -e "export PATH=\"\$JAVA_HOME/bin:\$PATH\""
        echo -e "cd $SCRIPT_DIR"
        echo -e "$MVN_CMD clean install"
        return 1
    fi
}

# Funzione per creare configurazione settings.json
create_settings_json_config() {
    local java_bin="$1"
    local config_dir="$SCRIPT_DIR/mcp-configs"
    
    echo -e "\n${BLUE}Creazione configurazione settings.json...${NC}"
    
    # Configurazione per Claude Desktop settings.json
    cat > "$config_dir/claude-desktop-settings.json" << EOF
{
  "mcpServers": {
    "jdbc-server": {
      "command": "$java_bin",
      "args": [
        "-jar",
        "$SCRIPT_DIR/jdbc/target/quarkus-app/quarkus-run.jar",
        "--jdbc.url=jdbc:h2:mem:testdb",
        "--jdbc.user=sa",
        "--jdbc.password="
      ]
    },
    "filesystem-server": {
      "command": "$java_bin",
      "args": [
        "-jar",
        "$SCRIPT_DIR/filesystem/target/quarkus-app/quarkus-run.jar",
        "/tmp"
      ]
    },
    "jvminsight-server": {
      "command": "$java_bin",
      "args": [
        "-jar",
        "$SCRIPT_DIR/jvminsight/target/quarkus-app/quarkus-run.jar"
      ]
    },
    "kubernetes-server": {
      "command": "$java_bin",
      "args": [
        "-jar",
        "$SCRIPT_DIR/kubernetes/target/quarkus-app/quarkus-run.jar"
      ]
    },
    "containers-server": {
      "command": "$java_bin",
      "args": [
        "-jar",
        "$SCRIPT_DIR/containers/target/quarkus-app/quarkus-run.jar"
      ]
    }
  }
}
EOF

    echo -e "${GREEN}Configurazione Claude Desktop creata: $config_dir/claude-desktop-settings.json${NC}"
}

# Funzione per mostrare le istruzioni finali
show_final_instructions() {
    local java_bin="$1"
    local java_home="$(dirname "$(dirname "$java_bin")")"
    
    echo -e "\n${GREEN}=== SETUP COMPLETATO ===${NC}"
    echo -e "${BLUE}JDK 17 installato, progetto compilato e configurazioni MCP create!${NC}\n"
    
    echo -e "${YELLOW}📁 File di configurazione creati:${NC}"
    echo -e "• $SCRIPT_DIR/mcp-configs/claude-desktop-settings.json (Configurazione principale)"
    echo -e "• $SCRIPT_DIR/mcp-configs/mcp-config-jar.json (JAR files)"
    echo -e "• $SCRIPT_DIR/mcp-configs/mcp-config-postgresql.json (PostgreSQL)"
    echo -e "• $SCRIPT_DIR/mcp-configs/mcp-config-mysql.json (MySQL)"
    echo -e "• $SCRIPT_DIR/mcp-configs/start-mcp-servers.sh (Script di avvio)"
    
    echo -e "\n${GREEN}🔧 CONFIGURAZIONE CLAUDE DESKTOP:${NC}"
    echo -e "${YELLOW}Copia il contenuto del seguente file nel tuo Claude Desktop settings.json:${NC}"
    echo -e "${BLUE}$SCRIPT_DIR/mcp-configs/claude-desktop-settings.json${NC}"
    
    echo -e "\n${YELLOW}💡 Percorsi tipici per settings.json:${NC}"
    echo -e "• macOS: ~/Library/Application Support/Claude/claude_desktop_config.json"
    echo -e "• Windows: %APPDATA%/Claude/claude_desktop_config.json"
    echo -e "• Linux: ~/.config/Claude/claude_desktop_config.json"
    
    echo -e "\n${GREEN}📋 CONTENUTO DA COPIARE IN SETTINGS.JSON:${NC}"
    echo -e "${BLUE}────────────────────────────────────────────────────────${NC}"
    cat "$SCRIPT_DIR/mcp-configs/claude-desktop-settings.json"
    echo -e "${BLUE}────────────────────────────────────────────────────────${NC}"
    
    echo -e "\n${YELLOW}🚀 Per avviare manualmente i server MCP:${NC}"
    echo -e "$SCRIPT_DIR/mcp-configs/start-mcp-servers.sh"
    
    echo -e "\n${YELLOW}🔄 Per ricompilare il progetto:${NC}"
    echo -e "export JAVA_HOME=\"$java_home\""
    echo -e "export PATH=\"\$JAVA_HOME/bin:\$PATH\""
    echo -e "cd $SCRIPT_DIR"
    echo -e "mvn clean install"
    
    echo -e "\n${GREEN}✅ Setup completato con successo!${NC}"
    echo -e "${BLUE}I server MCP sono pronti per essere utilizzati con Claude Desktop.${NC}"
}

# Funzione principale
main() {
    echo -e "${BLUE}=== Setup JDK 17 per Quarkus MCP Servers ===${NC}\n"
    
    detect_platform
    echo -e "${BLUE}Piattaforma rilevata: $OS-$ARCH${NC}"
    
    # Scarica sempre JDK 17 localmente
    echo -e "\n${BLUE}Download automatico di JDK 17 locale...${NC}"
    echo -e "${YELLOW}Utilizzeremo sempre la versione locale per garantire compatibilità${NC}"
        
    # Rimuovi directory JDK esistente se presente
    if [[ -d "$JDK_DIR" ]]; then
        echo -e "${YELLOW}Rimozione JDK locale esistente...${NC}"
        rm -rf "$JDK_DIR"
    fi
        
        download_jdk
        
        local java_bin="$JDK_DIR/bin/java"
        
        # Verifica installazione
        if [[ -f "$java_bin" ]]; then
            echo -e "${GREEN}Verifica installazione...${NC}"
            
            # Cambia nella directory del progetto prima del test
            cd "$SCRIPT_DIR"
            
            # Disabilita temporaneamente JAVA_TOOL_OPTIONS per la verifica
            local saved_java_opts="$JAVA_TOOL_OPTIONS"
            unset JAVA_TOOL_OPTIONS
            
            if "$java_bin" -version 2>&1; then
                echo -e "${GREEN}JDK 17 installato e funzionante!${NC}"
                
                # Ripristina JAVA_TOOL_OPTIONS se era impostato
                if [[ -n "$saved_java_opts" ]]; then
                    export JAVA_TOOL_OPTIONS="$saved_java_opts"
                fi
                
                # Compila il progetto
                if compile_project "$java_bin"; then
                    create_mcp_config "$java_bin"
                    create_settings_json_config "$java_bin"
                    show_final_instructions "$java_bin"
                else
                    echo -e "${YELLOW}Compilazione fallita, ma JDK installato. Puoi compilare manualmente.${NC}"
                    create_mcp_config "$java_bin"
                    create_settings_json_config "$java_bin"
                    show_final_instructions "$java_bin"
                fi
            else
                echo -e "${RED}Errore: JDK installato ma non funzionante${NC}"
                # Ripristina JAVA_TOOL_OPTIONS se era impostato
                if [[ -n "$saved_java_opts" ]]; then
                    export JAVA_TOOL_OPTIONS="$saved_java_opts"
                fi
                exit 1
            fi
        else
            echo -e "${RED}Errore: JDK non installato correttamente${NC}"
            exit 1
        fi
}

# Avvia script
main "$@"
