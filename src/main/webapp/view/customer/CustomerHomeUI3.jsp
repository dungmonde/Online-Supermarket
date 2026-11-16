<%@ page pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/view/common/common.jspf" %>
<%
String title = "Cửa hàng trực tuyến";
String itemName = text(request.getParameter("itemName"));
boolean validSearch = within(itemName, 255);
List<Item3> items = List.of();
if (validSearch) {
    try (java.sql.Connection con = DAO3.connect()) {
        ItemDAO3 dao = new ItemDAO3(con);
        items = itemName.isEmpty() ? dao.getAvailableItems() : dao.searchAvailableItemsByName(itemName);
    }
}
%>
<%@ include file="/WEB-INF/view/common/head.jspf" %>
<main class="page">
    <header class="masthead">
        <h1><%= title %></h1>
        <% if (member != null) { %>
            <p class="identity">Xin chào, <%= html(member.fullName()) %></p>
        <% } %>
        <div class="account">
            <% if (member != null || staff != null) { %>
                <form action="<%= app %>/view/common/doLogin3.jsp" method="post">
                    <input type="hidden" name="csrf" value="<%= csrf %>">
                    <input type="hidden" name="action" value="logout">
                    <button type="submit" class="button secondary">Đăng xuất</button>
                </form>
            <% } else { %>
                <a class="button secondary" href="<%= app %>/view/customer/RegisterMemberUI3.jsp">Đăng ký thành viên</a>
                <a class="button" href="<%= app %>/view/common/LoginUI3.jsp">Đăng nhập</a>
            <% } %>
        </div>
    </header>

    <div class="toolbar">
        <form class="search" action="<%= app %>/view/customer/CustomerHomeUI3.jsp" method="get">
            <label for="itemName">Tên mặt hàng</label>
            <input id="itemName" name="itemName" maxlength="255" placeholder="Nhập tên mặt hàng" value="<%= html(itemName) %>">
            <button class="button" type="submit">Tìm</button>
            <% if (!itemName.isEmpty()) { %>
                <a class="button secondary" href="<%= app %>/view/customer/CustomerHomeUI3.jsp">Xóa bộ lọc</a>
            <% } %>
        </form>
        <a class="button" href="<%= app %>/view/customer/ShoppingCartUI3.jsp">Xem giỏ</a>
    </div>

    <div class="table-wrap">
        <table aria-label="Danh sách mặt hàng">
            <thead>
                <tr><th scope="col">Mã</th><th scope="col">Tên mặt hàng</th><th scope="col">Đơn vị</th>
                    <th scope="col">Giá bán</th><th scope="col">Thao tác</th></tr>
            </thead>
            <tbody>
            <% for (Item3 item : items) { %>
                <tr>
                    <td class="center"><%= item.itemID() %></td><td><%= html(item.itemName()) %></td>
                    <td class="center"><%= html(item.unit()) %></td><td class="amount"><%= number(item.price()) %> đ</td>
                    <td class="center">
                        <% if (item.quantity().signum() > 0) { %>
                            <a class="button" href="<%= app %>/view/customer/SelectItemUI3.jsp?itemID=<%= item.itemID() %>">Đặt</a>
                        <% } else { %><span>Hết hàng</span><% } %>
                    </td>
                </tr>
            <% } %>
            <% if (items.isEmpty()) { %>
                <tr class="empty"><td colspan="5"><%= !validSearch ? "Tên tìm kiếm quá dài."
                        : itemName.isEmpty() ? "Cửa hàng chưa có mặt hàng đang bán." : "Không tìm thấy mặt hàng phù hợp." %></td></tr>
            <% } %>
            </tbody>
        </table>
    </div>
</main>
</body>
</html>
