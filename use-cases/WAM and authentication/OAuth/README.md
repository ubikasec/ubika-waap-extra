# OAuth

> **Note**: This use case is provided "AS IS", there is no official support by the UBIKA team. Use cases may not work on new versions due to behavior changes. In case of custom deployment, we invite you to contact our Customer Service team at https://my.ubikasec.com/.

For the integration or any need of improvements, please contact our Service team.

## Introduction

The OAuth pack will help you to integrate modern way of authentication, particularly on modern web applications and mobile applications and also to make OAuth-aware an application that natively doesn’t support OAuth.

Use cases:

* Implement an Authorisation Server
* Implement a Ressource Server
* Delegate Authentication to GoogleConnect, O365/AzureAD, France Connect, ECPS etc 

The various OAuth use cases make use of workflows that are available in the backup files below: [OAuth-Pack-v2.8.3.backup](./OAuth-Pack-v2.8.3.backup) (principal, contains the necessary elements), [OAuth-Pack-2.8.3-Complementary.backup](./OAuth-Pack-2.8.3-Complementary.backup) (contains the complementary/additional elements) and [OAuth-Pack-2.8.3-Tunnels.backup](./OAuth-Pack-2.8.3-Tunnels.backup) (contains the tunnels configuration).

⚠️ The previous [OAuth-Pack-v2.6.backup](./OAuth-Pack-v2.6.backup) is kept for archive purposes only.

In all cases, an Extended API security license is required. In certain implementations, the WAM license is also required.

## What is OAuth?

