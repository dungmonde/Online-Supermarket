package model;

import java.math.BigDecimal;

public record OnlineOrderDetail3(long itemID, BigDecimal quantity, BigDecimal unitPrice) {}
