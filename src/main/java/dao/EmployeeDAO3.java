package dao;

import model.Employee3;

import java.sql.Connection;
import java.sql.SQLException;

public final class EmployeeDAO3 extends DAO3 {
    public EmployeeDAO3(Connection con) {
        super(con);
    }

    public Employee3 authenticate(String username, String password) throws SQLException {
        try (var ps = con.prepareStatement("""
                SELECT employeeID, fullName, password FROM tblEmployee3
                WHERE username=? AND status='ACTIVE' AND role='WAREHOUSE'
                """)) {
            ps.setString(1, username);
            try (var rows = ps.executeQuery()) {
                if (rows.next() && passwordMatches(password, rows.getString("password"))) {
                    return new Employee3(rows.getLong("employeeID"), rows.getString("fullName"));
                }
                return null;
            }
        }
    }

    public boolean canEditItems(long employeeID) throws SQLException {
        try (var ps = con.prepareStatement("""
                SELECT employeeID FROM tblEmployee3
                WHERE employeeID=? AND role='WAREHOUSE' AND status='ACTIVE'
                """)) {
            ps.setLong(1, employeeID);
            try (var rows = ps.executeQuery()) {
                return rows.next();
            }
        }
    }

}
