--[[
 Copyright 2015 Ned Hyett

 Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except
 in compliance with the License. You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under the License
 is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
 or implied. See the License for the specific language governing permissions and limitations under
 the License.

 The right to upload this project to the Steam Workshop (which is operated by Valve Corporation)
 is reserved by the original copyright holder, regardless of any modifications made to the code,
 resources or related content. The original copyright holder is not affiliated with Valve Corporation
 in any way, nor claims to be so.
]]

local lang = Vermilion:CreateLangBody("English")

lang:Add("yes", "Yes")
lang:Add("no", "No")
lang:Add("close", "Close")
lang:Add("refresh", "Refresh")
lang:Add("ok", "OK")
lang:Add("error", "Error")
lang:Add("cancel", "Cancel")
lang:Add("none", "None")
lang:Add("rank", "Rank")

lang:Add("name", "Name")

lang:Add("yearslabel", "Years:")
lang:Add("monthslabel", "Months:")
lang:Add("weekslabel", "Weeks:")
lang:Add("dayslabel", "Days:")
lang:Add("hourslabel", "Hours:")
lang:Add("minuteslabel", "Minutes:")
lang:Add("secondslabel", "Seconds:")

lang:Add("activeplayers", "Active Players")


lang:Add("no_users", "No such player exists on the server.")
lang:Add("ambiguous_users", "Ambiguous results for search \"%s\". (Matched %s users).")
lang:Add("access_denied", "Access Denied!")
lang:Add("under_construction", "Under Construction!")
lang:Add("bad_syntax", "Invalid Syntax!")
lang:Add("not_number", "That isn't a number!")
lang:Add("not_bool", "That isn't a boolean!")
lang:Add("player_immune", "%s is immune to you.")
lang:Add("ban_self", "You can't ban yourself!")
lang:Add("kick_self", "You can't kick yourself!")
lang:Add("no_rank", "No such rank!")
lang:Add("cmd_failure", "Command failed!")
lang:Add("cmd_notfound", "No such command!")

lang:Add("combopanel_title", "Vermilion - Select an Option")
lang:Add("confirmpanel_title", "Vermilion - Confirm")
lang:Add("textpanel_title", "Vermilion - Text Entry Required")

lang:Add("cmd_chatpredict_prompt", "Press up/down to select a suggestion and press tab to insert it.")
lang:Add("cmd_chatpredict_nopredict", "No predictions available!")
lang:Add("cmd_chatpredict_setting", "Enable chat predictions")

lang:Add("cmd_all_bad_pos", "Cannot specify all players (@) here!")

lang:Add("basecommand:dedicatedunknown", "Unknown command! You are not the host of this server; could you perhaps be trying to set your rank? If so, this is not the correct console!")
lang:Add("basecommand:unknown", "Unknown Command!")


--[[

	//		Prints:Config		\\

]]--
lang:Add("config:rank:cantmoveup", "Cannot move rank up. Would interfere with owner rank.")
lang:Add("config:rank:moveprotected", "Cannot move protected rank!")
lang:Add("config:rank:cantmovedown", "Cannot move rank; already at bottom!")
lang:Add("config:rank:renameprotected", "Cannot rename protected rank!")
lang:Add("config:rank:renamed", "Renamed rank %s to %s")
lang:Add("config:rank:deleteprotected", "Cannot delete protected rank!")
lang:Add("config:rank:deleted", "Deleted rank %s")
lang:Add("config:unknownpermission", "Looking for unknown permission (%s)!")
lang:Add("config:badcolour", "Warning: cannot set colour. Invalid type %s!")
lang:Add("config:invaliduser", "Invalid user during permissions check; assuming console!")
lang:Add("config:saving", "Saving data...")
lang:Add("config:loaded", "Loaded data!")
lang:Add("config:backup", "Backing up configuration file...")


lang:Add("config:join", "%s has joined the server.")
lang:Add("config:join:first", "%s has joined the server for the first time!")

lang:Add("config:left", "%s left the server: %s")
lang:Add("config:joinleave_enabled", "Enable Join/Leave Messages")

--[[

	//		Core		\\

]]--
lang:Add("change_rank", "You have been assigned to the %s rank.")


--[[

	//		GeoIP		\\

]]--
lang:Add("geoip:enablesetting", "Enable GeoIP Services")
lang:Add("geoip:cache:expired", "GeoIP cache has expired. Removing...")

--[[

	//		Skybox Protector		\\

]]--
lang:Add("skybox_protect:opt:enable", "Enable Skybox Protector")

--[[

	//		Categories		\\

]]--

lang:Add("category:basic", "Basics")
lang:Add("category:server", "Server Settings")
lang:Add("category:ranks", "Ranks")
lang:Add("category:player", "Player Management")
lang:Add("category:limits", "Limits")

