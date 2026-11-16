package dao;

import model.CartItem3;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public final class CartItemDAO3 extends DAO3 {
    public CartItemDAO3(Connection con) {
        super(con);
    }

    public List<CartItem3> getCartItems(long cartID) throws SQLException {
        String sql = """
                SELECT c.cartItemID, c.itemID, i.itemName, i.unit, c.quantity, c.displayUnitPrice
                FROM tblCartItem3 c JOIN tblItem3 i ON i.itemID=c.itemID
                WHERE c.cartID=? ORDER BY c.itemID
                """;
        try (var ps = con.prepareStatement(sql)) {
            ps.setLong(1, cartID);
            try (var rows = ps.executeQuery()) {
                List<CartItem3> items = new ArrayList<>();
                while (rows.next()) {
                    items.add(new CartItem3(rows.getLong("cartItemID"), rows.getLong("itemID"),
                            rows.getString("itemName"), rows.getString("unit"),
                            rows.getBigDecimal("quantity"), rows.getBigDecimal("displayUnitPrice")));
                }
                return items;
            }
        }
    }

    public void addOrUpdateItems(long cartID, long itemID, BigDecimal quantity, BigDecimal unitPrice)
            throws SQLException {
        String sql = """
                INSERT INTO tblCartItem3 (cartID, itemID, quantity, displayUnitPrice) VALUES (?, ?, ?, ?)
                ON DUPLICATE KEY UPDATE quantity=quantity + ?, displayUnitPrice=?
                """;
        try (var ps = con.prepareStatement(sql)) {
            ps.setLong(1, cartID);
            ps.setLong(2, itemID);
            ps.setBigDecimal(3, quantity);
            ps.setBigDecimal(4, unitPrice);
            ps.setBigDecimal(5, quantity);
            ps.setBigDecimal(6, unitPrice);
            ps.executeUpdate();
        }
    }

    public void updateItem(long cartID, long itemID, BigDecimal quantity, BigDecimal unitPrice)
            throws SQLException {
        try (var ps = con.prepareStatement("""
                UPDATE tblCartItem3 SET quantity=?, displayUnitPrice=? WHERE cartID=? AND itemID=?
                """)) {
            ps.setBigDecimal(1, quantity);
            ps.setBigDecimal(2, unitPrice);
            ps.setLong(3, cartID);
            ps.setLong(4, itemID);
            ps.executeUpdate();
        }
    }

    public void removeItem(long cartID, long itemID) throws SQLException {
        try (var ps = con.prepareStatement("DELETE FROM tblCartItem3 WHERE cartID=? AND itemID=?")) {
            ps.setLong(1, cartID);
            ps.setLong(2, itemID);
            ps.executeUpdate();
        }
    }
}
