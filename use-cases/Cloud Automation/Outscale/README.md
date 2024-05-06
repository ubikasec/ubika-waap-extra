# Outscale

* 1 [Authentication on Outscale](#authentication-in-outscale)
* 2 [Usage](#usage)

The Terraform modules for Oustscale are based on the AWS provider. 

## Authentication in Outscale

Add your `access_key_id` and `secret_key_id` in the `main.tf` script. Access keys can be found in the outscale profile menu "Access Keys".

For more details about the authentication of Terraform, see: https://www.terraform.io/docs/providers/aws/index.html.

## Usage

Terraform modules for Outscale and an example are provided on [github.com/ubikasec/ubika-waap-extra](https://github.com/ubikasec/ubika-waap-extra/tree/master/terraform).

Modules are located in:

* **modules/outscale/basic**: module to deploy a basic UBIKA WAAP cluster.
* **modules/outscale/lb**: basic implementation of Outscale Load Balancer for an UBIKA WAAP cluster.

Example for Outscale can be found in **examples/outscale_basic**. It shows how we deploy a basic UBIKA WAAP cluster with an Load Balancer.

In the main configuration file, **main.tf**, you can edit variables like access and secret key, Outscale region (eu-west-2, cloudgouv-eu-west-1) and prefix of your future instances. You can also find every configuration needed to deploy your instances.

| :warning: Don't forget to edit the template to match your configuration before using it.|
|:----------------------------------------------------------------------------------------|

You will need at least to:
* have added your `access_key_id` and `secret_key_id` in the `.tf` file.
* specify the ssh `keypair_name`. It will be use to access the instance via SSH once created.
* specify the `product_version` you want to use. Available versions can be found on the marketplace offers.
* specify a `name_prefix` for resources that will be created.
* specify a random `autoreg_admin_apiuid` to access to the product API once the instance created.
* specify a the license mode in `management_mode` and `managed_mode`: `byol` or `payg`. For `payg`, you must subscribe to the offer to access to Outscale image.

Then, test your configuration:
```
terraform plan
```

At last, deploy your infrastructure with:
```
terraform apply
```

Go to the Cockpit interface. You should now see new instances. Don't forget to add an Inbound rule on the Security Group to allow the access to the public IP.
