# Quarkus MCP JDBC Server - Guida Rapida

Server MCP (Model Context Protocol) universale per database JDBC basato su Quarkus. Supporta tutti i principali database con un singolo JAR.

## 🚀 Quick Start

### 1. Compilazione

```bash
# Compila il progetto (senza test per velocità)
./build-no-tests.sh
```

Il comando creerà il JAR universale in:
```
jdbc/target/mcp-server-jdbc-universal-999-SNAPSHOT.jar
```

### 2. Test del Server

```bash
# Test con database H2 in memoria
./run-server.sh jdbc --jdbc.url="jdbc:h2:mem:testdb" --jdbc.user="sa" --jdbc.password=""
```

### 3. Configurazione MCP per Claude Desktop

Aggiungi questa configurazione nel file `settings.json` di VS Code o nella configurazione di Claude Desktop:

```json
{
    "mcp": {
        "servers": {
            "jdbc-oracle": {
                "type": "stdio",
                "command": "java",
                "args": [
                    "-jar",
                    "/workspace/db-ready/quarkus-mcp-servers/jdbc/target/mcp-server-jdbc-universal-999-SNAPSHOT.jar",
                    "--jdbc.url=jdbc:oracle:thin:@localhost:1521:xe",
                    "--jdbc.user=ORACLEUSR",
                    "--jdbc.password=ORACLEUSR"
                ],
                "cwd": "/workspace/db-ready/quarkus-mcp-servers/jdbc"
            }
        }
    }
}
```

## 🗄️ Database Supportati

Il JAR universale include driver per:

| Database | URL JDBC Example | Driver Incluso |
|----------|------------------|----------------|
| **Oracle** | `jdbc:oracle:thin:@localhost:1521:xe` | ✅ ojdbc11 |
| **PostgreSQL** | `jdbc:postgresql://localhost:5432/mydb` | ✅ postgresql |
| **MySQL** | `jdbc:mysql://localhost:3306/mydb` | ✅ mysql-connector-j |
| **MariaDB** | `jdbc:mariadb://localhost:3306/mydb` | ✅ mariadb-java-client |
| **SQL Server** | `jdbc:sqlserver://localhost:1433;databaseName=mydb` | ✅ mssql-jdbc |
| **H2** | `jdbc:h2:mem:testdb` o `jdbc:h2:file:./data/mydb` | ✅ h2 |
| **SQLite** | `jdbc:sqlite:./data/mydb.db` | ✅ sqlite-jdbc |
| **IBM DB2** | `jdbc:db2://localhost:50000/mydb` | ✅ db2-jcc |

## 📋 Configurazioni MCP per Database

### Oracle
```json
{
    "mcp": {
        "servers": {
            "jdbc-oracle": {
                "type": "stdio",
                "command": "java",
                "args": [
                    "-jar",
                    "/workspace/db-ready/quarkus-mcp-servers/jdbc/target/mcp-server-jdbc-universal-999-SNAPSHOT.jar",
                    "--jdbc.url=jdbc:oracle:thin:@localhost:1521:xe",
                    "--jdbc.user=ORACLEUSR",
                    "--jdbc.password=ORACLEUSR"
                ],
                "cwd": "/workspace/db-ready/quarkus-mcp-servers/jdbc"
            }
        }
    }
}
```

### PostgreSQL
```json
{
    "mcp": {
        "servers": {
            "jdbc-postgres": {
                "type": "stdio",
                "command": "java",
                "args": [
                    "-jar",
                    "/workspace/db-ready/quarkus-mcp-servers/jdbc/target/mcp-server-jdbc-universal-999-SNAPSHOT.jar",
                    "--jdbc.url=jdbc:postgresql://localhost:5432/mydb",
                    "--jdbc.user=postgres",
                    "--jdbc.password=password"
                ],
                "cwd": "/workspace/db-ready/quarkus-mcp-servers/jdbc"
            }
        }
    }
}
```

### MySQL
```json
{
    "mcp": {
        "servers": {
            "jdbc-mysql": {
                "type": "stdio",
                "command": "java",
                "args": [
                    "-jar",
                    "/workspace/db-ready/quarkus-mcp-servers/jdbc/target/mcp-server-jdbc-universal-999-SNAPSHOT.jar",
                    "--jdbc.url=jdbc:mysql://localhost:3306/mydb",
                    "--jdbc.user=root",
                    "--jdbc.password=password"
                ],
                "cwd": "/workspace/db-ready/quarkus-mcp-servers/jdbc"
            }
        }
    }
}
```

### H2 (per test)
```json
{
    "mcp": {
        "servers": {
            "jdbc-h2": {
                "type": "stdio",
                "command": "java",
                "args": [
                    "-jar",
                    "/workspace/db-ready/quarkus-mcp-servers/jdbc/target/mcp-server-jdbc-universal-999-SNAPSHOT.jar",
                    "--jdbc.url=jdbc:h2:mem:testdb",
                    "--jdbc.user=sa",
                    "--jdbc.password="
                ],
                "cwd": "/workspace/db-ready/quarkus-mcp-servers/jdbc"
            }
        }
    }
}
```

## 🛠️ Funzioni MCP Disponibili

Il server JDBC fornisce questi **Tools MCP**:

| Tool | Descrizione | Esempio |
|------|-------------|---------|
| `database_info` | Informazioni su database e driver | Chiama sempre per primo |
| `list_tables` | Lista tutte le tabelle | Mostra schema database |
| `describe_table` | Descrive struttura di una tabella | Colonne, tipi, vincoli |
| `read_query` | Esegue query SELECT | `SELECT * FROM users` |
| `write_query` | Esegue INSERT/UPDATE/DELETE | `INSERT INTO users...` |
| `create_table` | Crea nuove tabelle | `CREATE TABLE...` |

## 🎯 Prompt MCP Disponibili

| Prompt | Descrizione | Parametri |
|--------|-------------|-----------|
| `er_diagram` | Visualizza diagramma ER del database | - |
| `sample_data` | Crea dati di esempio e analisi | `topic` (es: "retail sales") |

## 📦 Build e Backup

```bash
# Compila solo JDBC senza test
./build-no-tests.sh

# Crea backup del codice sorgente (senza JAR)
../create-backup.sh
```

## 🔧 Troubleshooting

### Problemi di Connessione
1. Verifica che il database sia in esecuzione
2. Controlla URL, username e password
3. Assicurati che il database accetti connessioni esterne

### Errori di Driver
Tutti i driver sono inclusi nel JAR universale. Se hai errori:
1. Verifica la sintassi dell'URL JDBC
2. Controlla la versione del database (alcuni driver hanno limitazioni)

### Log e Debug
Il server usa logging standard. Per debug dettagliato, aggiungi:
```bash
--quarkus.log.level=DEBUG
```

## 🌐 Esempi di URL JDBC Completi

```bash
# Oracle con SID
jdbc:oracle:thin:@hostname:1521:xe

# Oracle con Service Name
jdbc:oracle:thin:@//hostname:1521/service_name

# PostgreSQL con SSL
jdbc:postgresql://hostname:5432/dbname?ssl=true

# MySQL con timezone
jdbc:mysql://hostname:3306/dbname?serverTimezone=UTC

# SQL Server con istanza
jdbc:sqlserver://hostname:1433;instanceName=SQLEXPRESS;databaseName=mydb
```

## 📝 Note

- **JAR Size**: ~57MB (include tutti i driver)
- **Java Version**: Richiede Java 17+
- **Memory**: Consigliati almeno 512MB heap
- **Performance**: Ottimizzato per uso MCP (connessioni brevi)
