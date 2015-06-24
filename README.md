Vermilion
=========

In-development administration tool for Garry's Mod servers.

The main aim for Vermilion is to have something that is powerful yet permissive.

In the scope of Vermilion, permissive is defined as:
* allowing other addons to use hooks when possible instead of returning a value regardless
* doesn't require any other addons to function
* works out-of-the-box with zero-configuration and intelligent defaults, but highly customisable when required
* players need not know that Vermilion is installed on the server unless they get on the wrong side of the admins

Vermilion is designed in a modular nature. This means that each major piece of functionality is stored in its own module (referred to by Vermilion as an "extension"). Vermilion should continue to operate regardless of what extensions are loaded. This means that all extensions should be SELF SUFFICIENT without depending on each other, and if they do, it should be a soft dependency so it quietly fails without producing an error.

Do not upload to the Steam Workshop without my permission.


Submitting a Feature Request and/or Bug report
==============================================

A few rules about submitting a bug report or feature request:
* Only apply the bug report label to a bug report, and a feature request tag to a feature request. I will add other labels to the issue when I see it.
* Once I have edited the labels, please don't remove them. For example, if I mark your issue as low priority, do not subsequently remove that label.
* If you are going to submit a bug report, please provide all stack traces that appear in the console, otherwise I will either mark your report as low priority, or I will close it immediately.
* I reserve the right to deny any feature request that I feel is useless, breaks the T&C's of any service or is immoral, or for any other reason.
* Check your stack traces. If only the last one, two, or three lines reference Vermilion, then I will most likely not accept your report as that is a bug in a different mod.
* Correct grammar and spelling is appreciated in reports, as it makes it easier to understand what is going on.
* Please make sure that the issue is to do with Vermilion itself or one of the default modules before submitting it. Third party modules are not supported.
* Make completely sure that your bug/feature request has not been submitted before, even in the closed issues section.
* Bug reports will generally be ignored if ULX is present on the system. This is because Vermilion and ULX don't like each other, and I don't see the point in using ULX and Vermilion at the same time. (You will not be able to change my viewpoint on this matter, just leave it).

If you submit a feature request, expect me to play Devil's advocate. This doesn't mean that I won't add it, but you must be able to defend your feature and make it clear to me that it would be a worthy addition to the core Vermilion engine.

Contribution
============

Any code or other resource contributed will become the property of the Vermilion Project and will be subject to the license applied to the project (Apache 2). If you do not want your code to be assimilated into the project, please consider releasing a separate module that Vermilion can load. You can still change the author fields in your own modules.

Other things to take into account (and will be upheld, regardless):
* Be aware that your code will be updated to maintain compliance with newer engine versions. You may not be notified of this at the time.
* Contributing does not necessarily give you final control of the direction of the project. That call is still made by the primary developers (i.e. Ned).
* If you want your code removed from the project, for whatever reason, a reasonable period of time must be given for a substitute to be created.
* Any contributions do not have a guarantee of been accepted. Please make sure that the contribution adheres to general policy for a good contribution.

Good Contributions
==================

* Do not use MODULE.PreventDisable without good reason
* Do not modify the behaviour of other modules unless that is the primary purpose (this is a grey area and a call will have to be made on-the-spot)
* Do not copy code from other sources, unless necessary to override it. Blatant copying is not accepted. Credit must be given and a reason for the inclusion of the code must be given.
* Chat commands are registered inside MODULE:RegisterChatCommands()
* Code is reused as much as possible. Use the utility functions included in VToolkit
* GUIs are built using the VToolkit methods
* Malicious modules will not be accepted and your account will be reported/access to the repository will be blocked
* Other rules will be added over time.