OAuth 2.0 is the industry-standard protocol for authorization. OAuth 2.0 focuses on client developer simplicity while providing specific authorization flows for web applications, desktop applications, mobile phones, and living room devices. This specification and its extensions are being developed within the IETF OAuth Working Group : [https://datatracker.ietf.org/doc/html/rfc6749](https://datatracker.ietf.org/doc/html/rfc6749) 

Three server role :

1. A Resource Server
    A Resource Server performs **ONE** operation:
   * It receives the API call + authorization token, check the token signature, expiration, scope (right) and then lets the user pass

2. An Authorization Server
    An Authorization Server does several operations:
   * It receives the initial Authn&Request, initiates the session, then displays/redirect to an authentication form
   * Based on the authentication, he authorize the user and generates a token/code (depending of the grant-type)
   * It can exposes additional endpoints (/token, /introspec, /jwk, etc.)

3. An Authentication Server
   * The Authentication Server is in charge of authenticating the user ;

Proof of authentication: JWT token

Several use-case: Native-app (on mobile device), Modern Web-app (like SPA : Single Page Application)

## Pre-requisite

At least UBIKA-WAAP 6.5.6 required ;

Full Enterprise licence including EAS & WAM ;

8 tunnels (the management console can be included to the auth tunnel to remove 1 tunnel)

Add the following host information to your system to test the OAuth pack (`C:\\Windows\\System32\\drivers\\etc\\hosts` or `/etc/hosts`)

```
#OAuth Pack
[YourTunnelIP] [rs.u-lab.io](http://rs.u-lab.io) # ressource server
[YourTunnelIP] [as.u-lab.io](http://as.u-lab.io) # authorization server
[YourTunnelIP] [auth.u-lab.io](http://auth.u-lab.io) # authentication url
[YourTunnelIP] [mfa.u-lab.io](http://mfa.u-lab.io) # alias of [auth.u-lab.io](http://auth.u-lab.io) to have another authentication-url
[YourTunnelIP] [oauth-console.u-lab.io](http://oauth-console.u-lab.io) #management console for oauth client token
[YourTunnelIP] [oauth-client.u-lab.io](http://oauth-client.u-lab.io) #oauth test client
[YourTunnelIP] [portal.rs.u-lab.io](http://portal.rs.u-lab.io) #WAM OAuth integration testing sample pack
[YourTunnelIP] [app1-wam.u-lab.io](http://app1-wam.u-lab.io) # WAM OAuth integration testing sample pack
[YourTunnelIP] [app2-wam.u-lab.io#](http://app2-wam.u-lab.io) WAM OAuth integration testing sample pack
```

* [oauth-client.u-lab.io](http://oauth-client.u-lab.io): this is the « OAuth client test » 
* [rs.u-lab.io](http://rs.u-lab.io): this is « Oauth Ressource Server » 
* [as.u-lab.io](http://as.u-lab.io): this is the « OAuth Authorization Server », which enable the authorize and the token endpoint ; 
* [auth.u-lab.io](http://auth.u-lab.io): this is the « OAuth Authentication Server », basically it’s the WAM that handle the authentication, then there is a small OAuth logic added 
* [oauth-console.u-lab.io](http://oauth-console.u-lab.io): this is the « OAuth Management console » that allow you to create/revoke client and token (this one can be merged with the auth tunnel)
* [portal.rs.u-lab.io](http://portal.rs.u-lab.io): This is the « OAuth Portal Ressource Server » that allow you to implement WAM using OAuth delegation 
* [app1-wam.u-lab.io](http://app1-wam.u-lab.io) and [app2-wam.u-lab.io](http://app2-wam.u-lab.io): This is the sample app provided to test the WAM OAuth delegation

Note: the names of the various tunnels above are given as an example, you will need to rename them according to your client's needs.

## Installation

⚠️ Warning: backup all your configuration before proceeding

The OAuth pack is very quick to deploy and mostly configurable using the workflow parameter

⚠️ Warning: the content of the internal user-repository will be deleted and replaced by the OAuth Pack

1. You need to import the backup « OAuth-pack » to your UBIKA-WAAP

2. Activate the option to “handle distributed datastore” on your WAAP (Setup > Box > Modify > Advanced)

3. If needed, import the complementary backup packs, in this order: [OAuth-Pack-2.8.3-Complementary.backup](./OAuth-Pack-2.8.3-Complementary.backup), then [OAuth-Pack-2.8.3-Tunnels.backup](./OAuth-Pack-2.8.3-Tunnels.backup)

4. Adjust the configuration (tunnel names and parameters, IP or VIP addresses, WAM, certificates) according to your needs

5. Apply-all the configurations

Then you will need to go to this url to initialize the demo-client: [https://oauth-console.u-lab.io/oauth/management/client/reset](http://oauth-console.u-lab.io/oauth/management/client/reset)

Admin account is `admin`/`admin`

## Usage

You can begin the test by going to the client (button « Do authorize » is to initiale the OAuth sequence, it’s the equivalent to the button facebook login, google connect etc) : [http://oauth-client.u-lab.io/](http://oauth-client.u-lab.io/)

Then, you have the three use-cases:

1. Webapp (Impicit grant) : The user is on a browser and access to a OAuth aware web app :
   * Browser enable 302 redirection, the authorization sequence is done using redirection (http/302) ;

2. NativeApp (Authorisation code grant): The user is on a mobile/modern webapp :
   * We are on a rich client, so we are doing API CALL, there is no redirection, the client must implement the orchestration (it can be time-consuming and non scalable/evolutive ..) ;
   * We can open the web-browser and go to the Authorization-Server, once we are authorized we go back to the native app with a redirect-uri=[myapp://callback#code=32423523](myapp://callback#code=32423523) that open back the native-app ;

3. Machine to Machine or Rich client with internal authentication form (Ressource Owner Password Credentials grant): 
   * This grant type is used by clients to obtain an access token outside of the context of a user ;
   * This is typically used by clients to access resources about themselves rather than to access a user's resources ;

You can see a lot of text-field, these are parameter for the authorization-server, these field are offered as a demo purpose, it must be unique to your implementation ;

Account: `demo`/`demo`

### OAuth Console

You can configure the OAuth pack by going to the Management Console using the tunnel: 

[https://oauth-console.u-lab.io](http://oauth-console.u-lab.io/oauth/management/client/reset)

Default account is admin/admin, you must changed the password associated with the admin account in the WAM by going the the GUI, Policies tab and then WAM section and Internal store, you can now set a new password for the admin account : 

Or you can access the same console on the authentication url if you activated the following parameter on the Authentication Server tunnel

The management console will help you to configure:

* Client (application that are authorized to connect to the autorisation server) ;
* Authentication delegation (possibility to delegate authentication to a Third-party (Google, O365, France Connect) ;
* Token (visualize and revoke token) ;

### OAuth Console Client management

You can configure the OAuth Client in the "Client Management" section of the OAuth Console [https://oauth-console.u-lab.io](http://oauth-console.u-lab.io/oauth/management/client/reset) :

You can list the client authorized to connect to the autorisation server and also revoke old client :

You can also create a new client, you will need to fulfill the following information :

⚠️ WARNING: Be aware that when a client try to authorize itself, the autorisation server will check the following.

* `client_id` (secret is only required for the token endpoint) ;
* callback (the landing page must be the same that is declared) ;
* Scope ;
* And the grant-type ;

### OAuth Console Token management

You can configure the OAuth Token in the "Token Management" section of the OAuth Console [https://oauth-console.u-lab.io](http://oauth-console.u-lab.io/oauth/management/client/reset) :

You can list the token that has been delivered by the autorisation server and also revoke a token :

You can also revoke all the token issued by the autorisation server  by going to the [https://oauth-console.u-lab.io/oauth/management/t](https://oauth-console.u-lab.io/oauth/management/session)oken/reset endpoint 

### OAuth Console SSO Session management

You can check the current SSO Session in the OAuth SSO Session in the "Client Management" section of the OAuth Console [https://oauth-console.u-lab.io](http://oauth-console.u-lab.io/oauth/management/client/reset) :

You can list the SSO Session that has been created on the WAM and also revoke a session  :

You can also revoke all the SSO Session issued by the autorisation server by going to the [https://oauth-console.u-lab.io/oauth/management/session](https://oauth-console.u-lab.io/oauth/management/session)/reset endpoint 

### Customize the OAuth Ressource Server

You can configure the OAuth Ressource Server by going to the workflow parameter of the tunnel in the GUI :

The workflow parameters will help you to configure :

* The type of ressource server (API, WebApp ou WAM) ;
* The authorization server to redirect when the user don't have an access-token or a SSO Session ;
* JWT validations options ;
* Log options ;
* WAAP Options like blocking-mode, XML & JSON Security and exception profile ;
* Enhanced validations of Access-token using the Authorization Server to check if the token is not revoked by administrator ;

### Customize the OAuth WAM Ressource Server

In order to test the new WAM integration with OAuth, you need to change the IP Address of the backend in the "sample-app" configuration :

And then you can test directly on the [https://oauth-client.u-lab.io/](https://oauth-client.u-lab.io/) url

### OAuth Console Authentication Delegation (OpenID Connect integration)

In order to improve the OAuth pack, we offer the possibility to integrate with some third-party identity provider, this functionnality will allow your users to use they’re third-party account to authenticate to a WAAP protected application

*   Google connect 
*   Office 365 connect / Azure AD Connect
*   France Connect 
*   ECPS  
*   Keycloak
*   Ping (PingFederate)
*   Custom to implent any Identity Provider compatible with OpenIDConnect

*   A multi-option authentication screen will allow the user to choose how he want to authenticate using a list of Authentication Server:

This is the sequence diagram used in the OpenID Connect Delegation use-case

The customer can configure the delegation using the Management Console using the tunnel : [https://oauth-console.u-lab.io](http://oauth-console.u-lab.io/oauth/management/client/reset) and select the delegation he want to modify :

### Google Connect

To create the google credentials, you need to go to this url : [https://console.developers.google.com/](https://console.developers.google.com/)

*   A tutorial to create google credentials is available here :

[https://www.intricatecloud.io/2019/07/adding-google-sign-in-to-your-webapp-pt-1/](https://www.intricatecloud.io/2019/07/adding-google-sign-in-to-your-webapp-pt-1/)

*   The full documentation is available here (Server side web apps)

[https://developers.google.com/identity/protocols/oauth2/web-server](https://developers.google.com/identity/protocols/oauth2/web-server)

*   You can now use your own client credentials that you have created on google developpers
*   Client ID & secret, redirect url and authentication-server
*   [https://console.developers.google.com/](https://console.developers.google.com/)

MFA: you can use Google MFA with mobile notification.

### O365 (Azure AD Connect)

To create the o365 application credentials for OpenIDConnect, you need to go to this url :

[https://portal.azure.com/#blade/Microsoft\_AAD\_IAM/ActiveDirectoryMenuBlade/RegisteredApps](https://portal.azure.com/)

The full documentation is available here :

[https://docs.microsoft.com/fr-fr/azure/active-directory/develop/](https://docs.microsoft.com/fr-fr/azure/active-directory/develop/v2-protocols-oidc)[v2-protocols-oidc](https://docs.microsoft.com/fr-fr/azure/active-directory/develop/v2-protocols-oidc)

*   You can now use your own client credentials that you have created on o365 developpers
*   Client ID & secret, redirect url and authentication-server

MFA : you can use MFA (SMS, call, and Microsoft Authenticator) by activating the option on your account.

### France Connect

To create the France Connect application credentials for OpenIDConnect, you need to go to this url :

[https://partenaires.franceconnect.gouv.fr/fcp/fournisseur-service](https://partenaires.franceconnect.gouv.fr/fcp/fournisseur-service)

*   You can now use your own client credentials that you have created from the France Connect developpers website
*   Client ID & secret, redirect url and authentication-server

Also FranceConnect does not send the email as an identifier, but instead a UUID supposed to represent the user anonymously in the attribute sub.  
You need to instructs the application to be able to mount the authentication context on this UUID or used the user-info endpoint to retrieve additionnal information (but sensitive) detailed in this link (données usager):

[https://partenaires.franceconnect.gouv.fr/fcp/fournisseur-service](https://partenaires.franceconnect.gouv.fr/fcp/fournisseur-service)

### ECPS

To create the ECPS application credentials for OpenIDConnect, you need to go to this url :

[https://api.gouv.fr/](https://api.gouv.fr/)

To register an access to ProSantéConnect [https://tech.esante.gouv.fr/](https://tech.esante.gouv.fr/)

*   You can now use your own client credentials that you have created from the ECPS developpers website
*   Client ID & secret, redirect url and authentication-server

Also FranceConnect does not send the email as an identifier, but instead a UUID supposed to represent the user anonymously in the attribute sub.  
You need to instructs the application to be able to mount the authentication context on this UUID or used the user-info endpoint to retrieve additionnal information (but sensitive) detailed in this link (données usager):

[https://partenaires.franceconnect.gouv.fr/fcp/fournisseur-service](https://partenaires.franceconnect.gouv.fr/fcp/fournisseur-service)

### Keycloak

To configure Keycloak as an OpenIDConnect delegation provider, you need to go to this url :

[https://www.keycloak.org/securing-apps/oauth-identity-authorization-chaining-across-domains](https://www.keycloak.org/securing-apps/oauth-identity-authorization-chaining-across-domains)

*   You can now use your own client credentials that you have created on your Keycloak realm
*   Client ID & secret, redirect url and authentication-server

### Ping

To configure Ping (PingFederate) as an OpenIDConnect delegation provider, you need to go to this url :

[https://docs.pingidentity.com/pingfederate/13.1/administrators_reference_guide/pf_configuring_oauth_clients.html](https://docs.pingidentity.com/pingfederate/13.1/administrators_reference_guide/pf_configuring_oauth_clients.html)

*   You can now use your own client credentials that you have created on your PingFederate OAuth client
*   Client ID & secret, redirect url and authentication-server

### Custom delegation

This one is to allow you to connect to every Identity Provider compatible with OpenIDConnect.

### Retrieve additionnal User Information

We implement the access to the user-information endpoint in order to retrieve the user attributes provided by the delegation, in order to use this functionnality, you need to declare the UserInfo Endpoint on the delegation configuration and to define the attribute you want to retrieve.

You can find the UserInfo attribute by going to the SSO Session :

And then click on Show UserInfo :

You can retrieve every data in the UserInfo payload, this is an exemple of complex attribute retrieving :

```
SubjectRefPro/exercices/0/activities/0/raisonSocialeSite
{
    "Secteur\_Activite": "SA01^1.2.250.1.71.4.2.4",
    "SubjectRefPro": {
        "codeCivilite": "MME",
        "exercices": \[
            {
                "codeProfession": "",
                "activities": \[
                    {
                        "codeModeExercice": "S",
                        "raisonSocialeSite": "HOPITAL GENERIQUE  FIN VARI",
                        "enseigneCommercialeSite": "",
                        "autoriteDenregistrement": ""
                    }
                \]
            }
        \]
    }
    \],
    "PSI\_Locale": "1.2.250.1.213.1.3.1.1",
    "SubjectNameID": "30B0168811/CPET00001",
}
```

### Implement global logout

You can also implement global logout in order to disconnect the Delegation session and the Local WAAP session, in order to use this functionnality, you need to declare the « Local logout url » and the « Provider logout url » :

When the « Provider logout URL » is defined, the following logout sequence will be activated :

## OAuth use-cases

### Authorization code use-case

This is the authorization code grant required parameter to initialize the OAuth sequence:

/authorize : 

* `response_type`: `code`; For authorization code grant-type
* `client_id`: `85f89l43l8rvqtg88epck3msuxg6k84qxqk35tnm9zexeh9d`; Client-id of the app obtainted during the enrollment
* `redirect_uri`: `http://oauth-client.u-lab.io/usecase/AC/retrieveAT`; Landing-page once the authorization is done
* `scope`: `openid profile email`; Authorization requested by the client
* `state`: `xcoivjuywkdkhvusuye3kch`; UUID to avoid CSRF
* `PKCE challenge`: `73924932644EE11CE8ABC066C7D4A409AD209EC3DB0445CC7F88FEA6BF515040`; Additionnal security mechanism to prevent token-leakage (Optional defined by client)
* `PKCE method`: `SHA256`; Method for validating the challenge (sha128/256/512) (Optional defined by client)

/token:

* `grant_type`: `authorization_code`; For authorization code grant-type
* `client_id`: `ejajlhjwv9lnep869358bdtgmn3djnaqhjpx5jyd5clcpkvt`; Client-id of the app obtainted during the enrollment
* `secret`: `srfcgsdpbajbfvcg699gxmhddd4e7fxpdq9myhprv4wy8dhw`; Secret of the app obtainted during the enrollment
* `redirect_uri`: `http://oauth-client.u-lab.io/usecase/AC/retrieveAT`; Landing-page once the authorization is done
* `code`: `vb6yvzl86y77a6uznh8byszp6q4tntrykfzsa6ecdvdmm9uu`; Code delivered by the autorisation server
* `code_verifier`: `MonPetitSecret12345dsfgsdg+`; Additionnal security mechanism to prevent token-leakage (Optional defined by client)

This is the sequence diagram used in the OAuth Authorization code use-case:

NOTE: when using the test-case included in the OAuth pack, don't forget to change the IP address inside the test client, otherwise the client cannot retrieve the Access Token :

### Implicit use-case

* `response_type`: `token`; For implicit grant-type
* `client_id`: `85f89l43l8rvqtg88epck3msuxg6k84qxqk35tnm9zexeh9d`; Client-id of the app obtainted during the enrollment
* `redirect_uri`: `http://oauth-client.u-lab.io/usecase/implicit/redirecturl`: Landing-page once the authorization is done
* `scope`: `openid profile email`; Authorization requested by the client
* `state`: `xcoivjuywkdkhvusuye3kch`; UUID to avoid CSRF

This is the sequence diagram used in the OAuth Implicit use-case

### Resource Owner Password Credentials use-case

This is the Resource Owner Password Credentials grant required parameter to obtain an OAuth token directly from the token Endpoint /token (HTTP POST application/x-www-form-urlencoded):

The call need to be authenticated with basic Authentication, credentials are the one of the NativeApp (application):
```
client-id=unyrqjn3ah53req56fczbf9ztxb8acsyuq
secret=l7wdt3n5yzzm2s6fjjtlbly8vhady9z9py3mx
```

* `grant_type`: `password`; For Resource Owner Password Credentials
* `username`: `demo`; Username of the user
* `password`: `demo`; Password of the user
* `scope`: `openid profile email`; Authorization requested by the client

This is the sequence diagram used in the OAuth "Resource Owner Password Credentials" Grant use-case:

### Client Credentials use-case

This is the Client Credentials grant required parameter to obtain an OAuth token directly from the token Endpoint /token (HTTP POST application/x-www-form-urlencoded). This grant-type doesn't involve a user, it's used for Machine to Machine communication where the client is acting on its own behalf:

The call need to be authenticated with basic Authentication, credentials are the one of the client (application):
```
client-id=k3mzq7rxb5t92wfhcyupl4vnasgd68o
secret=xh4jn8pfz2wq1blgmcv75edatouy9skr
```

* `grant_type`: `client_credentials`; For Client Credentials grant-type
* `scope`: `api`; Authorization requested by the client

This is the sequence diagram used in the OAuth Client Credentials use-case:

```mermaid
sequenceDiagram
    participant C as Client (M2M app)
    participant AS as Authorization Server
    participant RS as Ressource Server

    C->>AS: POST /token (grant_type=client_credentials, basic-auth client_id/secret, scope)
    AS-->>C: 200 OK (access_token, token_type, expires_in)
    C->>RS: API call (Authorization: Bearer access_token)
    RS-->>C: API response
```

## JWT Token

JWT token is the proof of the authentication, it contain all the required value of the user (email, name etc), but it can also contain authorization information in the scope attribute. The JWT Token validity is check using the signature, but also using the date of the token.

This is an example of a JWT token: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWJqZWN0IjoiSm9obiBkb2UiLCJhZG1pbiI6dHJ1ZSwiaWF0IjoiMTQ4NTk2ODEwNSJ9.fiSiLFuR4RYuw606Djr2KtQ7y2u-G6OzlHchzklBcd0`

This token is composed of 3 parts separated by `.`:

    Header`.`Payload`.`Signature

Header containing the signature/encryption algorithm:

```
{
  "alg": "HS256",
  "typ": "JWT"
}
``` 

Payload contain all the required data:
```
{
        "iss":"https://as.u-lab.io",
        "aud":"https://rs.u-lab.io",
        "sub":"User1@domain.tld",
        "exp": 1515604697,
        "iat": 1515593897,
        "nonce":"uuid-anti-replay-protection",
        "scope":"create/delete",
        "jti":"f232b54cb285452db02770c9d16f8f212151"
}
```

# Glossaire

* Native-app: Mobile app downloaded from a store (rich-client, etc.)
* SPA: Single-Page-Application, web-application that makes API calls
* PWA: Progressive Web Application: application that adapts to the device
* Ressource Server (SP): Service Provider, consumes an identity
* Autorisation Server (IDP): Identity Provider, produces an identity
* Multi-factor MFA: MFA authentication, multiple authentication proofs
* Proof of authentication: What I know (credentials), what I own (token software/hardware), what I am (biometrics)
* SSO: Single-sign-on Authentication, Centralized and Session Authentication, allow the user to log once and access multiple application
* WebSSO: SSO only on the Web, no client-heavy/native-app
* SSO Mobile: SSO in the mobile world (SSO app + SSO client app)
* JSON: JavaScript Object Notation, data structure format
* Token JWT: Token based on a JSON structure data containing user info and authentication proof (signature)
* Token Bearer (Artefact): UUID to retrieve a JWT token (code)
* Access-token(AT): Access token (access control)
* Access-code(AC): Intermediate code to obtain an Access-token
* Refresh-token(RT): Special Token that you can used to obtain a couple of new tokens when the access-token has expired
* Identity-token(ID): Token carrying identity information, ie last name/first name/date of birth (Open-ID Connect)
* Signé: A signed token cannot be modified by the user (integrity, non-repudiation)
* Chiffré: Encrypted token cannot be read by the user (integrity, confidentiality)
* sub: Username of the user (user-id, sAMAccountName, mail, uid, etc.) in an Access Token
* Scope: Right of access scope on the resource
* UUID: Randomized random and single digit series and letter: b3687cc0-5aa4-46a2-ab5a-3d1fce4a35be
