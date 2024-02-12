<%
Dim PageTitle
Set Shell = CreateObject("WScript.Shell")
Set Environment = Shell.Environment( "PROCESS" )
Set Redis = Server.CreateObject("RedisComClient")
%>