--[[

	//		Base Menus		\\

]]--

lang:Add("menu:api", "API Documentation")
lang:Add("menu:credits", "Credits")

lang:Add("credits:title", "Vermilion Credits")
lang:Add("credits:thanks", "Thank you to anyone else who has contributed ideas and has supported Vermilion throughout development!")
lang:Add("credits:scapi", "Vermilion uses resources from the SoundCloud API. Use of the services provided by Vermilion  that use the SoundCloud API constitutes acceptance of the SoundCloud API terms of use.")
lang:Add("credits:fgip", "The GeoIP services in Vermilion are powered by freegeoip.net. freegeoip.net includes GeoLite data created by MaxMind, available from maxmind.com.")
lang:Add("credits:workshop", "Vermilion Workshop Page")
lang:Add("credits:github", "GitHub Repository")
lang:Add("credits:group", "Steam Group")
lang:Add("credits:workshoprating", "Workshop Rating")
lang:Add("credits:workshoprating:detail", "Workshop Rating: %s%%")

lang:Add("menu:modules", "Modules")
lang:Add("modules:clickon", "Click on a module...")
lang:Add("modules:enabled", "Enabled")
lang:Add("modules:tabs:tabletitle", "Tab Name")
lang:Add("modules:tabs", "Tabs")
lang:Add("modules:permissions", "Permissions")
lang:Add("modules:permissions:tabletitle", "Permission")
lang:Add("modules:tabs:tt", "List of tabs added by this module.")
lang:Add("modules:permissions:tt", "List of permissions added by this module.")


--[[

	//		Welcome Panel		\\

]]--
lang:Add("menu:welcome", "Welcome")
lang:Add("welcome:welcome", "Welcome to Vermilion!")
lang:Add("welcome:changelog", "Change Log")
lang:Add("welcome:faq", "FAQ")


--[[

	//		Addon Validator		\\

]]--
lang:Add("addon_validator:title", "Vermilion Addon Alert")
lang:Add("addon_validator:windowtext", [[Vermilion has detected that you are missing some addons.

Subscribing to these addons will significantly decrease the time taken to connect to this server as you will not have to download the addons each time you connect, and will also solve any missing textures that you are seeing as a result of missing these addons!

Please consider fixing this by using the list below!]])
lang:Add("addon_validator:open_workshop_page", "Open Workshop Page")
lang:Add("addon_validator:open_workshop_page:g1", "Must select at least one addon to open the workshop page for!")
lang:Add("addon_validator:dna", "Close and do not ask again")
lang:Add("addon_validator:dna:confirm", "Are you sure?\nThis will take effect on every server you join.\nTo reset it, type \"vermilion_addonnag_do_not_ask 0\" into the console!")

lang:Add("addon_validator:settingstext", "Enable Addon Validator")

--[[

	//		Automatic Broadcast		\\

]]--
lang:Add("menu:autobroadcast", "Auto-Broadcast")
lang:Add("autobroadcast:list:text", "Text")
lang:Add("autobroadcast:list:interval", "Interval")
lang:Add("autobroadcast:list:colour", "Colour")
lang:Add("autobroadcast:list:title", "Auto-Broadcast Listings")
lang:Add("autobroadcast:edit", "Edit Listing...")
lang:Add("autobroadcast:remove", "Remove Listing")
lang:Add("autobroadcast:new", "New Listing...")
lang:Add("autobroadcast:new:interval", "Broadcast every:")
lang:Add("autobroadcast:new:add", "Add Listing")
lang:Add("autobroadcast:new:gz", "Must have interval greater than zero!")


--[[

	//		Automatic Promotion		\\

]]--
lang:Add("menu:autopromote", "Auto-Promote")
lang:Add("auto_promote:autodone", "%s was automatically promoted to %s after playing for %s!")
lang:Add("auto_promote:header", "Auto-Promotion Listings")
lang:Add("auto_promote:remove", "Remove Listing")
lang:Add("auto_promote:remove:error", "Must select at least one listing to remove.")
lang:Add("auto_promote:save", "Save Listings")
lang:Add("auto_promote:from", "From Rank: ")
lang:Add("auto_promote:to", "To Rank: ")
lang:Add("auto_promote:after", "After Playing For (running total since first ever spawn, not since last promotion):")
lang:Add("auto_promote:list:from", "From Rank")
lang:Add("auto_promote:list:to", "To Rank")
lang:Add("auto_promote:list:after", "After Playing For")
lang:Add("auto_promote:add", "Add Listing")
lang:Add("auto_promote:add:error:inittarrank", "Please input the initial rank and target rank correctly!")
lang:Add("auto_promote:add:error:diff", "Must select two different ranks.")
lang:Add("auto_promote:add:error:time:0", "Must have playtime greater than zero.")
lang:Add("auto_promote:editapply", "Apply Edits")
lang:Add("auto_promote:edit", "Edit")
lang:Add("auto_promote:addmain", "Add")
lang:Add("auto_promote:removemain", "Remove")


