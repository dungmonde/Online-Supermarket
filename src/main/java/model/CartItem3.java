package model;

import java.math.BigDecimal;
import java.math.RoundingMode;

public record CartItem3(long cartItemID, long itemID, String itemName, String unit,
                        BigDecimal quantity, BigDecimal displayUnitPrice) {
    public BigDecimal lineTotal() {
        return quantity.multiply(displayUnitPrice).setScale(2, RoundingMode.HALF_UP);
    }
}
