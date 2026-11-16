<%@ page pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/view/common/common.jspf" %>
<%@ include file="/WEB-INF/view/common/warehouse.jspf" %>
<%
String title = "Sửa thông tin mặt hàng";
long itemID = id(request.getParameter("itemID"));
Item3 item;
try (java.sql.Connection con = DAO3.connect()) {
    item = new ItemDAO3(con).getItem(itemID);
}
if (item == null) {
    response.sendError(404, "Mặt hàng không còn tồn tại.");
    return;
}
String error = (String) request.getAttribute("editError");
boolean success = false;
synchronized (session) {
    if (Objects.equals(session.getAttribute("savedItemID"), itemID)) {
        session.removeAttribute("savedItemID");
        success = true;
    }
}
boolean retry = error != null;
String searchName = text(request.getParameter("searchName"));
if (!retry && request.getParameter("searchName") == null) {
    searchName = text(request.getParameter("itemName"));
}
String searchQuery = java.net.URLEncoder.encode(searchName, java.nio.charset.StandardCharsets.UTF_8);
String back = app + "/view/warehouse/ItemSearchUI3.jsp"
        + (searchName.isEmpty() ? "" : "?itemName=" + searchQuery);
String cancel = app + "/view/warehouse/EditItemUI3.jsp?itemID=" + itemID + "&searchName=" + searchQuery;
String editName = retry ? request.getParameter("itemName") : item.itemName();
String editUnit = retry ? request.getParameter("unit") : item.unit();
String editDescription = retry ? request.getParameter("description") : item.description();
String editPrice = retry ? request.getParameter("price") : inputNumber(item.price());
String editStatus = retry ? request.getParameter("status") : item.status().name();
%>
<%@ include file="/WEB-INF/view/common/head.jspf" %>
<main class="page compact">
    <h1><%= title %></h1>
    <form method="post" action="<%= app %>/view/warehouse/doUpdateItem3.jsp">
        <input type="hidden" name="csrf" value="<%= csrf %>">
        <input type="hidden" name="itemID" value="<%= item.itemID() %>">
        <input type="hidden" name="searchName" value="<%= html(searchName) %>">
        <div class="fields">
            <span>Mã mặt hàng</span><output class="read-only"><%= item.itemID() %></output>
            <label for="itemName">Tên mặt hàng <span class="required-mark" aria-hidden="true">*</span></label>
            <input id="itemName" name="itemName" value="<%= html(editName) %>" maxlength="255" pattern=".*\S.*" required>
            <label for="unit">Đơn vị tính <span class="required-mark" aria-hidden="true">*</span></label>
            <input id="unit" name="unit" value="<%= html(editUnit) %>" maxlength="255" pattern=".*\S.*" required>
            <label for="description">Mô tả (tùy chọn)</label>
            <textarea id="description" name="description" maxlength="255"><%= html(editDescription) %></textarea>
            <label for="price">Giá bán <span class="required-mark" aria-hidden="true">*</span></label>
            <input id="price" name="price" inputmode="decimal" maxlength="19" value="<%= html(editPrice) %>"
                   pattern="\s*[0-9]{1,16}([.,][0-9]{1,2})?\s*" title="Nhập giá từ 0 trở lên, tối đa hai chữ số thập phân." required>
            <span>Số lượng tồn</span><output class="read-only"><%= number(item.quantity()) %></output>
            <label for="status">Trạng thái <span class="required-mark" aria-hidden="true">*</span></label>
            <select id="status" name="status" required>
                <% for (Item3.Status status : Item3.Status.values()) { %>
                    <option value="<%= status.name() %>" <%= status.name().equals(editStatus) ? "selected" : "" %>><%= status.label() %></option>
                <% } %>
            </select>
        </div>
        <div class="actions">
            <button class="button" type="submit">Lưu</button>
            <a class="button secondary" href="<%= html(cancel) %>">Hủy</a>
            <a class="button secondary" href="<%= html(back) %>">Quay lại danh sách tìm kiếm</a>
        </div>
    </form>
    <% if (error != null) { %><p class="notice error" role="alert"><%= html(error) %></p><% } %>
    <% if (success) { %><p class="notice success" role="status">Sửa thông tin mặt hàng thành công.</p><% } %>
</main>
</body>
</html>
