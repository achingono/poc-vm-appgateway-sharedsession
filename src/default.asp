<!--#include virtual="/includes/variables.inc.asp" -->

<% 
PageTitle="Welcome" & " : " & Environment.Item("COMPUTERNAME") 

If Request.ServerVariables("REQUEST_METHOD") = "POST" Then
    Session(Request.Form("key")) = Request.Form("value")
End If
%>
    <!DOCTYPE html>
    <html>

    <head>
        <!--#include virtual="/includes/header.inc.asp" -->
    </head>

    <body>
        <!--#include virtual="/includes/nav.inc.asp" -->
        <section class="hero is-large">
            <div class="hero-body">
                <p class="title">
                Shared Session Demo
                </p>
                <p class="subtitle">
                How to share session between Classic ASP and ASP.Net
                </p>
                <p>Coming at you from <%= Environment.Item("COMPUTERNAME")%></p>
            </div>
        </section>
    </body>
    <!--#include virtual="/includes/footer.inc.asp" -->

    </html>