--[[

	//		Bans		\\

]]--
lang:Add("menu:bans", "Ban Management")
lang:Add("cmd:ban:syntax", "<name> <time:minutes (can be fractional, or 0 for permaban)> <reason>")
lang:Add("cmd:kick:syntax", "<name> <reason>")
lang:Add("cmd:unban:syntax", "<name>")
lang:Add("bans:noreason", "No reason given")
lang:Add("bans:ban:allplayers:perma", "All players were permanently banned by %s with reason: %s")
lang:Add("bans:ban:allplayers", "All players were banned by %s until %s with reason: %s")
lang:Add("bans:ban:perma:text", "%s was permanently banned by %s with reason: %s")
lang:Add("bans:ban:text", "%s was banned by %s until %s with reason: %s")
lang:Add("bans:kick:kicked", "%s was kicked by %s: %s")
lang:Add("bans:kick:kickedtext", "Kicked by %s: %s")
lang:Add("bans:kick:allplayers", "All players were kicked by %s with reason: %s")
lang:Add("bans:unban:toomany", "Too many results found. Please narrow your search.")
lang:Add("bans:unban:none", "No results found.")
lang:Add("bans:unban:text", "%s was unbanned by %s")
lang:Add("bans:alreadybanned", "This player has already been banned!")
lang:Add("bans:time:toosmall", "Cannot ban player for less than 0 minutes! Valid times are 0 (permaban), and any time greater than 0.")
lang:Add("bans:reconnectalert", "%s has tried to reconnect to the server!")
lang:Add("bans:reconnect:event", "%s has attempted to reconnect to the server!")
lang:Add("bans:retorttext:perma", "You are banned permanently: %s")
lang:Add("bans:retorttext", "You are banned until %s: %s")
lang:Add("bans:gui:bantime", "Input ban time")
lang:Add("bans:reason", "For what reason are you banning this/these player(s)?")
lang:Add("bans:never", "Never")
lang:Add("bans:listings", "Ban Listings")
lang:Add("bans:banbtn", "Ban Player(s)")
lang:Add("bans:banbtn:error:0", "Must select at least one player to ban.")
lang:Add("bans:kickbtn", "Kick Player(s)")
lang:Add("bans:kickbtn:error:0", "Must select at least one player to kick.")
lang:Add("bans:kickbtn:reason", "For what reason are you kicking this/these players?")
lang:Add("bans:banply", "Ban Player")
lang:Add("bans:kickply", "Kick Player")
lang:Add("bans:editreason", "Edit Reason")
lang:Add("bans:editreason:dialog", "Enter the new reason for banning this player:")
lang:Add("bans:details", "Details...")
lang:Add("bans:editduration", "Edit Duration")
lang:Add("bans:unbanbtn", "Unban Player")
lang:Add("bans:list:bannedon", "Banned On")
lang:Add("bans:list:expires", "Expires")
lang:Add("bans:list:bannedby", "Banned By")
lang:Add("bans:list:reason", "Reason")


--[[

	//		Battery Meter		\\

]]--
lang:Add("battery_meter:unplugged", "Computer unplugged!")
lang:Add("battery_meter:pluggedin", "Computer plugged in!")
lang:Add("battery_meter:low", "Low battery: %s%%!")
lang:Add("battery_meter:critical", "Critical battery: %s%%!")
lang:Add("battery_meter:interface", "Battery Level: %s%%")
lang:Add("battery_meter:cl_opt", "Enable Battery Meter")

--[[

	//		Chat Censor		\\

]]--
lang:Add("menu:chat_censor", "Chat Censor")
lang:Add("chat_censor:enable", "Enable Chat Censor")
lang:Add("chat_censor:ipv4", "Censor IPv4 Addresses")
lang:Add("chat_censor:add", "Add Phrase")
lang:Add("chat_censor:edit", "Edit Phrase")
lang:Add("chat_censor:remove", "Remove Phrase")
lang:Add("chat_censor:phrase", "Phrase")
lang:Add("chat_censor:list", "Blocked Phrases")

--[[

	//		Client Settings		\\

]]--
lang:Add("menu:client_settings", "Client Settings")
lang:Add("client_settings:cat:features", "Features")
lang:Add("client_settings:cat:graphics", "Graphics")
lang:Add("client_settings:opt:skin", "Skin (requires restart)")
lang:Add("client_settings:opt:lang", "Language (requires restart)")

--[[

	//		Player Management Menu		\\

]]--
lang:Add("menu:playermanagement", "Execute Commands")


--[[

	//		Toolgun Limiter		\\

]]--

lang:Add("limit_toolgun:cannot_use", "You cannot use this toolgun mode!")


