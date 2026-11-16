<%@ page pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/view/common/common.jspf" %>
<%@ include file="/WEB-INF/view/common/warehouse.jspf" %>
<% String title = "Quản lí mặt hàng"; %>
<%@ include file="/WEB-INF/view/common/head.jspf" %>
<main class="page compact">
    <h1><%= title %></h1>
    <nav class="menu" aria-label="Chức năng quản lí mặt hàng">
        <button class="button" disabled type="button">Thêm mặt hàng</button>
        <button class="button" disabled type="button">Xóa mặt hàng</button>
        <a class="button" href="<%= app %>/view/warehouse/ItemSearchUI3.jsp">Sửa thông tin mặt hàng</a>
    </nav>
    <a class="button secondary" href="<%= app %>/view/warehouse/WarehouseHomeUI3.jsp">Quay lại</a>
</main>
</body>
</html>
