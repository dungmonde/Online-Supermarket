USE OnlineSupermarketDB3;

INSERT INTO tblEmployee3 (employeeID, fullName, phoneNumber, username, password, role, status)
VALUES (1, 'Nguyễn Minh Hoàng', '0901000001', 'nhanvienkho', '5c483cb3f5bd6bdba5c794f0fc54379b:4d405663222e22dbd915932151e432006a70898f7a72b6592920aeeda0994ce0', 'WAREHOUSE', 'ACTIVE')
ON DUPLICATE KEY UPDATE employeeID=employeeID;

INSERT INTO tblCustomer3 (customerID, fullName, phoneNumber, email, address, username, password, status)
VALUES (1, 'Trần Minh An', '0901000002', 'an@example.com', 'Hà Nội', 'thanhvien', '52a6874ba678164703ac9c8d8c4d999f:84870da0159f6a07974adb0e6074dd988e3963e0a953bdcd81978527ef162803', 'ACTIVE')
ON DUPLICATE KEY UPDATE customerID=customerID;

INSERT INTO tblItem3 (itemID, itemName, unit, description, price, quantity, status) VALUES
(1001, 'Sữa tươi', 'Hộp', 'Sữa tươi đóng hộp', 8000, 120, 'ACTIVE'),
(1002, 'Sữa hạt', 'Hộp', 'Sữa hạt đóng hộp', 15000, 80, 'ACTIVE'),
(1003, 'Gạo thơm', 'kg', 'Gạo thơm', 32000, 100, 'ACTIVE')
ON DUPLICATE KEY UPDATE itemID=itemID;
