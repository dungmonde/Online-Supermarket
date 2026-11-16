package model;

public record OnlineOrder3(Long customerID, String recipientName, String recipientPhone,
                           String deliveryAddress, String note) {}
