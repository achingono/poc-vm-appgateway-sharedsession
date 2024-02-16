<%
Response.ContentType = "text/xml"
Response.Charset = "UTF-8"

Dim objXML
Dim objNode
Dim key

' Create an XML document object
Set objXML = Server.CreateObject("MSXML2.DOMDocument")

' Create the root element
Set objRoot = objXML.createElement("session")
objXML.appendChild objRoot

' Loop through each session variable
For Each key In Session.Contents
    ' Create an 'item' element for each session variable
    Set objNode = objXML.createElement("item")
    
    ' Create a 'key' attribute and set its value
    objNode.setAttribute "key", key
    
    ' Create a 'value' attribute and set its value
    objNode.setAttribute "value", Session(key)
    
    ' Append this 'item' element to the root
    objRoot.appendChild objNode
Next

' Output the XML
Response.Write "<?xml version=""1.0"" encoding=""UTF-8""?>"
Response.Write objXML.xml

' Clean up
Set objNode = Nothing
Set objRoot = Nothing
Set objXML = Nothing
%>
