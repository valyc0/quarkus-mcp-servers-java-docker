# Quarkus MCP Servers

Server MCP (Model Context Protocol) universali basati su Quarkus. Supporta database JDBC, filesystem, container Docker e molto altro con un singolo JAR.

## 🚀 Setup Rapido

### 1. Setup JDK 17

Il progetto richiede JDK 17. Usa lo script automatico per scaricarlo e configurarlo:

```bash
# Setup automatico JDK 17
./setup-jdk17.sh
```

Lo script:
- Rileva automaticamente l'architettura (x64, aarch64) e OS (Linux, macOS)
- Scarica JDK 17 da Eclipse Temurin
- Configura le variabili d'ambiente JAVA_HOME e PATH
- Crea un file di configurazione `jdk17/jdk-env.sh` per riutilizzi futuri

Dopo l'installazione, carica l'ambiente JDK:
```bash
source jdk17/jdk-env.sh
```

### 2. Compilazione

Una volta configurato JDK 17, compila il progetto:

```bash
# Compila tutti i moduli (senza test per velocità)
./build-no-tests.sh
```

Il comando creerà i JAR in:
- `jdbc/target/mcp-server-jdbc-universal-999-SNAPSHOT.jar` - Server JDBC
- `filesystem/target/mcp-server-filesystem-999-SNAPSHOT.jar` - Server Filesystem
- `containers/target/mcp-server-containers-999-SNAPSHOT.jar` - Server Container
- `jvminsight/target/mcp-server-jvminsight-999-SNAPSHOT.jar` - Server JVM Insights

## 🐳 Utilizzo con Docker

### Build immagine Docker

```bash
# Builda l'immagine Docker con tutti i server
./docker-mcp.sh build
```

### Server JDBC

```bash
# Oracle (richiede Oracle su localhost:1521)
./docker-mcp.sh oracle

# Oracle in modalità read-only (solo lettura)
./docker-mcp.sh run jdbc --jdbc.url="jdbc:oracle:thin:@localhost:1521:xe" --jdbc.user="ORACLEUSR" --jdbc.password="ORACLEUSR" --jdbc.readonly=true

# H2 in memoria
./docker-mcp.sh h2

# Server JDBC generico
./docker-mcp.sh run jdbc --jdbc.url="jdbc:postgresql://localhost:5432/mydb" --jdbc.user="user" --jdbc.password="pass"

# Server JDBC in modalità read-only
./docker-mcp.sh run jdbc --jdbc.url="jdbc:postgresql://localhost:5432/mydb" --jdbc.user="user" --jdbc.password="pass" --jdbc.readonly=true
```

### Server Filesystem

```bash
# Monta /tmp come directory condivisa
./docker-mcp.sh filesystem /tmp

# Directory personalizzata
./docker-mcp.sh filesystem /path/to/directory
```

### Altri server

```bash
# Container Docker
./docker-mcp.sh run containers

# JVM Insights
./docker-mcp.sh run jvminsight
```

## ⚙️ Configurazione MCP

### Generazione automatica

Genera automaticamente la configurazione MCP per Claude Desktop:

```bash
./docker-mcp.sh config
```

Questo crea il file `mcp-docker-config.json` con configurazioni per:
- Server JDBC Oracle
- Server JDBC H2 
- Server Filesystem
- Server Container
- Server JVM Insights

### Configurazione manuale per Claude Desktop

#### Linux/macOS
Copia il contenuto del file generato in:
```
~/.config/claude/claude_desktop_config.json
```

#### Windows
```
%APPDATA%/Claude/claude_desktop_config.json
```

### Configurazione per Docker

