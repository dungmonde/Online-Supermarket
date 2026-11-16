package dao;

import model.Item3;
import model.Item3.Status;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public final class ItemDAO3 extends DAO3 {
    public enum Availability { OK, NOT_FOR_SALE, INSUFFICIENT_STOCK, PRICE_CHANGED }
    public record OrderItemCheck(Availability availability, Item3 item) {}

    public ItemDAO3(Connection con) {
        super(con);
    }

    public List<Item3> getAvailableItems() throws SQLException {
        try (var ps = con.prepareStatement("SELECT * FROM tblItem3 WHERE status = 'ACTIVE' ORDER BY itemID")) {
            return readItems(ps.executeQuery());
        }
    }

    public List<Item3> searchItemsByName(String name) throws SQLException {
        return search(name, false);
    }

    public List<Item3> searchAvailableItemsByName(String name) throws SQLException {
        return search(name, true);
    }

    private List<Item3> search(String name, boolean availableOnly) throws SQLException {
        String sql = "SELECT * FROM tblItem3 WHERE LOCATE(?, itemName) > 0"
                + (availableOnly ? " AND status = 'ACTIVE'" : "") + " ORDER BY itemID";
        try (var ps = con.prepareStatement(sql)) {
            ps.setString(1, name);
            return readItems(ps.executeQuery());
        }
    }

    public Item3 getItem(long itemID) throws SQLException {
        return readItem(itemID, false);
    }

    private Item3 readItem(long itemID, boolean forUpdate) throws SQLException {
        String sql = "SELECT * FROM tblItem3 WHERE itemID = ?" + (forUpdate ? " FOR UPDATE" : "");
        try (var ps = con.prepareStatement(sql)) {
            ps.setLong(1, itemID);
            try (var rows = ps.executeQuery()) {
                return rows.next() ? map(rows) : null;
            }
        }
    }

    public boolean updateItem(Item3 itemInfo) throws SQLException {
        String sql = """
                UPDATE tblItem3 SET itemName=?, unit=?, description=?, price=?, status=?
                WHERE itemID=?
                """;
        try (var ps = con.prepareStatement(sql)) {
            ps.setString(1, itemInfo.itemName());
            ps.setString(2, itemInfo.unit());
            ps.setString(3, itemInfo.description());
            ps.setBigDecimal(4, itemInfo.price());
            ps.setString(5, itemInfo.status().name());
            ps.setLong(6, itemInfo.itemID());
            return ps.executeUpdate() == 1;
        }
    }

    // Called inside the cart transaction, so price and stock stay stable until it ends.
    public OrderItemCheck checkOrderItem(long itemID, BigDecimal quantity, BigDecimal unitPrice)
            throws SQLException {
        Item3 item = readItem(itemID, true);
        if (item == null || item.status() != Status.ACTIVE) {
            return new OrderItemCheck(Availability.NOT_FOR_SALE, item);
        }
        if (quantity.compareTo(item.quantity()) > 0) {
            return new OrderItemCheck(Availability.INSUFFICIENT_STOCK, item);
        }
        if (item.price().compareTo(unitPrice) != 0) {
            return new OrderItemCheck(Availability.PRICE_CHANGED, item);
        }
        return new OrderItemCheck(Availability.OK, item);
    }

    private static List<Item3> readItems(ResultSet rows) throws SQLException {
        try (rows) {
            List<Item3> items = new ArrayList<>();
            while (rows.next()) {
                items.add(map(rows));
            }
            return items;
        }
    }

    private static Item3 map(ResultSet rows) throws SQLException {
        return new Item3(rows.getLong("itemID"), rows.getString("itemName"),
                rows.getString("unit"), rows.getString("description"), rows.getBigDecimal("price"),
                rows.getBigDecimal("quantity"), Status.valueOf(rows.getString("status")));
    }
}