--[[

	//		Prop Protection		\\

]]--
lang:Add("server_settings:cat:prop_protect", "Prop Protection")
lang:Add("server_settings:cat:antispam", "Anti-Spam")
lang:Add("prop_protect:toolgun:cannotuse", "You cannot use the toolgun on this prop!")
lang:Add("prop_protect:world:cannotuse", "You cannot interact with map-spawned props.")
lang:Add("prop_protect:gravgun:cannotuse", "You cannot use the gravity gun on this prop!")
lang:Add("prop_protect:physgun:cannotuse", "You cannot use the physics gun on this prop!")
lang:Add("prop_protect:use:cannotuse", "You cannot use this prop!")
lang:Add("prop_protect:drive:cannotuse", "You cannot drive this prop!")
lang:Add("prop_protect:break:cannotuse", "You cannot break this prop!")
lang:Add("prop_protect:property:cannotuse", "You cannot use properties on this prop!")
lang:Add("prop_protect:variable:cannotuse", "You cannot edit this prop's variables!")
lang:Add("prop_protect:quotaheader", "Buddy Quota (%s/64):")

--[[

	//		Commands		\\

]]--
lang:Add("menu:gimps", "Gimp Editor")
lang:Add("commands:gimps:list:text", "Gimp Message")
lang:Add("commands:gimps:list:title", "Gimps")
lang:Add("commands:gimps:remove", "Remove Gimp")
lang:Add("commands:gimps:remove:g1", "Must select at least one gimp to remove.")
lang:Add("commands:gimps:new", "Add Gimp")
lang:Add("commands:gimps:new:add", "Add Gimp")
lang:Add("commands:gimps:newlines", "Gimp must not contain new lines!")

lang:Add("commands:version", "The current version is: %s")

lang:Add("commands:cmd:tplook:syntax", "[player to move] [player reference]")
lang:Add("commands:cmd:tppos:syntax", "[player] <x> <y> <z>")
lang:Add("commands:cmd:teleport:syntax", "[player to move] <player to move to>")
lang:Add("commands:cmd:goto:syntax", "<player to go to>")
lang:Add("commands:cmd:bring:syntax", "<player to bring>")
lang:Add("commands:cmd:tpquery:syntax", "<player>")
lang:Add("commands:cmd:tpaccept:syntax", "<player>")
lang:Add("commands:cmd:tpdeny:syntax", "<player>")
lang:Add("commands:cmd:speed:syntax", "[player] <speed multiplier>")
lang:Add("commands:cmd:respawn:syntax", "[player]")
lang:Add("commands:cmd:pm:syntax", "<player> <message>")
lang:Add("commands:cmd:r:syntax", "<message>")
lang:Add("commands:cmd:getpos:syntax", "[player]")
lang:Add("commands:cmd:sudo:syntax", "<player> <command>")
lang:Add("commands:cmd:spectate:syntax", "[-entity <entityid>] [-player <player>]") //Note: don't localise -entity and -player
lang:Add("commands:cmd:steamid:syntax", "[player]")
lang:Add("commands:cmd:ping:syntax", "[player]")
lang:Add("commands:cmd:convar:syntax", "<cvar> [value]")
lang:Add("commands:cmd:deaths:syntax", "<player> <deaths>")
lang:Add("commands:cmd:frags:syntax", "<player> <frags>")
lang:Add("commands:cmd:armour:syntax", "<player> <armour>")
lang:Add("commands:cmd:kickvehicle:syntax", "<player>")
lang:Add("commands:cmd:ignite:syntax", "<player> <time:seconds>")
lang:Add("commands:cmd:extinguish:syntax", "<player>")
lang:Add("commands:cmd:random:syntax", "[min] <max>")
lang:Add("commands:cmd:lockplayer:syntax", "<player>")
lang:Add("commands:cmd:unlockplayer:syntax", "<player>")
lang:Add("commands:cmd:kill:syntax", "<player>")
lang:Add("commands:cmd:assassinate:syntax", "<player>")
lang:Add("commands:cmd:ragdoll:syntax", "<player>")
lang:Add("commands:cmd:stripammo:syntax", "<player>")
lang:Add("commands:cmd:flatten:syntax", "<player>")
lang:Add("commands:cmd:launch:syntax", "<player>")
lang:Add("commands:cmd:stripweapons:syntax", "<player>")
lang:Add("commands:cmd:health:syntax", "[player] <health>")
lang:Add("commands:cmd:explode:syntax", "<player> [magnitude:20]")
lang:Add("commands:cmd:setteam:syntax", "<player> <team>")
lang:Add("commands:cmd:slap:syntax", "<player> <times> <damage>")
lang:Add("commands:cmd:adminchat:syntax", "<msg>")
lang:Add("commands:cmd:gimp:syntax", "<player>")
lang:Add("commands:cmd:mute:syntax", "<player>")
lang:Add("commands:cmd:gag:syntax", "<player>")

