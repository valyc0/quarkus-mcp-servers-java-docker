# Quarkus MCP Servers - Standalone Java Setup

This document describes how to run the Quarkus MCP servers using plain Java without JBang.

## Prerequisites

- Java 17 or higher
- Maven 3.8.1 or higher

## Building the Project

From the root directory, build all modules:

```bash
mvn clean install
```

## Running Individual Servers

### JDBC Server

```bash
# Navigate to the jdbc module
cd jdbc

# Run with Maven (development mode)
mvn quarkus:dev

# Or build and run the JAR
mvn package
java -jar target/quarkus-app/quarkus-run.jar --jdbc.url="jdbc:h2:mem:testdb" --jdbc.user="sa" --jdbc.password=""
```

### Filesystem Server

```bash
cd filesystem
mvn quarkus:dev
# Or
mvn package
java -jar target/quarkus-app/quarkus-run.jar /path/to/serve
```

### JVM Insight Server

```bash
cd jvminsight
mvn quarkus:dev
# Or
mvn package
java -jar target/quarkus-app/quarkus-run.jar
```

### Kubernetes Server

```bash
cd kubernetes
mvn quarkus:dev
# Or
mvn package
java -jar target/quarkus-app/quarkus-run.jar
```

### Containers Server

```bash
cd containers
mvn quarkus:dev
# Or
mvn package
java -jar target/quarkus-app/quarkus-run.jar
```

## Configuration

Each server can be configured using:

1. Command line arguments: `--property.name=value`
2. Environment variables: `PROPERTY_NAME=value`
3. System properties: `-Dproperty.name=value`
4. application.properties file

## Building Native Executables

To build native executables (requires GraalVM):

```bash
# For a specific module
cd jdbc
mvn package -Pnative

# The native executable will be in target/
./target/mcp-server-jdbc-999-SNAPSHOT-runner
```

## Docker Images

To build Docker images:

```bash
# For a specific module
cd jdbc
mvn package -Pcontainer

# Run the container
docker run -p 8080:8080 quarkus/mcp-server-jdbc
```

## MCP Server Configuration

After building the project, you can configure the MCP servers in your MCP client configuration file. Here are the different ways to configure each server:

### Using Built JAR Files (Recommended)

#### JDBC Server
```json
{
  "mcpServers": {
    "jdbc": {
      "command": "java",
      "args": [
        "-jar",
        "/workspace/db-ready/quarkus-mcp-servers/jdbc/target/quarkus-app/quarkus-run.jar",
        "--jdbc.url=jdbc:postgresql://localhost:5432/mydb",
        "--jdbc.user=username",
        "--jdbc.password=password"
      ]
    }
  }
}
```

#### Filesystem Server
```json
{
  "mcpServers": {
    "filesystem": {
      "command": "java",
      "args": [
        "-jar",
        "/workspace/db-ready/quarkus-mcp-servers/filesystem/target/quarkus-app/quarkus-run.jar",
        "/path/to/serve"
      ]
    }
  }
}
```

#### JVM Insight Server
```json
{
  "mcpServers": {
    "jvminsight": {
      "command": "java",
      "args": [
        "-jar",
        "/workspace/db-ready/quarkus-mcp-servers/jvminsight/target/quarkus-app/quarkus-run.jar"
      ]
    }
  }
}
```

#### Kubernetes Server
```json
{
  "mcpServers": {
    "kubernetes": {
      "command": "java",
      "args": [
        "-jar",
        "/workspace/db-ready/quarkus-mcp-servers/kubernetes/target/quarkus-app/quarkus-run.jar"
      ]
    }
  }
}
```

#### Containers Server
```json
{
  "mcpServers": {
    "containers": {
      "command": "java",
      "args": [
        "-jar",
        "/workspace/db-ready/quarkus-mcp-servers/containers/target/quarkus-app/quarkus-run.jar"
      ]
    }
  }
}
```

### Using Native Executables (If Built with GraalVM)

After building native executables with `mvn package -Pnative`:

#### JDBC Server (Native)
```json
{
  "mcpServers": {
    "jdbc": {
      "command": "/workspace/db-ready/quarkus-mcp-servers/jdbc/target/mcp-server-jdbc-999-SNAPSHOT-runner",
      "args": [
        "--jdbc.url=jdbc:postgresql://localhost:5432/mydb",
        "--jdbc.user=username",
        "--jdbc.password=password"
      ]
    }
  }
}
```

#### Filesystem Server (Native)
```json
{
  "mcpServers": {
    "filesystem": {
      "command": "/workspace/db-ready/quarkus-mcp-servers/filesystem/target/mcp-server-filesystem-999-SNAPSHOT-runner",
      "args": [
        "/path/to/serve"
      ]
    }
  }
}
```

### Using Maven Development Mode (For Testing)

#### JDBC Server (Dev Mode)
```json
{
  "mcpServers": {
    "jdbc": {
      "command": "mvn",
      "args": [
        "quarkus:dev",
        "-Djdbc.url=jdbc:postgresql://localhost:5432/mydb",
        "-Djdbc.user=username",
        "-Djdbc.password=password"
      ],
      "cwd": "/workspace/db-ready/quarkus-mcp-servers/jdbc"
    }
  }
}
```

### Complete Example Configuration

Here's a complete MCP client configuration with multiple servers:

```json
{
  "mcpServers": {
    "jdbc": {
      "command": "java",
      "args": [
        "-jar",
        "/workspace/db-ready/quarkus-mcp-servers/jdbc/target/quarkus-app/quarkus-run.jar",
        "--jdbc.url=jdbc:h2:mem:testdb",
        "--jdbc.user=sa",
        "--jdbc.password="
      ]
    },
    "filesystem": {
      "command": "java",
      "args": [
        "-jar",
        "/workspace/db-ready/quarkus-mcp-servers/filesystem/target/quarkus-app/quarkus-run.jar",
        "/home/user/documents"
      ]
    },
    "jvminsight": {
      "command": "java",
      "args": [
        "-jar",
        "/workspace/db-ready/quarkus-mcp-servers/jvminsight/target/quarkus-app/quarkus-run.jar"
      ]
    },
    "kubernetes": {
      "command": "java",
      "args": [
        "-jar",
        "/workspace/db-ready/quarkus-mcp-servers/kubernetes/target/quarkus-app/quarkus-run.jar"
      ]
    }
  }
}
```

### Configuration Notes

1. **Path Adjustments**: Update the JAR file paths to match your actual build location
2. **JDBC Configuration**: Replace database URL, username, and password with your actual values
3. **Filesystem Path**: Set the appropriate directory path for the filesystem server
4. **Native Executables**: Provide faster startup times but require GraalVM to build
5. **Development Mode**: Use Maven dev mode for development and testing, not production

### Common JDBC URLs Examples

- **H2 In-Memory**: `jdbc:h2:mem:testdb`
- **H2 File**: `jdbc:h2:file:./data/mydb`
- **PostgreSQL**: `jdbc:postgresql://localhost:5432/mydb`
- **MySQL**: `jdbc:mysql://localhost:3306/mydb`
- **SQLite**: `jdbc:sqlite:./data/mydb.db`
