package com.example.Smart.Attendance.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Map;

/**
 * Startup verification component that ensures database schema
 * supports server-side signing by checking column types.
 *
 * Fails application startup loudly if critical columns are still VARCHAR(255).
 */
@Component
public class DatabaseSchemaVerifier implements CommandLineRunner {

    private static final Logger logger = LoggerFactory.getLogger(DatabaseSchemaVerifier.class);

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Override
    public void run(String... args) throws Exception {
        logger.info("🔍 Verifying database schema for server-side signing support...");
        verifyColumnTypes();
        logger.info("✅ Database schema verification complete - server-side signing ready");
    }

    private void verifyColumnTypes() {
        // Query information_schema.columns for critical columns
        String sql = """
            SELECT table_name, column_name, data_type, character_maximum_length
            FROM information_schema.columns
            WHERE table_name = 'attendance_sessions'
              AND column_name IN ('payload_b64', 'signature_b64')
            ORDER BY table_name, column_name
        """;

        List<Map<String, Object>> columns = jdbcTemplate.queryForList(sql);

        logger.info("📊 Checking attendance_sessions column types:");

        for (Map<String, Object> column : columns) {
            String tableName = (String) column.get("table_name");
            String columnName = (String) column.get("column_name");
            String dataType = (String) column.get("data_type");
            Integer maxLength = (Integer) column.get("character_maximum_length");

            logger.info("  - {}.{}: {} {}", tableName, columnName, dataType,
                       maxLength != null ? "(max " + maxLength + ")" : "");

            // Critical security check: RSA signatures require TEXT, not VARCHAR(255)
            if ("signature_b64".equals(columnName) && "character varying".equals(dataType) && maxLength != null && maxLength == 255) {
                throw new IllegalStateException(
                    "🚨 CRITICAL: attendance_sessions.signature_b64 is still VARCHAR(255)! " +
                    "RSA-2048 signatures (~344 chars) will be truncated. " +
                    "Run Flyway migration V3__widen_signed_columns.sql to fix this."
                );
            }

            if ("payload_b64".equals(columnName) && "character varying".equals(dataType) && maxLength != null && maxLength == 255) {
                throw new IllegalStateException(
                    "🚨 CRITICAL: attendance_sessions.payload_b64 is still VARCHAR(255)! " +
                    "JSON payloads may be truncated. " +
                    "Run Flyway migration V3__widen_signed_columns.sql to fix this."
                );
            }

            // Verify TEXT type is properly set
            if (("payload_b64".equals(columnName) || "signature_b64".equals(columnName)) && "text".equals(dataType)) {
                logger.info("  ✅ {}.{} correctly configured as TEXT", tableName, columnName);
            }
        }

        // Verify we found both columns
        if (columns.size() < 2) {
            logger.warn("⚠️  Expected 2 columns (payload_b64, signature_b64) but found {}", columns.size());
        }
    }
}
