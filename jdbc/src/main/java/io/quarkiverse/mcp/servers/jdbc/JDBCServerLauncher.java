package io.quarkiverse.mcp.servers.jdbc;

import io.quarkiverse.mcp.servers.shared.SharedApplication;

/**
 * Standalone launcher for JDBC MCP Server.
 * This class provides a main method to run the JDBC server without JBang.
 */
public class JDBCServerLauncher {

    public static void main(String[] args) {
        // Set default properties if not provided
        setDefaultProperty("quarkus.application.name", "mcp-server-jdbc");
        setDefaultProperty("quarkus.log.category.\"io.quarkiverse.mcp\".level", "INFO");

        // Validate JDBC URL is provided
        boolean hasJdbcUrl = false;
        for (String arg : args) {
            if (arg.startsWith("--jdbc.url=") || arg.startsWith("-Djdbc.url=")) {
                hasJdbcUrl = true;
                break;
            }
        }

        if (!hasJdbcUrl && System.getProperty("jdbc.url") == null && System.getenv("JDBC_URL") == null) {
            System.err.println("Error: JDBC URL is required.");
            System.err.println(
                    "Usage: java -jar mcp-server-jdbc.jar --jdbc.url=<url> [--jdbc.user=<user>] [--jdbc.password=<password>] [--jdbc.readonly=<true|false>]");
            System.err.println(
                    "Example: java -jar mcp-server-jdbc.jar --jdbc.url=\"jdbc:h2:mem:testdb\" --jdbc.user=\"sa\" --jdbc.password=\"\" --jdbc.readonly=true");
            System.exit(1);
        }

        SharedApplication.main(args);
    }

    private static void setDefaultProperty(String key, String value) {
        if (System.getProperty(key) == null) {
            System.setProperty(key, value);
        }
    }
}
