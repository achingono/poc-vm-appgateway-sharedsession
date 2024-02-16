<%@ WebHandler Language="C#" Class="TransferHandler" %>
using System;
using System.Web;
using System.Web.SessionState;
using System.Net;
using System.Xml;

public class TransferHandler : IHttpHandler, IRequiresSessionState {

    public void ProcessRequest(HttpContext context) {
        var sessionUrl = "http://localhost/session/classic.asp";
        HttpWebRequest request = (HttpWebRequest)WebRequest.Create(sessionUrl);

        // Copy cookies from the incoming request to the outgoing request
        string cookieHeader = context.Request.Headers["Cookie"];
        if (!string.IsNullOrEmpty(cookieHeader)) {
            request.Headers.Add("Cookie", cookieHeader);
        }

        request.Method = "GET";

        // Get the response from the remote server
        using (HttpWebResponse response = (HttpWebResponse)request.GetResponse()) {
            // Ensure we received an OK response
            if (response.StatusCode == HttpStatusCode.OK) {
                // Load the response stream into an XmlDocument
                XmlDocument xmlDoc = new XmlDocument();
                xmlDoc.Load(response.GetResponseStream());

                // Iterate through each XML node and populate the ASP.NET session with key/value pairs
                foreach (XmlNode node in xmlDoc.SelectNodes("//item")) {
                    string key = node.Attributes["key"].InnerText;
                    string value = node.Attributes["value"].InnerText;

                    // Populate the ASP.NET session
                    context.Session[key] = value;
                }
            }
        }
    }

    public bool IsReusable {
        get {
            return false;
        }
    }
}
