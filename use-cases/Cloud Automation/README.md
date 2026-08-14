# Cloud Automation

* 1 [Use cases for each Cloud provider](#use-cases-for-each-cloud-provider)
* 2 [Presentation](#presentation)
* 3 [Usage](#usage)
	* 3.1 [Pre-requisites](#pre-requisites)
	* 3.2 [Where the Terraform files are](#where-the-terraform-files-are)
	* 3.3 [Terraform basic usage](#terraform-basic-usage)

## Use cases for each Cloud provider

* [Amazon Web Services](./Amazon%20Web%20Services)
* [Google Cloud Platform](./Google%20Cloud%20Platform)
* [Microsoft Azure](./Microsoft%20Azure)
* [Outscale](./Outscale)

## Presentation

To handle peaks of traffic and reduce infrastructure cost, UBIKA WAAP can automatically scale following the instances workloads. A fast deployment is possible using Terraform.

The platform will scale out on peaks of traffic (by creating new Managed instances), and back down when traffic returns back to normal (by removing Managed instances). The administrator can thus benefit from a potentially unlimited scalability.

![](./attachments/cloud%20automation.png)

![](./attachments/Instances%20EC2%20Management%20Console.jpg)

This feature uses the new capability to mix several types of instances :

* **Bring Your Own License (BYOL)** instances available permanently to handle the usual traffic demand (see "UBIKA WAAP Workers" on the schema above)
* **Pay as you go (PAYG)** instances created on demand by an auto-scaling group to handle peak loads (see "On demand UBIKA WAAP Workers" on the schema above).

This guarantees the most cost-effective solution as new WAF instances are launched automatically when they are needed but are also terminated when they are not. In addition, the administrator can define a threshold to limit the costs.

![](./attachments/CloudWatch%20Management%20Console.jpg)

## Usage

### Pre-requisites

Download and install **Terraform** 0.14 or greater on a local computer.

See https://developer.hashicorp.com/terraform/install for more information on how to install Terraform.

The examples pin the provider versions they have been tested with (for example `hashicorp/aws` 2.26, `hashicorp/azurerm` 2.46.1, `hashicorp/google` 3.46 or `outscale/outscale` 0.12.0). `terraform init` downloads those exact versions, so do not expect a recent provider release to be used unless you edit the `required_providers` block yourself.

### Where the Terraform files are

The modules and examples live in the [terraform](../../terraform) directory of this repository, split by product version:

* [terraform/6_11](../../terraform/6_11): LTS version
* [terraform/6_16](../../terraform/6_16): latest version

Each version directory has its own `modules/` and `examples/` sub-directories. **All the module and example paths given on the provider pages are relative to the version directory you picked**: `examples/aws_basic` means `terraform/6_16/examples/aws_basic` if you work with the latest version.

Note that the two versions do not offer the same providers: Outscale is only available in `6_16`.

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

After the deployment of your cluster, a scheduled task named **Remove inactive long time appliance** is created on the WAAP cluster. This task is active only if you have an autoscaled managed instance in your cluster.

To destroy the platform, run:
```
terraform destroy
```
