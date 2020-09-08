<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ page import="java.sql.Connection" %>
<%@ page import="java.sql.Statement" %>
<%@ page import="java.sql.ResultSet" %>
<%@ page import="java.sql.DriverManager" %>
<%@ page import="java.sql.SQLException" %>
<%@ page import="java.sql.PreparedStatement" %>

<%

PreparedStatement pstmt = null;
String schTitle = null;
Connection con = null;
ResultSet result = null;
Statement stmt = null;

//페이지 정보
String space = null; 	//페이지에 보여질 답글단계 정보
int DISPLAY_ROW = 10;	//한 페이지에 보여질 게시글 수
int DISPLAY_PAGE = 10;	//한 페이지에 보여질 페이지 수 
int paging = 0;			//페이지
int beginPage = 0;		//리스트안에 보여질 처음페이지 
int endPage = 0;		//리스트안에 보여질 마지막페이지
int totalCount = 0; 	//총 게시글 수 
int totalPage = 0;		//총 페이지
int i=0;				//페이지에서 사용할 idx 정보 


try{
	request.setCharacterEncoding("UTF-8");
	schTitle = request.getParameter("schTitle") == null ? "" : request.getParameter("schTitle").replaceAll(" ","");
	
	paging = request.getParameter("paging") == null || Integer.parseInt(request.getParameter("paging")) <= 0 ? 1 : Integer.parseInt(request.getParameter("paging"));
	
	
	//DB 연결
	Class.forName("org.mariadb.jdbc.Driver");
	con = DriverManager.getConnection("jdbc:mariadb://127.0.0.1:3306/mynote","root","asd0728");
	stmt = con.createStatement();
	
	//게시글 수 조회
	pstmt = con.prepareStatement("SELECT count(sno) AS cnt FROM board WHERE title LIKE CONCAT('%',?,'%')");
	pstmt.setString(1, schTitle);
	result = pstmt.executeQuery();
	pstmt.close();
	
	
	if(result.next()){
		//총 게시글 수 
		totalCount = result.getInt("cnt");
	}
	
	/* #### 페이징 구현  ####*/
	
	//총 페이지 = 총 게시글 수 / 한페이지에 보여질 게시글 수
	totalPage = totalCount % DISPLAY_ROW > 0 ? totalCount / DISPLAY_ROW + 1 : totalCount / DISPLAY_ROW; 
	
	beginPage = ((paging-1)/DISPLAY_PAGE) * DISPLAY_PAGE +1;
	endPage = beginPage + DISPLAY_PAGE -1;
	endPage = endPage > totalPage ? totalPage : endPage;
	
	totalCount = totalCount - ((paging-1) * DISPLAY_ROW);
	//### 페이징 구현 ####
	
	//게시글 조회
	/* pstmt = con.prepareStatement("SELECT sno ,title, writer ,wdt ,rnum, grpdepth FROM (SELECT @ROWNUM := @ROWNUM +1 AS rnum ,sno ,title, writer, wdt ,grpdepth FROM board ,(SELECT @ROWNUM := 0) sub "+ 
			"WHERE title LIKE CONCAT('%', ? , '%') ORDER BY grpno ,grpord desc) sub WHERE title LIKE CONCAT('%',?,'%') ORDER BY rnum desc limit ? ,?"); */
	pstmt = con.prepareStatement("SELECT sno, title, writer ,wdt , grpdepth FROM board WHERE title LIKE CONCAT('%', ? ,'%') ORDER BY grpno desc,grpord limit ?,?");
	pstmt.setString(1,schTitle);
	pstmt.setInt(2,DISPLAY_ROW * (paging-1));
	pstmt.setInt(3,DISPLAY_ROW);
	result = pstmt.executeQuery();
%>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>게시글 목록</title>
<script src="https://code.jquery.com/jquery-3.5.1.min.js"></script>
</head>
<body>
<h4>MVC1 게시판</h4>
<label>제목검색</label>
<input type="text" name="schTitle" value="<%=schTitle%>">
<button type="button" onclick="schTitle();">검색하기</button>
<br>
<%
		if(result.isBeforeFirst()){
%>
<div>
	<table border="1">
		<thead>
			<tr>
				<th>번호</th>
				<th>제목</th>
				<th>작성자</th>
				<th>날짜</th>
			</tr>
		</thead>
		<tbody>
<%
			while(result.next()){
				space = "";
				
				for(i=1 ; i < result.getInt("grpdepth"); i++){
					space = space + "&nbsp&nbsp";
					if(i == result.getInt("grpdepth")-1){
						space += "re:";
					}
				}
%>
			<tr>
				<td><%=totalCount %></td>
				<td>
					<a href="/detail.jsp?sno=<%=result.getString("sno")%>">
						<%=space + result.getString("title")%>
					</a>
				</td>
				<td><%=result.getString("writer") %></td>
				<td><%=result.getString("wdt") %></td>
			</tr>
<%
				totalCount = totalCount -1;
			}
%>
		</tbody>
	</table>
</div>
<div>		
<%
			if(beginPage > 1){
				out.print("<a href='/list.jsp?paging="+(beginPage-1)+"&schTitle="+schTitle+"'>prev</a>");
			} 
			for(i=beginPage ; i<=endPage ; i++){
				if(paging == i){
					/* <!-- 현재 페이지와 같은 경우  --> */
					out.print(i);
				}else{
					/* <!-- 페이지 이동 --> */
					out.print("<a href=/list.jsp?paging="+i+"&schTitle="+schTitle+">"+i+"</a>");
				}
			}
			if(totalPage > endPage){
				out.print("<a href=/list.jsp?paging="+i+"&schTitle="+schTitle+">next</a>");
			}
		}else{
%>
		<p>검색 결과가 없습니다.</p>
<%	
		}		
%>
</div>
	
	<a href="/write.jsp?mode=write">글 등록하기</a>
<script>
	function schTitle(){
		$(location).attr('href', '/list.jsp?schTitle='+$("input[name='schTitle']").val());
	}
</script>
</body>
</html>
<%
	} catch (Exception e) {
		e.printStackTrace();
} finally {
	//statement 종료
	if (stmt != null) {
		try {
			stmt.close();
		} catch (SQLException e) {
			e.printStackTrace();
		}
	}
	//preparedStatement 종료
	if (pstmt != null) {
		try {
			pstmt.close();
		} catch (SQLException e) {
			e.printStackTrace();
		}
	}
	//connection 종료
	if (con != null) {
		try {
			con.close();
		} catch (SQLException e) {
			e.printStackTrace();
		}
	}
}
%>