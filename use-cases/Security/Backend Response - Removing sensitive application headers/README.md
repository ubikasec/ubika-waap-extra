Removing sensitive application headers
======================================

Presentation
------------

This use case allows to delete sensitive headers frequently sent by the application backend. For example, most applications send by default the HTTP header **Server**. It will contains information about the software used by the origin server to handle the request.

Example: `Server: Apache/2.4.1 (Unix)`

They potentially reveal internal implementation details that might make it (slightly) easier for attackers to find and exploit known security holes.

How to use it in a Workflow ?
-----------------------------

The Sub-Workflow **SWF - Remove sensitive application headers** must be placed after the **Proxy Request** node to allow changes in the **http.response.headers** attribute.

Response Headers handled
------------------------

| **Name** | Description | **Example  <br>** |
| --- | --- | --- |
| Server | The Server header contains information about the software used by the application. | Microsoft-IIS/3.0 |
| X-Powered-By | Specifies the technology (e.g. ASP.NET, PHP, JBoss, Apache, ...) used by the application. | ASP.NET |
| X-AspNet-Version | Specifies the version of ASP.NET being used by the application. | 2.0.50727 |
| X-AspNetMvc-Version | Specifies the version of ASP.NET MVC being used by the application. | 1.0 |
| X-MS-Smart-Tags | A non-standard Microsoft header. | ?   |
| X-Meta-MSSmartTagsPreventParsing | A non-standard Microsoft header. | ?   |
| MicrosoftOfficeWebServer | A non-standard Microsoft header. | ?   |
| IISExport | A non-standard Microsoft header. | ?   |