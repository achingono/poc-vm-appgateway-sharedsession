<%@ WebHandler Language="C#" Class="ConfigHandler" %>
using System;
using System.Web;
using System.Web.Configuration;
using System.Xml.Linq;

public class ConfigHandler : IHttpHandler {

    public void ProcessRequest(HttpContext context) {
        var configuration = WebConfigurationManager.OpenWebConfiguration("/");
        var section = configuration.GetSection("system.web/sessionState") as SessionStateSection;
        var provider = section.Providers[section.CustomProvider];
        var connectionString = WebConfigurationManager.ConnectionStrings[WebConfigurationManager.AppSettings["SQLConnectionStringName"]].ConnectionString;

        var element = new XElement("configuration",
            new XElement("session",
                new XAttribute("timeout", section.Timeout),
                new XElement("provider",
                    new XAttribute("host", provider.Parameters["host"]),
                    new XAttribute("port", provider.Parameters["port"]),
                    new XAttribute("accessKey", provider.Parameters["accessKey"]),
                    new XAttribute("ssl", provider.Parameters["ssl"]),
                    new XAttribute("applicationName", provider.Parameters["applicationName"]),
                    new XAttribute("databaseId", provider.Parameters["databaseId"])
                )
            ),
            new XElement("connectionString",
                new XAttribute("value", connectionString),
                new XAttribute("provider", WebConfigurationManager.AppSettings["SQLProvider"])
            )
        );
        XDocument document = new XDocument(element);
        
        context.Response.ContentType = "text/xml";
        context.Response.Write(document.ToString());
    }

    public bool IsReusable {
        get {
            return false;
        }
    }
}
