package dao;

import model.OnlineOrder3;
import model.OnlineOrderDetail3;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Types;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

public final class OnlineOrderDAO3 extends DAO3 {
    public record ReceiptLine(OnlineOrderDetail3 detail, String itemName, String unit) {}

    public record OrderReceipt(long orderID, LocalDateTime placedAt, String status, OnlineOrder3 order,
                               List<ReceiptLine> lines) {
        public BigDecimal total() {
            return lines.stream().map(line -> line.detail().lineTotal()).reduce(BigDecimal.ZERO, BigDecimal::add);
        }

        public String statusLabel() {
            return switch (status) {
                case "PENDING" -> "Chờ duyệt";
                case "APPROVED" -> "Đã duyệt";
                case "REJECTED" -> "Từ chối";
                case "HANDED_OVER" -> "Đã bàn giao";
                default -> status;
            };
        }
    }

    public OnlineOrderDAO3(Connection con) {
        super(con);
    }

    public long saveOrder(OnlineOrder3 orderInfo, List<OnlineOrderDetail3> orderItems) throws SQLException {
        if (orderItems.isEmpty()) {
            throw new IllegalArgumentException("An order needs at least one line");
        }
        long orderID;
        try (var ps = con.prepareStatement("""
                INSERT INTO tblOnlineOrder3
                    (recipientName, recipientPhone, deliveryAddress, note, customerID, status)
                VALUES (?, ?, ?, ?, ?, 'PENDING')
                """, Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, orderInfo.recipientName());
            ps.setString(2, orderInfo.recipientPhone());
            ps.setString(3, orderInfo.deliveryAddress());
            ps.setString(4, orderInfo.note());
            if (orderInfo.customerID() == null) {
                ps.setNull(5, Types.BIGINT);
            } else {
                ps.setLong(5, orderInfo.customerID());
            }
            ps.executeUpdate();
            try (var keys = ps.getGeneratedKeys()) {
                if (!keys.next()) {
                    throw new SQLException("Missing generated orderID");
                }
                orderID = keys.getLong(1);
            }
        }

        try (var ps = con.prepareStatement("""
                INSERT INTO tblOnlineOrderDetail3 (orderID, itemID, quantity, unitPrice) VALUES (?, ?, ?, ?)
                """)) {
            for (OnlineOrderDetail3 line : orderItems) {
                ps.setLong(1, orderID);
                ps.setLong(2, line.itemID());
                ps.setBigDecimal(3, line.quantity());
                ps.setBigDecimal(4, line.unitPrice());
                ps.addBatch();
            }
            ps.executeBatch();
        }
        return orderID;
    }

    public OrderReceipt getOrderReceipt(long orderID) throws SQLException {
        try (var ps = con.prepareStatement("""
                SELECT o.date, o.recipientName, o.recipientPhone, o.deliveryAddress, o.note, o.customerID, o.status,
                       d.itemID, d.quantity, d.unitPrice, i.itemName, i.unit
                FROM tblOnlineOrder3 o
                JOIN tblOnlineOrderDetail3 d ON d.orderID = o.orderID
                JOIN tblItem3 i ON i.itemID = d.itemID
                WHERE o.orderID = ?
                ORDER BY d.orderDetailID
                """)) {
            ps.setLong(1, orderID);
            try (var rows = ps.executeQuery()) {
                if (!rows.next()) {
                    return null;
                }
                var order = new OnlineOrder3(rows.getObject("customerID", Long.class), rows.getString("recipientName"),
                        rows.getString("recipientPhone"), rows.getString("deliveryAddress"), rows.getString("note"));
                LocalDateTime placedAt = rows.getObject("date", LocalDateTime.class);
                String status = rows.getString("status");
                List<ReceiptLine> lines = new ArrayList<>();
                do {
                    var detail = new OnlineOrderDetail3(rows.getLong("itemID"), rows.getBigDecimal("quantity"),
                            rows.getBigDecimal("unitPrice"));
                    lines.add(new ReceiptLine(detail, rows.getString("itemName"), rows.getString("unit")));
                } while (rows.next());
                return new OrderReceipt(orderID, placedAt, status, order, List.copyOf(lines));
            }
        }
    }
}
