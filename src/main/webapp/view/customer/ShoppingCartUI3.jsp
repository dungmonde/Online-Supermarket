<%@ page pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/view/common/common.jspf" %>
<%
String title = "Giỏ hàng và thông tin nhận hàng";
String error = (String) request.getAttribute("cartError");
String notice;
Long cartID;
synchronized (session) {
    notice = (String) session.getAttribute("cartNotice");
    cartID = (Long) session.getAttribute("cartID");
    session.removeAttribute("cartNotice");
}
List<CartItem3> items = List.of();
if (cartID != null) {
    try (java.sql.Connection con = DAO3.connect()) {
        if (new ShoppingCartDAO3(con).getCart(cartID) != null) {
            items = new CartItemDAO3(con).getCartItems(cartID);
        }
    }
}
String snapshot = items.isEmpty() ? "" : cartSnapshot(cartID, items);
boolean retry = Boolean.TRUE.equals(request.getAttribute("checkoutRetry"));
String recipientName = retry ? text(request.getParameter("recipientName")) : "";
String recipientPhone = retry ? text(request.getParameter("recipientPhone")) : "";
String deliveryAddress = retry ? text(request.getParameter("deliveryAddress")) : "";
String note = retry ? text(request.getParameter("note")) : "";
%>
<%@ include file="/WEB-INF/view/common/head.jspf" %>
<main class="page">
    <h1><%= title %></h1>
    <p class="subtitle"><%= member == null ? "Đặt hàng với tư cách khách vãng lai" : "Đặt hàng với tài khoản thành viên" %></p>
    <div class="table-wrap">
        <table aria-label="Mặt hàng đã chọn">
            <thead>
                <tr><th scope="col">Mã</th><th scope="col">Tên mặt hàng</th><th scope="col">Số lượng</th>
                    <th scope="col">Đơn giá</th><th scope="col">Thành tiền</th></tr>
            </thead>
            <tbody>
                <% for (CartItem3 line : items) { %>
                    <tr>
                        <td class="center"><%= line.itemID() %></td>
                        <td><%= html(line.itemName()) %></td>
                        <td>
                            <form class="line-actions" method="post" action="<%= app %>/view/customer/SelectItemUI3.jsp">
                                <input type="hidden" name="csrf" value="<%= csrf %>">
                                <input type="hidden" name="itemID" value="<%= line.itemID() %>">
                                <input aria-label="Số lượng của <%= html(line.itemName()) %>" name="quantity" type="number" min="0.01" step="0.01"
                                       value="<%= inputNumber(line.quantity()) %>" required>
                                <button class="button secondary" name="action" value="update" type="submit">Cập nhật</button>
                                <button class="button secondary" name="action" value="remove" type="submit" formnovalidate>Bỏ</button>
                            </form>
                        </td>
                        <td class="amount"><%= number(line.displayUnitPrice()) %> đ</td>
                        <td class="amount"><%= number(line.lineTotal()) %> đ</td>
                    </tr>
                <% } %>
                <% if (items.isEmpty()) { %><tr class="empty"><td colspan="5">Giỏ hàng đang trống.</td></tr><% } %>
            </tbody>
            <tfoot><tr><td colspan="4" class="amount">Tổng tiền</td><td class="amount"><%= number(total(items)) %> đ</td></tr></tfoot>
        </table>
    </div>
    <form method="post" action="<%= app %>/view/customer/doSubmitOrder3.jsp">
        <input type="hidden" name="csrf" value="<%= csrf %>">
        <input type="hidden" name="snapshot" value="<%= snapshot %>">
        <div class="fields">
            <label for="recipientName">Tên người nhận <span class="required-mark" aria-hidden="true">*</span></label>
            <input id="recipientName" name="recipientName" value="<%= html(recipientName) %>" placeholder="Nhập họ tên người nhận"
                   autocomplete="shipping name" maxlength="255" pattern=".*\S.*" required>
            <label for="recipientPhone">Số điện thoại <span class="required-mark" aria-hidden="true">*</span></label>
            <input id="recipientPhone" name="recipientPhone" value="<%= html(recipientPhone) %>" type="tel" placeholder="Nhập số điện thoại"
                   autocomplete="shipping tel" maxlength="25" pattern="<%= PHONE_INPUT_PATTERN %>"
                   title="Nhập số điện thoại có từ 7 đến 15 chữ số." required>
            <label for="deliveryAddress">Địa chỉ nhận <span class="required-mark" aria-hidden="true">*</span></label>
            <input id="deliveryAddress" name="deliveryAddress" value="<%= html(deliveryAddress) %>" placeholder="Nhập địa chỉ nhận hàng"
                   autocomplete="shipping street-address" maxlength="255" pattern=".*\S.*" required>
            <label for="note">Ghi chú (tùy chọn)</label>
            <textarea id="note" name="note" maxlength="255"><%= html(note) %></textarea>
        </div>
        <div class="actions">
            <a class="button" href="<%= app %>/view/customer/CustomerHomeUI3.jsp">Tiếp tục mua hàng</a>
            <button class="button" type="submit" <%= items.isEmpty() ? "disabled" : "" %>>Gửi đơn</button>
        </div>
    </form>
    <% if (error != null) { %><p class="notice error" role="alert"><%= html(error) %></p><% } %>
    <% if (notice != null) { %><p class="notice" role="status"><%= html(notice) %></p><% } %>
</main>
</body>
</html>