lang:Add("commands:tplook:text:self", "%s teleported %s to his/her look position.")
lang:Add("commands:tplook:text", "%s teleported %s to %s's look position.")
lang:Add("commands:tplook:all", "All players were teleported to %s's look position.")

lang:Add("commands:tppos:outofworld", "Cannot put player here; it is outside of the world!")
lang:Add("commands:tppos:teleported", "%s teleported %s to %s")
lang:Add("commands:tppos:teleported:all", "%s teleported all players to %s")

lang:Add("commands:teleport", "%s teleported %s to %s")
lang:Add("commands:teleport:all", "%s teleported all players to %s")

lang:Add("commands:goto", "%s teleported to %s")

lang:Add("commands:bring", "%s brought %s to him/herself.")
lang:Add("commands:bring:all", "%s brought all players to him/herself.")

lang:Add("commands:tpquery:otherpermission", "This player doesn't have permission to respond to teleport requests.")
lang:Add("commands:tpquery:sent", "Sent request!")
lang:Add("commands:tpquery:notification", "%s is requesting to teleport to you...")

lang:Add("commands:tpaccept:notask", "This player has not asked to teleport to you.")
lang:Add("commands:tpaccept:already", "This player has already teleported to you and the ticket has been cancelled!")
lang:Add("commands:tpaccept:accepted", "Request accepted! Teleporting in 10 seconds.")
lang:Add("commands:tpaccept:moved", "Someone moved! Teleportation cancelled!")
lang:Add("commands:tpaccept:done", "Teleporting...")

lang:Add("commands:tpdeny:notask", "This player has not asked to teleport to you.")
lang:Add("commands:tpdeny:already", "This player has already teleported to you and the ticket has been cancelled!")
lang:Add("commands:tpdeny:done", "Request denied!")

lang:Add("commands:speed:done:self", "%s set his/her speed to %sx normal speed.")
lang:Add("commands:speed:done:other", "%s set the speed of %s to %sx normal speed.")
lang:Add("commands:speed:done:all", "%s set the speed of all players to %sx normal speed.")

lang:Add("commands:respawn:done", "%s forced %s to respawn.")
lang:Add("commands:respawn:done:all", "%s forced all players to respawn.")

lang:Add("commands:r:notvalid", "You haven't received a private message yet or the player has left the server!")
lang:Add("commands:r:private", "Private")

lang:Add("commands:time", "The server time is: %s")

lang:Add("commands:getpos:self", "Your position is %s")
lang:Add("commands:getpos:other", "%s's position is %s")

lang:Add("commands:spectate:banned", "You cannot spectate this entity!")
lang:Add("commands:spectate:done", "You are now spectating %s")
lang:Add("commands:spectate:ent:invalid", "That isn't a valid entity.")
lang:Add("commands:spectate:ply:self", "You cannot spectate yourself!")
lang:Add("commands:spectate:invtyp", "Invalid type!")
lang:Add("commands:spectate:removed", "The entity you were spectating was removed.")

lang:Add("commands:unspectate:bad", "You aren't spectating anything...")

lang:Add("commands:steamid:self", "Your SteamID is %s")
lang:Add("commands:steamid:other", "%s's SteamID is %s")

lang:Add("commands:ping:self", "Your ping is %sms")
lang:Add("commands:ping:other", "%s's ping is %sms")

lang:Add("commands:convar:nexist", "This convar doesn't exist!")
lang:Add("commands:convar:value", "%s is set to %s")
lang:Add("commands:convar:cannotset", "Cannot set the value of this convar.")
lang:Add("commands:convar:set", "%s set %s to %s")

lang:Add("commands:deaths", "%s set %s's death count to %s")

lang:Add("commands:frags", "%s set %s's frag count to %s")

lang:Add("commands:armour", "%s set %s's armour to %s")

lang:Add("commands:decals", "%s cleared up the decals.")

lang:Add("commands:kickvehicle:notin", "This player isn't in a vehicle!")
lang:Add("commands:kickvehicle:done", "%s kicked %s from his/her vehicle.")

lang:Add("commands:ignite:done", "%s set %s on fire for %s seconds.")

lang:Add("commands:extinguish:done", "%s extinguished %s")

lang:Add("commands:random", "Number: %s")

lang:Add("commands:suicide", "%s killed him/herself.")

lang:Add("commands:lockplayer", "%s was locked by %s")
lang:Add("commands:lockplayer:all", "%s locked all players.")

lang:Add("commands:unlockplayer", "%s was unlocked by %s")
lang:Add("commands:unlockplayer:all", "%s unlocked all players.")

lang:Add("commands:kill", "%s killed %s")
lang:Add("commands:kill:all", "%s killed everybody.")

