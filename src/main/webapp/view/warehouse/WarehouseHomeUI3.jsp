<%@ page pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/view/common/common.jspf" %>
<%@ include file="/WEB-INF/view/common/warehouse.jspf" %>
<% String title = "Trang chủ nhân viên kho"; %>
<%@ include file="/WEB-INF/view/common/head.jspf" %>
<main class="page compact">
    <h1><%= title %></h1>
    <nav class="menu" aria-label="Chức năng nhân viên kho">
        <a class="button" href="<%= app %>/view/warehouse/ItemManagementUI3.jsp">Quản lí mặt hàng</a>
    </nav>
    <form action="<%= app %>/view/common/doLogin3.jsp" method="post" class="foot">
        <input type="hidden" name="csrf" value="<%= csrf %>">
        <input type="hidden" name="action" value="logout">
        <button type="submit" class="button secondary">Đăng xuất</button>
    </form>
</main>
</body>
</html>
