# Microsoft Azure

* 1 [Microsoft Azure recommendations and specific behaviours](#microsoft-azure-recommendations-and-specific-behaviours)
* 2 [Authentication in Azure](#authentication-in-azure)
* 3 [UBIKA images](#ubika-images)
* 4 [Usage](#usage)
  * 4.1 [Autoscaled cluster](#autoscaled-cluster)
* 5 [Enable programmatic deployments of our products](#enable-programmatic-deployments-of-our-products)
* 6 [Azure marketplace agreements](#azure-marketplace-agreements)

## Microsoft Azure recommendations and specific behaviours

| :warning: Please read this carefully before running our service in production on Microsoft Azure.|
|:-------------------------------------------------------------------------------------------------|

We recommend using a network (level 4) load balancer to allow direct TCP connections to the WAF instances.

Azure health checks (**azurerm_lb_probe**) cannot provide a **Host** HTTP header, reverse proxies must not block unknown hosts.

## Authentication in Azure

Setup an authentication strategy like explained here: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs#authenticating-to-azure.

## UBIKA images

Execute the following command to list the available images of UBIKA:
```
az vm image list --publisher UBIKA --all --output table
```

The `product_version` variable is the dotted image version found in that listing, for example `product_version = "6.16.3"`.

## Usage

Terraform modules for Microsoft Azure and some examples are provided on [github.com/ubikasec/ubika-waap-extra](https://github.com/ubikasec/ubika-waap-extra/tree/main/terraform)

The `terraform` directory is split by product version (`6_11` for the LTS, `6_16` for the latest); the paths below are relative to the version directory you picked, as explained in [Cloud Automation](..).

Modules are located in:

* **modules/azure/autoscaled**: Module to deploy an autoscaled UBIKA WAAP cluster.
* **modules/azure/basic**: Module to deploy a basic UBIKA WAAP cluster.
* **modules/azure/lb**: Basic implementation of Azure Loadbalancer for a UBIKA WAAP cluster (basic or autoscaled).
* **modules/azure/policy**: Basic implementation of autoscaling policies for an autoscaled UBIKA WAAP cluster.

Examples for Azure can be found in:

* **examples/azure_basic**: shows how we deploy a basic UBIKA WAAP cluster with an Azure loadbalancer.
* **examples/azure_autoscaled**: shows how we deploy an autoscaled UBIKA WAAP cluster with an Azure loadbalancer and some autoscaling capabilities.

In the main configuration file, **main.tf**, you can edit variables like Azure region and prefix of your future instances. You can also find every configuration needed to deploy your instances.

| :warning: Don't forget to edit the template to match your configuration before using it.|
|:----------------------------------------------------------------------------------------|

You will need at least to:
* specify the `product_version` you want to use. Available versions can be listed as explained in [UBIKA images](#ubika-images).
* specify the `ssh_key_data`. It will be used to access the instance via SSH once created.
* specify a `name_prefix` for resources that will be created.
* specify a random `autoreg_admin_apiuid` to access to the product API once the instance created.
* accept the marketplace legal terms, see: [Enable programmatic deployments of our products](#enable-programmatic-deployments-of-our-products) and [Azure marketplace agreements](#azure-marketplace-agreements).

Then, test your configuration:
```
terraform plan
```

At last, deploy your infrastructure with:
```
terraform apply
```

### Autoscaled cluster

On Azure the whole cluster is deployed in a single `terraform apply`. The `autoscaled_clone_source` variable names the managed instance that autoscaled instances clone at boot: in the example it is `managed_0`, one of the managed instances created by the same apply. Unlike on [Google Cloud Platform](../Google%20Cloud%20Platform), no two-phase bootstrap is required, because the scale set is created with a capacity of 0 and only grows when the autoscaling policy triggers.

That managed instance must be up and registered on the management instance before the scale set grows, otherwise the autoscaled instances have nothing to clone.

## Enable programmatic deployments of our products

In Microsoft Azure Portal, go to the Marketplace and search **UBIKA WAAP - Enterprise Edition**.

Select the software plan **Web Application Firewall Enterprise Edition (BYOL)**, and click on **Want to deploy programmatically? Get started**.

![](./attachments/Marketplace_product.png)

Then, select **enable** for your subscription, and **Save**.

![](./attachments/Enable_programmatic_deployments.png)

Do the same operations with the software plan **Web Application Firewall Enterprise Edition (PAYG)**.

## Azure marketplace agreements

If you have an error like the following while applying a `.tf` script to deploy on Azure:

```
│ Error: A resource with the ID "/subscriptions/<subscription_id>/providers/Microsoft.MarketplaceOrdering/agreements/ubika/offers/<offer>/plans/<plan>" already exists - to be managed via Terraform this resource needs to be imported into the State. Please see the resource documentation for "azurerm_marketplace_agreement" for more information.
│   with module.ubikawaap.module.image.azurerm_marketplace_agreement.waf_byol,
│   on ../../modules/azure/_/image/main.tf line 21, in resource "azurerm_marketplace_agreement" "waf_byol":
│   21: resource "azurerm_marketplace_agreement" "waf_byol" {

│ Error: A resource with the ID "/subscriptions/<subscription_id>/providers/Microsoft.MarketplaceOrdering/agreements/ubika/offers/<offer>/plans/<plan>" already exists - to be managed via Terraform this resource needs to be imported into the State. Please see the resource documentation for "azurerm_marketplace_agreement" for more information.
│   with module.ubikawaap.module.image.azurerm_marketplace_agreement.waf_payg,
|   on ../../modules/azure/_/image/main.tf line 26, in resource "azurerm_marketplace_agreement" "waf_payg":
│   26: resource "azurerm_marketplace_agreement" "waf_payg" {
```

It means the marketplace agreement for that offer/plan was already accepted (e.g. from a previous deployment, or manually in the Portal), but Terraform doesn't know about it yet: you need to import it into the state instead of trying to recreate it.

| :warning: The `offer` and `plan` names depend on the `product_version` you deploy (they change over time, e.g. `ubika-waap-cloud-6-16-2025`/`ubika-byol` vs. the older `ubika-waap-cloud`/`6-lts-byol`). Always copy the exact resource ID from **your own error message** rather than reusing an example from this README.|
|:----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|

To fix it, run `terraform import` for both resources, using the exact module address and ID given in your error message:

```
terraform import module.ubikawaap.module.image.azurerm_marketplace_agreement.waf_byol "<id from the error message above>"
terraform import module.ubikawaap.module.image.azurerm_marketplace_agreement.waf_payg "<id from the error message above>"
```

For example, with the first error above:

```
terraform import module.ubikawaap.module.image.azurerm_marketplace_agreement.waf_byol "/subscriptions/<subscription_id>/providers/Microsoft.MarketplaceOrdering/agreements/ubika/offers/<offer>/plans/<plan>"
```

Then make sure the legal terms are accepted for the images you'll deploy (use the `offer`, `plan` and `image_version` from your module, or list them with `az vm image list --publisher UBIKA --all --output table`):

```
az vm image terms accept --urn ubika:<offer>:<plan>:<image_version>
```

You can now run `terraform plan`/`terraform apply` again.

For more details, see the Azure documentation:
* https://learn.microsoft.com/en-us/marketplace/programmatic-deploy-of-marketplace-products#deploy-vm-from-azure-marketplace-using-terraform
* https://learn.microsoft.com/en-us/cli/azure/vm/image?view=azure-cli-latest#az-vm-image-accept-terms