lang:Add("commands:ragdoll:done", "%s turned %s into a ragdoll.")
lang:Add("commands:ragdoll:done:all", "%s turned everybody into a ragdoll.")

lang:Add("commands:stripammo:done", "%s removed all of %s's ammo.")
lang:Add("commands:stripammo:done:all", "%s removed everybody's ammo.")

lang:Add("commands:stripweapons:done", "%s stripped %s of his/her weapons!")
lang:Add("commands:stripweapons:done:all", "%s stripped everybody of their weapons!")

lang:Add("commands:flatten:done", "%s flattened %s")
lang:Add("commands:flatten:done:all", "%s flattened everybody.")

lang:Add("commands:launch:done", "%s launched %s into the air!")
lang:Add("commands:launch:done:all", "%s launched everybody into the air!")

lang:Add("commands:health:done", "%s set %s's health to %s")
lang:Add("commands:health:done:all", "%s set everybody's health to %s")

lang:Add("commands:explode:done", "%s blew up %s")
lang:Add("commands:explode:done:all", "%s blew everybody up.")

lang:Add("commands:setteam:amb", "Ambiguous result for team name. Try again!")
lang:Add("commands:setteam:nores", "No results for team name. Try again!")
lang:Add("commands:setteam:done", "%s assigned %s to team '%s'")
lang:Add("commands:setteam:done:all", "%s assigned everybody to team '%s'")

lang:Add("commands:slap:done", "%s slapped %s %s times!")
lang:Add("commands:slap:done:all", "%s slapped everybody %s times!")

lang:Add("commands:adminchat:noadmin", "No administrators are currently online.")
lang:Add("commands:adminchat:sent", "Message Sent!")

lang:Add("commands:gimp:gimped:done", "%s gimped %s")
lang:Add("commands:gimp:ungimped:done", "%s ungimped %s")
lang:Add("commands:gimp:help", "Run the gimp command again to ungimp this player.")

lang:Add("commands:mute:muted:done", "%s muted %s")
lang:Add("commands:mute:unmuted:done", "%s unmuted %s")
lang:Add("commands:mute:help", "Run the mute command again to unmute this player.")

lang:Add("commands:gag:gagged:done", "%s gagged %s")
lang:Add("commands:gag:ungagged:done", "%s ungagged %s")
lang:Add("commands:gag:help", "Run the gag command again to ungag this player.")


lang:Add("commands:setjailpos:world", "That isn't inside the world...")
lang:Add("commands:setjailpos:done", "%s set the jail position to %s")

lang:Add("commands:convarvote:question", "Set %s to %s?")
lang:Add("commands:convarvote:syntax", "Syntax: <convar> <value>")

--[[

	//		Death Notice		\\

]]--
lang:Add("deathnotice:hitgroup:head", "head")
lang:Add("deathnotice:hitgroup:chest", "chest")
lang:Add("deathnotice:hitgroup:stomach", "stomach")
lang:Add("deathnotice:hitgroup:larm", "left arm")
lang:Add("deathnotice:hitgroup:rarm", "right arm")
lang:Add("deathnotice:hitgroup:lleg", "left leg")
lang:Add("deathnotice:hitgroup:rleg", "right leg")

lang:Add("deathnotice:opt:enable", "Enable Death Notices")
lang:Add("deathnotice:opt:debug", "Enable Death Notice Debug Output")

lang:Add("deathnotice:die:fizzled", "%s was fizzled by %s")
lang:Add("deathnotice:die:fizzled:unk", "%s was fizzled.")

lang:Add("deathnotice:die:crush", "%s was crushed by %s")
lang:Add("deathnotice:die:crush:self", "%s crushed him/herself.")
lang:Add("deathnotice:die:crush:unk", "%s was crushed.")

lang:Add("deathnotice:die:weapon:self", "%s killed him/herself with a %s")
lang:Add("deathnotice:die:weapon:recordhitgroup", "%s was killed by %s with a %s from %sm away with a direct hit to the %s (NEW RECORD FOR THIS WEAPON! Old: %sm - %s)")
lang:Add("deathnotice:die:weapon:hitgroup", "%s was killed by %s with a %s from %sm away with a direct hit to the %s")
lang:Add("deathnotice:die:weapon:default", "%s was killed by %s with a %s from %sm away")
lang:Add("deathnotice:die:weapon:unk", "%s was killed by %s from %sm away")
lang:Add("deathnotice:die:weapon:unkhitgroup", "%s was killed by %s from %sm away with a direct hit to the %s")

lang:Add("deathnotice:die:fall", "%s was dominated by Isaac Newton!")
lang:Add("deathnotice:die:burn", "%s burned to death.")

lang:Add("deathnotice:die:vehicle", "%s was run over by %s in a %s")
lang:Add("deathnotice:die:vehicle:unk", "%s was run over by %s")

