Redirect on Path
================

* 1 [Presentation](#presentation)
* 2 [Backup](#backup)
* 3 [URL Mapping](#url-mapping)
	* 3.1 [URL Mapping profile](#url-mapping-profile)
	* 3.2 [URL Mapping rule](#url-mapping-rule)
* 4 [Workflow](#workflow)
* 5 [Result](#result)

Presentation
------------

This use case presents you how to redirect clients depending on the **Path** being called, using URL Mapping. The destination can include a query.

Backup
------

You can download the backup here: [WF - Redirect on Path](./backup/WF%20-%20Redirect%20on%20Path.backup).

URL Mapping
-----------

### URL Mapping profile

First of all, we need to create an **URL Mapping profile** that will allow to select specific **Path** that will lead to automatic redirection in your application with another path and possibly parameters. 

To create the URL mapping: 
* Go to **Policies > Workflows > URL Mappings**.
* Press **Add** to create it, select a **Name** and press **OK**.

### URL Mapping rule

Now, select the newly created **URL Mapping** and in the view below press **Add** to add a rule to your **URL Mapping**. 

You will have to add proper parameters in the **General** tab for the **URL Mapping rule**:
* The fields **Host** and **Port** have to remain empty as we will not use them.
* The field **Source path** has to contain a regular expression representing the **Path** of the request. In this case we will set it at **/test/**.
* The field **Destination path** should contain the destination path of the redirection. Here, it will be **/dvwa/instructions.php?query=value**.

![](./attachments/url_mapping_general.png)

The **Map Backend** tab will not be used, so you can untick the **Map Backend** box in it.

Workflow
--------

The Workflow **WF - Redirect on Path** is mandatory to use the **URL Mapping profile** with your tunnel and to redirect the user accordingly.

![](./attachments/workflow.png)

Firstly, this workflow will use the **URL Mapping** node with the **URL Mapping profile** we have just created to check if the **Path** of the request matches a rule in the **URL Mapping profile**. Note that this node will only use the first matching rule of the list.

Then, we check if any rule matched with the provided attribute **url.mapping.matched**. If so, we continue in the Workflow, otherwise we send the request to the backend.

Finally, it will check if the URL of redirection contains a query or not, and depending on it, it will use the **Redirect** node appropriately to redirect the request.

Result
------

Now, you can try to access to the URL triggering the redirection, in our example we used **ww<span>w.redirection1.com/test/**. 

| Note that the FQDN **ww<span>w.redirection1.com** is the one we use for this example, you will have to replace it with the one you are using.|
|----------------------------------------------------------------------------------------------------------------------------------------------|

![](./attachments/result_redirection.png)

You can see that when we get to **ww<span>w.redirection1.com/test/** we have a redirection to the URL we set previously: **http:/<span>/ww<span>w.redirection1.com/dvwa/instructions.php?query=value**.
