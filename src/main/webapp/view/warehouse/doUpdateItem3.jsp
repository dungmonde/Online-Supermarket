<%@ page pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/view/common/common.jspf" %>
<%@ include file="/WEB-INF/view/common/post.jspf" %>
<%@ include file="/WEB-INF/view/common/warehouse.jspf" %>
<%
long itemID = id(request.getParameter("itemID"));
String itemName = text(request.getParameter("itemName"));
String unit = text(request.getParameter("unit"));
String description = text(request.getParameter("description"));
BigDecimal price = decimal(request.getParameter("price"));
String statusName = text(request.getParameter("status"));
String searchName = text(request.getParameter("searchName"));

if (itemID == 0) {
    response.sendError(404, "Mặt hàng không còn tồn tại.");
    return;
}
String error = null;
if (itemName.isEmpty() || unit.isEmpty() || !within(itemName, 255)
        || !within(unit, 255) || !within(description, 255)) {
    error = "Nhập tên và đơn vị tính hợp lệ. Các trường văn bản tối đa 255 ký tự.";
} else if (price == null) {
    error = "Giá bán phải từ 0 trở lên, với tối đa hai chữ số thập phân.";
} else if (!Set.of("ACTIVE", "INACTIVE").contains(statusName)) {
    error = "Trạng thái mặt hàng không hợp lệ.";
}
if (error != null) {
    response.setStatus(400);
} else {
    try (java.sql.Connection con = DAO3.connect()) {
        Item3 itemInfo = new Item3(itemID, itemName, unit, description.isEmpty() ? null : description,
                price, null, Item3.Status.valueOf(statusName));
        if (!new ItemDAO3(con).updateItem(itemInfo)) {
            response.sendError(404, "Mặt hàng không còn tồn tại.");
            return;
        }
    } catch (SQLException e) {
        application.log("Không lưu được thông tin mặt hàng " + itemID, e);
        response.setStatus(500);
        error = "Chưa lưu được thông tin mặt hàng. Hãy thử lại.";
    }
}
if (error != null) {
    request.setAttribute("editError", error);
    request.getRequestDispatcher("/view/warehouse/EditItemUI3.jsp").forward(request, response);
    return;
}
session.setAttribute("savedItemID", itemID);
response.sendRedirect(app + "/view/warehouse/EditItemUI3.jsp?itemID=" + itemID + "&searchName="
        + java.net.URLEncoder.encode(searchName, java.nio.charset.StandardCharsets.UTF_8));
%>