lang:Add("deathnotice:die:expl:self", "%s has blown him/herself up with a %s")
lang:Add("deathnotice:die:expl:record", "%s was blown up by %s with a %s from %sm away (NEW RECORD FOR THIS WEAPON! Old: %sm - %s)")
lang:Add("deathnotice:die:expl:text", "%s was blown up by %s with a %s from %sm away.")
lang:Add("deathnotice:die:expl:unk:self", "%s has blown him/herself up.")
lang:Add("deathnotice:die:expl:unk", "%s was blown up by %s from %sm away.")


--[[

	//		Zones		\\

]]--
lang:Add("zones:mode_params", "Mode Parameters")

lang:Add("zones:mode:anti_noclip", "Anti-Noclip")
lang:Add("zones:mode:anti_rank", "Anti-Rank")
lang:Add("zones:mode:sudden_death", "Sudden Death")
lang:Add("zones:mode:notify_enter", "Notify on Enter")
lang:Add("zones:mode:notify_leave", "Notify on Leave")
lang:Add("zones:mode:speed", "Speed Boost")
lang:Add("zones:mode:no_vehicles", "No Vehicles")
lang:Add("zones:mode:confiscate_weapons", "Confiscate Weapons")
lang:Add("zones:mode:kill", "Kill")
lang:Add("zones:mode:anti_propspawn", "Prevent Prop Spawning")
lang:Add("zones:mode:no_gravity", "Zero Gravity")
lang:Add("zones:mode:anti_pvp", "Anti-PvP")


lang:Add("zones:cmd:jail:syntax", "<player> <jail zone>")

lang:Add("zones:jail:release", "%s has released %s from jail!")
lang:Add("zones:jail:nojail", "There is no such jail zone!")
lang:Add("zones:jail:jail", "%s has placed %s in jail!")

--[[

	//		Event Log		\\

	Note that the event translations won't be used until the event logger is rewritten as the event logger will currently default to the server language instead of client languages.

]]--
lang:Add("event_logger:chatcommand", "%s is running the %s chat command. (%s)")
lang:Add("event_logger:connect", "%s has connected to the server.")
lang:Add("event_logger:disconnect", "%s has disconnected from the server.")
lang:Add("event_logger:suicide", "%s committed suicide.")
lang:Add("event_logger:kill", "%s was killed by %s")
lang:Add("event_logger:spawn", "%s spawned a %s with model (%s)")
lang:Add("event_logger:spray", "%s sprayed near %s")
lang:Add("event_logger:break:pos", "%s broke %s with model (%s) near %s")
lang:Add("event_logger:break:owner", "%s broke %s owned by %s")
lang:Add("event_logger:entervehicle:pos", "%s entered %s with model (%s) near %s")
lang:Add("event_logger:entervehicle:owner", "%s entered %s owned by %s")
lang:Add("event_logger:exitvehicle:pos", "%s exited %s with model (%s) near %s")
lang:Add("event_logger:exitvehicle:owner", "%s exited %s owned by %s")
lang:Add("event_logger:drive:pos", "%s is driving %s with model (%s) near %s")
lang:Add("event_logger:drive:owner", "%s is driving %s owned by %s")

-- whereas these will


--[[

	//		Server Settings		\\

]]--
lang:Add("menu:basicsettings", "Basic Settings")
lang:Add("menu:motd", "MOTD")
lang:Add("menu:userdata", "Userdata Browser")
lang:Add("menu:voip_channels", "VoIP Channels")
lang:Add("menu:command_muting", "Command Muting")

lang:Add("server_settings:motd:std", "Standard")
lang:Add("server_settings:motd:html", "HTML")
lang:Add("server_settings:motd:url", "URL")
lang:Add("server_settings:motd:showvars", "Show Variables")
lang:Add("server_settings:motd:varlist", "MOTD Variables")
lang:Add("server_settings:motd:vardesc", "Description")
lang:Add("server_settings:motd:preview", "Preview")
lang:Add("server_settings:motd:save", "Save Changes...")
lang:Add("server_settings:motd:unsaved", "There are unsaved changes to the MOTD! Really close?")

lang:Add("server_settings:userdata:users", "Users")
lang:Add("server_settings:userdata:userdata", "User Data")
lang:Add("server_settings:userdata:delete", "Delete Userdata")

lang:Add("server_settings:muting:desc", "Control which commands can produce global output, i.e. \"Ned cleared the decals.\". If a command isn't on this list, it doesn't produce global output.")

lang:Add("server_settings:notimpl", "Feature not implemented!")

lang:Add("server_settings:off", "Off")
lang:Add("server_settings:all_players", "All Players")
lang:Add("server_settings:permissions_based", "Permissions Based")
lang:Add("server_settings:all_blocked", "All Players Blocked")
lang:Add("server_settings:all_allowed", "All Players Allowed")


