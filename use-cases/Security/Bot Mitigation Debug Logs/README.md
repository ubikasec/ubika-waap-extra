Bot Mitigation Debug Logs
===============================

* 1 [Presentation](#presentation)
* 2 [Backup](#backup)
* 3 [Usage](#usage)

Presentation
------------

In the following use case, we show how to have 'Debug Logs' for Bot Mitigation. The purpose is to learn more about what happen with Bot Mitigation. 

[!WARNING]
The SwfBotMitLogsDebug can drastically reduce the performance of a tunnel.
Logging everything as Security Event consumes resources. In production, you may not want to consume resources only to log that a bot was challenged, or that a valid user was allowed.

We advice to only use this workflow to discover more on Bot Mitigation.

Backup
------

Download the use case backup here: [DemoBotMitigationDebugLog.backup](./backup/DemoBotMitigationDebugLogs.backup)

Usage
-----


The Bot Mitigation Debug Logs Demo main workflow executes as follows:

1.  Defines what is the source ip
2.  Executes the Bot mitigation node for the source ip.
3.  Executes the SwfBotMitigationLogsDebug

The SwfBotMitigationLogsDebug sub-workflow has the following logs customization:
* Denied: creates a security event for each request which is denied.
* Allowed: creates a security event for each request which is allowed (very frequent).
* Challenge: creates a security event for each request wich is challenged (very frequent).
* Redirect: creates a security event for each request which is a valid redirect.
