<%@ WebHandler Language="C#" Class="SessionHandler" %>
using System;
using System.Web;
using System.Web.Configuration;
using System.Web.SessionState;
using Newtonsoft.Json;
using System.Collections;
using System.Collections.Generic;
using System.Linq;

public class SessionHandler : IHttpHandler, IRequiresSessionState {

    public void ProcessRequest (HttpContext context) {
        var collection = new List<dynamic>();

        if (context.Request.RequestType.Equals("POST", StringComparison.OrdinalIgnoreCase)
            && !string.IsNullOrEmpty(context.Request.Form["key"]))
        {
            context.Session[context.Request.Form["key"]] = context.Request.Form["value"];
        }

        context.Response.ContentType = "application/xml";
        context.Response.Write("<?xml version=\"1.0\" encoding=\"UTF-8\"?>");
        context.Response.Write("<session>");

        foreach(string key in context.Session.Contents)
        {
            context.Response.Write("<item key=\"" + key + "\" value=\"" + context.Session[key].ToString() + "\" />");
        }

        context.Response.Write("</session>");
    }

    public bool IsReusable {
        get {
            return false;
        }
    }
}