lang:Add("server_settings:cat:limits", "Limits")
lang:Add("server_settings:cat:immunity", "Immunity")
lang:Add("server_settings:cat:misc", "Misc")
lang:Add("server_settings:cat:danger", "Danger Zone")
lang:Add("server_settings:unlimited_ammo", "Unlimited ammunition:")
lang:Add("server_settings:limitremover", "Spawn Limit Remover:")
lang:Add("server_settings:damage", "Disable Damage:")
lang:Add("server_settings:flashlight", "Flashlight Control:")
lang:Add("server_settings:noclipcontrol", "Noclip Control:")
lang:Add("server_settings:spraycontrol", "Spray Control:")
lang:Add("server_settings:voip", "VoIP Control:")
lang:Add("server_settings:chat", "Chat Blocker:")
lang:Add("server_settings:lockimm", "Lua Lock Immunity:")
lang:Add("server_settings:killimm", "Lua Kill Immunity:")
lang:Add("server_settings:kickimm", "Lua Kick Immunity:")
lang:Add("server_settings:falldmg", "Fall Damage Modifier:")
lang:Add("server_settings:ownernag", "Disable 'No owner detected' nag at startup")
lang:Add("server_settings:plycoll", "Player Collisions Mode (experimental):")
lang:Add("server_settings:pvpmode", "PvP Mode:")
lang:Add("server_settings:resetconf", "Reset Configuration")

lang:Add("server_settings:apb", "All Players Blocked")
lang:Add("server_settings:apa", "All Players Allowed")

lang:Add("server_settings:voip:dnl", "Do not limit")
lang:Add("server_settings:voip:global", "Globally Disable VoIP")

lang:Add("server_settings:chat:global", "Globally Disable Chat")

lang:Add("server_settings:falldmg:reduced", "All Players Suffer Reduced Damage")

lang:Add("server_settings:plycoll:no", "No Change")
lang:Add("server_settings:plycoll:always", "Always disable collisions")

lang:Add("server_settings:pvpmode:allow", "Allow All PvP")
lang:Add("server_settings:pvpmode:disable", "Disable All PvP")

lang:Add("server_settings:resetconf:question", "Are you sure you want to reset the configuration? The map will also be reset.")
lang:Add("server_settings:noemergency", "NO!")

lang:Add("server_settings:driver", "Data Driver:")

lang:Add("server_settings:cat:spawncampprevention", "Spawncamp Prevention")
lang:Add("server_settings:spawncampprevention:enable", "Enable Spawncamp Prevention")
lang:Add("server_settings:spawncampprevention:timer", "Invincibility Time")

lang:Add("server_settings:sprint", "Sprint Permissions:")
lang:Add("server_settings:forced_menu_keybind:enabled", "Enable Forced Menu Keybind")
lang:Add("server_settings:forced_menu_keybind:key", "Forced Key:")


--[[

	//		Votes		\\

]]--
lang:Add("cat:votes", "Votes")
lang:Add("votes:enabletext", "Enable %s voting")
lang:Add("votes:success", "Vote succeeded with %s%% of players saying yes.")
lang:Add("votes:failure", "Vote failed with %s%% of players saying no.")
lang:Add("votes:nopartake", "Vote failed because nobody responded to the vote.")
lang:Add("votes:cmd:callvote:syntax", "<type> <data>")
lang:Add("votes:inprogress", "There is already a vote in progress. Please wait until it is finished.")
lang:Add("votes:notype", "No such vote type.")
lang:Add("votes:validtypes", "Valid vote types: %s")
lang:Add("votes:invalidparatype", "Invalid parameters for this vote type!")
lang:Add("votes:disabled", "This vote type is disabled.")
lang:Add("votes:header", "VOTE - Called by %s")
lang:Add("votes:footer", "%s - Yes | %s - No")

lang:Add("votes:vyes", "YES vote acknowledged.")
lang:Add("votes:vno", "NO vote acknowledged.")

lang:Add("votes:maps:question", "Change level to %s?")
lang:Add("votes:maps:syntax", "Syntax: <map>")
lang:Add("votes:maps:dne", "Map does not exist!")

lang:Add("votes:ban:question", "Ban player %s?")
lang:Add("votes:ban:syntax", "Syntax: <player> <time in minutes>")

lang:Add("votes:unban:question", "Unban player %s?")
lang:Add("votes:unban:syntax", "Syntax: <player>")
lang:Add("votes:unban:notbanned", "This player has not been banned!")

lang:Add("votes:kick:question", "Kick player %s?")
lang:Add("votes:kick:syntax", "Syntax: <player>")
lang:Add("votes:kick:done", "%s was kicked from the server!")


Vermilion:RegisterLanguage(lang)
