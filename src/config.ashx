<%@ WebHandler Language="C#" Class="ConfigHandler" %>
using System;
using System.Web;
using System.Web.Configuration;
using Newtonsoft.Json;

public class ConfigHandler : IHttpHandler {

    public void ProcessRequest (HttpContext context) {
        var configuration = WebConfigurationManager.OpenWebConfiguration("/");
        var section = configuration.GetSection("system.web/sessionState") as SessionStateSection;
        var provider = section.Providers[section.CustomProvider];
        var output = new {
            session = new {
                timeout = section.Timeout,
                provider = new {
                    host=provider.Parameters["host"],
                    port=provider.Parameters["port"],
                    accessKey=provider.Parameters["accessKey"],
                    ssl=provider.Parameters["ssl"],
                    applicationName=provider.Parameters["applicationName"],
                    databaseId=provider.Parameters["databaseId"]
                }
            }
        };

        context.Response.ContentType = "application/json";
        context.Response.Write(JsonConvert.SerializeObject(output));
    }

    public bool IsReusable {
        get {
            return false;
        }
    }
}