<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ page import="java.sql.Connection"%>
<%@ page import="java.sql.PreparedStatement"%>
<%@ page import="java.sql.ResultSet"%>
<%@ page import="java.sql.DriverManager" %>
<%@ page import="java.sql.PreparedStatement" %>
<%
String mode = null;

Connection con = null;
PreparedStatement pstmt = null;
ResultSet result = null;

String title="";
String content="";
String writer="";
String msg = "";

/*
	write.jsp 에는 등록하기, 답글쓰기 , 수정하기로 넘어온 쓰기 페이지.
	수정하기 인경우에는 이미 등록한 글이 있으므로 수정하기 모드와 글번호를 기준으로 
	이미 작성한 데이터들을 조회해온다.
*/
request.setCharacterEncoding("UTF-8");
mode = request.getParameter("mode") ;
if("modify".equals(mode)){
	try {
		//DB 연결
		Class.forName("org.mariadb.jdbc.Driver");
		con = DriverManager.getConnection("jdbc:mariadb://127.0.0.1:3306/mynote","root","asd0728");
		//수정모드와 넘어온 sno 가 있으면 등록했던 데이터들을 조회 
		pstmt = con.prepareStatement("SELECT sno, title, content, writer FROM board WHERE sno=?");
		pstmt.setString(1, request.getParameter("sno"));
		result = pstmt.executeQuery();
		if(result.next()){
				title=result.getString("title");
				content=result.getString("content");
				writer=result.getString("writer");
		}else{
			throw new Exception("요청을 불러오는데 실패하였습니다.");
		}
		
	} catch(Exception e){
		msg = e.getMessage();
	} finally{
		if(con != null){
			con.close();
		}
		if(pstmt != null){
			pstmt.close();
		}
	}
}
%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>작성</title>
<script src="https://code.jquery.com/jquery-3.5.1.min.js"></script>
</head>
<body>
	<form action="/service.jsp" method="post" onsubmit="return frmVali()">
		<%-- <input type="hidden" name="sno" value="<%="".equals(request.getParameter("sno")) ? "" : request.getParameter("sno")%>"> --%>
		<input type="hidden" name="sno" value="<%=request.getParameter("sno") == null ? "" : request.getParameter("sno")%>">
		<input type="hidden" name="mode" value="<%= "modify".equals(mode) ? "modify": "write" %>">
		<table>
			<tr>
				<td><label>제목</label></td>
				<td>
					<input type="text" name="title" value="<%=title%>" maxlength="255" />
					<label id="titleCheck"></label>
				</td>
			</tr>
			<tr>
				<td>작성자</td>
				<td>
					<input type="text" name="writer" value="<%=writer%>" maxlength="20" />
					<label id="writerCheck"></label>
				</td>
			</tr>
			<tr>
				<td>내용</td>
				<td>
					<textarea cols="23" id="content" rows="10" name="content"><%=content%></textarea>
					<label id="contentCheck"></label>
				</td>
			</tr>
		</table>
		<button type="submit" onclick="frmVali()"><%= "modify".equals(mode) ? "수정하기" : "등록하기"  %></button>
	</form>
	</br><a href="/list.jsp">돌아가기</a>
<script>
	$(document).ready(function(){
		
		
	})
	
	function frmVali(){
		var valiCheck = true;
		
		if(!$("input[name='title']").val().trim()){
			$("#titleCheck").empty();
			$("#titleCheck").append("제목을 입력하세요.");
			valiCheck = false;
		}else{
			$("#titleCheck").empty();
		}
		
		if(!$("input[name='writer']").val().trim()){
			$("#writerCheck").empty();
			$("#writerCheck").append("작성자를 입력하세요.");
			valiCheck = false;
		}else{
			$("#writerCheck").empty();
		}
		
		if(!$("#content").val().trim()){
			$("#contentCheck").empty();
			$("#contentCheck").append("내용을 입력하세요.");
			valiCheck = false;
		}else{
			$("#contentCheck").empty();
		}
		
		return valiCheck;
	}
	
	if("<%=msg%>" != ""){
		alert("<%=msg%>");
		location.href = "/list.jsp";
	}
</script>
</body>
</html>