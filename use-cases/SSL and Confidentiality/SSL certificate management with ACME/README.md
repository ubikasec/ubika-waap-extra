SSL certificate management with ACME
====================================

* 1 [Presentation](#presentation)
* 2 [Instructions](#instructions)
    * 2.1 [Pre-requisites](#prerequisites)
    * 2.2 [Settings](#setting-environment)
    * 2.3 [Run the stack](#run-the-stack)
    * 2.4 [Certificate management](#cert-management)
        * 2.4.1 [DNS challenge](#cert-management-dns)
        * 2.4.2 [DNS-alias challenge](#cert-management-dns-alias)
* 3 [External Ressources](#external-resources)

Presentation
------------

UBIKA WAAP Gateway does not currently support ACME (Automatic Certificate Management Environment) internally.
However, it is possible to manage ACME certificates externally and deploy those certificates on the product using the API.

This use case leverages the installation of [acme.sh](https://github.com/acmesh-official/acme.sh) and a dedicated hook to deploy the certificates on the product.

Instructions
------------

### Pre-requisites

Acme.sh can be installed on Linux, MacOS X and Windows environments.
The installation instructions can be found in [the official documentation](https://github.com/acmesh-official/acme.sh/wiki/How-to-install).

According to [this documentation](https://github.com/acmesh-official/acme.sh/wiki/Run-acme.sh-in-docker), acme.sh is also available as a Docker image.

This use case can be deployed using either the standalone or docker version of acme.sh, but for ease of deployment, **we will cover the Docker deployment only**, using a docker compose stack.

In order to get a certificate from the Certificate Authority (CA), an authentication step is required, known as an ACME challenge.
There are several types of challenges (which are supported by acme.sh), but for ease of deployment, **we will only cover the DNS based challenges (DNS and DNS-alias)**.

Make sure that the docker container is deployed on a machine that can reach the API of the WAAP.

### Settings

1. We need to create a directory which will contain the docker-compose stack and the data:

```
$ mkdir acme.sh
$ mkdir acme.sh/data
$ mkdir acme.sh/deploy
$ cd acme.sh
```

2. We need to create the file `docker-compose.yaml` which describes the stack.

The contents can be copied from [here](./attachments/docker-compose.yaml).

3. We need the acme.sh deploy hook to install the certificates on the product.

The file is available [here](./attachments/ubika_waap_gw.sh) and has to be downloaded to `./deploy/ubika_waap_gw.sh`.

4. We need a file `.env` to store the secrets needed by acme.sh:
    * Secrets related to the DNS challenge
    * Secrets related to the the WAAP for the certificates deployment

The DNS secrets depend on your DNS provider. The DNS providers supported by acme.sh and their specific configuration are available in [the official documentation](https://github.com/acmesh-official/acme.sh/wiki/dnsapi).

This is an example of the contents for OVH:

```
# WARNING: the variable contents must NOT be surrounded by quotes or double quotes.

# Application key
OVH_AK=xxxxxxxxxxxxxxxxxxxxxxx

# Application secret
OVH_AS=xxxxxxxxxxxxxxxxxxxxxxx

# Consumer key
OVH_CK=xxxxxxxxxxxxxxxxxxxxxxx
```

The secrets related to the WAAP are:

```
# WARNING: the variable contents must NOT be surrounded by quotes or double quotes.

# WAAP API URL
DEPLOY_UBIKA_WAAP_GW_API_URL=https://my.waap.gw.ip:3001/api/v1

# WAAP API Key
DEPLOY_UBIKA_WAAP_GW_API_KEY=xxxxxxxxxxxxxxxxxxxxxxx

# Do not check the certificate while connecting to the API
DEPLOY_UBIKA_WAAP_GW_INSECURE=yes

# Auto apply the certificates and reload related Tunnels
DEPLOY_UBIKA_WAAP_GW_APPLY=yes
```

For more information about the parameters related to the deploy hook, please read the hook file header.

### Run the stack

We are ready to run the docker compose stack:

```
$ docker compose up -d
```

This command runs the acme.sh image which basically just launches a crontab (scheduled task) to renew the certificates periodically (once a day).

Check that the stack is running properly:

```
$ docker compose ps
NAME      IMAGE              COMMAND              SERVICE   CREATED         STATUS         PORTS
acme.sh   neilpang/acme.sh   "/entry.sh daemon"   acme.sh   2 minutes ago   Up 2 minutes
```

### Certificate management

#### DNS challenge

Once the stack is running, type this command to issue a new certificate:

```
$ docker compose exec -it acme.sh --issue --server letsencrypt --dns dns_ovh -d "*.test.com"
```

> [!NOTE]
> If you need to specify some SAN in your certificate, you can add some more `-d fqdn.tld`.
> Please refer to the acme.sh documentation for more information about the possible options.

The newly created certificate can now be deployed on the product:

```
$ docker compose exec -it acme.sh --deploy -d *.test.com --deploy-hook ubika_waap_gw
```

> [!NOTE]
> The deploy hook will search for a certificate with the same Common Name on the product. If such a certificate exists, it will be replaced by the new one and a warm restart of the tunnels using will be issued (if the parameter `DEPLOY_UBIKA_WAAP_GW_APPLY` is set to `yes`).
> If no existing certificate matches the Common Name, a new certificate will be created in the product configuration (in this case, this certificate will have to be attached to a tunnel manually or via API).

> [!NOTE]
> Those commands should be run only once.
> Once created and deployed the first time, the certificate will then automatically be renewed and uploaded by the acme.sh crontab.

> [!NOTE]
> For troubleshooting purposes, the flag `--debug` can be added to the previous commands to get a more comprehensive output.
> The flag `--output-insecure` can also be added to see secrets/hidden output like passwords or API keys.

#### DNS-alias challenge

The DNS-alias challenge is pretty similar to DNS challenge itself, the only difference is that a another domain is used for the challenge validation. This is useful when the main domain does not support an API access or when such an access is brohibited for security reasons.

It requires two things:

* A secondary domain
* A CNAME entry in the main domain

For example, given our main domain `test.com` (which does not support API access), we will need another domain (let's say `aliasDomainForValidationOnly.com`), and a CNAME DNS entry like `_acme-challenge.test.com IN CNAME _acme-challenge.aliasDomainForValidationOnly.com.`.

Obviously, the secondary domain has to support API access and the DNS secrets to pass to acme.sh are related to this domain.

Then, the procedure is similar to the DNS challenge, we just need to generate our certificates with the following command:

```
$ docker compose exec -it acme.sh --deploy -d *.test.com --challenge-alias aliasDomainForValidationOnly.com --deploy-hook ubika_waap_gw

```
> [!NOTE]
> Please note the use of the `--challenge-alias` parameter to tell acme.sh to make the challenge on the secondary domain.
> The official documentation of the implementation of DNS-alias mode in acme.sh can be found [here](https://github.com/acmesh-official/acme.sh/wiki/DNS-alias-mode).

### Logging

The crontab logs can be displayed with this command:

```
$ docker compose logs -f
acme.sh  | [Wed Nov 20 09:13:01 UTC 2024] ===Starting cron===
acme.sh  | [Wed Nov 20 09:13:01 UTC 2024] Installing from online archive.
acme.sh  | [Wed Nov 20 09:13:01 UTC 2024] Downloading https://github.com/acmesh-official/acme.sh/archive/master.tar.gz
acme.sh  | [Wed Nov 20 09:13:02 UTC 2024] Extracting master.tar.gz
acme.sh  | [Wed Nov 20 09:13:02 UTC 2024] Using config home: /acme.sh
acme.sh  | [Wed Nov 20 09:13:02 UTC 2024] Installing to /root/.acme.sh
acme.sh  | [Wed Nov 20 09:13:02 UTC 2024] Installed to /root/.acme.sh/acme.sh
acme.sh  | [Wed Nov 20 09:13:02 UTC 2024] OK
acme.sh  | [Wed Nov 20 09:13:02 UTC 2024] Install success!
acme.sh  | [Wed Nov 20 09:13:02 UTC 2024] Upgrade successful!
acme.sh  | [Wed Nov 20 09:13:02 UTC 2024] Automatically upgraded to: 3.1.0
acme.sh  | [Wed Nov 20 09:13:02 UTC 2024] Renewing: '*.test.com'
acme.sh  | [Wed Nov 20 09:13:02 UTC 2024] Renewing using Le_API=https://acme-v02.api.letsencrypt.org/directory
acme.sh  | [Wed Nov 20 09:13:02 UTC 2024] Skipping. Next renewal time is: 2025-01-17T16:37:26Z
acme.sh  | [Wed Nov 20 09:13:02 UTC 2024] Add '--force' to force renewal.
acme.sh  | [Wed Nov 20 09:13:02 UTC 2024] Skipped *.test.com_ecc
acme.sh  | [Wed Nov 20 09:13:02 UTC 2024] ===End cron===
```

External Ressources
-------------------

* [The acme.sh official website](https://github.com/acmesh-official/acme.sh)
* [The acme.sh wiki](https://github.com/acmesh-official/acme.sh/wiki/)

