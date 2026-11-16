<%@ page pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/view/common/common.jspf" %>
<%
if ("POST".equals(request.getMethod())) {
%>
<%@ include file="/WEB-INF/view/common/post.jspf" %>
<%
    String action = text(request.getParameter("action"));
    long itemID = id(request.getParameter("itemID"));
    boolean add = action.equals("add");
    boolean remove = action.equals("remove");
    if (itemID == 0 || !Set.of("add", "update", "remove").contains(action)) {
        response.sendError(400, "Thao tác giỏ hàng không hợp lệ.");
        return;
    }
    BigDecimal quantity = decimal(request.getParameter("quantity"));
    BigDecimal seenPrice = decimal(request.getParameter("seenPrice"));
    String message = null;
    boolean priceUpdated = false;
    synchronized (session) {
        Long currentCart = (Long) session.getAttribute("cartID");
        if (!add && currentCart == null) {
            message = "Giỏ hàng đã thay đổi. Hãy kiểm tra lại.";
        } else {
            try (java.sql.Connection con = DAO3.connect()) {
                con.setAutoCommit(false);
                try {
                    ShoppingCartDAO3 cartDAO = new ShoppingCartDAO3(con);
                    CartItemDAO3 lineDAO = new CartItemDAO3(con);
                    ItemDAO3 itemDAO = new ItemDAO3(con);
                    long cartID = currentCart == null ? cartDAO.createCart().cartID() : currentCart;
                    if (currentCart != null && !cartDAO.lockCart(cartID)) {
                        message = "Giỏ hàng đã thay đổi. Hãy thử lại.";
                        session.removeAttribute("cartID");
                    } else {
                        CartItem3 line = lineDAO.getCartItems(cartID).stream()
                                .filter(value -> value.itemID() == itemID).findFirst().orElse(null);
                        if (!add && line == null) {
                            message = "Mặt hàng không còn trong giỏ.";
                        } else if (remove) {
                            lineDAO.removeItem(cartID, itemID);
                        } else if (quantity == null || quantity.signum() <= 0 || (add && seenPrice == null)) {
                            message = "Số lượng đặt phải lớn hơn 0 và có tối đa hai chữ số thập phân.";
                        } else {
                            BigDecimal totalQuantity = add && line != null ? line.quantity().add(quantity) : quantity;
                            BigDecimal expectedPrice = add ? seenPrice : line.displayUnitPrice();
                            ItemDAO3.OrderItemCheck check = itemDAO.checkOrderItem(itemID, totalQuantity, expectedPrice);
                            Item3 item = check.item();
                            if (check.availability() == ItemDAO3.Availability.NOT_FOR_SALE) {
                                message = "Mặt hàng hiện không còn bán.";
                            } else if (!validQuantity(totalQuantity, item) || !validQuantity(quantity, item)) {
                                message = "Nhập số lượng phù hợp với đơn vị " + item.unit() + ".";
                            } else if (check.availability() == ItemDAO3.Availability.INSUFFICIENT_STOCK) {
                                message = "Không đủ hàng cho số lượng đã chọn. Vui lòng giảm số lượng hoặc chọn mặt hàng khác.";
                            } else if (add && check.availability() == ItemDAO3.Availability.PRICE_CHANGED) {
                                message = "Giá bán đã thay đổi. Hãy xem giá mới và chọn Thêm vào giỏ để xác nhận.";
                            } else if (add) {
                                lineDAO.addOrUpdateItems(cartID, itemID, quantity, item.price());
                            } else {
                                priceUpdated = check.availability() == ItemDAO3.Availability.PRICE_CHANGED;
                                lineDAO.updateItem(cartID, itemID, quantity, item.price());
                            }
                        }
                    }
                    if (message == null) {
                        cartDAO.touchCart(cartID);
                        con.commit();
                        session.setAttribute("cartID", cartID);
                        if (add) {
                            session.setAttribute("addedItemID", itemID);
                        }
                    } else {
                        con.rollback();
                    }
                } catch (SQLException e) {
                    con.rollback();
                    throw e;
                }
            } catch (SQLException e) {
                application.log("Không cập nhật được giỏ hàng", e);
                message = "Chưa cập nhật được giỏ hàng. Hãy thử lại.";
            }
        }
    }
    if (message == null) {
        if (priceUpdated) {
            session.setAttribute("cartNotice", "Giá của mặt hàng vừa sửa đã thay đổi. Hãy kiểm tra tổng tiền mới trước khi gửi đơn.");
        }
        response.sendRedirect(app + (add ? "/view/customer/SelectItemUI3.jsp?itemID=" + itemID : "/view/customer/ShoppingCartUI3.jsp"));
        return;
    }

    request.setAttribute("cartError", message);
    response.setStatus(409);
    if (!add) {
        request.getRequestDispatcher("/view/customer/ShoppingCartUI3.jsp").forward(request, response);
        return;
    }
}

String title = "Chọn mặt hàng và số lượng";
long itemID = id(request.getParameter("itemID"));
Item3 item;
try (java.sql.Connection con = DAO3.connect()) {
    item = new ItemDAO3(con).getItem(itemID);
}
if (item == null) {
    response.sendError(404, "Không tìm thấy mặt hàng.");
    return;
}
boolean available = item.status() == Item3.Status.ACTIVE && item.quantity().signum() > 0;
String error = (String) request.getAttribute("cartError");
boolean added;
synchronized (session) {
    added = Objects.equals(session.getAttribute("addedItemID"), itemID);
    if (added) {
        session.removeAttribute("addedItemID");
    }
}
String draft = error == null ? "" : text(request.getParameter("quantity"));
%>
<%@ include file="/WEB-INF/view/common/head.jspf" %>
<main class="page compact">
    <h1><%= title %></h1>
    <form method="post" action="<%= app %>/view/customer/SelectItemUI3.jsp">
        <input type="hidden" name="csrf" value="<%= csrf %>">
        <input type="hidden" name="action" value="add">
        <input type="hidden" name="itemID" value="<%= item.itemID() %>">
        <input type="hidden" name="seenPrice" value="<%= inputNumber(item.price()) %>">
        <div class="fields">
            <span>Mã mặt hàng</span><output class="read-only"><%= item.itemID() %></output>
            <span>Tên mặt hàng</span><output class="read-only"><%= html(item.itemName()) %></output>
            <span>Đơn vị tính</span><output class="read-only"><%= html(item.unit()) %></output>
            <span>Giá bán</span><output class="read-only"><%= number(item.price()) %> đ</output>
            <label for="quantity">Số lượng đặt <span class="required-mark" aria-hidden="true">*</span></label>
            <input id="quantity" name="quantity" type="number" min="0.01" step="0.01" value="<%= html(draft) %>"
                <%= available ? "required" : "disabled" %>>
        </div>
        <div class="actions">
            <button type="submit" class="button" <%= available ? "" : "disabled" %>>Thêm vào giỏ</button>
            <a class="button" href="<%= app %>/view/customer/CustomerHomeUI3.jsp">Quay lại</a>
            <a class="button" href="<%= app %>/view/customer/ShoppingCartUI3.jsp">Xem giỏ</a>
        </div>
    </form>
    <% if (error != null) { %>
        <p class="notice error" role="alert"><%= html(error) %></p>
    <% } else if (added) { %>
        <p class="notice success" role="status">Đã thêm mặt hàng vào giỏ.</p>
    <% } else if (!available) { %>
        <p class="notice error" role="status">Mặt hàng hiện không thể đặt.</p>
    <% } %>
</main>
</body>
</html>
