package dao;

import model.ShoppingCart3;

import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Statement;
import java.time.LocalDateTime;

public final class ShoppingCartDAO3 extends DAO3 {
    public ShoppingCartDAO3(Connection con) {
        super(con);
    }

    public ShoppingCart3 createCart() throws SQLException {
        try (var ps = con.prepareStatement("INSERT INTO tblShoppingCart3 () VALUES ()",
                Statement.RETURN_GENERATED_KEYS)) {
            ps.executeUpdate();
            try (var keys = ps.getGeneratedKeys()) {
                if (!keys.next()) {
                    throw new SQLException("Missing generated cartID");
                }
                return getCart(keys.getLong(1));
            }
        }
    }

    public ShoppingCart3 getCart(long cartID) throws SQLException {
        try (var ps = con.prepareStatement("SELECT * FROM tblShoppingCart3 WHERE cartID=?")) {
            ps.setLong(1, cartID);
            try (var rows = ps.executeQuery()) {
                return rows.next() ? new ShoppingCart3(cartID,
                        rows.getObject("createdAt", LocalDateTime.class),
                        rows.getObject("updatedAt", LocalDateTime.class)) : null;
            }
        }
    }

    public boolean lockCart(long cartID) throws SQLException {
        try (var ps = con.prepareStatement("SELECT cartID FROM tblShoppingCart3 WHERE cartID=? FOR UPDATE")) {
            ps.setLong(1, cartID);
            try (var rows = ps.executeQuery()) {
                return rows.next();
            }
        }
    }

    public void touchCart(long cartID) throws SQLException {
        try (var ps = con.prepareStatement("UPDATE tblShoppingCart3 SET updatedAt=CURRENT_TIMESTAMP WHERE cartID=?")) {
            ps.setLong(1, cartID);
            ps.executeUpdate();
        }
    }

    public void clearCart(long cartID) throws SQLException {
        try (var ps = con.prepareStatement("DELETE FROM tblCartItem3 WHERE cartID=?")) {
            ps.setLong(1, cartID);
            ps.executeUpdate();
        }
        touchCart(cartID);
    }
}
