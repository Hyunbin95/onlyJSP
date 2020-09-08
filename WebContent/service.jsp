<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ page import="java.sql.Connection"%>
<%@ page import="java.sql.PreparedStatement"%>
<%@ page import="java.sql.ResultSet"%>
<%@ page import="java.sql.DriverManager" %>
<%@ page import="java.sql.PreparedStatement" %>
<%@ page import="java.sql.Statement" %>
<%@ page import="java.sql.SQLException" %>

<%


String sno = null;
String insertSno = null;
//String mode = request.getParameter("mode");
String errMsg ="";

//페이지 이동 경로
String url = null;

Connection con = null;
PreparedStatement pstmt = null;
Statement stmt = null;

int grpno = 0;
int grpord = 0;
int grpdepth = 0;	

ResultSet resultVal = null;
//insert , update 문의 결과값을 받기 위한 변수 
int result = 0;
try{
	request.setCharacterEncoding("UTF-8");
	url ="/list.jsp";
	sno = request.getParameter("sno");
	Class.forName("org.mariadb.jdbc.Driver");
	con = DriverManager.getConnection("jdbc:mariadb://127.0.0.1:3306/mynote","root","asd0728");
	//트랜잭션 사용을 위한 autoCommit 사용 안함.
	stmt = con.createStatement();
	con.setAutoCommit(false);
	switch(request.getParameter("mode")){
	
	
		//write : 답글달기, 글등록시
		case "write" :
			/*
			mode= write 인 경우에는 답글달기와 글등록에 대한 로직이 공존한다.
			
				글쓰기					답글달기	 
			1. 				게시글등록
			2. 			등록한게시글 sno 조회
			3.						이미 등록된 답글 그룹번호 업데이트
			4.		parameter 로 받은 sno 값으로 그룹정보조회및 세팅 
			5.			게시글 그룹순서 update 
			*/
			
			//1.게시글 등록
			pstmt = con.prepareStatement("INSERT INTO board(title, content, writer, wdt) VALUES(?,?,?,now())");
			pstmt.setString(1,request.getParameter("title"));
			pstmt.setString(2,request.getParameter("content"));
			pstmt.setString(3,request.getParameter("writer"));
			result = pstmt.executeUpdate();
			pstmt.close();
			
			if(result < 1){
				throw new Exception("요청을 실패하였습니다.");
			}
			//2.등록한 게시글 sno 조회
			resultVal = stmt.executeQuery("SELECT max(sno) AS sno FROM board");
			if(resultVal.next()){
				insertSno = resultVal.getString("sno");
			}
			
			//3.등록하기와 답글쓰기에 따른 그룹정보 조회및 세팅
			
			//파라미터로 넘어온 sno가 있을경우 답글달기 로직 없을경우 글 등록하기
			if(!"".equals(sno)){
				//파라미터로 넘어온 sno 값에 그룹 정보 조회 
				pstmt = con.prepareStatement("SELECT grpno, grpord, grpdepth FROM board WHERE sno=?");
				pstmt.setString(1,sno);
				resultVal = pstmt.executeQuery();
				//그룹번호조회 및 세팅
				if(resultVal.next()){
					grpno = resultVal.getInt("grpno");
					grpord = resultVal.getInt("grpord");
					grpdepth = resultVal.getInt("grpdepth")+1;
				}
				pstmt.close();
				//4.이미 등록된 답글  그룹번호 업데이트
				pstmt = con.prepareStatement("UPDATE board SET grpord=grpord+1 WHERE grpno=? AND grpord > ?");
				pstmt.setInt(1, grpno);
				pstmt.setInt(2, grpord++);
				result = pstmt.executeUpdate();
				
			//글 등록하기인 경우 등록하고 받은 sno 기준 그룹정보조회
			}else{
				//그룹번호 세팅
				grpno = Integer.parseInt(insertSno);
				grpord = 0;
				grpdepth = 1;
			}
			
			//5.그룹정보 업데이트  
			pstmt = con.prepareStatement("UPDATE board SET grpno=? ,grpord=? ,grpdepth=? WHERE sno=?");
			pstmt.setInt(1, grpno);	
			pstmt.setInt(2, grpord);
			pstmt.setInt(3, grpdepth);
			pstmt.setString(4, insertSno);
			result = pstmt.executeUpdate();
			if(result < 1){
				throw new Exception("요청을 실패하였습니다.");
			}
			break;
			
		case "modify" :
			//modify 수정
			/*
				1.parameter로 받은 글번호(sno) 와 title,content,writer 정보를 수정 
				2.수정이 안될시에대한 에러처리 ex)존재하지 않는 글번호를 수정하려는 시도
			*/
			pstmt = con.prepareStatement("UPDATE board SET title=? ,content=? ,writer=? WHERE sno=?");
			pstmt.setString(1,request.getParameter("title"));
			pstmt.setString(2,request.getParameter("content"));
			pstmt.setString(3,request.getParameter("writer"));
			pstmt.setString(4,request.getParameter("sno"));
			
			result = pstmt.executeUpdate();
			if(result < 1){
				throw new Exception("요청에 실패 하였습니다.");
			}
			url = "/detail.jsp?sno="+request.getParameter("sno");
			
			break;
		
		case "delete" :
			//delete 삭제
			/*
				1. parameter로 받은 글번호(sno) 로 자식글 존재유무 확인
				2. 자식글이 있는경우는 삭제 처리를  하지않고 (답글을 먼저 지우라는 알림을 보낸다.)
				3. 자식글이 없는경우에 삭제 처리 .
			*/
			//1. 자식글 존재여부 확인
			pstmt = con.prepareStatement("SELECT count(T1.sno) AS cnt FROM board AS T1 ,(SELECT sno ,grpno ,grpord ,grpdepth FROM board WHERE sno=?) sub " +
					"WHERE T1.grpno = sub.grpno AND T1.grpord=sub.grpord+1 AND T1.grpdepth > sub.grpdepth");
			pstmt.setString(1,request.getParameter("sno"));
			resultVal = pstmt.executeQuery();
			pstmt.close();
			if(resultVal.next()){
				//2.자식글이 있는 경우 삭제처리 X 
				if(0 < resultVal.getInt("cnt")){
					throw new Exception("자식글을 먼저 지워주세요.");
				}
			}
			
			//3. 자식글이 없는 경우에 삭제처리 수행
			pstmt = con.prepareStatement("DELETE FROM board WHERE sno=?");
			pstmt.setString(1,request.getParameter("sno"));
			result = pstmt.executeUpdate();
			
			//삭제 처리에 실패할 경우 Exception
			if(result < 1){
				throw new Exception("요청에 실패하였습니다.");
			}
			
			break;
			
		//mode에 해당하는 case가 없을 경우 잘못된 접근으로 판단 에러메시지 송출
		default :
			if(true){
				throw new Exception("올바른 접근경로가 아닙니다.");
			}
		}
	//모든 요청에 성공한 경우 commit 후 redirect 페이지 이동 
	con.commit();
	response.sendRedirect(url);
	
	}catch (Exception e){
		//Exception 이 발생한 경우 롤백
		con.rollback();
		errMsg = e.getMessage();
	} finally{
		if(pstmt != null){
			try {
				pstmt.close();
			} catch (SQLException e){
				errMsg = e.getMessage();		
			}
		}
		
		if(stmt != null){
			try {
				stmt.close();
			} catch (SQLException e){
				errMsg = e.getMessage();
			}
		}
		
		if (con != null){
			try {
				con.close();
			}catch (SQLException e){
				errMsg = e.getMessage();
			}
		}
		
	}
%>
    

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>비즈니스</title>
</head>
<body>
<script>
//에러 메시지 띄운 후 리스트 페이지로 이동 
if("<%=errMsg%>" != ""){
	alert("<%=errMsg%>");
	location.href = "/list.jsp";
}
</script>
</body>
</html>