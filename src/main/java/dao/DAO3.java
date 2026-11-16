package dao;

import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.PBEKeySpec;
import java.security.GeneralSecurityException;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.HexFormat;

public abstract class DAO3 {
    private static final SecureRandom PASSWORD_RANDOM = new SecureRandom();
    protected final Connection con;

    protected DAO3(Connection con) {
        this.con = con;
    }

    public static Connection connect() throws SQLException {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            throw new SQLException("MySQL JDBC driver unavailable", e);
        }
        String url = System.getenv().getOrDefault("SUPERMARKET_DB_URL",
                "jdbc:mysql://127.0.0.1:3306/OnlineSupermarketDB3");
        String user = System.getenv().getOrDefault("SUPERMARKET_DB_USER", "root");
        String password = System.getenv().getOrDefault("SUPERMARKET_DB_PASSWORD", "");
        return DriverManager.getConnection(url, user, password);
    }

    protected static boolean passwordMatches(String candidate, String stored) {
        String[] parts = stored.split(":", -1);
        if (parts.length != 2) {
            return false;
        }
        HexFormat hex = HexFormat.of();
        try {
            return MessageDigest.isEqual(hex.parseHex(parts[1]), derivePassword(candidate, hex.parseHex(parts[0])));
        } catch (IllegalArgumentException e) {
            return false;
        }
    }

    protected static String hashPassword(String password) {
        byte[] salt = new byte[16];
        PASSWORD_RANDOM.nextBytes(salt);
        HexFormat hex = HexFormat.of();
        return hex.formatHex(salt) + ":" + hex.formatHex(derivePassword(password, salt));
    }

    private static byte[] derivePassword(String password, byte[] salt) {
        PBEKeySpec spec = new PBEKeySpec(password.toCharArray(), salt, 210_000, 256);
        try {
            return SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256").generateSecret(spec).getEncoded();
        } catch (GeneralSecurityException e) {
            throw new IllegalStateException("PBKDF2 unavailable", e);
        } finally {
            spec.clearPassword();
        }
    }
}
