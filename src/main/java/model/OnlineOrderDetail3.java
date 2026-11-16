package model;

import java.math.BigDecimal;
import java.math.RoundingMode;

public record OnlineOrderDetail3(long itemID, BigDecimal quantity, BigDecimal unitPrice) {
    public BigDecimal lineTotal() {
        return quantity.multiply(unitPrice).setScale(2, RoundingMode.HALF_UP);
    }
}
