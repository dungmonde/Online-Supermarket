<%@ page pageEncoding="UTF-8" %>
<%@ include file="/WEB-INF/view/common/common.jspf" %>
<%
String title = "Đăng nhập";
String message = (String) request.getAttribute("loginError");
String username = text((String) request.getAttribute("username"));
boolean registered = false;
synchronized (session) {
    String registeredUsername = (String) session.getAttribute("registeredUsername");
    if (registeredUsername != null && message == null) {
        session.removeAttribute("registeredUsername");
        username = registeredUsername;
        registered = true;
    }
}
%>
<%@ include file="/WEB-INF/view/common/head.jspf" %>
<main class="page compact">
    <h1>Đăng nhập</h1>
    <% if (registered) { %>
        <p class="notice success" role="status">Đăng ký thành công. Bạn có thể đăng nhập bằng tài khoản vừa tạo.</p>
    <% } %>
    <form method="post" action="<%= app %>/view/common/doLogin3.jsp">
        <input type="hidden" name="csrf" value="<%= csrf %>">
        <div class="fields">
            <label for="username">Tên đăng nhập <span class="required-mark" aria-hidden="true">*</span></label>
            <input id="username" name="username" value="<%= html(username) %>" autocomplete="username" maxlength="255" pattern=".*\S.*" required>
            <label for="password">Mật khẩu <span class="required-mark" aria-hidden="true">*</span></label>
            <input id="password" name="password" type="password" autocomplete="current-password" maxlength="128" required>
        </div>
        <div class="actions">
            <button class="button" type="submit">Đăng nhập</button>
            <a class="button secondary" href="<%= app %>/view/customer/CustomerHomeUI3.jsp">Về cửa hàng</a>
        </div>
    </form>
    <% if (member == null && staff == null) { %>
        <p class="foot"><a href="<%= app %>/view/customer/RegisterMemberUI3.jsp">Đăng ký thành viên</a></p>
    <% } %>
    <% if (message != null) { %><p class="notice error" role="alert"><%= html(message) %></p><% } %>
</main>
</body>
</html>
