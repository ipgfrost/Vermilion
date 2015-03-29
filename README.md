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
1. Only apply the bug report label to a bug report, and a feature request tag to a feature request. I will add other labels to the issue when I see it.
2. Once I have edited the labels, please don't remove them. For example, if I mark your issue as low priority, do not subsequently remove that label.
3. If you are going to submit a bug report, please provide all stack traces that appear in the console, otherwise I will either mark your report as low priority, or I will close it immediately.
4. I reserve the right to deny any feature request that I feel is useless, breaks the T&C's of any service or is immoral, or for any other reason.
5. Check your stack traces. If only the last one, two, or three lines reference Vermilion, then I will most likely not accept your report as that is a bug in a different mod.
6. Correct grammar and spelling is appreciated in reports, as it makes it easier to understand what is going on.
7. Please make sure that the issue is to do with Vermilion itself or one of the default modules before submitting it. Third party modules are not supported.
8. Make completely sure that your bug/feature request has not been submitted before, even in the closed issues section.
9. Bug reports will generally be ignored if ULX is present on the system. This is because Vermilion and ULX don't like each other, and I don't see the point in using ULX and Vermilion at the same time. (You will not be able to change my viewpoint on this matter, just leave it).

If you submit a feature request, expect me to play Devil's advocate. This doesn't mean that I won't add it, but you must be able to defend your feature and make it clear to me that it would be a worthy addition to the core Vermilion engine.