#### Esempio configurazione Docker:

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
        "--jdbc.password=ORACLEUSR",
        "--jdbc.readonly=false"
      ]
    },
    "jdbc-oracle-readonly": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm", "--network", "host",
        "mcp-servers:latest", "jdbc",
        "--jdbc.url=jdbc:oracle:thin:@localhost:1521:xe",
        "--jdbc.user=ORACLEUSR",
        "--jdbc.password=ORACLEUSR",
        "--jdbc.readonly=true"
      ]
    },
    "jdbc-h2-docker": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm", "-p", "3000:3000",
        "mcp-servers:latest", "jdbc",
        "--jdbc.url=jdbc:h2:mem:testdb",
        "--jdbc.user=sa",
        "--jdbc.password=",
        "--jdbc.readonly=false"
      ]
    },
    "filesystem-docker": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm", "-v", "/tmp:/mnt/shared",
        "mcp-servers:latest", "filesystem", "/mnt/shared"
      ]
    }
  }
}
```

### Configurazione per Esecuzione Locale (senza Docker)

Quando esegui i server localmente senza Docker, usa questa configurazione:

```json
{
  "mcp": {
    "servers": {
      "jdbc-oracle": {
        "type": "stdio",
        "command": "/workspace/db-ready/quarkus-mcp-servers/jdk17/bin/java",
        "args": [
          "-jar",
          "/workspace/db-ready/quarkus-mcp-servers/jdbc/target/mcp-server-jdbc-universal-999-SNAPSHOT.jar",
          "--jdbc.url=jdbc:oracle:thin:@localhost:1521:xe",
          "--jdbc.user=ORACLEUSR",
          "--jdbc.password=ORACLEUSR",
          "--jdbc.readonly=false"
        ],
        "cwd": "/workspace/db-ready/quarkus-mcp-servers/jdbc"
      },
      "jdbc-oracle-readonly": {
        "type": "stdio",
        "command": "/workspace/db-ready/quarkus-mcp-servers/jdk17/bin/java",
        "args": [
          "-jar",
          "/workspace/db-ready/quarkus-mcp-servers/jdbc/target/mcp-server-jdbc-universal-999-SNAPSHOT.jar",
          "--jdbc.url=jdbc:oracle:thin:@localhost:1521:xe",
          "--jdbc.user=ORACLEUSR",
          "--jdbc.password=ORACLEUSR",
          "--jdbc.readonly=true"
        ],
        "cwd": "/workspace/db-ready/quarkus-mcp-servers/jdbc"
      },
      "jdbc-h2": {
        "type": "stdio",
        "command": "/workspace/db-ready/quarkus-mcp-servers/jdk17/bin/java",
        "args": [
          "-jar",
          "/workspace/db-ready/quarkus-mcp-servers/jdbc/target/mcp-server-jdbc-universal-999-SNAPSHOT.jar",
          "--jdbc.url=jdbc:h2:mem:testdb",
          "--jdbc.user=sa",
          "--jdbc.password=",
          "--jdbc.readonly=false"
        ],
        "cwd": "/workspace/db-ready/quarkus-mcp-servers/jdbc"
      },
      "filesystem-local": {
        "type": "stdio",
        "command": "/workspace/db-ready/quarkus-mcp-servers/jdk17/bin/java",
        "args": [
          "-jar",
          "/workspace/db-ready/quarkus-mcp-servers/filesystem/target/mcp-server-filesystem-999-SNAPSHOT.jar",
          "/tmp"
        ],
        "cwd": "/workspace/db-ready/quarkus-mcp-servers/filesystem"
      },
      "containers-local": {
        "type": "stdio",
        "command": "/workspace/db-ready/quarkus-mcp-servers/jdk17/bin/java",
        "args": [
          "-jar",
          "/workspace/db-ready/quarkus-mcp-servers/containers/target/mcp-server-containers-999-SNAPSHOT.jar"
        ],
        "cwd": "/workspace/db-ready/quarkus-mcp-servers/containers"
      }
    }
  }
}
```

## 📋 Comandi Disponibili

### setup-jdk17.sh
```bash
./setup-jdk17.sh              # Setup automatico JDK 17
./setup-jdk17.sh --help       # Mostra opzioni disponibili
./setup-jdk17.sh --force      # Forza reinstallazione anche se esiste
```

### docker-mcp.sh
```bash
./docker-mcp.sh build         # Builda immagine Docker
./docker-mcp.sh oracle        # Server JDBC Oracle
./docker-mcp.sh h2            # Server JDBC H2
./docker-mcp.sh filesystem [path]  # Server Filesystem
./docker-mcp.sh config        # Genera configurazione MCP
./docker-mcp.sh help          # Mostra aiuto
```

## 🗄️ Database Supportati

Il server JDBC supporta tutti i database con driver JDBC:

- **Oracle** - `jdbc:oracle:thin:@host:port:sid`
- **PostgreSQL** - `jdbc:postgresql://host:port/database`
- **MySQL** - `jdbc:mysql://host:port/database`
- **H2** - `jdbc:h2:mem:testdb` (in memoria) o `jdbc:h2:file:/path/to/db`
- **SQLite** - `jdbc:sqlite:/path/to/database.db`
- **SQL Server** - `jdbc:sqlserver://host:port;databaseName=db`
- **MariaDB** - `jdbc:mariadb://host:port/database`

## 🔒 Modalità Read-Only per Server JDBC

Il server JDBC supporta una modalità **read-only** che permette di esplorare e interrogare i database senza rischio di modifiche accidentali.

### Funzionalità in Modalità Read-Only

