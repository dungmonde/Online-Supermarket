# Siêu thị trực tuyến

Ứng dụng Java 17, JSP, DAO, JDBC và MySQL cho hai module Đề 08. Các trang xử lý `do*.jsp` nhận dữ liệu biểu mẫu và gọi DAO. Mặt hàng, tài khoản, giỏ và đơn hàng đều đọc hoặc ghi qua MySQL. Dữ liệu mẫu được nạp bằng SQL khi khởi tạo schema.

- **Sửa thông tin mặt hàng** đi từ trang nhân viên kho đến Quản lí mặt hàng, tìm theo tên, chọn bản ghi và lưu. Mã và tồn kho chỉ đọc.
- **Đặt hàng trực tuyến** mở cửa hàng trực tiếp, tìm theo tên tại trang chủ, chọn số lượng, kiểm tra giỏ và gửi đơn. Khách vãng lai dùng giỏ theo phiên. Thành viên có thể đăng nhập giữa chừng và giữ giỏ. Cả hai nhập thông tin nhận hàng cho từng đơn. Đơn mới ở trạng thái `PENDING` (Chờ duyệt).

Hai nút Thêm và Xóa mặt hàng có trên menu để khớp mẫu Word. Phạm vi triển khai của bản này là sửa mặt hàng, đặt hàng và đăng nhập/đăng xuất phục vụ hai luồng. Schema có 15 bảng theo thiết kế toàn hệ thống.

## Cấu trúc và triển khai

- `src/main/java/model` chứa các lớp thực thể. `src/main/java/dao` chứa các lớp truy xuất MySQL qua JDBC.
- `src/main/webapp/view` chứa JSP theo nhóm `common`, `warehouse`, `customer`. Các đoạn JSP dùng chung nội bộ nằm trong `WEB-INF/view/common`.
- Trình duyệt gửi yêu cầu HTTP đến ứng dụng WAR chạy trên Tomcat. DAO trong WAR kết nối với MySQL qua JDBC. Thư mục `database` chứa SQL khởi tạo, còn `scripts` chứa các script chạy thử trên máy.

## Chạy trên máy hiện tại

Mở PowerShell ở thư mục dự án và chạy:

```powershell
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File .\scripts\Start-Local.ps1
```

`-ExecutionPolicy RemoteSigned` áp dụng cho tiến trình PowerShell mở bằng lệnh trên. Script khởi động MySQL tại `127.0.0.1:33319`, tạo schema và nạp dữ liệu mẫu ở lần chạy đầu, build Maven WAR rồi triển khai Tomcat ở cổng `18087`. Dữ liệu của dự án lưu trong `.runtime/mysql` và được dùng lại khi chạy lần sau. Để chỉ khởi động MySQL, thay `Start-Local.ps1` bằng `Start-Database.ps1` trong lệnh trên.

Mở [cửa hàng](http://127.0.0.1:18087/OnlineSupermarket3/). Có thể đặt với tư cách khách ngay hoặc đăng nhập bằng tài khoản mẫu:

| Vai trò | Tên đăng nhập | Mật khẩu |
| --- | --- | --- |
| Nhân viên kho | `nhanvienkho` | `KhoDemo2026!` |
| Thành viên | `thanhvien` | `KhachDemo2026!` |

Khách có thể chọn **Đăng ký thành viên** từ cửa hàng hoặc trang đăng nhập. Đăng ký thành công sẽ mở trang đăng nhập với tên tài khoản vừa tạo. Giỏ của khách được giữ trong cùng phiên truy cập.

Khi chuyển sang máy khác, cài Java 17, Maven, Tomcat 9 và MySQL Server 8.0. Đặt `JAVA_HOME` và `CATALINA_HOME`, đưa Maven vào `PATH`, hoặc truyền đường dẫn qua `-JavaHome`, `-TomcatHome`, `-MavenCommand` và `-MySqlHome`. Với MySQL và Tomcat do bạn quản lý, chạy `database/01-schema.sql` và `database/02-demo.sql`, cấu hình `SUPERMARKET_DB_URL`, `SUPERMARKET_DB_USER`, `SUPERMARKET_DB_PASSWORD` cho tiến trình Tomcat, rồi chạy `mvn package` và triển khai `target/OnlineSupermarket3.war`.

## Dừng web chạy nền

```powershell
powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File .\scripts\Start-Local.ps1 -Stop
```

Lệnh dừng Tomcat của dự án trên cổng `18087`. MySQL vẫn phục vụ Workbench trên cổng `33319`. Khi muốn mở lại web, chạy lệnh khởi động ở trên.

## Xem dữ liệu trong MySQL Workbench

Mở kết nối **OnlineSupermarket3 - 33319**. Nếu cấu hình trên một máy khác, tạo kết nối **Standard (TCP/IP)** với các giá trị sau.

| Trường | Giá trị |
| --- | --- |
| Hostname | `127.0.0.1` |
| Port | `33319` |
| Username | `supermarket3` |
| Password | `Supermarket3Local!2026` |
| Default Schema | `onlinesupermarketdb3` |

Trong **Schemas**, mở **onlinesupermarketdb3 → Tables**. Workbench trên Windows có thể hiển thị tên bảng dưới dạng chữ thường. Chạy các truy vấn sau trong SQL Editor trước và sau khi thao tác trên web.

```sql
USE onlinesupermarketdb3;

-- Sửa giá mã 1001 trên web rồi chạy lại câu này.
SELECT itemID, itemName, price, quantity, status
FROM tblItem3 WHERE itemID = 1001;

-- Chạy sau khi thêm hàng, rồi chạy lại sau khi gửi đơn.
SELECT cartID, itemID, quantity, displayUnitPrice
FROM tblCartItem3 ORDER BY cartID DESC, itemID;

-- Đối chiếu mã đơn web trả về với đơn và các dòng được lưu.
SELECT o.orderID, o.date, o.customerID, o.recipientName,
       o.recipientPhone, o.status, d.itemID, d.quantity, d.unitPrice
FROM tblOnlineOrder3 AS o
JOIN tblOnlineOrderDetail3 AS d ON d.orderID = o.orderID
ORDER BY o.orderID DESC, d.itemID;
```

Trong đơn vãng lai, `customerID` là `NULL`. Khi gửi đơn thành công, hệ thống lưu đơn và chi tiết, trừ số lượng tồn của từng mặt hàng trong `tblItem3` và làm rỗng giỏ trong cùng một giao dịch. Trang xác nhận hiển thị mã đơn, thông tin người nhận, mặt hàng và tổng tiền đã lưu. Nếu giá đổi trong lúc mua, giỏ hiện lại giá mới để khách xác nhận trước khi lưu đơn.

