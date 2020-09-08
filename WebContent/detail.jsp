<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ page import="java.sql.Connection"%>
<%@ page import="java.sql.PreparedStatement"%>
<%@ page import="java.sql.ResultSet"%>
<%@ page import="java.sql.DriverManager" %>
<%@ page import="java.sql.PreparedStatement" %>

<%
Connection con = null;
PreparedStatement pstmt = null;
ResultSet result = null;
String sno = null;
try{
	request.setCharacterEncoding("UTF-8");
	sno = request.getParameter("sno");
	//DB 정보
	Class.forName("org.mariadb.jdbc.Driver");
	con = DriverManager.getConnection("jdbc:mariadb://127.0.0.1:3306/mynote","root","asd0728"); 
	pstmt = con.prepareStatement("SELECT sno, title, content, writer, wdt FROM board WHERE sno=?");
	pstmt.setString(1, sno);
	result = pstmt.executeQuery();
	if(result.next()){
			
%>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title></title>
</head>
<body>
	<h4>상세보기</h4>
	<table border="1">
		<thead>
			<tr>
				<th>제목</th>
				<th>작성자</th>
				<th>날짜</th>
			</tr>
		</thead>
		<tbody>
			<tr>
				<td><%=result.getString("title") %></td>
				<td><%=result.getString("writer") %></td>
				<td><%=result.getString("wdt") %></td>
			</tr>
			<tr>
				<td colspan='5'><%=result.getString("content") %></td>
			</tr>
		</tbody>
	</table>
	<a href="/list.jsp">목록으로</a>&nbsp;
	<a href="/write.jsp?mode=modify&sno=<%=sno%>">수정하기</a>&nbsp;
	<a href="/write.jsp?mode=write&sno=<%=sno%>">답글달기</a>&nbsp;
	<a href="/service.jsp?mode=delete&sno=<%=sno%>" onclick="return confirm('정말로 삭제하시겠습니까?');">삭제하기</a>
<%
	} else{
		throw new Exception("해당 게시글이 존재하지 않습니다.");
	}
}catch (Exception e){
%>
	<script>
		if("" != "<%=e.getMessage()%>"){
			alert("<%=e.getMessage()%>");
			location.href= "list.jsp";
		}
	</script>
<%
}finally{
	if(con != null){
		try {
			con.close();
		}catch (Exception e){
			e.printStackTrace();
		}
	}
	if(pstmt != null){
		try {
			pstmt.close();
		}catch (Exception e){
			e.printStackTrace();
		}
	}
}
 %>
 </body>
</html>