<!--#include virtual="/includes/variables.inc.asp" -->
<!--#include virtual="/includes/session.inc.asp" -->

<% 
PageTitle="Welcome" & " : " & Environment.Item("COMPUTERNAME") 

If Request.ServerVariables("REQUEST_METHOD") = "POST" Then
    'Session(Request.Form("key")) = Request.Form("value")
    Dim data: data = "key=" & Server.URLEncode(Request.Form("key")) & "&value=" & Server.URLEncode(Request.Form("value"))
    Set HttpClient = CreateObject("MSXML2.ServerXMLHTTP.3.0")
    HttpClient.Open "POST", "http://localhost/session.ashx", False
    HttpClient.setRequestHeader "Cookie", Request.ServerVariables("HTTP_COOKIE")
    HttpClient.setRequestHeader "Content-Type", "application/x-www-form-urlencoded"
    HttpClient.setRequestHeader "Content-Length", Len(data)
    HttpClient.send data

    If HttpClient.Status = 200 Then
        Set XmlDom = HttpClient.ResponseXML
        
        For Each node in XmlDom.SelectNodes("//item")
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
End If
%>
    <!DOCTYPE html>
    <html>

    <head>
        <!--#include virtual="/includes/header.inc.asp" -->
    </head>

    <body>
        <!--#include virtual="/includes/nav.inc.asp" -->
        <div class="container">
            <h1 class="title">Session Test</h1>
            <div class="section">
                <form class="form" action="" method="post">
                    <h2 class="subtitle">Add Session Item</h2>
                    <div class="field is-horizontal">
                        <div class="field-label is-normal">
                            <label class="label">Key:</label>
                        </div>
                        <div class="field-body">
                            <div class="field">
                                <div class="control">
                                    <input name="key" class="input" type="text" placeholder="Session key">
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="field is-horizontal">
                        <div class="field-label is-normal">
                            <label class="label">Value:</label>
                        </div>
                        <div class="field-body">
                            <div class="field">
                                <div class="control">
                                    <input name="value" class="input" type="text" placeholder="Session value">
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="field is-horizontal">
                        <div class="field-label">
                            <!-- Left empty for spacing -->
                        </div>
                        <div class="field-body">
                            <div class="field">
                                <div class="control">
                                    <button type="submit"  class="button is-primary">
                                        Save Session
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                </form>
            </div>

            <div class="section">
                <h2 class="subtitle">Session Items</h2>
                <table class="table is-fullwidth">
                    <thead>
                        <tr>
                            <th>Key</th>
                            <th>Value</th>
                        </tr>
                    </thead>
                    <tbody>
                        <%
                        For each key in Session.Contents
                            Response.Write "<tr><td>" & key & "</td><td>" & Session(key) & "</td></tr>"
                        Next
                        %>
                    </tbody>
                </table>
            </div>
        </div>
    </body>
    <!--#include virtual="/includes/footer.inc.asp" -->

    </html>