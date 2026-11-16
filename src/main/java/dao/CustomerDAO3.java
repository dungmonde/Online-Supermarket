package dao;

import model.Customer3;

import java.sql.Connection;
import java.sql.SQLException;
import java.sql.SQLIntegrityConstraintViolationException;

public final class CustomerDAO3 extends DAO3 {
    public CustomerDAO3(Connection con) {
        super(con);
    }

    public boolean registerMember(String fullName, String phoneNumber, String email, String address,
                                  String username, String password) throws SQLException {
        String sql = """
                INSERT INTO tblCustomer3 (fullName, phoneNumber, email, address, username, password, status)
                SELECT ?, ?, ?, ?, ?, ?, 'ACTIVE'
                WHERE NOT EXISTS (SELECT 1 FROM tblEmployee3 WHERE username=?)
                """;
        try (var ps = con.prepareStatement(sql)) {
            ps.setString(1, fullName);
            ps.setString(2, phoneNumber);
            ps.setString(3, email);
            ps.setString(4, address);
            ps.setString(5, username);
            ps.setString(6, hashPassword(password));
            ps.setString(7, username);
            return ps.executeUpdate() == 1;
        } catch (SQLIntegrityConstraintViolationException e) {
            if (e.getErrorCode() == 1062) {
                return false;
            }
            throw e;
        }
    }

    public Customer3 authenticate(String username, String password) throws SQLException {
        try (var ps = con.prepareStatement("""
                SELECT customerID, fullName, password FROM tblCustomer3
                WHERE username=? AND status='ACTIVE'
                """)) {
            ps.setString(1, username);
            try (var rows = ps.executeQuery()) {
                if (rows.next() && passwordMatches(password, rows.getString("password"))) {
                    return new Customer3(rows.getLong("customerID"), rows.getString("fullName"));
                }
                return null;
            }
        }
    }
}
