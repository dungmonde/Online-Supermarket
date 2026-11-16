<%@ page pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/view/common/common.jspf" %>
<%@ include file="/WEB-INF/view/common/warehouse.jspf" %>
<%
String title = "Tìm mặt hàng để sửa";
String itemName = text(request.getParameter("itemName"));
String message = null;
List<Item3> items = List.of();
if (request.getParameter("itemName") != null) {
    if (itemName.isEmpty() || !within(itemName, 255)) {
        message = "Nhập tên mặt hàng cần tìm (tối đa 255 ký tự).";
    } else {
        try (java.sql.Connection con = DAO3.connect()) {
            items = new ItemDAO3(con).searchItemsByName(itemName);
        }
        message = items.isEmpty() ? "Không tìm thấy mặt hàng phù hợp."
                : "Chọn một mặt hàng trong danh sách để sửa.";
    }
}
%>
<%@ include file="/WEB-INF/view/common/head.jspf" %>
<main class="page">
    <h1><%= title %></h1>
    <div class="toolbar">
        <form class="search" action="<%= app %>/view/warehouse/ItemSearchUI3.jsp" method="get">
            <label for="itemName">Tên mặt hàng <span class="required-mark" aria-hidden="true">*</span></label>
            <input id="itemName" name="itemName" value="<%= html(itemName) %>" maxlength="255" pattern=".*\S.*" required>
            <button class="button" type="submit">Tìm</button>
        </form>
    </div>
    <div class="table-wrap">
        <table aria-label="Các mặt hàng tìm được">
            <thead><tr><th scope="col">Mã</th><th scope="col">Tên mặt hàng</th>
                <th scope="col">Đơn vị</th><th scope="col">Giá bán</th><th scope="col">Trạng thái</th>
                <th scope="col">Chọn</th></tr></thead>
            <tbody>
                <% for (Item3 item : items) { %>
                    <tr>
                        <td class="center"><%= item.itemID() %></td><td><%= html(item.itemName()) %></td>
                        <td class="center"><%= html(item.unit()) %></td><td class="amount"><%= number(item.price()) %> đ</td>
                        <td class="center"><%= item.status().label() %></td>
                        <td class="center"><a class="button" href="<%= app %>/view/warehouse/EditItemUI3.jsp?itemID=<%= item.itemID() %>&amp;itemName=<%= java.net.URLEncoder.encode(itemName, java.nio.charset.StandardCharsets.UTF_8) %>">Chọn</a></td>
                    </tr>
                <% } %>
            </tbody>
        </table>
    </div>
    <% if (message != null) { %><p class="notice" role="status"><%= html(message) %></p><% } %>
    <p class="foot"><a class="button secondary" href="<%= app %>/view/warehouse/ItemManagementUI3.jsp">Quay lại</a></p>
</main>
</body>
</html>