**✅ Operazioni Permesse:**
- `read_query` - Esecuzione di query SELECT
- `list_tables` - Visualizzazione tabelle
- `describe_table` - Descrizione struttura tabelle  
- `database_info` - Informazioni database (include stato read-only)

**❌ Operazioni Bloccate:**
- `write_query` - INSERT, UPDATE, DELETE
- `create_table` - Creazione tabelle

### Come Attivare la Modalità Read-Only

#### Docker:
```bash
./docker-mcp.sh run jdbc \
  --jdbc.url="jdbc:oracle:thin:@localhost:1521:xe" \
  --jdbc.user="ORACLEUSR" \
  --jdbc.password="ORACLEUSR" \
  --jdbc.readonly=true
```

#### Esecuzione Locale:
```bash
java -jar jdbc/target/mcp-server-jdbc-universal-999-SNAPSHOT.jar \
  --jdbc.url="jdbc:h2:mem:testdb" \
  --jdbc.user="sa" \
  --jdbc.password="" \
  --jdbc.readonly=true
```

### Verifica Stato Read-Only

Usa il tool `database_info` per verificare lo stato:
```json
{
  "database_product_name": "Oracle",
  "mcp_server_readonly_mode": "true",
  "read_only": "false",
  ...
}
```

**Nota:** `mcp_server_readonly_mode` indica la modalità del server MCP, mentre `read_only` indica se il database stesso è in sola lettura.

## 🔧 Esecuzione Locale (senza Docker)

### Server JDBC
```bash
source jdk17/jdk-env.sh

# Modalità standard (read/write)
java -jar jdbc/target/mcp-server-jdbc-universal-999-SNAPSHOT.jar \
  --jdbc.url="jdbc:h2:mem:testdb" \
  --jdbc.user="sa" \
  --jdbc.password="" \
  --jdbc.readonly=false

# Modalità read-only (solo lettura)
java -jar jdbc/target/mcp-server-jdbc-universal-999-SNAPSHOT.jar \
  --jdbc.url="jdbc:h2:mem:testdb" \
  --jdbc.user="sa" \
  --jdbc.password="" \
  --jdbc.readonly=true
```

### Server Filesystem
```bash
source jdk17/jdk-env.sh
java -jar filesystem/target/mcp-server-filesystem-999-SNAPSHOT.jar /tmp
```

## 🔍 Testing

### Test server locale
```bash
# Test JDBC H2
./run-server.sh jdbc --jdbc.url="jdbc:h2:mem:testdb" --jdbc.user="sa"

# Test Filesystem
./run-server.sh filesystem /tmp
```

### Test Docker
```bash
# Test setup Docker
./test-docker-setup.sh
```

## 📁 Struttura Progetto

```
quarkus-mcp-servers/
├── setup-jdk17.sh          # Setup automatico JDK 17
├── docker-mcp.sh           # Script Docker per MCP
├── build-no-tests.sh       # Build senza test
├── run-server.sh           # Esecuzione server locale
├── jdbc/                   # Server JDBC
├── filesystem/             # Server Filesystem  
├── containers/             # Server Container Docker
├── jvminsight/            # Server JVM Insights
├── jdk17/                 # JDK 17 (creato da setup)
├── mcp-configs/           # Configurazioni MCP
└── mcp-docker-config.json # Config generata per Docker
```

## 🚨 Troubleshooting

### JDK 17 non trovato
```bash
# Reinstalla JDK 17
./setup-jdk17.sh --force

# Carica ambiente
source jdk17/jdk-env.sh

# Verifica versione
java -version
```

### Docker image non trovata
```bash
# Rebuilda immagine
./docker-mcp.sh build
```

### Errori di connessione database
- Verifica che il database sia in esecuzione
- Controlla URL, username e password
- Per Oracle, assicurati che sia su localhost:1521

### Problemi con Docker Desktop
```bash
# Su Linux, assicurati che Docker sia in esecuzione
sudo systemctl start docker

# Aggiungi utente al gruppo docker
sudo usermod -aG docker $USER
# Poi fai logout/login
```

## 📚 Documentazione Aggiuntiva

- [README Docker](README-DOCKER.md) - Guida completa Docker
- [README Italiano](README-ITALIANO.md) - Documentazione in italiano
- [Standalone Java Setup](standalone-java-setup.md) - Setup Java standalone

## 🤝 Contributi

1. Fork del repository
2. Crea feature branch (`git checkout -b feature/amazing-feature`)
3. Commit dei cambiamenti (`git commit -m 'Add amazing feature'`)
4. Push al branch (`git push origin feature/amazing-feature`)
5. Apri Pull Request

## 📝 Licenza

Questo progetto è sotto licenza MIT. Vedi il file [LICENSE](LICENSE) per dettagli.
