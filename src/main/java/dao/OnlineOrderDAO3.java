package dao;

import model.OnlineOrder3;
import model.OnlineOrderDetail3;

import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Types;
import java.util.List;

public final class OnlineOrderDAO3 extends DAO3 {
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
}
