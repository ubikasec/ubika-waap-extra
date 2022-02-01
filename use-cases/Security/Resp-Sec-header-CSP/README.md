# Security Headers (CSP) in Responses

This sub-Workflow is used to implement security mechanisms at the level of the client browser by injecting specific headers into the responses.<br>
These security mechanisms are mainly aimed at preventing the browser from loading such content as scripts, images, media, styles, etc. from an untrusted domain.<br>
This sub-Workflow is placed under a Proxy Request to add headers in the application's responses.

## Backup

> Download the sub-Workflow (backup): [Security Headers (CSP) in Responses](./backup/SWF%20-%20Response%20Secure%20Headers.backup)

## Parameters

- **Display name:** the name of the node as it will appear in the Workflow. Replaces the term “SWF - Response Secure Headers”;
- **X-Frame-Options:** lets you specify whether a page can be loaded from another domain via the `<frame>`, `<iframe>` or `<object>` tags;
    - **DENY:** web application pages cannot be loaded in a frame;
    - **SAMEORIGIN:** the Web application's pages can be loaded only in a frame located in the same domain;
    - **ALLOW-FROM:** the web application pages can be loaded in a frame only from domains specified in the `Allow frame from domain` field;
    - **Don’t use this header:** disables control of frames on the browser. The header will not be added;<br>
    The header added in the response from the application will be of the type:<br>
    `X-Frame-Options: DENY` or `X-Frame-Options: SAMEORIGIN` or `X-Frame-Options: ALLOW-FROM` uri;
- **Allow frame from domain:** if `ALLOW-FROM` was chosen in the preceding field, you can specify which domains are accepted here, separated by a space;
- **Use Content-Security-Policy:** if `Yes` is selected, the browser will take the CSP (Content-Security-Policy) directives defined in the following fields into account.

    - `CSP-Default-src:` Defines the list of the authorized domains for the fonts, frames, images, media, objects, scripts, and styles element groups.

  They use the following fields to customize elements separately. If `CSP-Default-src` and one of the following directives are defined, that directive will be applied instead of `CSP-Default-src`.

    - `CSP-Script-src`: defines the list of domains allowed to provide JavaScript code (`<script>`) to the web application;
    - `CSP-Style-src`: defines the list of domains allowed to provide style sheets (`<style>`) to the web application;
    - `CSP-Image-src`: specifies the list of domains allowed to provide images to the web application;
    - `CSP-Font-src`: specifies the list of domains allowed to provide fonts (`<link>`) to the Web application;
    - `CSP-Object-src`: specifies the list of domains allowed to provide objects (`<object>`, `<embed>`, `<applet>`) to the Web application;
    - `CSP-Media-src`: specifies the list of domains allowed to provide media (`<audio>`, `<video>`) to the Web application;
    - `CSP-Frame-src`: specifies the list of domains allowed to provide code intended for the Web application’s frames (`<frame>` and `<iframe>`);
    - `CSP-Connect-src`: defines the list of domains to which scripts are allowed to connect from the browser: `XMLHttpRequest`, `WebSocket` and `EventSource`.

    ---
    **Info**

    `Content-Security-Policy` controls the domain(s) from which sources are loaded. Several values are possible for the policy directives:
    - `none`: prohibits all domains;
    - `self`: represents the domain of the web application;
    - valid domain name: authorizes the indicated domain (mydomain.com, <http://*.mydomain.com>).

    The values `self` and `domain` can be used together, eg. `self mydomain2.com mydomain3.com`.

    ---

    The header added in the response from the application will be of the type:

    `Content-Security-Policy: [parameters]`
    > An empty field in the CSP configuration rules specifies that no filtering is to be done for that object type.

## Required attributes

The sub-Workflow requires a response's headers table – that is the `http.response.headers` attribute.
