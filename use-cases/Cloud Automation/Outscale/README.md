# Outscale

* 1 [Authentication in Outscale](#authentication-in-outscale)
* 2 [UBIKA images](#ubika-images)
* 3 [Usage](#usage)

The Terraform modules for Outscale use the [Outscale provider](https://registry.terraform.io/providers/outscale/outscale/latest/docs) (`outscale/outscale`). They are only available for the latest product version (`terraform/6_16`).

## Authentication in Outscale

Add your `access_key_id` and `secret_key_id` in the `main.tf` script. Access keys can be found in the outscale profile menu "Access Keys".

They can also be passed as Terraform variables, without editing the script:

```
export TF_VAR_access_key_id=XXXXX
export TF_VAR_secret_key_id=XXXXX
```

| :warning: These keys are credentials. If you write them in a `.tf` file, never commit that file to a repository.|
|:---------------------------------------------------------------------------------------------------------------|

For more details about the authentication of Terraform with Outscale, see: https://registry.terraform.io/providers/outscale/outscale/latest/docs.

## UBIKA images

The images are published on the Outscale marketplace. They can be browsed from the Cockpit interface, in the images catalog, and are named after this convention:

```
UBIKA-WAAP-byol-<version with dashes>-MKP*
UBIKA-WAAP-payg-<version with dashes>-MKP*
```

The `product_version` variable is the dotted form of that version: the image `UBIKA-WAAP-byol-6-16-3-MKP...` corresponds to `product_version = "6.16.3"`.

With [osc-cli](https://github.com/outscale/osc-cli) configured, the same list can be obtained with:

```
osc-cli api ReadImages --Filters '{"ImageNames": ["UBIKA-WAAP-*"]}'
```

## Usage

Terraform modules for Outscale and an example are provided on [github.com/ubikasec/ubika-waap-extra](https://github.com/ubikasec/ubika-waap-extra/tree/main/terraform).

The `terraform` directory is split by product version; the paths below are relative to `terraform/6_16`, as explained in [Cloud Automation](..).

Modules are located in:

* **modules/outscale/basic**: module to deploy a basic UBIKA WAAP cluster.
* **modules/outscale/lb**: basic implementation of Outscale Load Balancer for a UBIKA WAAP cluster.

Example for Outscale can be found in **examples/outscale_basic**. It shows how we deploy a basic UBIKA WAAP cluster with a Load Balancer.

In the main configuration file, **main.tf**, you can edit variables like access and secret key, Outscale region (eu-west-2, cloudgouv-eu-west-1) and prefix of your future instances. You can also find every configuration needed to deploy your instances.

| :warning: Don't forget to edit the template to match your configuration before using it.|
|:----------------------------------------------------------------------------------------|

You will need at least to:
* have exported or added your `access_key_id` and `secret_key_id` in the `.tf` file.
* specify the ssh `keypair_name`. It will be used to access the instance via SSH once created.
* specify the `product_version` you want to use. Available versions can be listed as explained in [UBIKA images](#ubika-images).
* specify a `name_prefix` for resources that will be created.
* specify a random `autoreg_admin_apiuid` to access to the product API once the instance created.
* specify the license mode in `management_mode` and `managed_mode`: `byol` or `payg`. For `payg`, you must subscribe to the offer to access to Outscale image.

Then, test your configuration:
```
terraform plan
```

At last, deploy your infrastructure with:
```
terraform apply
```

Go to the Cockpit interface. You should now see new instances. Don't forget to add an Inbound rule on the Security Group to allow the access to the public IP.
