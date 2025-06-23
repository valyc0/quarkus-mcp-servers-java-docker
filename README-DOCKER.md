# MCP Servers - Configurazione Docker

Questo documento descrive come utilizzare i server MCP (Model Context Protocol) tramite Docker, semplificando l'installazione e la configurazione.

## 🚀 Quick Start

### 1. Build dell'immagine Docker

```bash
# Naviga nella directory del progetto
cd /workspace/db-ready/quarkus-mcp-servers

# Builda l'immagine Docker
./docker-mcp.sh build
```

### 2. Avvio rapido server

```bash
# Server JDBC per Oracle (richiede Oracle su localhost:1521)
./docker-mcp.sh oracle

# Server JDBC per H2 (database in memoria)
./docker-mcp.sh h2

# Server Filesystem
./docker-mcp.sh filesystem /tmp

# Genera configurazione MCP per Claude Desktop
./docker-mcp.sh config
```

## 📋 Comandi Disponibili

### Build e Setup

```bash
# Build immagine Docker
./docker-mcp.sh build

# Genera configurazione MCP
./docker-mcp.sh config
```

### Server Specifici

```bash
# JDBC Oracle
./docker-mcp.sh oracle

# JDBC H2 (in memoria)
./docker-mcp.sh h2

# Filesystem
./docker-mcp.sh filesystem /path/to/directory

# Comando generico
./docker-mcp.sh run [server] [opzioni...]
```

### Esempi di Uso Avanzato

```bash
# JDBC con database PostgreSQL
./docker-mcp.sh run jdbc \
  --jdbc.url="jdbc:postgresql://localhost:5432/mydb" \
  --jdbc.user="postgres" \
  --jdbc.password="password"

# JDBC con MySQL
./docker-mcp.sh run jdbc \
  --jdbc.url="jdbc:mysql://localhost:3306/mydb" \
  --jdbc.user="root" \
  --jdbc.password="password"

# Server JVM Insight
./docker-mcp.sh run jvminsight

# Server Containers (per Docker management)
./docker-mcp.sh run containers

# Server Kubernetes
./docker-mcp.sh run kubernetes
```

## 🐳 Docker Compose

Per un ambiente completo con database Oracle incluso:

```bash
# Avvia tutti i servizi
docker-compose up -d

# Avvia solo il server JDBC Oracle
docker-compose up mcp-jdbc-oracle

# Avvia solo il server H2
docker-compose up mcp-jdbc-h2

# Visualizza i log
docker-compose logs -f mcp-jdbc-oracle

# Ferma tutti i servizi
docker-compose down
```

### Servizi Disponibili in Docker Compose

- `mcp-jdbc-oracle`: Server JDBC per Oracle
- `mcp-jdbc-h2`: Server JDBC per H2 in memoria
- `mcp-filesystem`: Server filesystem
- `mcp-jvminsight`: Server JVM insight
- `mcp-containers`: Server containers management
- `oracle-db`: Database Oracle XE (opzionale)

## ⚙️ Configurazione Claude Desktop

### Generazione Automatica

```bash
./docker-mcp.sh config
```

Questo comando genera il file `mcp-docker-config.json` con la configurazione per Claude Desktop.

### Configurazione Manuale

Copia il contenuto del file generato in:

- **macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
- **Windows**: `%APPDATA%/Claude/claude_desktop_config.json`
- **Linux**: `~/.config/claude/claude_desktop_config.json`

### Esempio di Configurazione

```json
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
    }
  }
}
```

## 🔧 Risoluzione Problemi

### Problemi Comuni

1. **Docker non trovato**
   ```bash
   # Installa Docker su Ubuntu/Debian
   sudo apt update && sudo apt install docker.io
   
   # Aggiungi utente al gruppo docker
   sudo usermod -aG docker $USER
   newgrp docker
   ```

2. **Porta già in uso**
   ```bash
   # Controlla processi su porta 3000
   sudo lsof -i :3000
   
   # Termina processo se necessario
   sudo kill -9 <PID>
   ```

3. **Problemi di connessione Oracle**
   ```bash
   # Verifica che Oracle sia in ascolto
   telnet localhost 1521
   
   # Controlla i log di Oracle
   docker-compose logs oracle-db
   ```

4. **Problemi di permessi filesystem**
   ```bash
   # Assicurati che la directory sia accessibile
   chmod 755 /path/to/directory
   ```

### Debug

```bash
# Controlla lo stato dei container
docker ps -a

# Visualizza i log di un container
docker logs <container_name>

# Accedi al container per debug
docker exec -it <container_name> /bin/bash

# Testa la connessione al database
docker run -it --rm --network host mcp-servers:latest jdbc \
  --jdbc.url="jdbc:oracle:thin:@localhost:1521:xe" \
  --jdbc.user="ORACLEUSR" \
  --jdbc.password="ORACLEUSR"
```

## 📁 Struttura File

```
quarkus-mcp-servers/
├── Dockerfile                 # Immagine Docker principale
├── docker-compose.yml         # Configurazione multi-servizio
├── docker-mcp.sh             # Script di gestione Docker
├── mcp-docker-config.json    # Config generata per Claude Desktop
└── README-DOCKER.md          # Questa documentazione
```

## 🌐 Network e Porte

### Porte Utilizzate

- `3000`: Server MCP H2
- `1521`: Database Oracle (se usando docker-compose)
- `8080`: Porta interna Quarkus (non esposta di default)

### Network Modes

- `--network host`: Per connessioni a database locali
- `bridge` (default): Per servizi isolati
- `docker-compose`: Network personalizzato per comunicazione inter-servizi

## 🔒 Sicurezza

### Best Practices

1. **Non esporre password in plain text**
   ```bash
   # Usa variabili d'ambiente
   export ORACLE_PASSWORD="your_password"
   ./docker-mcp.sh run jdbc --jdbc.password="$ORACLE_PASSWORD"
   ```

2. **Limita accesso filesystem**
   ```bash
   # Monta solo directory necessarie
   docker run -v /specific/path:/mnt/safe mcp-servers:latest filesystem /mnt/safe
   ```

3. **Usa network dedicati**
   ```bash
   # Crea network personalizzato
   docker network create mcp-network
   ```

## 📝 Note Aggiuntive

- L'immagine Docker include Java 17 e Maven
- La build esclude automaticamente i test per velocizzare il processo
- Tutti i server supportano stdin/stdout per compatibilità MCP
- I container sono configurati per restart automatico in caso di errore
