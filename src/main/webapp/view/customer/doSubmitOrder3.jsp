<%@ page pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/view/common/common.jspf" %>
<%@ include file="/WEB-INF/view/common/post.jspf" %>
<%
String recipientName = text(request.getParameter("recipientName"));
String recipientPhone = text(request.getParameter("recipientPhone"));
String deliveryAddress = text(request.getParameter("deliveryAddress"));
String note = text(request.getParameter("note"));
String snapshot = text(request.getParameter("snapshot"));
String error = null;
int errorStatus = 409;
Long savedOrderID = null;

List<String> formErrors = new ArrayList<>();
if (recipientName.isEmpty() || !within(recipientName, 255)) {
    formErrors.add("Nhập tên người nhận, tối đa 255 ký tự.");
}
if (!validPhone(recipientPhone)) {
    formErrors.add("Nhập số điện thoại hợp lệ có từ 7 đến 15 chữ số.");
}
if (deliveryAddress.isEmpty() || !within(deliveryAddress, 255)) {
    formErrors.add("Nhập địa chỉ nhận hàng, tối đa 255 ký tự.");
}
if (!within(note, 255)) {
    formErrors.add("Ghi chú tối đa 255 ký tự.");
}
if (!formErrors.isEmpty()) {
    error = String.join(" ", formErrors);
    errorStatus = 400;
} else {
    synchronized (session) {
        Long cartID = (Long) session.getAttribute("cartID");
        Customer3 currentMember = (Customer3) session.getAttribute("member");
        if (!csrf.equals(session.getAttribute("csrf"))) {
            error = "Phiên làm việc đã thay đổi. Kiểm tra lại giỏ trước khi gửi đơn.";
        } else if (cartID == null) {
            error = "Giỏ hàng đang trống. Chọn mặt hàng trước khi gửi đơn.";
        } else {
            try (java.sql.Connection con = DAO3.connect()) {
                con.setAutoCommit(false);
                try {
                    ShoppingCartDAO3 cartDAO = new ShoppingCartDAO3(con);
                    CartItemDAO3 lineDAO = new CartItemDAO3(con);
                    ItemDAO3 itemDAO = new ItemDAO3(con);
                    List<CartItem3> lines = cartDAO.lockCart(cartID) ? lineDAO.getCartItems(cartID) : List.of();
                    if (lines.isEmpty()) {
                        error = "Giỏ hàng đang trống. Chọn mặt hàng trước khi gửi đơn.";
                        con.rollback();
                    } else if (!cartSnapshot(cartID, lines).equals(snapshot)) {
                        error = "Giỏ hàng đã thay đổi. Hãy kiểm tra lại các mặt hàng và tổng tiền.";
                        con.rollback();
                    } else {
                        List<OnlineOrderDetail3> details = new ArrayList<>();
                        List<String> problems = new ArrayList<>();
                        boolean priceChanged = false;
                        for (CartItem3 line : lines) {
                            ItemDAO3.OrderItemCheck check = itemDAO.checkOrderItem(line.itemID(), line.quantity(), line.displayUnitPrice());
                            switch (check.availability()) {
                                case NOT_FOR_SALE:
                                    problems.add(line.itemName() + " đã ngừng bán.");
                                    break;
                                case INSUFFICIENT_STOCK:
                                    problems.add(line.itemName() + " không đủ hàng cho số lượng đã chọn. Vui lòng điều chỉnh giỏ.");
                                    break;
                                case PRICE_CHANGED:
                                    lineDAO.updateItem(cartID, line.itemID(), line.quantity(), check.item().price());
                                    priceChanged = true;
                                    break;
                                case OK:
                                    if (validQuantity(line.quantity(), check.item())) {
                                        details.add(new OnlineOrderDetail3(line.itemID(), line.quantity(), line.displayUnitPrice()));
                                    } else {
                                        problems.add("Chỉnh số lượng " + line.itemName() + " theo đơn vị " + check.item().unit() + ".");
                                    }
                                    break;
                            }
                        }
                        if (priceChanged) {
                            problems.add("Giá đã thay đổi. Hãy kiểm tra tổng tiền mới và bấm Gửi đơn để xác nhận lại.");
                        }
                        if (!problems.isEmpty()) {
                            error = String.join(" ", problems);
                            if (priceChanged) {
                                cartDAO.touchCart(cartID);
                            }
                            // Save only the new display prices before asking the customer to accept them.
                            con.commit();
                        } else {
                            OnlineOrder3 order = new OnlineOrder3(currentMember == null ? null : currentMember.customerID(),
                                    recipientName, recipientPhone, deliveryAddress, note.isEmpty() ? null : note);
                            long orderID = new OnlineOrderDAO3(con).saveOrder(order, details);
                            cartDAO.clearCart(cartID);
                            con.commit();
                            savedOrderID = orderID;
                            session.setAttribute("savedOrderID", orderID);
                        }
                    }
                } catch (SQLException e) {
                    con.rollback();
                    throw e;
                }
            } catch (SQLException e) {
                application.log("Không lưu được đơn trực tuyến", e);
                error = "Chưa lưu được đơn. Vui lòng kiểm tra giỏ và thử lại.";
                errorStatus = 500;
            }
        }
    }
}

if (savedOrderID != null) {
    response.sendRedirect(app + "/view/customer/OrderConfirmationUI3.jsp?orderID=" + savedOrderID);
} else {
    request.setAttribute("checkoutRetry", true);
    request.setAttribute("cartError", error);
    response.setStatus(errorStatus);
    request.getRequestDispatcher("/view/customer/ShoppingCartUI3.jsp").forward(request, response);
}
%>
