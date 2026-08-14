# Google Cloud Platform

* 1 [Google Cloud Platform recommendations and specific behaviours](#google-cloud-platform-recommendations-and-specific-behaviours)
* 2 [Authentication in Google Cloud Platform](#authentication-in-google-cloud-platform)
  * 2.1 [The `credentials` variable](#the-credentials-variable)
  * 2.2 [Generating the `account.json` service account key](#generating-the-accountjson-service-account-key)
  * 2.3 [Required roles](#required-roles)
  * 2.4 [Checking your credentials](#checking-your-credentials)
  * 2.5 [Using Application Default Credentials instead](#using-application-default-credentials-instead)
* 3 [UBIKA images](#ubika-images)
* 4 [Usage](#usage)

## Recommendations and specific behaviours

| :warning: Please read this carefully before running our service in production on Google Cloud Platform.|
|:-------------------------------------------------------------------------------------------------------|

We recommend using a network (level 4) load balancer to allow direct TCP connections to the WAF instances.

Google Cloud Platform provides network load balancers with these characteristics:

* Only plain HTTP health checks are supported
* Public port and backend (WAF instances) port are the same
* The destination IP address is preserved (use routing with no NAT)

Read Google Cloud Platform network load balancers [documentation](https://cloud.google.com/load-balancing/docs/network/) for more details.

In the case where the load balancer is not using NAT, tunnels must be created in *routing* mode to listen on the load balancer public IP.

If the **Host** header is not provided in the load balancer health checks, reverse proxies must not block unknown hosts or accept the load balancer public IP as valid hostname.

Our modules and examples use [regional instance groups](https://cloud.google.com/compute/docs/instance-groups/distributing-instances-with-regional-instance-groups) to create instances across multiple zones of the same region.
These instance groups even create a distribution of instances which can lead to more instances.

An instance group cannot be empty. When the autoscaling part of our modules is enabled, there will be at least 2 PAYG (Pay as you go) instances created.

## Authentication in Google Cloud Platform

Our examples authenticate the Terraform `google` provider with a **service account key file**, as explained in the [GCP provider documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/getting_started#adding-credentials).

### The `credentials` variable

In the examples, the provider is configured like this:

```hcl
variable "credentials" { default = "account.json" }
variable "project" {}

provider "google" {
  credentials = file(var.credentials)
  project     = var.project
  region      = "us-central1"
}
```

Because of the `file()` call, `credentials` must contain the **path to a service account key file in JSON format**, *not* the JSON content itself. The default value, `account.json`, is a relative path: the file is looked up in the example directory you run `terraform` from (`examples/gcp_basic` or `examples/gcp_autoscaled`).

The `project` variable has no default and must always be provided: it is the ID of the GCP project the resources are created in.

Both variables can be set in any of the usual Terraform ways:

```
# environment variables
export TF_VAR_credentials=/absolute/path/to/account.json
export TF_VAR_project=my-gcp-project
terraform apply

# or on the command line
terraform apply -var credentials=/absolute/path/to/account.json -var project=my-gcp-project

# or in a terraform.tfvars file next to main.tf
credentials = "/absolute/path/to/account.json"
project     = "my-gcp-project"
```

You can also edit the defaults directly in the `main.tf` file.

The file the variable points to is the key file downloaded from GCP, and looks like this:

```json
{
  "type": "service_account",
  "project_id": "my-gcp-project",
  "private_key_id": "0123456789abcdef0123456789abcdef01234567",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "ubika-waap-terraform@my-gcp-project.iam.gserviceaccount.com",
  "client_id": "123456789012345678901",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/ubika-waap-terraform%40my-gcp-project.iam.gserviceaccount.com"
}
```

| :warning: This file contains a private key. Never commit it to a repository, and keep it readable by its owner only (`chmod 600 account.json`).|
|:----------------------------------------------------------------------------------------------------------------------------------------------|

### Generating the `account.json` service account key

With the [`gcloud` CLI](https://cloud.google.com/sdk/docs/install), from the example directory:

```
export PROJECT_ID=my-gcp-project
export SA_NAME=ubika-waap-terraform

gcloud config set project "$PROJECT_ID"

# the Compute Engine API must be enabled in the project
gcloud services enable compute.googleapis.com

# create the service account used by Terraform
gcloud iam service-accounts create "$SA_NAME" \
  --display-name="UBIKA WAAP Terraform"

# allow it to manage Compute Engine resources
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/compute.admin"

# generate the key file expected by the credentials variable
gcloud iam service-accounts keys create account.json \
  --iam-account="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

chmod 600 account.json
```

The same can be done from the [Google Cloud console](https://console.cloud.google.com/):

1. **IAM & Admin** > **Service Accounts** > **Create service account**.
2. Give it a name (for example `ubika-waap-terraform`) and continue.
3. Grant it the **Compute Admin** role (`roles/compute.admin`), then finish.
4. Open the service account, go to the **Keys** tab, then **Add key** > **Create new key** > **JSON**.
5. The key file is downloaded by your browser: rename it to `account.json` and move it next to the example `main.tf`, or point the `credentials` variable to its location.

### Required roles

The modules create Compute Engine resources only: networks, firewall rules, instances, instance templates, regional instance group managers, autoscalers, addresses, forwarding rules, target pools and HTTP health checks.

The `roles/compute.admin` role covers all of them. If you prefer finer-grained roles, the following set is equivalent for these examples:

* `roles/compute.instanceAdmin.v1`: instances, instance templates, instance group managers and autoscalers
* `roles/compute.networkAdmin`: networks, addresses, forwarding rules, target pools and health checks
* `roles/compute.securityAdmin`: firewall rules

The modules do not attach any service account to the created instances, so `roles/iam.serviceAccountUser` is not needed.

These roles are granted on **your own** project. The UBIKA images live in a separate project, `rohde-schwarz-cs-sas-public`, and reading them requires `roles/compute.imageUser` **on that project** for the identity Terraform authenticates as. This grant is not implied by `roles/compute.admin` on your project. Without it, the very first `terraform plan` fails on the image lookup:

```
Error: error retrieving image information: googleapi: Error 403: Required
'compute.images.get' permission for
'projects/rohde-schwarz-cs-sas-public/global/images/ubika-waap-byol-<version>', forbidden

  with module.ubikawaap.module.images.data.google_compute_image.byol,
  on ../../modules/gcp/_/images/main.tf line 7, in data "google_compute_image" "byol":
```

Note that this permission is granted to *identities*, not to projects: a service account that you have just created in your own project has no access to the image project, even if your own user account does. Ask UBIKA to grant `roles/compute.imageUser` on `rohde-schwarz-cs-sas-public` to the service account you generated the key for:

```
gcloud projects add-iam-policy-binding rohde-schwarz-cs-sas-public \
  --member="serviceAccount:ubika-waap-terraform@my-gcp-project.iam.gserviceaccount.com" \
  --role="roles/compute.imageUser"
```

You can check which identity a key file belongs to with:

```
grep client_email account.json
```

### Checking your credentials

Once the key file is generated, you can verify that it works and that the UBIKA images are reachable **as the service account** (and not merely as your own user account, which may have accesses the service account does not have):

```
gcloud auth activate-service-account --key-file=account.json

# does the identity see the image project at all?
gcloud compute images list --project=rohde-schwarz-cs-sas-public --no-standard-images

# does it see the exact image the product_version resolves to?
gcloud compute images describe ubika-waap-byol-<product_version> \
  --project=rohde-schwarz-cs-sas-public
```

If the first command fails or returns nothing, the `roles/compute.imageUser` grant described above is missing. If it succeeds but the second one reports the image as *not found*, the `product_version` value is wrong: run the first command to list the versions actually available to you.

Switch back to your own account afterwards with `gcloud config set account <your-email>`.

### Using Application Default Credentials instead

If you would rather use your own user account or the credentials of the machine Terraform runs on, remove the `credentials` line from the `provider "google"` block and rely on [Application Default Credentials](https://cloud.google.com/docs/authentication/application-default-credentials):

```
gcloud auth application-default login
export GOOGLE_PROJECT=my-gcp-project
```

Keeping `credentials = file(var.credentials)` while no key file exists makes Terraform fail with an error on the missing file, before contacting GCP.

## UBIKA images

Execute to following command to list the available images of UBIKA:

```
gcloud compute images list --project=rohde-schwarz-cs-sas-public --no-standard-images
```

## Usage

Terraform modules for Google Cloud Platform and some examples are provided on [https://github.com/ubikasec/ubika-waap-extra](https://github.com/ubikasec/ubika-waap-extra/tree/master/terraform)

Modules are located in:

* `modules/gcp/autoscaled`: module to deploy an autoscaled UBIKA WAAP cluster
* `modules/gcp/basic`: module to deploy a basic UBIKA WAAP cluster
* `modules/gcp/lb`: basic implementation of GCP network load balancer for an UBIKA WAAP cluster (basic or autoscaled)
* `modules/gcp/policy`: basic implementation of autoscaling capabilities for an autoscaled UBIKA WAAP cluster

Examples for Google Cloud Platform can be found in:

* `examples/gcp_basic`: shows how we deploy a basic UBIKA WAAP cluster with a GCP network load balancer.
* `examples/gcp_autoscaled`: shows how we deploy an autoscaled UBIKA WAAP cluster with a GCP network load balancer and some autoscaling capabilities.

In the main configuration file, `main.tf`, you can edit variables like GCP region and prefix of your future instances. You can also find every configuration needed to deploy your instances.

| :warning: Don't forget to edit the template to match your configuration before using it.|
|:----------------------------------------------------------------------------------------|

Autoscaled cluster must be set up in two phases:

* The first one, to create a basic cluster and configure it (with `autoscaled_clone_source` set to an empty string and autoscaling policy `max_size` set to 0).
* The second, to add the autoscaling part based on the configuration of the basic cluster (with `autoscaled_clone_source` set to a managed box name and autoscaling policy `max_size` greater than 0).
