CREATE DATABASE IF NOT EXISTS OnlineSupermarketDB3
    CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE OnlineSupermarketDB3;

CREATE TABLE IF NOT EXISTS tblEmployee3 (
    employeeID BIGINT AUTO_INCREMENT PRIMARY KEY,
    fullName VARCHAR(255) NOT NULL,
    phoneNumber VARCHAR(25) NOT NULL,
    username VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(30) NOT NULL CHECK (role IN ('WAREHOUSE', 'SALES', 'MANAGEMENT')),
    status VARCHAR(20) NOT NULL CHECK (status IN ('ACTIVE', 'INACTIVE'))
);

CREATE TABLE IF NOT EXISTS tblCustomer3 (
    customerID BIGINT AUTO_INCREMENT PRIMARY KEY,
    fullName VARCHAR(255) NOT NULL,
    phoneNumber VARCHAR(25) NOT NULL,
    email VARCHAR(255),
    address VARCHAR(255) NOT NULL,
    username VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('ACTIVE', 'INACTIVE'))
);

CREATE TABLE IF NOT EXISTS tblSupplier3 (
    supplierID BIGINT AUTO_INCREMENT PRIMARY KEY,
    supplierName VARCHAR(255) NOT NULL,
    address VARCHAR(255) NOT NULL,
    phoneNumber VARCHAR(25) NOT NULL,
    email VARCHAR(255),
    status VARCHAR(20) NOT NULL
);

CREATE TABLE IF NOT EXISTS tblDeliveryStaff3 (
    deliveryStaffID BIGINT AUTO_INCREMENT PRIMARY KEY,
    fullName VARCHAR(255) NOT NULL,
    phoneNumber VARCHAR(25) NOT NULL
);

CREATE TABLE IF NOT EXISTS tblItem3 (
    itemID BIGINT AUTO_INCREMENT PRIMARY KEY,
    itemName VARCHAR(255) NOT NULL,
    unit VARCHAR(255) NOT NULL,
    description VARCHAR(255),
    price DECIMAL(18,2) NOT NULL CHECK (price >= 0),
    quantity DECIMAL(18,2) NOT NULL CHECK (quantity >= 0),
    status VARCHAR(20) NOT NULL CHECK (status IN ('ACTIVE', 'INACTIVE')),
    INDEX ix_item_name (itemName)
);

