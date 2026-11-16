<%@ page pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/view/common/common.jspf" %>
<%@ include file="/WEB-INF/view/common/post.jspf" %>
<%
if ("logout".equals(request.getParameter("action"))) {
    session.invalidate();
    response.sendRedirect(app + "/view/customer/CustomerHomeUI3.jsp");
    return;
}

String username = text(request.getParameter("username"));
String password = request.getParameter("password");
Employee3 authenticatedStaff = null;
Customer3 authenticatedMember = null;

if (!username.isEmpty() && within(username, 255) && password != null
        && !password.isEmpty() && within(password, 128)) {
    try (java.sql.Connection con = DAO3.connect()) {
        authenticatedStaff = new EmployeeDAO3(con).authenticate(username, password);
        authenticatedMember = new CustomerDAO3(con).authenticate(username, password);
    }
}

if ((authenticatedStaff == null) == (authenticatedMember == null)) {
    request.setAttribute("username", username);
    request.setAttribute("loginError", "Tên đăng nhập hoặc mật khẩu không hợp lệ.");
    response.setStatus(401);
    request.getRequestDispatcher("/view/common/LoginUI3.jsp").forward(request, response);
    return;
}
synchronized (session) {
    request.changeSessionId();
    session.setAttribute("csrf", UUID.randomUUID().toString());
    session.removeAttribute("warehouseStaff");
    session.removeAttribute("member");
    if (authenticatedStaff != null) {
        session.setAttribute("warehouseStaff", authenticatedStaff);
    } else {
        session.setAttribute("member", authenticatedMember);
    }
}
response.sendRedirect(app + (authenticatedStaff == null ? "/view/customer/CustomerHomeUI3.jsp" : "/view/warehouse/WarehouseHomeUI3.jsp"));
%>
