# Dockerfile per Quarkus MCP Servers
# Usa OpenJDK 17 come base
FROM openjdk:17-jdk-slim

# Installa dipendenze di base
RUN apt-get update && \
    apt-get install -y git curl wget && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Installa Maven 3.9.9 manualmente per soddisfare i requisiti di versione
ENV MAVEN_VERSION=3.9.9
ENV MAVEN_HOME=/opt/maven
ENV PATH=$MAVEN_HOME/bin:$PATH

RUN wget -q https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz && \
    tar -xzf apache-maven-${MAVEN_VERSION}-bin.tar.gz && \
    mv apache-maven-${MAVEN_VERSION} ${MAVEN_HOME} && \
    rm apache-maven-${MAVEN_VERSION}-bin.tar.gz

# Crea directory di lavoro
WORKDIR /app

# Copia i file del progetto
COPY . .

# Esegue la build senza test per velocizzare
RUN mvn clean install -DskipTests

# Espone le porte comuni per MCP
EXPOSE 3000 8080

# Crea script di avvio
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
# Funzione per mostrare l'\''help\n\
show_help() {\n\
    echo "Uso: docker run -it mcp-servers [OPZIONI]"\n\
    echo ""\n\
    echo "Server disponibili:"\n\
    echo "  jdbc        - Server database JDBC"\n\
    echo "  filesystem  - Server filesystem"\n\
    echo "  jvminsight  - Server monitoraggio JVM"\n\
    echo "  kubernetes  - Server Kubernetes"\n\
    echo "  containers  - Server containers Docker"\n\
    echo "  jfx         - Server JavaFX"\n\
    echo ""\n\
    echo "Esempi:"\n\
    echo "  docker run -it mcp-servers jdbc --jdbc.url=\"jdbc:h2:mem:testdb\" --jdbc.user=\"sa\""\n\
    echo "  docker run -it mcp-servers filesystem /tmp"\n\
    echo "  docker run -it mcp-servers jvminsight"\n\
    echo ""\n\
    echo "Per Oracle (con database esterno):"\n\
    echo "  docker run -it --network host mcp-servers jdbc \\"\\n\
    echo "    --jdbc.url=\"jdbc:oracle:thin:@localhost:1521:xe\" \\"\\n\
    echo "    --jdbc.user=\"ORACLEUSR\" --jdbc.password=\"ORACLEUSR\""\n\
}\n\
\n\
# Se nessun argomento fornito, mostra help\n\
if [ $# -eq 0 ]; then\n\
    show_help\n\
    exit 1\n\
fi\n\
\n\
# Esegue il run-server.sh con gli argomenti forniti\n\
exec ./run-server.sh "$@"' > /app/docker-entrypoint.sh

# Rende eseguibile lo script
RUN chmod +x /app/docker-entrypoint.sh

# Entry point
ENTRYPOINT ["/app/docker-entrypoint.sh"]
