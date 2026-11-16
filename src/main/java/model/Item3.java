package model;

import java.math.BigDecimal;

public record Item3(long itemID, String itemName, String unit, String description,
                    BigDecimal price, BigDecimal quantity, Status status) {
    public enum Status {
        ACTIVE("Đang kinh doanh"), INACTIVE("Ngừng kinh doanh");

        private final String label;

        Status(String label) {
            this.label = label;
        }

        public String label() {
            return label;
        }
    }
}
