Use cases
=========

This section list use cases for the R&S®Web Application Firewall.

Use cases are classified by categories:
 * [Security](./Security)

Documentation:
* 1 [How to import a subworkflow in the WAF](#how-to-import-a-subworkflow-in-the-waf)
* 2 [R&S documentation](#rohde-and-schwarz-documentation)


How to import a subworkflow in the WAF
--------------------------------------

Use case can provide backups to deploy it on a R&S®WAF.

You can import a backup file through the R&S®WAF Administration Interface. Go to Management > Backup view:

Click on "Upload":

![](attachments/readme_img/1.png "Backup menu")

Choose the backup file and import it:

![](attachments/readme_img/2.png "Upload a backup")

Right click on the imported backup file and click on "Restore":

![](attachments/readme_img/3.png "Restore the backup")

Select all the elements (here there is one sub-workflow, but it could contain multiple subworkflows, ICX rules, static bundles...), and click on "OK":

![](attachments/readme_img/4.png "Select objects to restore")

Now, in your workflow list, you can use your imported sub-workflow.


Rohde and Schwarz documentation
-------------

For more information, see the official documentation at https://documentation.appsec.rohde-schwarz.com/x/QRw9