CREATE TABLE IF NOT EXISTS tblShoppingCart3 (
    cartID BIGINT AUTO_INCREMENT PRIMARY KEY,
    createdAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updatedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS tblCartItem3 (
    cartItemID BIGINT AUTO_INCREMENT PRIMARY KEY,
    cartID BIGINT NOT NULL,
    itemID BIGINT NOT NULL,
    quantity DECIMAL(18,2) NOT NULL CHECK (quantity > 0),
    displayUnitPrice DECIMAL(18,2) NOT NULL CHECK (displayUnitPrice >= 0),
    UNIQUE (cartID, itemID),
    FOREIGN KEY (cartID) REFERENCES tblShoppingCart3(cartID) ON DELETE CASCADE,
    FOREIGN KEY (itemID) REFERENCES tblItem3(itemID)
);

CREATE TABLE IF NOT EXISTS tblOnlineOrder3 (
    orderID BIGINT AUTO_INCREMENT PRIMARY KEY,
    date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    recipientName VARCHAR(255) NOT NULL,
    recipientPhone VARCHAR(25) NOT NULL,
    deliveryAddress VARCHAR(255) NOT NULL,
    note VARCHAR(255),
    status VARCHAR(25) NOT NULL CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED', 'HANDED_OVER')),
    customerID BIGINT,
    warehouseStaffID BIGINT,
    FOREIGN KEY (customerID) REFERENCES tblCustomer3(customerID),
    FOREIGN KEY (warehouseStaffID) REFERENCES tblEmployee3(employeeID)
);

CREATE TABLE IF NOT EXISTS tblOnlineOrderDetail3 (
    orderDetailID BIGINT AUTO_INCREMENT PRIMARY KEY,
    orderID BIGINT NOT NULL,
    itemID BIGINT NOT NULL,
    quantity DECIMAL(18,2) NOT NULL CHECK (quantity > 0),
    unitPrice DECIMAL(18,2) NOT NULL CHECK (unitPrice >= 0),
    UNIQUE (orderID, itemID),
    FOREIGN KEY (orderID) REFERENCES tblOnlineOrder3(orderID),
    FOREIGN KEY (itemID) REFERENCES tblItem3(itemID)
);

CREATE TABLE IF NOT EXISTS tblOnlineInvoice3 (
    invoiceID BIGINT AUTO_INCREMENT PRIMARY KEY,
    orderID BIGINT NOT NULL UNIQUE,
    paymentStatus VARCHAR(20) NOT NULL,
    issuedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    date DATETIME,
    CHECK ((paymentStatus = 'PAID' AND date IS NOT NULL)
        OR (paymentStatus = 'UNPAID' AND date IS NULL)),
    FOREIGN KEY (orderID) REFERENCES tblOnlineOrder3(orderID)
);

CREATE TABLE IF NOT EXISTS tblDeliveryExport3 (
    exportID BIGINT AUTO_INCREMENT PRIMARY KEY,
    orderID BIGINT NOT NULL UNIQUE,
    warehouseStaffID BIGINT NOT NULL,
    deliveryStaffID BIGINT NOT NULL,
    handedOverAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (orderID) REFERENCES tblOnlineOrder3(orderID),
    FOREIGN KEY (warehouseStaffID) REFERENCES tblEmployee3(employeeID),
    FOREIGN KEY (deliveryStaffID) REFERENCES tblDeliveryStaff3(deliveryStaffID)
);

CREATE TABLE IF NOT EXISTS tblItemReceipt3 (
    receiptID BIGINT AUTO_INCREMENT PRIMARY KEY,
    receivedAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    warehouseStaffID BIGINT NOT NULL,
    supplierID BIGINT NOT NULL,
    FOREIGN KEY (warehouseStaffID) REFERENCES tblEmployee3(employeeID),
    FOREIGN KEY (supplierID) REFERENCES tblSupplier3(supplierID)
);

CREATE TABLE IF NOT EXISTS tblItemReceiptDetail3 (
    receiptDetailID BIGINT AUTO_INCREMENT PRIMARY KEY,
    receiptID BIGINT NOT NULL,
    itemID BIGINT NOT NULL,
    quantity DECIMAL(18,2) NOT NULL CHECK (quantity > 0),
    importUnitPrice DECIMAL(18,2) NOT NULL CHECK (importUnitPrice >= 0),
    UNIQUE (receiptID, itemID),
    FOREIGN KEY (receiptID) REFERENCES tblItemReceipt3(receiptID),
    FOREIGN KEY (itemID) REFERENCES tblItem3(itemID)
);

CREATE TABLE IF NOT EXISTS tblCounterInvoice3 (
    invoiceID BIGINT AUTO_INCREMENT PRIMARY KEY,
    soldAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    paidAt DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    paymentStatus VARCHAR(20) NOT NULL CHECK (paymentStatus = 'PAID'),
    employeeID BIGINT NOT NULL,
    customerID BIGINT,
    FOREIGN KEY (employeeID) REFERENCES tblEmployee3(employeeID),
    FOREIGN KEY (customerID) REFERENCES tblCustomer3(customerID)
);

CREATE TABLE IF NOT EXISTS tblCounterInvoiceDetail3 (
    counterInvoiceDetailID BIGINT AUTO_INCREMENT PRIMARY KEY,
    invoiceID BIGINT NOT NULL,
    itemID BIGINT NOT NULL,
    quantity DECIMAL(18,2) NOT NULL CHECK (quantity > 0),
    unitPrice DECIMAL(18,2) NOT NULL CHECK (unitPrice >= 0),
    UNIQUE (invoiceID, itemID),
    FOREIGN KEY (invoiceID) REFERENCES tblCounterInvoice3(invoiceID),
    FOREIGN KEY (itemID) REFERENCES tblItem3(itemID)
);
