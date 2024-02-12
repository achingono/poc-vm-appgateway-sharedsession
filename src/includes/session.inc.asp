<%
Set HttpClient = CreateObject("MSXML2.ServerXMLHTTP.3.0")
HttpClient.Open "GET", "http://localhost/session.ashx", False
HttpClient.setRequestHeader "Cookie", Request.ServerVariables("HTTP_COOKIE")
HttpClient.Send

If HttpClient.Status = 200 Then
    Set XmlDom = HttpClient.ResponseXML
    
    For Each node in XmlDom.SelectNodes("//item")
        Dim key, value
        key = node.GetAttribute("key")
        value = node.GetAttribute("value")

        ' Ensure key is a non-empty string
        If Not IsEmpty(key) And Not IsNull(key) And Trim(key) <> "" Then
            ' Explicitly convert value to string to avoid type mismatch issues
            If Not IsNull(value) Then
                Session(CStr(key)) = CStr(value)
            Else
                Session(CStr(key)) = ""
            End If
        End If
    Next
End If
%>

