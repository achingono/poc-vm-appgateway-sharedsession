<%@ WebHandler Language="C#" Class="SessionHandler" %>
using System;
using System.Web;
using System.Web.Configuration;
using System.Web.SessionState;
using System.Collections;
using System.Collections.Generic;
using System.Xml.Linq;

public class SessionHandler : IHttpHandler, IRequiresSessionState {

    public void ProcessRequest(HttpContext context) {
        if (context.Request.RequestType.Equals("POST", StringComparison.OrdinalIgnoreCase)
            && !string.IsNullOrEmpty(context.Request.Form["key"])) {
            context.Session[context.Request.Form["key"]] = context.Request.Form["value"];
        }

        XElement element = new XElement("session");

        foreach (string key in context.Session.Keys) {
            XElement itemElement = new XElement("item",
                new XAttribute("key", key),
                new XAttribute("value", null == string.Format("{0}", context.Session[key]))
            );
            element.Add(itemElement);
        }

        XDocument document = new XDocument(new XDeclaration("1.0", "UTF-8", null), element);

        context.Response.ContentType = "application/xml";
        context.Response.Write(document.Declaration.ToString());
        context.Response.Write(document.ToString());
    }

    public bool IsReusable {
        get {
            return false;
        }
    }
}
