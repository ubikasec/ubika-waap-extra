# Amazon Web Services

* 1 [Amazon Web Services recommendations and specific behaviours](#amazon-web-services-recommendations-and-specific-behaviours)
* 2 [Authentication in AWS](#authentication-in-aws)
* 3 [UBIKA images](#ubika-images)
* 4 [Usage](#usage)
  * 4.1 [Autoscaled cluster](#autoscaled-cluster)

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

| :warning: These keys are credentials. If you write them in a `.tf` file, never commit that file to a repository.|
|:---------------------------------------------------------------------------------------------------------------|

For more details about the authentication of Terraform with AWS see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication-and-configuration.

## UBIKA images

The AMIs are published on the AWS Marketplace. Execute the following command to list the images available to you in the region your AWS CLI is configured for:

```
aws ec2 describe-images --owners aws-marketplace \
  --filters "Name=name,Values=ubika-waap-*" \
  --query "sort_by(Images, &Name)[].Name" --output table
```

The `product_version` variable is the dotted form of the version found in those names: the AMI `ubika-waap-byol-6-16-3-<id>` corresponds to `product_version = "6.16.3"`.

## Usage

Terraform modules for AWS and some examples are provided on [github.com/ubikasec/ubika-waap-extra](https://github.com/ubikasec/ubika-waap-extra/tree/main/terraform).

The `terraform` directory is split by product version (`6_11` for the LTS, `6_16` for the latest); the paths below are relative to the version directory you picked, as explained in [Cloud Automation](..).

Modules are located in:

* **modules/aws/autoscaled**: module to deploy an autoscaled UBIKA WAAP cluster.
* **modules/aws/basic**: module to deploy a basic UBIKA WAAP cluster.
* **modules/aws/lb**: basic implementation of AWS ELB for a UBIKA WAAP cluster (basic or autoscaled).
* **modules/aws/policy**: basic implementation of autoscaling policies for an autoscaled UBIKA WAAP cluster.

Examples for AWS can be found in:

* **examples/aws_basic**: shows how we deploy a basic UBIKA WAAP cluster with an AWS ELB.
* **examples/aws_autoscaled**: shows how we deploy an autoscaled UBIKA WAAP cluster with an AWS ELB and some autoscaling policies.

In the main configuration file, **main.tf**, you can edit variables like access and secret key, AWS region and prefix of your future instances. You can also find every configuration needed to deploy your instances.

| :warning: Don't forget to edit the template to match your configuration before using it.|
|:----------------------------------------------------------------------------------------|

You will need at least to:
* have exported or added your `access_key` and `secret_key` in the `.tf` file.
* specify the `product_version` you want to use. Available versions can be listed as explained in [UBIKA images](#ubika-images).
* specify the ssh `key_name`. It will be used to access the instance via SSH once created.
* specify a `name_prefix` for resources that will be created.
* specify a random `autoreg_admin_apiuid` to access to the product API once the instance created.

Then, test your configuration:
```
terraform plan
```

At last, deploy your infrastructure with:
```
terraform apply
```

### Autoscaled cluster

On AWS the whole cluster is deployed in a single `terraform apply`. The `autoscaled_clone_source` variable names the managed instance that autoscaled instances clone at boot: in the example it is `managed_0`, one of the managed instances created by the same apply. Unlike on [Google Cloud Platform](../Google%20Cloud%20Platform), no two-phase bootstrap is required, because the AWS autoscaling group can stay empty until the policies scale it out.

That managed instance must be up and registered on the management instance before the group scales out, otherwise the autoscaled instances have nothing to clone.
