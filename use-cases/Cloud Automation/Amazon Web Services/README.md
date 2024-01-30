# Amazon Web Services

* 1 [Amazon Web Services recommendations and specific behaviours](#amazon-web-services-recommendations-and-specific-behaviours)
* 2 [Authentication in AWS](#authentication-in-aws)
* 3 [Usage](#usage)

## Amazon Web Services recommendations and specific behaviours

| :warning: Please read this carefully before running our service in production on Amazon Web Services.|
|:-----------------------------------------------------------------------------------------------------|

We recommend using a network (level 4) load balancer to allow direct TCP connections to the WAF instances.

AWS health checks (in **aws_lb_target_group**) cannot provide a **Host** HTTP header, reverse proxies must not block unknown hosts.

## Authentication in AWS

Export AWS parameters for Terraform (access and secret key for your Amazon account):

```
export TF_VAR_access_key=XXXXX
export TF_VAR_secret_key=XXXXX
```

You can also add them directly in the appropriate **main.tf** file.

For more details about the authentication of Terraform with AWS see: https://www.terraform.io/docs/providers/aws/index.html.

## Usage

Terraform modules for AWS and some examples are provided on [github.com/ubikasec/ubika-waap-extra](https://github.com/ubikasec/ubika-waap-extra/tree/master/terraform).

Modules are located in:

* **modules/aws/autoscaled**: module to deploy an autoscaled UBIKA WAAP cluster.
* **modules/aws/basic**: module to deploy a basic UBIKA WAAP cluster.
* **modules/aws/lb**: basic implementation of AWS ELB for an UBIKA WAAP cluster (basic or autoscaled).
* **modules/aws/policy**: basic implementation of autoscaling policies for an autoscaled UBIKA WAAP cluster.

Examples for AWS can be found in:

* **examples/aws_basic**: shows how we deploy a basic UBIKA WAAP cluster with an AWS ELB.
* **examples/aws_autoscaled**: shows how we deploy an autoscaled UBIKA WAAP cluster with an AWS ELB and some autoscaling policies.

In the main configuration file, **main.tf**, you can edit variables like access and secret key, AWS region and prefix of your future instances. You can also find every configuration needed to deploy your instances.

| :warning: Don't forget to edit the template to match your configuration before using it.|
|:----------------------------------------------------------------------------------------|

You will need at least to:
* have exported or added your `access_key` and `access_secret` in the `.tf` file.
* specify the `product_version` you want to use. Available versions can be found on the marketplace offers.
* specify the ssh `key_name`. It will be use to access the instance via SSH once created.
* specify a `name_prefix` for resources that will be created.
* specify a random `autoreg_admin_apiuid` to access to the product API once the instance created.

and apply your configuration to deploy your infrastructure with:
```
terraform apply
```
