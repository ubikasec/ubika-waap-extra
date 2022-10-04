Google Cloud Platform
=====================

* 1 [Google Cloud Platform recommendations and specific behaviours](#google-cloud-platform-recommendations-and-specific-behaviours)
* 2 [Authentication in Google Cloud Platform](#authentication-in-google-cloud-platform)
* 3 [Usage](#usage)

Google Cloud Platform recommendations and specific behaviours
-------------------------------------------------------------

| :warning: Please read this carefully before running our service in production on Google Cloud Platform.|
|:-------------------------------------------------------------------------------------------------------|

We recommend using a network (level 4) load balancer to allow direct TCP connections to the WAF instances.

Google Cloud Platform provides network load balancers with these characteristics:

* Only plain HTTP health checks are supported
* Public port and backend (WAF instances) port are the same
* The destination IP address is preserved (use routing with no NAT)

Read Google Cloud Platform network load balancers [documentation](https://cloud.google.com/load-balancing/docs/network/) for more details.

Tunnels must be created in **routing** mode to listen on the load balancer public IP.

If the **Host** header is not provided in the load balancer health checks, reverse proxies must not block unknown hosts or accept the load balancer public IP as valid hostname.

Our modules and examples use [regional instance groups](https://cloud.google.com/compute/docs/instance-groups/distributing-instances-with-regional-instance-groups) to create instances across multiple zones of the same region.
These instance groups even create a distribution of instances which can lead to more instances.

An instance group cannot be empty. When the autoscaling part of our modules is enabled, there will be at least 2 PAYG (Pay as you go) instances created.

Authentication in Google Cloud Platform
---------------------------------------

Setup an authentication strategy like explained here: https://www.terraform.io/docs/providers/google/guides/getting_started.html#adding-credentials

Usage
-----

Terraform modules for Google Cloud Platform and some examples are provided on [https://github.com/ubikasec/ubika-waap-extra](https://github.com/ubikasec/ubika-waap-extra/tree/master/terraform)

Modules are located in:

* **modules/gcp/autoscaled**: module to deploy an autoscaled UBIKA WAAP cluster
* **modules/gcp/basic**: module to deploy a basic UBIKA WAAP cluster
* **modules/gcp/lb**: basic implementation of GCP network load balancer for an UBIKA WAAP cluster (basic or autoscaled)
* **modules/gcp/policy**: basic implementation of autoscaling capabilities for an autoscaled UBIKA WAAP cluster

Examples for Google Cloud Platform can be found in:

* **examples/gcp_basic**: shows how we deploy a basic UBIKA WAAP cluster with a GCP network load balancer.
* **examples/gcp_autoscaled**: shows how we deploy an autoscaled UBIKA WAAP cluster with a GCP network load balancer and some autoscaling capabilities.

In the main configuration file, **main.tf**, you can edit variables like GCP region and prefix of your future instances. You can also find every configuration needed to deploy your instances.

| :warning: Don't forget to edit the template to match your configuration before using it.|
|:----------------------------------------------------------------------------------------|

Autoscaled cluster must be set up in two phases:

* The first one, to create a basic cluster and configure it (with **autoscaled_clone_source** set to an empty string and autoscaling policy **max_size** set to 0).
* The second, to add the autoscaling part based on the configuration of the basic cluster (with **autoscaled_clone_source** set to a managed box name and autoscaling policy **max_size** greater than 0).
