<%@ page contentType="text/html; charset=UTF-8" isErrorPage="true" pageEncoding="UTF-8" %>
<!doctype html>
<html lang="vi"><head><meta charset="UTF-8"><title>Lỗi xử lý</title>
<link rel="stylesheet" href="<%= request.getContextPath() %>/view/common/store.css"></head>
<body><main class="page compact"><h1>Không thể xử lý yêu cầu</h1>
<p>Thao tác chưa hoàn tất. Vui lòng thử lại.</p>
<a class="button" href="<%= request.getContextPath() %>/view/customer/CustomerHomeUI3.jsp">Về cửa hàng</a>
</main></body></html>
