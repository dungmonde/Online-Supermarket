<%@ page pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/view/common/common.jspf" %>
<%
if (member != null || staff != null) {
    response.sendRedirect(app + (staff == null ? "/view/customer/CustomerHomeUI3.jsp" : "/view/warehouse/WarehouseHomeUI3.jsp"));
    return;
}

String title = "Đăng ký thành viên";
String fullName = "";
String phone = "";
String email = "";
String address = "";
String username = "";
List<String> errors = new ArrayList<>();

if ("POST".equals(request.getMethod())) {
%>
<%@ include file="/WEB-INF/view/common/post.jspf" %>
<%
    fullName = text(request.getParameter("fullName"));
    phone = text(request.getParameter("phoneNumber"));
    email = text(request.getParameter("email"));
    address = text(request.getParameter("address"));
    username = text(request.getParameter("username"));
    String password = request.getParameter("password");
    String confirmation = request.getParameter("confirmPassword");

    if (fullName.isEmpty() || !within(fullName, 255)) {
        errors.add("Nhập họ và tên, tối đa 255 ký tự.");
    }
    if (!validPhone(phone)) {
        errors.add("Nhập số điện thoại hợp lệ có từ 7 đến 15 chữ số.");
    }
    if (!email.isEmpty() && (!within(email, 255) || !email.matches("[^\\s@<>]+@[^\\s@<>.]+(?:\\.[^\\s@<>.]+)+"))) {
        errors.add("Nhập địa chỉ email hợp lệ.");
    }
    if (address.isEmpty() || !within(address, 255)) {
        errors.add("Nhập địa chỉ, tối đa 255 ký tự.");
    }
    if (username.isEmpty() || !within(username, 255)) {
        errors.add("Nhập tên đăng nhập, tối đa 255 ký tự.");
    }
    if (password == null || password.isBlank() || password.length() < 8 || password.length() > 128) {
        errors.add("Mật khẩu phải có từ 8 đến 128 ký tự.");
    } else if (!password.equals(confirmation)) {
        errors.add("Xác nhận mật khẩu chưa khớp.");
    }

    if (errors.isEmpty()) {
        try (java.sql.Connection con = DAO3.connect()) {
            CustomerDAO3 dao = new CustomerDAO3(con);
            if (dao.registerMember(fullName, phone, email.isEmpty() ? null : email, address, username, password)) {
                session.setAttribute("registeredUsername", username);
                response.sendRedirect(app + "/view/common/LoginUI3.jsp");
                return;
            }
            response.setStatus(409);
            errors.add("Tên đăng nhập đã được sử dụng. Hãy chọn tên khác.");
        } catch (SQLException e) {
            application.log("Không lưu được tài khoản thành viên", e);
            response.setStatus(500);
            errors.add("Chưa đăng ký được tài khoản. Vui lòng thử lại.");
        }
    } else {
        response.setStatus(400);
    }
}
%>
<%@ include file="/WEB-INF/view/common/head.jspf" %>
<main class="page compact">
    <h1><%= title %></h1>
    <% if (!errors.isEmpty()) { %>
        <ul class="notice error" role="alert">
            <% for (String error : errors) { %><li><%= html(error) %></li><% } %>
        </ul>
    <% } %>
    <form method="post" action="<%= app %>/view/customer/RegisterMemberUI3.jsp">
        <input type="hidden" name="csrf" value="<%= csrf %>">
        <div class="fields">
            <label for="fullName">Họ và tên <span class="required-mark" aria-hidden="true">*</span></label>
            <input id="fullName" name="fullName" value="<%= html(fullName) %>" autocomplete="name"
                   maxlength="255" pattern=".*\S.*" required>
            <label for="phoneNumber">Số điện thoại <span class="required-mark" aria-hidden="true">*</span></label>
            <input id="phoneNumber" name="phoneNumber" value="<%= html(phone) %>" type="tel" autocomplete="tel"
                   maxlength="25" pattern="<%= PHONE_INPUT_PATTERN %>"
                   title="Nhập số điện thoại có từ 7 đến 15 chữ số." required>
            <label for="email">Email (tùy chọn)</label>
            <input id="email" name="email" value="<%= html(email) %>" type="email" autocomplete="email" maxlength="255">
            <label for="address">Địa chỉ <span class="required-mark" aria-hidden="true">*</span></label>
            <input id="address" name="address" value="<%= html(address) %>" autocomplete="street-address"
                   maxlength="255" pattern=".*\S.*" required>
            <label for="username">Tên đăng nhập <span class="required-mark" aria-hidden="true">*</span></label>
            <input id="username" name="username" value="<%= html(username) %>" autocomplete="username"
                   maxlength="255" pattern=".*\S.*" required>
            <label for="password">Mật khẩu <span class="required-mark" aria-hidden="true">*</span></label>
            <input id="password" name="password" type="password" autocomplete="new-password"
                   minlength="8" maxlength="128" placeholder="Ít nhất 8 ký tự" required>
            <label for="confirmPassword">Xác nhận mật khẩu <span class="required-mark" aria-hidden="true">*</span></label>
            <input id="confirmPassword" name="confirmPassword" type="password" autocomplete="new-password"
                   minlength="8" maxlength="128" required>
        </div>
        <div class="actions">
            <button class="button" type="submit">Đăng ký</button>
            <a class="button secondary" href="<%= app %>/view/common/LoginUI3.jsp">Đăng nhập</a>
            <a class="button secondary" href="<%= app %>/view/customer/CustomerHomeUI3.jsp">Về cửa hàng</a>
        </div>
    </form>
</main>
</body>
</html>
