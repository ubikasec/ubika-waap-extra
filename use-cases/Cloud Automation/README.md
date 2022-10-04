Cloud Automation
================

* 1 [Use cases](#use-cases)
* 2 [Presentation](#presentation)
* 3 [Usage](#usage)
	* 3.1 [Pre-requisites](#pre-requisites)
	* 3.2 [Terraform basic usage](#terraform-basic-usage)

Use cases
---------

* [Amazon Web Services](./Amazon%20Web%20Services)
* [Google Cloud Platform](./Google%20Cloud%20Platform)
* [Microsoft Azure](./Microsoft%20Azure)

Presentation
------------

To handle peaks of traffic and reduce infrastructure cost, UBIKA WAAP can automatically scale following the instances workloads. A fast deployment is possible using Terraform.

The platform will scale out on peaks of traffic (by creating new Managed instances), and back down when traffic returns back to normal (by removing Managed instances). The administrator can thus benefit a potentially unlimited scalability.

![](./attachments/cloud%20automation.png)

![](./attachments/Instances%20EC2%20Management%20Console.jpg)

This feature uses the new capability to mix several types of instances :

* **Bring Your Own License (BYOL)** instances available permanently to handle the usual traffic demand (see "UBIKA WAAP Workers" on the schema above)
* **Pay as you go (PAYG)** instances created on demand by an auto-scaling group to handle peak loads (see "On demand UBIKA WAAP Workers" on the schema above).

This guarantees the most cost-effective solution as new WAF instances are launched automatically when they are needed but are also terminated when they are not. In addition, the administrator can define a threshold to limit the costs.

![](./attachments/CloudWatch%20Management%20Console.jpg)

Usage
-----

### Pre-requisites

Download and install **Terraform**, with a version greater than 0.14, on a local computer.

See https://learn.hashicorp.com/terraform/getting-started/install for more informations on how to install Terraform.

### Terraform basic usage

Initiate your directory to use Terraform:

```
terraform init
```

| :warning: Terraform uses a local database to store the platform configuration. Do not delete it or you will not be able to apply changes to your current deployment.|
|----------|

Edit the templates to match your needs and apply your configuration to deploy your infrastructure with:
```
terraform apply
```

After the deployment of your cluster, a scheduled task named **Remove inactive long time appliance** is created. This task is active only if you have an autoscaled managed in your cluster.

To destroy the platform run:
```
terraform destroy
```
