--[[
 Copyright 2015 Ned Hyett,

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

local MODULE = MODULE
MODULE.Name = "Commands"
MODULE.ID = "commands"
MODULE.Description = "Provides some basic commands."
MODULE.Author = "Ned"
MODULE.Permissions = {
	"tplook",
	"tppos",
	"teleport",
	"goto",
	"bring",
	"conditional_teleport",
	"speed",
	"respawn",
	"private_message",
	"getpos",
	"sudo",
	"spectate",
	"vanish",
	"convar",
	"set_deaths",
	"set_frags",
	"set_armour",
	"clear_decals",
	"kickvehicle",
	"ignite",
	"extinguish",
	"suicide",
	"flatten",
	"lock_player",
	"unlock_player",
	"kill_player",
	"ragdoll_player",
	"strip_ammo",
	"strip_weapons",
	"set_health",
	"explode",
	"launch_player",
	"set_team",
	"slap",
	"admin_chat",
	"see_admin_chat",
	"edit_gimps",
	"gimp",
	"mute",
	"gag"
}

MODULE.NetworkStrings = {
	"VGetGimpList",
	"VAddGimp",
	"VRemoveGimp",
	"VEditGimp"
}

MODULE.TeleportRequests = {}
MODULE.PrivateMessageHistory = {}

MODULE.DefaultGimps = {
	"Kick me!",
	"This is the best server I have ever played on!",
	"My shoe size is greater than my IQ!",
	"The moon really is made of cheese! I read it on the internet! It must be true!",
	"How do I move?",
	"How do I fly?",
	"I paid for this game myself! I promise!",
	"How do I Google?",
	"What is the secret phrase?",
	"How do I quit?",
	"Ha! I just got the achievement for playing multiplayer! Fear me!",
	"How do I shoot?"
}

function MODULE:RegisterChatCommands()

	Vermilion:AddChatCommand({
		Name = "tplook",
		Description = "Teleports players to a look position.",
		Syntax = function(vplayer) return MODULE:TranslateStr("cmd:tplook:syntax", nil, vplayer) end,
		BasicParameters = {
			{ Type = Vermilion.ChatCommandConst.MultiPlayerArg },
			{ Type = Vermilion.ChatCommandConst.PlayerArg }
		},
		Category = "Teleport",
		CommandFormat = "\"%s\" \"%s\"",
		CanMute = true,
		Permissions = { "tplook" },
		AllValid = {
			{ Size = 1, Indexes = {} },
			{ Size = 2, Indexes = { 1 } }
		},
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1 or pos == 2) then
				return VToolkit.MatchPlayerPart(current)
			end
		end,
		Function = function(sender, text, log, glog, tglog)
			local target = sender
			local eyeTarget = sender
			if(table.Count(text) > 0) then
				target = VToolkit.LookupPlayer(text[1])
				if(table.Count(text) > 1) then
					eyeTarget = VToolkit.LookupPlayer(text[2])
				end
			end
			if(not IsValid(target) or not IsValid(eyeTarget)) then
				log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
				return
			end
			local trace = eyeTarget:GetEyeTrace()
			if(trace.Hit) then
				if(not Vermilion:GetUser(target):IsImmune(sender)) then
					local targetPhrase = ""
					if(sender == eyeTarget) then
						tglog("commands:tplook:text:self", { sender:GetName(), target:GetName() })
					else
						tglog("commands:tplook:text", { sender:GetName(), target:GetName(), eyeTarget:GetName() })
					end
					target:SetPos(trace.HitPos)
				end
			else
				return false
			end
		end,
		AllBroadcast = function(sender, text, forplayer)
			local eyeTarget = sender
			if(table.Count(text) > 1) then
				eyeTarget = VToolkit.LookupPlayer(text[2])
			end
			if(IsValid(eyeTarget)) then
				return MODULE:TranslateStr("tplook:all", { eyeTarget:GetName() }, forplayer)
			end
		end
	})

	Vermilion:AddChatCommand({
		Name = "tppos",
		Description = "Teleports players to exact coordinates.",
		Syntax = function(vplayer) return MODULE:TranslateStr("cmd:tppos:syntax", nil, vplayer) end,
		BasicParameters = {
			{ Type = Vermilion.ChatCommandConst.MultiPlayerArg },
			{ Type = Vermilion.ChatCommandConst.NumberArg, Bounds = { Min = -1000000, Max = 1000000 } },
			{ Type = Vermilion.ChatCommandConst.NumberArg, Bounds = { Min = -1000000, Max = 1000000 } },
			{ Type = Vermilion.ChatCommandConst.NumberArg, Bounds = { Min = -1000000, Max = 1000000 } }
		},
		Category = "Teleport",
		CommandFormat = "\"%s\" %s %s %s",
		CanMute = true,
		Permissions = { "tppos" },
		AllValid = {
			{ Size = 4, Indexes = { 1 } },
			{ Size = nil, Indexes = {} }
		},
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchPlayerPart(current)
			end
		end,
		Function = function(sender, text, log, glog, tglog)
			local target = sender
			local coordinates = { text[1], text[2], text[3] }
			if(table.Count(text) > 3) then
				target = VToolkit.LookupPlayer(text[1])
				coordinates = { text[2], text[3], text[4] }
			end
			for i,k in pairs(coordinates) do
				if(tonumber(k) == nil) then
					log(Vermilion:TranslateStr("not_number", nil, sender), NOTIFY_ERROR)
					return false
				end
			end
			if(not IsValid(target)) then
				log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
				return
			end

			local vector = Vector(tonumber(coordinates[1]), tonumber(coordinates[2]), tonumber(coordinates[3]))
			if(not util.IsInWorld(vector)) then
				log(MODULE:TranslateStr("tppos:outofworld", nil, sender), NOTIFY_ERROR)
				return false
			end
			if(not Vermilion:GetUser(target):IsImmune(sender)) then
				tglog("commands:tppos:teleported", { sender:GetName(), target:GetName(), table.concat(coordinates, ":") })
				target:SetPos(vector)
			end
		end,
		AllBroadcast = function(sender, text, forplayer)
			coordinates = { text[2], text[3], text[4] }
			return MODULE:TranslateStr("tppos:teleported:all", { sender:GetName(), table.concat(coordinates, ":") }, forplayer)
		end
	})

	Vermilion:AddChatCommand({
		Name = "teleport",
		Description = "Teleports a player to another player",
		Syntax = function(vplayer) return MODULE:TranslateStr("cmd:teleport:syntax", nil, vplayer) end,
		BasicParameters = {
			{ Type = Vermilion.ChatCommandConst.MultiPlayerArg },
			{ Type = Vermilion.ChatCommandConst.PlayerArg }
		},
		Category = "Teleport",
		CommandFormat = "\"%s\" \"%s\"",
		CanMute = true,
		Permissions = { "teleport" },
		AllValid = {
			{ Size = 2, Indexes = { 1 } },
			{ Size = nil, Indexes = { } }
		},
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1 or pos == 2) then
				return VToolkit.MatchPlayerPart(current)
			end
		end,
		Function = function(sender, text, log, glog, tglog)
			local mtarget = nil
			local ptarget = nil

			if(table.Count(text) < 1) then
				log(Vermilion:TranslateStr("bad_syntax", nil, sender), NOTIFY_ERROR)
				return false
			end

			if(table.Count(text) == 1) then
				ptarget = VToolkit.LookupPlayer(text[1])
				mtarget = sender
			elseif(table.Count(text) > 1) then
				ptarget = VToolkit.LookupPlayer(text[2])
				mtarget = VToolkit.LookupPlayer(text[1])
			end

			local target = ptarget:GetPos() + Vector(0, 0, 100)

			if(not IsValid(mtarget) or not IsValid(ptarget)) then
				log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
				return false
			end

			if(not Vermilion:GetUser(mtarget):IsImmune(sender)) then
				tglog("commands:teleport", { sender:GetName(), mtarget:GetName(), ptarget:GetName() })
				mtarget:SetPos(target)
			end
		end,
		AllBroadcast = function(sender, text, forplayer)
			local target = VToolkit.LookupPlayer(text[2])
			if(IsValid(target)) then
				return MODULE:TranslateStr("teleport:all", { sender:GetName(), target:GetName() }, forplayer)
			end
		end
	})

	Vermilion:AliasChatCommand("teleport", "tp")

	Vermilion:AddChatCommand({
		Name = "goto",
		Description = "Teleport yourself to a player",
		Syntax = function(vplayer) return MODULE:TranslateStr("cmd:goto:syntax", nil, vplayer) end,
		BasicParameters = {
			{ Type = Vermilion.ChatCommandConst.PlayerArg }
		},
		Category = "Teleport",
		CommandFormat = "\"%s\"",
		CanMute = true,
		Permissions = { "goto" },
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchPlayerPart(current)
			end
		end,
		Function = function(sender, text, log, glog, tglog)
			if(table.Count(text) < 1) then
				log(Vermilion:TranslateStr("bad_syntax", nil, sender), NOTIFY_ERROR)
				return false
			end
			local target = VToolkit.LookupPlayer(text[1])
			if(not IsValid(target)) then
				log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
				return
			end
			tglog("commands:goto", { sender:GetName(), target:GetName() })
			sender:SetPos(target:GetPos() + Vector(0, 0, 100))
		end
	})

	Vermilion:AddChatCommand({
		Name = "bring",
		Description = "Bring a player to you",
		Syntax = function(vplayer) return MODULE:TranslateStr("cmd:bring:syntax", nil, vplayer) end,
		BasicParameters = {
			{ Type = Vermilion.ChatCommandConst.MultiPlayerArg }
		},
		Category = "Teleport",
		CommandFormat = "\"%s\"",
		CanMute = true,
		Permissions = { "bring" },
		AllValid = {
			{ Size = nil, Indexes = { 1 } }
		},
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchPlayerPart(current)
			end
		end,
		Function = function(sender, text, log, glog, tglog)
			if(table.Count(text) < 1) then
				log(Vermilion:TranslateStr("bad_syntax", nil, sender), NOTIFY_ERROR)
				return false
			end
			local target = VToolkit.LookupPlayer(text[1])
			if(not IsValid(target)) then
				log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
				return
			end
			if(not Vermilion:GetUser(target):IsImmune(sender)) then
				tglog("commands:bring", { sender:GetName(), target:GetName() })
				target:SetPos(sender:GetPos() + Vector(0, 0, 100))
			end
		end,
		AllBroadcast = function(sender, text, forplayer)
			return MODULE:TranslateStr("bring:all", { sender:GetName() }, forplayer)
		end
	})

	Vermilion:AddChatCommand({
		Name = "tpquery",
		Description = "Asks a player if you can teleport to them.",
		Syntax = function(vplayer) return MODULE:TranslateStr("cmd:tpquery:syntax", nil, vplayer) end,
		CanRunOnDS = false,
		Permissions = { "conditional_teleport" },
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchPlayerPart(current)
			end
		end,
		Function = function(sender, text, log, glog, tglog)
			if(table.Count(text) < 1) then
				log(Vermilion:TranslateStr("bad_syntax", nil, self), NOTIFY_ERROR)
				return false
			end
			local target = VToolkit.LookupPlayer(text[1])
			if(not IsValid(target)) then
				log(Vermilion:TranslateStr("no_users", nil, self), NOTIFY_ERROR)
				return
			end
			if(not Vermilion:HasPermission(target, "conditional_teleport")) then
				log(MODULE:TranslateStr("tpquery:otherpermission", nil, sender), NOTIFY_ERROR)
				return
			end
			log(MODULE:TranslateStr("tpquery:sent", nil, sender))
			MODULE.TeleportRequests[sender:SteamID() .. target:SteamID()] = false
			Vermilion:AddNotification(target, MODULE:TranslateStr("tpquery:notification", { sender:GetName() }, target), NOTIFY_HINT)
		end
	})

	Vermilion:AddChatCommand({
		Name = "tpaccept",
		Description = "Accept a teleport request",
		Syntax = function(vplayer) return MODULE:TranslateStr("cmd:tpaccept:syntax", nil, vplayer) end,
		CanRunOnDS = false,
		Permissions = { "conditional_teleport" },
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				local tab = {}
				for i,k in pairs(MODULE.TeleportRequests) do
					if(string.StartWith(i, vplayer:SteamID()) and not k) then
						local tplayer = VToolkit.LookupPlayerBySteamID(string.Replace(i, vplayer:SteamID(), ""))
						if(IsValid(tplayer)) then
							if(string.find(string.lower(tplayer:GetName()), string.lower(current))) then
								table.insert(tab, tplayer:GetName())
							end
						end
					end
				end
				return tab
			end
		end,
		Function = function(sender, text, log, glog, tglog)
			if(table.Count(text) < 1) then
				log(Vermilion:TranslateStr("bad_syntax", nil, sender), NOTIFY_ERROR)
				return false
			end
			local target = VToolkit.LookupPlayer(text[1])
			if(not IsValid(target)) then
				log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
				return
			end
			if(MODULE.TeleportRequests[target:SteamID() .. sender:SteamID()] == nil) then
				log(MODULE:TranslateStr("tpaccept:notask", nil, sender), NOTIFY_ERROR)
				return false
			end
			if(MODULE.TeleportRequests[target:SteamID() .. sender:SteamID()] == true) then
				log(MODULE:TranslateStr("tpaccept:already", nil, sender), NOTIFY_ERROR)
				return false
			end
			Vermilion:TransNotify({sender, target}, "tpaccept:accepted", nil, nil, nil, MODULE)
			local sPos = sender:GetPos()
			local tPos = target:GetPos()
			timer.Simple(10, function()
				if(sPos != sender:GetPos() or tPos != target:GetPos()) then
					Vermilion:TransNotify({sender, target}, "tpaccept:moved", nil, NOTIFY_ERROR, nil, MODULE)
					MODULE.TeleportRequests[target:SteamID() .. sender:SteamID()] = true
					return
				end
				Vermilion:TransNotify({sender, target}, "tpaccept:done", nil, nil, nil, MODULE)
				target:SetPos(sender:GetPos() + Vector(0, 0, 90))
				MODULE.TeleportRequests[target:SteamID() .. sender:SteamID()] = true
			end)
		end
	})

	Vermilion:AddChatCommand({
		Name = "tpdeny",
		Description = "Denies a teleport request",
		Syntax = function(vplayer) return MODULE:TranslateStr("cmd:tpdeny:syntax", nil, vplayer) end,
		CanRunOnDS = false,
		Permissions = { "conditional_teleport" },
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				local tab = {}
				for i,k in pairs(MODULE.TeleportRequests) do
					if(string.StartWith(i, vplayer:SteamID()) and not k) then
						local tplayer = VToolkit.LookupPlayerBySteamID(string.Replace(i, vplayer:SteamID(), ""))
						if(IsValid(tplayer)) then
							if(string.find(string.lower(tplayer:GetName()), string.lower(current))) then
								table.insert(tab, tplayer:GetName())
							end
						end
					end
				end
				return tab
			end
		end,
		Function = function(sender, text, log, glog, tglog)
			if(table.Count(text) < 1) then
				log(Vermilion:TranslateStr("bad_syntax", nil, sender), NOTIFY_ERROR)
				return
			end
			local target = VToolkit.LookupPlayer(text[1])
			if(not IsValid(target)) then
				log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
				return
			end
			if(MODULE.TeleportRequests[target:SteamID() .. sender:SteamID()] == nil) then
				log(MODULE:TranslateStr("tpdeny:notask", nil, sender), NOTIFY_ERROR)
				return
			end
			if(MODULE.TeleportRequests[target:SteamID() .. sender:SteamID()] == true) then
				log(MODULE:TranslateStr("tpdeny:already", nil, sender), NOTIFY_ERROR)
				return
			end
			Vermilion:TransNotify({sender, target}, "tpdeny:done", nil, nil, nil, MODULE)
			MODULE.TeleportRequests[target:SteamID() .. sender:SteamID()] = true
		end
	})

	Vermilion:AliasChatCommand("tpquery", "tpq")
	Vermilion:AliasChatCommand("tpaccept", "tpa")
	Vermilion:AliasChatCommand("tpdeny", "tpd")

	Vermilion:AddChatCommand({
		Name = "speed",
		Description = "Changes player speed",
		Syntax = function(vplayer) return MODULE:TranslateStr("cmd:speed:syntax", nil, vplayer) end,
		BasicParameters = {
			{ Type = Vermilion.ChatCommandConst.MultiPlayerArg },
			{ Type = Vermilion.ChatCommandConst.NumberRangeArg, Bounds = { Min = 0.1, Max = 20 }, Decimals = 2, InfoText = "Multiplier" }
		},
		Category = "Fun",
		CommandFormat = "\"%s\" %s",
		CanMute = true,
		Permissions = { "speed" },
		AllValid = {
			{ Size = 2, Indexes = { 1 } }
		},
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchPlayerPart(current)
			end
		end,
		Function = function(sender, text, log, glog, tglog)
			if(table.Count(text) < 1) then
				log(Vermilion:TranslateStr("bad_syntax", nil, sender), NOTIFY_ERROR)
				return false
			end
			local times = 0
			local target = sender
			if(table.Count(text) > 1) then
				times = tonumber(text[2])
				if(times == nil) then
					log(Vermilion:TranslateStr("not_number", nil, sender), NOTIFY_ERROR)
					return false
				end
				local tplayer = VToolkit.LookupPlayer(text[1])
				if(tplayer == nil or not IsValid(tplayer)) then
					log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
					return
				end
				target = tplayer
			else
				times = tonumber(text[1])
				if(times == nil) then
					log(Vermilion:TranslateStr("not_number", nil, sender), NOTIFY_ERROR)
					return false
				end
			end
			local speed = math.abs(200 * times)
			if(Vermilion:GetUser(target):IsImmune(sender)) then
				log(Vermilion:TranslateStr("player_immune", { target:GetName() }, sender), NOTIFY_ERROR)
				return
			end
			GAMEMODE:SetPlayerSpeed(target, speed, speed * 2)
			if(sender == target) then
				tglog("commands:speed:done:self", { sender:GetName(), tostring(times) })
			else
				tglog("commands:speed:done:other", { sender:GetName(), target:GetName(), tostring(times) })
			end
		end,
		AllBroadcast = function(sender, text, forplayer)
			return MODULE:TranslateStr("speed:done:all", { sender:GetName(), tostring(text[2]) }, forplayer)
		end
	})

	Vermilion:AddChatCommand({
		Name = "respawn",
		Description = "Forces a player to respawn",
		Syntax = function(vplayer) return MODULE:TranslateStr("cmd:respawn:syntax", nil, vplayer) end,
		BasicParameters = {
			{ Type = Vermilion.ChatCommandConst.MultiPlayerArg }
		},
		Category = "Utils",
		CommandFormat = "\"%s\"",
		CanMute = true,
		Permissions = { "respawn" },
		AllValid = {
			{ Size = 1, Indexes = { 1 } }
		},
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchPlayerPart(current)
			end
		end,
		Function = function(sender, text, log, glog, tglog)
			local target = sender
			if(table.Count(text) > 0) then
				local tplayer = VToolkit.LookupPlayer(text[1])
				if(tplayer == nil or not IsValid(tplayer)) then
					log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
					return
				end
				target = tplayer
			end
			if(IsValid(target)) then
				if(Vermilion:GetUser(target):IsImmune(sender)) then
					log(Vermilion:TranslateStr("player_immune", { target:GetName() }, sender), NOTIFY_ERROR)
					return
				end
				tglog("commands:respawn:done", { sender:GetName(), target:GetName() })
				target:Spawn()
			end
		end,
		AllBroadcast = function(sender, text, forplayer)
			return MODULE:TranslateStr("respawn:done:all", { sender:GetName() }, forplayer)
		end
	})

	Vermilion:AddChatCommand({
		Name = "pm",
		Description = "Sends a private message",
		Syntax = function(vplayer) return MODULE:TranslateStr("cmd:pm:syntax", nil, vplayer) end,
		BasicParameters = {
			{ Type = Vermilion.ChatCommandConst.MultiPlayerArg },
			{ Type = Vermilion.ChatCommandConst.StringArg }
		},
		Category = "Chat",
		CommandFormat = "\"%s\" %s",
		Permissions = { "private_message" },
		AllValid = {
			{ Size = nil, Indexes = { 1 } }
		},
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				local tab = VToolkit.MatchPlayerPart(current)
				table.RemoveByValue(tab, vplayer:GetName())
				return tab
			end
		end,
		Function = function(sender, text, log, glog, tglog)
			if(table.Count(text) < 2) then
				log(Vermilion:TranslateStr("bad_syntax", nil, sender), NOTIFY_ERROR)
				return false
			end
			local target = VToolkit.LookupPlayer(text[1])
			if(not IsValid(target)) then
				log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
				return
			end
			target:ChatPrint("[Private] " .. sender:GetName() .. ": " .. table.concat(text, " ", 2))
			MODULE.PrivateMessageHistory[target:SteamID()] = sender:SteamID()
		end
	})

	Vermilion:AddChatCommand({
		Name = "r",
		Description = "Replies to the last pm you were sent.",
		Syntax = function(vplayer) return MODULE:TranslateStr("cmd:r:syntax", nil, vplayer) end,
		Permissions = { "private_message" },
		Function = function(sender, text, log, glog, tglog)
			if(table.Count(text) < 1) then
				log(Vermilion:TranslateStr("bad_syntax", nil, sender), NOTIFY_ERROR)
				return false
			end
			local target = VToolkit.LookupPlayerBySteamID(MODULE.PrivateMessageHistory[sender:SteamID()])
			if(not IsValid(target)) then
				log(MODULE:TranslateStr("r:notvalid", nil, sender), NOTIFY_ERROR)
				return
			end
			sender:ChatPrint("[" .. MODULE:TranslateStr("r:private", nil, sender) .. "] " .. sender:GetName() .. ": " .. table.concat(text, " "))
			target:ChatPrint("[" .. MODULE:TranslateStr("r:private", nil, target) .. "] " .. sender:GetName() .. ": " .. table.concat(text, " "))
			MODULE.PrivateMessageHistory[target:SteamID()] = sender:SteamID()
		end
	})

	Vermilion:AddChatCommand({
		Name = "time",
		Description = "Prints the server time.",
		BasicParameters = {},
		Category = "Utils",
		CommandFormat = "",
		Function = function(sender, text, log, glog, tglog)
			log(MODULE:TranslateStr("time", { os.date(Vermilion.GetActiveLanguageFile(sender).DateTimeFormat) }, sender))
		end
	})

	Vermilion:AddChatCommand({
		Name = "getpos",
		Description = "Get the position of a player",
		Syntax = function(vplayer) return MODULE:TranslateStr("cmd:getpos:syntax", nil, vplayer) end,
		BasicParameters = {
			{ Type = Vermilion.ChatCommandConst.MultiPlayerArg }
		},
		Category = "Utils",
		CommandFormat = "\"%s\"",
		Permissions = { "getpos" },
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchPlayerPart(current)
			end
		end,
		Function = function(sender, text, log, glog, tglog)
			local target = sender
			if(table.Count(text) > 0) then
				target = VToolkit.LookupPlayer(text[1])
			end
			if(not IsValid(target)) then
				log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
				return
			end
			local pos = target:GetPos()
			if(target == sender) then
				log(MODULE:TranslateStr("getpos:self", { table.concat({ math.Round(pos.x), math.Round(pos.y), math.Round(pos.z) }, ":") }, sender))
			else
				log(MODULE:TranslateStr("getpos:other", { target:GetName(), table.concat({ math.Round(pos.x), math.Round(pos.y), math.Round(pos.z) }, ":") }, sender))
			end
		end
	})

	Vermilion:AddChatCommand({
		Name = "sudo",
		Description = "Makes another player run a chat command.",
		Syntax = function(vplayer) return MODULE:TranslateStr("cmd:sudo:syntax", nil, vplayer) end,
		BasicParameters = {
			{ Type = Vermilion.ChatCommandConst.MultiPlayerArg },
			{ Type = Vermilion.ChatCommandConst.StringArg }
		},
		Category = "Utils",
		CommandFormat = "\"%s\" \"%s\"",
		Permissions = { "sudo" },
		AllValid = {
			{ Size = nil, Indexes = { 1 } }
		},
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				local tab = VToolkit.MatchPlayerPart(current)
				table.RemoveByValue(tab, vplayer:GetName())
				return tab
			end
		end,
		Function = function(sender, text, log, glog, tglog)
			if(table.Count(text) < 2) then
				log(Vermilion:TranslateStr("bad_syntax", nil, sender), NOTIFY_ERROR)
				return false
			end
			local target = VToolkit.LookupPlayer(text[1])
			if(not IsValid(target)) then
				log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
				return
			end
			local cmd = table.concat(text, " ", 2)
			if(not string.StartWith(cmd, Vermilion:GetData("chat_prefix", "!", true))) then
				cmd = Vermilion:GetData("chat_prefix", "!", true) .. cmd
			end
			if(Vermilion:GetUser(target):IsImmune(sender)) then
				log(Vermilion:TranslateStr("player_immune", { target:GetName() }, sender), NOTIFY_ERROR)
				return
			end
			Vermilion:HandleChat(target, cmd, log, false)
		end
	})

	local bannedSpecClassses = { -- these should not be spectateable from the command. Yes. I can make up words. "spectateable" is now a new word by order of me. Because I obviously have the authority to do that.
		"filter_",
		"worldspawn",
		"soundent",
		"player_",
		"bodyque",
		"network",
		"sky_camera",
		"info_",
		"env_",
		"predicted_",
		"scene_",
		"gmod_gamerules",
		"shadow_",
		"weapon_",
		"gmod_tool",
		"gmod_camera",
		"gmod_hands",
		"physgun_beam",
		"phys_",
		"hint",
		"spotlight_",
		"path_",
		"lua_",
		"func_brush",
		"light",
		"point_"
	}

	Vermilion:AddChatCommand({
		Name = "spectate",
		Description = "Allows you to spectate stuff",
		Syntax = function(vplayer) return MODULE:TranslateStr("cmd:spectate:syntax", nil, vplayer) end,
		BasicParameters = {
			{ Type = Vermilion.ChatCommandConst.MultiPlayerArg }
		},
		Category = "Utils",
		CommandFormat = "-player \"%s\"",
		CanMute = true,
		CanRunOnDS = false,
		Permissions = { "spectate" },
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return { "-entity", "-player" }
			end
			if(pos == 2 and all[1] == "-entity") then
				local tab = {}
				for i,k in pairs(ents.GetAll()) do
					local banned = false
					for i1,k1 in pairs(bannedSpecClassses) do
						if(string.StartWith(k:GetClass(), k1)) then
							banned = true
							break
						end
					end
					if(banned) then continue end
					if(string.StartWith(tostring(k:EntIndex()), current)) then
						table.insert(tab, {Name = tostring(k:EntIndex()), Syntax = "(" .. k:GetClass() .. ")"})
					end
				end
				return tab
			end
			if(pos == 2 and all[1] == "-player") then
				return VToolkit.MatchPlayerPart(current)
			end
		end,
		Function = function(sender, text, log, glog, tglog)
			if(text[1] == "-entity") then
				if(tonumber(text[2]) == nil) then
					log(Vermilion:TranslateStr("not_number", nil, sender), NOTIFY_ERROR)
					return
				end
				local tent = ents.GetByIndex(tonumber(text[2]))
				if(IsValid(tent)) then
					for i,k in pairs(bannedSpecClassses) do
						if(string.StartWith(tent:GetClass(), k)) then
							log(MODULE:TranslateStr("spectate:banned", nil, sender), NOTIFY_ERROR)
							return
						end
					end
					sender.SpectateOriginalPos = sender:GetPos()
					log(MODULE:TranslateStr("spectate:done", { tent:GetClass() }, sender))
					sender:Spectate( OBS_MODE_CHASE )
					sender:SpectateEntity( tent )
					sender:StripWeapons()
					sender.VSpectating = true
				else
					log(MODULE:TranslateStr("spectate:ent:invalid", nil, sender), NOTIFY_ERROR)
				end
			elseif(text[1] == "-player") then
				local tplayer = VToolkit.LookupPlayer(text[2])
				if(tplayer == sender) then
					log(MODULE:TranslateStr("spectate:ply:self", nil, sender), NOTIFY_ERROR)
					return
				end
				if(IsValid(tplayer)) then
					sender.SpectateOriginalPos = sender:GetPos()
					sender:Spectate( OBS_MODE_CHASE )
					sender:SpectateEntity( tplayer )
					sender:StripWeapons()
					sender.VSpectating = true
				else
					log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
				end
			else
				log(MODULE:TranslateStr("spectate:invtyp", nil, sender), NOTIFY_ERROR)
			end
		end
	})

	self:AddHook("EntityRemoved", function(ent)
		for i,k in pairs(player.GetAll()) do
			if(k.VSpectating == true and k:GetObserverTarget() == ent) then
				k:UnSpectate()
				k:Spawn()
				k:SetPos(k.SpectateOriginalPos)
				k.VSpectating = false
				Vermilion:AddNotification(k, MODULE:TranslateStr("spectate:removed", nil, k))
			end
		end
	end)

	Vermilion:AddChatCommand({
		Name = "unspectate",
		Description = "Stops spectating an entity",
		BasicParameters = {},
		Category = "Utils",
		CommandFormat = "",
		CanRunOnDS = false,
		Function = function(sender, text, log, glog, tglog)
			if(not sender.VSpectating) then
				log(MODULE:TranslateStr("unspectate:bad", nil, sender))
				return
			end
			sender:UnSpectate()
			sender:Spawn()
			sender:SetPos(sender.SpectateOriginalPos)
			sender.VSpectating = false
		end
	})

	Vermilion:AddChatCommand({
		Name = "vanish",
		Description = "Makes you invisible to other players.",
		CanRunOnDS = false,
		Permissions = { "vanish" },
		Function = function(sender, text, log, glog, tglog)
			if(sender:GetRenderMode() == RENDERMODE_NORMAL) then
				sender:SetRenderMode(RENDERMODE_NONE)
				for i,k in pairs(player.GetAll()) do
					sender:SetPreventTransmit(k, true)
				end
			else
				sender:SetRenderMode(RENDERMODE_NORMAL)
				for i,k in pairs(player.GetAll()) do
					sender:SetPreventTransmit(k, false)
				end
			end
		end
	})

	Vermilion:AddChatCommand({
		Name = "steamid",
		Description = "Gets the steamid of a player",
		Syntax = function(vplayer) return MODULE:TranslateStr("cmd:steamid:syntax", nil, vplayer) end,
		BasicParameters = {
			{ Type = Vermilion.ChatCommandConst.MultiPlayerArg }
		},
		Category = "Utils",
		CommandFormat = "\"%s\"",
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchPlayerPart(current)
			end
		end,
		Function = function(sender, text, log, glog, tglog)
			if(table.Count(text) == 0) then
				log(MODULE:TranslateStr("steamid:self", { sender:SteamID() }, sender))
				return
			end
			local tplayer = VToolkit.LookupPlayer(text[1])
			if(IsValid(tplayer)) then
				log(MODULE:TranslateStr("steamid:other", { tplayer:GetName(), sender:SteamID() }, sender))
			else
				log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
			end
		end
	})

	Vermilion:AddChatCommand({
		Name = "ping",
		Description = "Gets the ping of a player.",
		Syntax = function(vplayer) return MODULE:TranslateStr("cmd:ping:syntax", nil, vplayer) end,
		BasicParameters = {
			{ Type = Vermilion.ChatCommandConst.MultiPlayerArg }
		},
		Category = "Utils",
		CommandFormat = "\"%s\"",
		CanRunOnDS = false,
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchPlayerPart(current)
			end
		end,
		Function = function(sender, text, log, glog, tglog)
			if(table.Count(text) == 0) then
				log(MODULE:TranslateStr("ping:self", { tostring(sender:Ping()) }, sender))
			else
				local tplayer = VToolkit.LookupPlayer(text[1])
				if(IsValid(tplayer)) then
					log(MODULE:TranslateStr("ping:other", { tplayer:GetName(), tostring(tplayer:Ping()) }, sender))
				else
					log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
				end
			end
		end
	})

	local allowedcvars = {
		"gm_",
		"sbox_",
		"sv_",
		"bot_",
    "life"
	}

	local blockedcvars = {
		"sv_cheats"
	}

  --if(SERVER) then
    if(Vermilion:GetModule("votes") != nil) then
      local VOTESMODULE = Vermilion:GetModule("votes")
      VOTESMODULE:AddVoteType("convar", function(data, sender, log)
        if(table.Count(data) < 1) then log(MODULE:TranslateStr("convarvote:syntax", nil, sender), NOTIFY_ERROR) return end
        if(not ConVarExists(data[1])) then
          log(MODULE:TranslateStr("convar:nexist", nil, sender), NOTIFY_ERROR)
          return
        end
        local allowed = false
        for i,k in pairs(allowedcvars) do
          if(string.StartWith(string.lower(data[1]), string.lower(k))) then
            allowed = true
            break
          end
        end
        for i,k in pairs(blockedcvars) do
          if(data[1] == k) then
            allowed = false
            break
          end
        end
        if(not allowed) then
          log(MODULE:TranslateStr("convar:cannotset", nil, sender), NOTIFY_ERROR)
          return
        end
        return "commands:convarvote:question", { data[1], data[2] }, "<convar> <value>"
      end, function(data)
        RunConsoleCommand(data[1], data[2])
      end)
    end
  --end

	Vermilion:AddChatCommand({
		Name = "convar",
		Description = "Modifies server convars",
		Syntax = function(vplayer) return MODULE:TranslateStr("cmd:convar:syntax", nil, vplayer) end,
		Permissions = { "convar" },
		CanMute = true,
		Function = function(sender, text, log, glog, tglog)
			if(table.Count(text) == 1) then
				if(not ConVarExists(text[1])) then
					log(MODULE:TranslateStr("convar:nexist", nil, sender), NOTIFY_ERROR)
				else
					log(MODULE:TranslateStr("convar:value", { text[1], cvars.String(text[1]) }, sender))
				end
			elseif(table.Count(text) > 1) then
				if(ConVarExists(text[1])) then
					local allowed = false
					for i,k in pairs(allowedcvars) do
						if(string.StartWith(text[1], k)) then
							allowed = true
							break
						end
					end
					for i,k in pairs(blockedcvars) do
						if(text[1] == k) then
							allowed = false
							break
						end
					end
					if(not allowed) then
						log(MODULE:TranslateStr("convar:cannotset", nil, sender), NOTIFY_ERROR)
						return
					end
					RunConsoleCommand(text[1], text[2])
					tglog("commands:convar:set", { sender:GetName(), text[1], text[2] })
				else
					log(MODULE:TranslateStr("convar:nexist", nil, sender), NOTIFY_ERROR)
				end
			else
				log(Vermilion:TranslateStr("bad_syntax", nil, sender), NOTIFY_ERROR)
			end
		end
	})

	Vermilion:AddChatCommand({
		Name = "deaths",
		Description = "Set the deaths for a player.",
		Syntax = function(vplayer) return MODULE:TranslateStr("cmd:deaths:syntax", nil, vplayer) end,
		BasicParameters = {
			{ Type = Vermilion.ChatCommandConst.MultiPlayerArg },
			{ Type = Vermilion.ChatCommandConst.NumberArg, Bounds = { Min = 0, Max = 1000 } }
		},
		Category = "Utils",
		CommandFormat = "\"%s\" %s",
		Permissions = { "set_deaths" },
		CanMute = true,
		AllValid = {
			{ Size = 2, Indexes = { 1 } }
		},
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchPlayerPart(current)
			end
		end,
		Function = function(sender, text, log, glog, tglog)
			if(table.Count(text) < 2) then
				log(Vermilion:TranslateStr("bad_syntax", nil, sender), NOTIFY_ERROR)
				return
			end
			local tplayer = VToolkit.LookupPlayer(text[1])
			if(IsValid(tplayer)) then
				if(Vermilion:GetUser(tplayer):IsImmune(sender)) then
					log(Vermilion:TranslateStr("player_immune", { tplayer:GetName() }, sender), NOTIFY_ERROR)
					return
				end
				local result = tonumber(text[2])
				if(result == nil) then
					log(Vermilion:TranslateStr("not_number", nil, sender), NOTIFY_ERROR)
					return
				end
				tplayer:SetDeaths(result)
				tglog("commands:deaths", { sender:GetName(), text[1], text[2] })
			else
				log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
			end
		end
	})

	Vermilion:AddChatCommand({
		Name = "frags",
		Description = "Set the frags for a player.",
		Syntax = function(vplayer) return MODULE:TranslateStr("cmd:frags:syntax", nil, vplayer) end,
		BasicParameters = {
			{ Type = Vermilion.ChatCommandConst.MultiPlayerArg },
			{ Type = Vermilion.ChatCommandConst.NumberArg, Bounds = { Min = 0, Max = 1000 } }
		},
		Category = "Utils",
		CommandFormat = "\"%s\" %s",
		Permissions = { "set_frags" },
		CanMute = true,
		AllValid = {
			{ Size = 2, Indexes = { 1 } }
		},
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchPlayerPart(current)
			end
		end,
		Function = function(sender, text, log, glog, tglog)
			if(table.Count(text) < 2) then
				log(Vermilion:TranslateStr("bad_syntax", nil, sender), NOTIFY_ERROR)
				return
			end
			local tplayer = VToolkit.LookupPlayer(text[1])
			if(IsValid(tplayer)) then
				if(Vermilion:GetUser(tplayer):IsImmune(sender)) then
					log(Vermilion:TranslateStr("player_immune", { tplayer:GetName() }, sender), NOTIFY_ERROR)
					return
				end
				local result = tonumber(text[2])
				if(result == nil) then
					log(Vermilion:TranslateStr("not_number", nil, sender), NOTIFY_ERROR)
					return
				end
				tplayer:SetFrags(result)
				tglog("commands:frags", { sender:GetName(), text[1], text[2] })
			else
				log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
			end
		end
	})

	Vermilion:AddChatCommand({
		Name = "armour",
		Description = "Set the armour for a player.",
		Syntax = function(vplayer) return MODULE:TranslateStr("cmd:armour:syntax", nil, vplayer) end,
		BasicParameters = {
			{ Type = Vermilion.ChatCommandConst.MultiPlayerArg },
			{ Type = Vermilion.ChatCommandConst.NumberRangeArg, Bounds = { Min = 0, Max = 200 }, Decimals = 0, InfoText = "Armour" }
		},
		Category = "Utils",
		CommandFormat = "\"%s\" %s",
		Permissions = { "set_armour" },
		CanMute = true,
		AllValid = {
			{ Size = 2, Indexes = { 1 } }
		},
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchPlayerPart(current)
			end
		end,
		Function = function(sender, text, log, glog, tglog)
			if(table.Count(text) < 2) then
				log(Vermilion:TranslateStr("bad_syntax", nil, sender), NOTIFY_ERROR)
				return
			end
			local tplayer = VToolkit.LookupPlayer(text[1])
			if(IsValid(tplayer)) then
				if(Vermilion:GetUser(tplayer):IsImmune(sender)) then
					log(Vermilion:TranslateStr("player_immune", { tplayer:GetName() }, sender), NOTIFY_ERROR)
					return
				end
				local result = tonumber(text[2])
				if(result == nil) then
					log(Vermilion:TranslateStr("not_number", nil, sender), NOTIFY_ERROR)
					return
				end
				tplayer:SetArmor(result)
				tglog("commands:armour", { sender:GetName(), text[1], text[2] })
			else
				log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
			end
		end
	})

	Vermilion:AddChatCommand({
		Name = "decals",
		Description = "Clears the decals",
		BasicParameters = {},
		Category = "Utils",
		CommandFormat = "",
		Permissions = { "clear_decals" },
		CanMute = true,
		Function = function(sender, text, log, glog, tglog)
			for i,k in pairs(VToolkit.GetValidPlayers()) do
				k:ConCommand("r_cleardecals")
			end
			tglog("commands:decals", { sender:GetName() })
		end
	})

	Vermilion:AddChatCommand({
		Name = "kickvehicle",
		Description = "Kicks a player from their vehicle.",
		Syntax = function(vplayer) return MODULE:TranslateStr("cmd:kickvehicle:syntax", nil, vplayer) end,
		BasicParameters = {
			{ Type = Vermilion.ChatCommandConst.MultiPlayerArg }
		},
		Category = "Utils",
		CommandFormat = "\"%s\"",
		Permissions = { "kickvehicle" },
		CanMute = true,
		AllValid = {
			{ Size = 1, Indexes = { 1 } }
		},
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchPlayerPart(current, function(p) return p:InVehicle() end)
			end
		end,
		Function = function(sender, text, log, glog, tglog)
			if(table.Count(text) < 1) then
				log(Vermilion:TranslateStr("bad_syntax", nil, sender), NOTIFY_ERROR)
				return
			end
			local tplayer = VToolkit.LookupPlayer(text[1])
			if(IsValid(tplayer)) then
				if(Vermilion:GetUser(tplayer):IsImmune(sender)) then
					log(Vermilion:TranslateStr("player_immune", { tplayer:GetName() }, sender), NOTIFY_ERROR)
					return
				end
				if(not tplayer:InVehicle()) then
					log(MODULE:TranslateStr("kickvehicle:notin", nil, sender), NOTIFY_ERROR)
					return
				end
				tplayer:ExitVehicle()
				tglog("commands:kickvehicle:done", { sender:GetName(), tplayer:GetName() })
			else
				log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
			end
		end
	})

	Vermilion:AddChatCommand({
		Name = "ignite",
		Description = "Set a player on fire.",
		Syntax = function(vplayer) return MODULE:TranslateStr("cmd:ignite:syntax", nil, vplayer) end,
		BasicParameters = {
			{ Type = Vermilion.ChatCommandConst.MultiPlayerArg },
			{ Type = Vermilion.ChatCommandConst.NumberRangeArg, Bounds = { Min = 0, Max = 200 }, Decimals = 1, InfoText = "Time (seconds)" }
		},
		Category = "Fun",
		CommandFormat = "\"%s\" %s",
		Permissions = { "ignite" },
		CanMute = true,
		AllValid = {
			{ Size = 2, Indexes = { 1 } }
		},
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchPlayerPart(current, function(p) return not p:IsOnFire() end)
			end
		end,
		Function = function(sender, text, log, glog, tglog)
			if(table.Count(text) < 2) then
				log(Vermilion:TranslateStr("bad_syntax", nil, sender), NOTIFY_ERROR)
				return false
			end
			local result = tonumber(text[2])
			if(result == nil) then
				log(Vermilion:TranslateStr("not_number", nil, sender), NOTIFY_ERROR)
				return false
			end
			local tplayer = VToolkit.LookupPlayer(text[1])
			if(IsValid(tplayer)) then
				if(Vermilion:GetUser(tplayer):IsImmune(sender)) then
					log(Vermilion:TranslateStr("player_immune", { tplayer:GetName() }, sender), NOTIFY_ERROR)
					return
				end
				tplayer:Ignite(result, 5)
				tglog("commands:ignite:done", { sender:GetName(), tplayer:GetName(), tostring(result) })
			else
				log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
			end
		end
	})

	Vermilion:AddChatCommand({
		Name = "extinguish",
		Description = "Stops a player from being on fire.",
		Syntax = function(vplayer) return MODULE:TranslateStr("cmd:extinguish:syntax", nil, vplayer) end,
		BasicParameters = {
			{ Type = Vermilion.ChatCommandConst.MultiPlayerArg }
		},
		Category = "Utils",
		CommandFormat = "\"%s\"",
		CanMute = true,
		Permissions = { "extinguish" },
		AllValid = {
			{ Size = 1, Indexes = { 1 } }
		},
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchPlayerPart(current, function(p) return p:IsOnFire() end)
			end
		end,
		Function = function(sender, text, log, glog, tglog)
			if(table.Count(text) < 1) then
				log(Vermilion:TranslateStr("bad_syntax", nil, sender), NOTIFY_ERROR)
				return false
			end
			local tplayer = VToolkit.LookupPlayer(text[1])
			if(IsValid(tplayer)) then
				if(Vermilion:GetUser(tplayer):IsImmune(sender)) then
					log(Vermilion:TranslateStr("player_immune", { tplayer:GetName() }, sender), NOTIFY_ERROR)
					return
				end
				tplayer:Extinguish()
				tglog("commands:extinguish:done", { sender:GetName(), tplayer:GetName() })
			else
				log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
				return
			end
		end
	})

	Vermilion:AddChatCommand({
		Name = "random",
		Description = "Generates a pseudo-random number.",
		Syntax = function(vplayer) return MODULE:TranslateStr("cmd:random:syntax", nil, vplayer) end,
		Function = function(sender, text, log, glog)
			if(table.Count(text) < 1) then
				log(Vermilion:TranslateStr("bad_syntax", nil, sender), NOTIFY_ERROR)
				return false
			end
			local min = 0
			local max = 0
			if(table.Count(text) == 1) then
				max = tonumber(text[1])
			else
				min = tonumber(text[1])
				max = tonumber(text[2])
			end

			if(min == nil or max == nil) then
				log(Vermilion:TranslateStr("not_number", nil, sender), NOTIFY_ERROR)
				return false
			end

			log(MODULE:TranslateStr("random", { tostring(math.random(min, max)) }, sender))
		end
	})

	Vermilion:AddChatCommand({
		Name = "suicide",
		Description = "Kills the player that sends the command.",
		Permissions = { "suicide" },
		CanMute = true,
		CanRunOnDS = false,
		Function = function(sender, text, log, glog, tglog)
			sender:Kill()
			tglog("commands:suicide", { sender:GetName() })
		end
	})

	Vermilion:AddChatCommand({
		Name = "lockplayer",
		Description = "Prevents a player from moving.",
		Syntax = function(vplayer) return MODULE:TranslateStr("cmd:lockplayer:syntax", nil, vplayer) end,
		BasicParameters = {
			{ Type = Vermilion.ChatCommandConst.MultiPlayerArg }
		},
		Category = "Fun",
		CommandFormat = "\"%s\"",
		CanMute = true,
		Permissions = { "lock_player" },
		AllValid = {
			{ Size = 1, Indexes = { 1 } }
		},
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchPlayerPart(current)
			end
		end,
		Function = function(sender, text, log, glog, tglog)
			if(table.Count(text) < 1) then
				log(Vermilion:TranslateStr("bad_syntax", nil, sender), NOTIFY_ERROR)
				return false
			end
			local tplayer = VToolkit.LookupPlayer(text[1])
			if(not IsValid(tplayer)) then
				log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
				return
			end
			if(Vermilion:GetUser(tplayer):IsImmune(sender)) then
				log(Vermilion:TranslateStr("player_immune", { tplayer:GetName() }, sender), NOTIFY_ERROR)
				return
			end
			tplayer:Lock()
			tglog("commands:lockplayer", { tplayer:GetName(), sender:GetName() })
		end,
		AllBroadcast = function(sender, text, forplayer)
			return MODULE:TranslateStr("lockplayer:all", { sender:GetName() }, forplayer)
		end
	})

	Vermilion:AddChatCommand({
		Name = "unlockplayer",
		Description = "Allows a player to move again after using !lockplayer",
		Syntax = function(vplayer) return MODULE:TranslateStr("cmd:unlockplayer:syntax", nil, vplayer) end,
		BasicParameters = {
			{ Type = Vermilion.ChatCommandConst.MultiPlayerArg }
		},
		Category = "Fun",
		CommandFormat = "\"%s\"",
		CanMute = true,
		Permissions = { "unlock_player" },
		AllValid = {
			{ Size = 1, Indexes = { 1 } }
		},
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchPlayerPart(current)
			end
		end,
		Function = function(sender, text, log, glog, tglog)
			if(table.Count(text) < 1) then
				log(Vermilion:TranslateStr("bad_syntax", nil, sender), NOTIFY_ERROR)
				return false
			end
			local tplayer = VToolkit.LookupPlayer(text[1])
			if(not IsValid(tplayer)) then
				log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
				return
			end
			if(Vermilion:GetUser(tplayer):IsImmune(sender)) then
				log(Vermilion:TranslateStr("player_immune", { tplayer:GetName() }, sender), NOTIFY_ERROR)
				return
			end
			tplayer:UnLock()
			tglog("commands:unlockplayer", { tplayer:GetName(), sender:GetName() })
		end,
		AllBroadcast = function(sender, text, forplayer)
			return MODULE:TranslateStr("unlockplayer:all", { sender:GetName() }, forplayer)
		end
	})

	Vermilion:AddChatCommand({
		Name = "kill",
		Description = "Kills a player.",
		Syntax = function(vplayer) return MODULE:TranslateStr("cmd:kill:syntax", nil, vplayer) end,
		BasicParameters = {
			{ Type = Vermilion.ChatCommandConst.MultiPlayerArg }
		},
		Category = "Fun",
		CommandFormat = "\"%s\"",
		CanMute = true,
		Permissions = { "kill_player" },
		AllValid = {
			{ Size = 1, Indexes = { 1 } }
		},
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchPlayerPart(current)
			end
		end,
		Function = function(sender, text, log, glog, tglog)
			if(table.Count(text) < 1) then
				log(Vermilion:TranslateStr("bad_syntax", nil, sender), NOTIFY_ERROR)
				return false
			end
			local tplayer = VToolkit.LookupPlayer(text[1])
			if(not IsValid(tplayer)) then
				log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
				return
			end
			if(Vermilion:GetUser(tplayer):IsImmune(sender)) then
				log(Vermilion:TranslateStr("player_immune", { tplayer:GetName() }, sender), NOTIFY_ERROR)
				return
			end
			tplayer:Kill()
			tglog("commands:kill", { sender:GetName(), tplayer:GetName() })
		end,
		AllBroadcast = function(sender, text, forplayer)
			return MODULE:TranslateStr("kill:all", { sender:GetName() }, forplayer)
		end
	})

	Vermilion:AddChatCommand({
		Name = "assassinate",
		Description = "Kills a player silently.",
		Syntax = function(vplayer) return MODULE:TranslateStr("cmd:assassinate:syntax", nil, vplayer) end,
		BasicParameters = {
			{ Type = Vermilion.ChatCommandConst.MultiPlayerArg }
		},
		Category = "Fun",
		CommandFormat = "\"%s\"",
		Permissions = { "kill_player" },
		AllValid = {
			{ Size = 1, Indexes = { 1 } }
		},
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchPlayerPart(current)
			end
		end,
		Function = function(sender, text, log, glog, tglog)
			if(table.Count(text) < 1) then
				log(Vermilion:TranslateStr("bad_syntax", nil, sender), NOTIFY_ERROR)
				return false
			end
			local tplayer = VToolkit.LookupPlayer(text[1])
			if(not IsValid(tplayer)) then
				log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
				return
			end
			if(Vermilion:GetUser(tplayer):IsImmune(sender)) then
				log(Vermilion:TranslateStr("player_immune", { tplayer:GetName() }, sender), NOTIFY_ERROR)
				return
			end
			tplayer:KillSilent()
		end
	})

	Vermilion:AddChatCommand({
		Name = "ragdoll",
		Description = "Turns a player into a ragdoll.",
		Syntax = function(vplayer) return MODULE:TranslateStr("cmd:ragdoll:syntax", nil, vplayer) end,
		BasicParameters = {
			{ Type = Vermilion.ChatCommandConst.MultiPlayerArg }
		},
		Category = "Fun",
		CommandFormat = "\"%s\"",
		CanMute = true,
		Permissions = { "ragdoll_player" },
		AllValid = {
			{ Size = 1, Indexes = { 1 } }
		},
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchPlayerPart(current)
			end
		end,
		Function = function(sender, text, log, glog, tglog)
			if(table.Count(text) < 1) then
				log(Vermilion:TranslateStr("bad_syntax", nil, sender), NOTIFY_ERROR)
				return false
			end
			local tplayer = VToolkit.LookupPlayer(text[1])
			if(not IsValid(tplayer)) then
				log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
				return
			end
			if(Vermilion:GetUser(tplayer):IsImmune(sender)) then
				log(Vermilion:TranslateStr("player_immune", { tplayer:GetName() }, sender), NOTIFY_ERROR)
				return
			end
			if(tplayer:Vermilion2_DoRagdoll()) then
				tglog("commands:ragdoll:done", { sender:GetName(), tplayer:GetName() })
			end
		end,
		AllBroadcast = function(sender, text, forplayer)
			return MODULE:TranslateStr("ragdoll:done:all", { sender:GetName() }, forplayer)
		end
	})

	Vermilion:AddChatCommand({
		Name = "stripammo",
		Description = "Removes all ammo from a player.",
		Syntax = function(vplayer) return MODULE:TranslateStr("cmd:stripammo:syntax", nil, vplayer) end,
		BasicParameters = {
			{ Type = Vermilion.ChatCommandConst.MultiPlayerArg }
		},
		Category = "Fun",
		CommandFormat = "\"%s\"",
		CanMute = true,
		Permissions = { "strip_ammo" },
		AllValid = {
			{ Size = 1, Indexes = { 1 } }
		},
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchPlayerPart(current)
			end
		end,
		Function = function(sender, text, log, glog, tglog)
			if(table.Count(text) < 1) then
				log(Vermilion:TranslateStr("bad_syntax", nil, sender), NOTIFY_ERROR)
				return false
			end
			local tplayer = VToolkit.LookupPlayer(text[1])
			if(not IsValid(tplayer)) then
				log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
				return
			end
			if(Vermilion:GetUser(tplayer):IsImmune(sender)) then
				log(Vermilion:TranslateStr("player_immune", { tplayer:GetName() }, sender), NOTIFY_ERROR)
				return
			end
			tplayer:RemoveAllAmmo()
			tglog("commands:stripammo:done", { sender:GetName(), tplayer:GetName() })
		end,
		AllBroadcast = function(sender, text, forplayer)
			return MODULE:TranslateStr("stripammo:done:all", { sender:GetName() }, forplayer)
		end
	})

	Vermilion:AddChatCommand({
		Name = "flatten",
		Description = "Flattens a player with a heavy object.",
		Syntax = function(vplayer) return MODULE:TranslateStr("cmd:flatten:syntax", nil, vplayer) end,
		BasicParameters = {
			{ Type = Vermilion.ChatCommandConst.MultiPlayerArg }
		},
		Category = "Fun",
		CommandFormat = "\"%s\"",
		CanMute = true,
		Permissions = { "flatten" },
		AllValid = {
			{ Size = 1, Indexes = { 1 } }
		},
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchPlayerPart(current)
			end
		end,
		Function = function(sender, text, log, glog, tglog)
			if(table.Count(text) < 1) then
				log(Vermilion:TranslateStr("bad_syntax", nil, sender), NOTIFY_ERROR)
				return false
			end
			local tplayer = VToolkit.LookupPlayer(text[1])
			if(not IsValid(tplayer)) then
				log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
				return
			end
			if(Vermilion:GetUser(tplayer):IsImmune(sender)) then
				log(Vermilion:TranslateStr("player_immune", { tplayer:GetName() }, sender), NOTIFY_ERROR)
				return
			end
			local loc = tplayer:GetPos()
			loc:Add(Vector(0, 0, 250))
			local model = "models/props_c17/column02a.mdl"
			local ent = ents.Create("prop_physics")
			tplayer:Freeze(true)
			timer.Simple(3, function()
				if(IsValid(tplayer)) then
					tplayer:Freeze(false)
				end
			end)
			ent:SetModel(model)
			ent:SetPos(loc)
			ent:SetAngles(Angle(0, 0, 0))
			ent:SetPhysicsAttacker(sender, 5)
			ent:Spawn()
			timer.Simple(5, function()
				if(IsValid(ent)) then ent:Remove() end
			end)
			tglog("commands:flatten:done", { sender:GetName(), tplayer:GetName() })
		end,
		AllBroadcast = function(sender, text, forplayer)
			return MODULE:TranslateStr("flatten:done:all", { sender:GetName() }, forplayer)
		end
	})

	Vermilion:AddChatCommand({
		Name = "launch",
		Description = "Throws a player into the air.",
		Syntax = function(vplayer) return MODULE:TranslateStr("cmd:launch:syntax", nil, vplayer) end,
		BasicParameters = {
			{ Type = Vermilion.ChatCommandConst.MultiPlayerArg }
		},
		Category = "Fun",
		CommandFormat = "\"%s\"",
		CanMute = true,
		Permissions = { "launch_player" },
		AllValid = {
			{ Size = 1, Indexes = { 1 } }
		},
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchPlayerPart(current)
			end
		end,
		Function = function(sender, text, log, glog, tglog)
			if(table.Count(text) < 1) then
				log(Vermilion:TranslateStr("bad_syntax", nil, sender), NOTIFY_ERROR)
				return false
			end
			local tplayer = VToolkit.LookupPlayer(text[1])
			if(not IsValid(tplayer)) then
				log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
				return
			end
			if(Vermilion:GetUser(tplayer):IsImmune(sender)) then
				log(Vermilion:TranslateStr("player_immune", { tplayer:GetName() }, sender), NOTIFY_ERROR)
				return
			end
			local phys = tplayer:GetPhysicsObject()
			if(IsValid(phys)) then phys:ApplyForceCenter(Vector(0, 0, -50000000)) end
			tglog("commands:launch:done", { sender:GetName(), tplayer:GetName() })
		end,
		AllBroadcast = function(sender, text, forplayer)
			return MODULE:TranslateStr("launch:done:all", { sender:GetName() }, forplayer)
		end
	})

	Vermilion:AddChatCommand({
		Name = "stripweapons",
		Description = "Removes all weapons from a player.",
		Syntax = function(vplayer) return MODULE:TranslateStr("cmd:stripweapons:syntax", nil, vplayer) end,
		BasicParameters = {
			{ Type = Vermilion.ChatCommandConst.MultiPlayerArg }
		},
		Category = "Fun",
		CommandFormat = "\"%s\"",
		CanMute = true,
		Permissions = { "strip_weapons" },
		AllValid = {
			{ Size = 1, Indexes = { 1 } }
		},
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchPlayerPart(current)
			end
		end,
		Function = function(sender, text, log, glog, tglog)
			if(table.Count(text) < 1) then
				log(Vermilion:TranslateStr("bad_syntax", nil, sender), NOTIFY_ERROR)
				return false
			end
			local tplayer = VToolkit.LookupPlayer(text[1])
			if(not IsValid(tplayer)) then
				log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
				return
			end
			if(Vermilion:GetUser(tplayer):IsImmune(sender)) then
				log(Vermilion:TranslateStr("player_immune", { tplayer:GetName() }, sender), NOTIFY_ERROR)
				return
			end
			tplayer:StripWeapons()
			tglog("commands:stripweapons:done", { sender:GetName(), tplayer:GetName() })
		end,
		AllBroadcast = function(sender, text, forplayer)
			return MODULE:TranslateStr("stripweapons:done:all", { sender:GetName() }, forplayer)
		end
	})

	Vermilion:AddChatCommand({
		Name = "health",
		Description = "Changes the health of a player.",
		Syntax = function(vplayer) return MODULE:TranslateStr("cmd:health:syntax", nil, vplayer) end,
		BasicParameters = {
			{ Type = Vermilion.ChatCommandConst.MultiPlayerArg },
			{ Type = Vermilion.ChatCommandConst.NumberRangeArg, Bounds = { Min = 0, Max = 100 }, Decimals = 0, InfoText = "Health" }
		},
		Category = "Fun",
		CommandFormat = "\"%s\" %s",
		CanMute = true,
		Permissions = { "set_health" },
		AllValid = {
			{ Size = 2, Indexes = { 1 } }
		},
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchPlayerPart(current)
			end
		end,
		Function = function(sender, text, log, glog, tglog)
			if(table.Count(text) < 1) then
				log(Vermilion:TranslateStr("bad_syntax", nil, sender), NOTIFY_ERROR)
				return false
			end
			local tplayer = VToolkit.LookupPlayer(text[1])
			if(not IsValid(tplayer)) then
				log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
				return
			end
			if(Vermilion:GetUser(tplayer):IsImmune(sender)) then
				log(Vermilion:TranslateStr("player_immune", { tplayer:GetName() }, sender), NOTIFY_ERROR)
				return
			end

			local health = nil
			if(table.Count(text) > 1) then
				health = tonumber(text[2])
			else
				health = tonumber(text[1])
			end

			if(health == nil) then
				log(Vermilion:TranslateStr("not_number", nil, sender), NOTIFY_ERROR)
				return false
			end

			tplayer:SetHealth(health)

			tglog("commands:health:done", { sender:GetName(), tplayer:GetName(), tostring(health) })
		end,
		AllBroadcast = function(sender, text, forplayer)
			return MODULE:TranslateStr("health:done:all", { sender:GetName(), text[2] }, forplayer)
		end
	})

	Vermilion:AddChatCommand({
		Name = "explode",
		Description = "Blows a player up.",
		Syntax = function(vplayer) return MODULE:TranslateStr("cmd:explode:syntax", nil, vplayer) end,
		BasicParameters = {
			{ Type = Vermilion.ChatCommandConst.MultiPlayerArg },
			{ Type = Vermilion.ChatCommandConst.NumberRangeArg, Bounds = { Min = 1, Max = 40 }, Decimals = 1, InfoText = "Magnitude" }
		},
		Category = "Fun",
		CommandFormat = "\"%s\" %s",
		CanMute = true,
		Permissions = { "explode" },
		AllValid = {
			{ Size = nil, Indexes = { 1 } }
		},
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchPlayerPart(current)
			end
		end,
		Function = function(sender, text, log, glog, tglog)
			if(table.Count(text) < 1) then
				log(Vermilion:TranslateStr("bad_syntax", nil, sender), NOTIFY_ERROR)
				return false
			end
			local tplayer = VToolkit.LookupPlayer(text[1])
			if(not IsValid(tplayer)) then
				log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
				return
			end
			if(Vermilion:GetUser(tplayer):IsImmune(sender)) then
				log(Vermilion:TranslateStr("player_immune", { tplayer:GetName() }, sender), NOTIFY_ERROR)
				return
			end
			local magnitude = 20
			if(table.Count(text) > 1) then
				magnitude = tonumber(text[2])
			end
			if(magnitude == nil or magnitude <= 0) then
				log(Vermilion:TranslateStr("not_number", nil, sender), NOTIFY_ERROR)
				return false
			end
			local explode = ents.Create("env_explosion")
			explode:SetPos(tplayer:GetPos())
			explode:Spawn()
			explode:SetKeyValue("iMagnitude", tostring(magnitude))
			explode:Fire("Explode", 0, 0)
			explode:EmitSound("weapon_AWP.Single", 400, 400)
			util.BlastDamage(explode, explode, explode:GetPos(), magnitude, 100)
			tglog("commands:explode:done", { sender:GetName(), tplayer:GetName() })
		end,
		AllBroadcast = function(sender, text, forplayer)
			return MODULE:TranslateStr("explode:done:all", { sender:GetName() }, forplayer)
		end
	})

	Vermilion:AddChatCommand({
		Name = "setteam",
		Description = "Assign a player to a team.",
		Syntax = function(vplayer) return MODULE:TranslateStr("cmd:setteam:syntax", nil, vplayer) end,
		CanMute = true,
		Permissions = { "set_team" },
		AllValid = {
			{ Size = nil, Indexes = { 1 } }
		},
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchPlayerPart(current)
			end
			if(pos == 2) then
				local tab = {}
				for i,k in pairs(team.GetAllTeams()) do
					if(string.find(string.lower(k.Name), string.lower(current)) and (k.Joinable or k.Name == "Unassigned")) then
						table.insert(tab, k.Name)
					end
				end
				return tab
			end
		end,
		Function = function(sender, text, log, glog, tglog)
			if(table.Count(text) < 2) then
				log(Vermilion:TranslateStr("bad_syntax", nil, sender), NOTIFY_ERROR)
				return false
			end
			local target = VToolkit.LookupPlayer(text[1])
			if(not IsValid(target)) then
				log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
				return
			end
			if(Vermilion:GetUser(target):IsImmune(sender)) then
				log(Vermilion:TranslateStr("player_immune", { target:GetName() }, sender), NOTIFY_ERROR)
				return
			end
			local teamid = nil
			local possibleTeams = {}
			for i,k in pairs(team.GetAllTeams()) do
				if(string.find(string.lower(k.Name), string.lower(text[2])) and (k.Joinable or k.Name == "Unassigned")) then
					table.insert(possibleTeams, i)
				end
			end
			if(table.Count(possibleTeams) > 1) then
				log(MODULE:TranslateStr("setteam:amb", nil, sender), NOTIFY_ERROR)
				return false
			end
			if(table.Count(possibleTeams) < 1) then
				log(MODULE:TranslateStr("setteam:nores", nil, sender), NOTIFY_ERROR)
				return false
			end
			teamid = possibleTeams[1]
			target:SetTeam(teamid)
			tglog("commands:setteam:done", { sender:GetName(), target:GetName(), team.GetName(teamid) })
		end,
		AllBroadcast = function(sender, text, forplayer)
			local teamid = nil
			local possibleTeams = {}
			for i,k in pairs(team.GetAllTeams()) do
				if(string.find(string.lower(k.Name), string.lower(text[2])) and (k.Joinable or k.Name == "Unassigned")) then
					table.insert(possibleTeams, i)
				end
			end
			if(table.Count(possibleTeams) > 1) then
				return false
			end
			if(table.Count(possibleTeams) < 1) then
				return false
			end
			teamid = possibleTeams[1]
			return MODULE:TranslateStr("setteam:done:all", { sender:GetName(), team.GetName(teamid) }, forplayer)
		end
	})

	Vermilion:AddChatCommand({
		Name = "slap",
		Description = "Hits a player repeatedly.",
		Syntax = function(vplayer) return MODULE:TranslateStr("cmd:slap:syntax", nil, vplayer) end,
		BasicParameters = {
			{ Type = Vermilion.ChatCommandConst.MultiPlayerArg },
			{ Type = Vermilion.ChatCommandConst.NumberRangeArg, Bounds = { Min = 0, Max = 100 }, Decimals = 0, InfoText = "Times" },
			{ Type = Vermilion.ChatCommandConst.NumberRangeArg, Bounds = { Min = 0, Max = 100 }, Decimals = 0, InfoText = "Damage" }
		},
		Category = "Fun",
		CommandFormat = "\"%s\" %s %s",
		CanMute = true,
		Permissions = { "slap" },
		AllValid = {
			{ Size = 3, Indexes = { 1 } }
		},
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchPlayerPart(current)
			end
		end,
		Function = function(sender, text, log, glog, tglog)
			if(table.Count(text) < 3) then
				log(Vermilion:TranslateStr("bad_syntax", nil, sender), NOTIFY_ERROR)
				return false
			end
			local tplayer = VToolkit.LookupPlayer(text[1])
			if(not IsValid(tplayer)) then
				log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
				return
			end
			if(Vermilion:GetUser(tplayer):IsImmune(sender)) then
				log(Vermilion:TranslateStr("player_immune", { tplayer:GetName() }, sender), NOTIFY_ERROR)
				return
			end
			local times = tonumber(text[2])
			local damage = tonumber(text[3])

			if(times == nil or damage == nil) then
				log(Vermilion:TranslateStr("not_number", nil, sender), NOTIFY_ERROR)
				return false
			end

			timer.Create("Slap" .. tplayer:GetName() .. tostring(RealTime()), 1, times, function()
				if(IsValid(tplayer)) then
					local dmg = DamageInfo()
					dmg:SetDamage(damage)
					dmg:SetDamageType(DMG_SLASH)
					dmg:SetAttacker(sender)
					local f = Vector(math.Rand(-850, 850), math.Rand(-850, 850), math.Rand(-150, 800))
					dmg:SetDamageForce(f)
					tplayer:TakeDamageInfo(dmg)
					tplayer:SetVelocity(f)
				end
			end)

			tglog("commands:slap:done", { sender:GetName(), tplayer:GetName(), tostring(times) })
		end,
		AllBroadcast = function(sender, text, forplayer)
			return MODULE:TranslateStr("slap:done:all", { sender:GetName(), text[2] }, forplayer)
		end
	})

	Vermilion:AddChatCommand({
		Name = "adminchat",
		Description = "Sends a message to all currently connected admins.",
		Syntax = function(vplayer) return MODULE:TranslateStr("cmd:adminchat:syntax", nil, vplayer) end,
		BasicParameters = {
			{ Type = Vermilion.ChatCommandConst.StringArg }
		},
		Category = "Chat",
		CommandFormat = "%s",
		CanMute = true,
		Permissions = { "admin_chat" },
		Function = function(sender, text, log, glog, tglog)
			if(table.Count(text) < 1) then
				log(Vermilion:TranslateStr("bad_syntax", nil, sender), NOTIFY_ERROR)
				return false
			end
			if(table.Count(Vermilion:GetUsersWithPermission("see_admin_chat")) == 0) then
				log(MODULE:TranslateStr("adminchat:noadmin", nil, sender), NOTIFY_HINT)
				return false
			end
			for i,k in pairs(Vermilion:GetUsersWithPermission("see_admin_chat")) do
				k:ChatPrint("[Vermilion - AdminChat] [" .. sender:GetName() .. "]: " .. table.concat(text, " "))
			end
			Vermilion.Log(sender:GetName() .. " sent admin message: " .. table.concat(text, " "))
			log(MODULE:TranslateStr("adminchat:sent", nil, sender))
		end
	})

	Vermilion:AliasChatCommand("adminchat", "asay")


	Vermilion:AddChatCommand({
		Name = "gimp",
		Description = "Prevents a player from using chat by making them say what the admin wants them to.",
		Syntax = function(vplayer) return MODULE:TranslateStr("cmd:gimp:syntax", nil, vplayer) end,
		BasicParameters = {
			{ Type = Vermilion.ChatCommandConst.MultiPlayerArg }
		},
		Category = "Chat",
		CommandFormat = "\"%s\"",
		Permissions = { "gimp" },
		AllValid = {
			{ Size = nil, Indexes = { 1 } }
		},
		CanMute = true,
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchPlayerPart(current)
			end
		end,
		Function = function(sender, text, log, glog, tglog)
			if(table.Count(text) < 1) then
				log(Vermilion:TranslateStr("bad_syntax", nil, sender), NOTIFY_ERROR)
				return false
			end
			local tplayer = VToolkit.LookupPlayer(text[1])
			if(not IsValid(tplayer)) then
				log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
				return
			end
			if(Vermilion:GetUser(tplayer):IsImmune(sender)) then
				log(Vermilion:TranslateStr("player_immune", { tplayer:GetName() }, sender), NOTIFY_ERROR)
				return
			end
			local gimpedPlayers = MODULE:GetData("gimped_players", {}, true)
			if(gimpedPlayers[tplayer:SteamID()]) then
				tglog("commands:gimp:ungimped:done", { sender:GetName(), tplayer:GetName() })
			else
				tglog("commands:gimp:gimped:done", { sender:GetName(), tplayer:GetName() })
				if(sender:SteamID() != "CONSOLE") then
					if(not Vermilion:GetUser(sender).GimpHelpNotified) then
						log(MODULE:TranslateStr("gimp:help", nil, sender), NOTIFY_HINT)
						Vermilion:GetUser(sender).GimpHelpNotified = true
					end
				else
					log(MODULE:TranslateStr("gimp:help", nil, sender), NOTIFY_HINT)
				end
			end
			gimpedPlayers[tplayer:SteamID()] = not gimpedPlayers[tplayer:SteamID()]
		end
	})

	Vermilion:AddChatCommand({
		Name = "mute",
		Description = "Stop a player from chatting completely.",
		Syntax = function(vplayer) return MODULE:TranslateStr("cmd:mute:syntax", nil, vplayer) end,
		BasicParameters = {
			{ Type = Vermilion.ChatCommandConst.MultiPlayerArg },
		},
		Category = "Chat",
		CommandFormat = "\"%s\"",
		Permissions = { "mute" },
		AllValid = {
			{ Size = nil, Indexes = { 1 } }
		},
		CanMute = true,
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchPlayerPart(current)
			end
		end,
		Function = function(sender, text, log, glog, tglog)
			if(table.Count(text) < 1) then
				log(Vermilion:TranslateStr("bad_syntax", nil, sender), NOTIFY_ERROR)
				return false
			end
			local tplayer = VToolkit.LookupPlayer(text[1])
			if(not IsValid(tplayer)) then
				log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
				return
			end
			if(Vermilion:GetUser(tplayer):IsImmune(sender)) then
				log(Vermilion:TranslateStr("player_immune", { tplayer:GetName() }, sender), NOTIFY_ERROR)
				return
			end
			local mutedPlayers = MODULE:GetData("muted_players", {}, true)
			if(mutedPlayers[tplayer:SteamID()]) then
				tglog("commands:mute:unmuted:done", { sender:GetName(), tplayer:GetName() })
			else
				tglog("commands:mute:muted:done", { sender:GetName(), tplayer:GetName() })
				if(sender:SteamID() != "CONSOLE") then
					if(not Vermilion:GetUser(sender).MuteHelpNotified) then
						log(MODULE:TranslateStr("mute:help", nil, sender), NOTIFY_HINT)
						Vermilion:GetUser(sender).MuteHelpNotified = true
					end
				else
					log(MODULE:TranslateStr("mute:help", nil, sender), NOTIFY_HINT)
				end
			end
			mutedPlayers[tplayer:SteamID()] = not mutedPlayers[tplayer:SteamID()]
		end
	})

	Vermilion:AddChatCommand({
		Name = "gag",
		Description = "Stop a player from using VoIP.",
		Syntax = function(vplayer) return MODULE:TranslateStr("cmd:gag:syntax", nil, vplayer) end,
		BasicParameters = {
			{ Type = Vermilion.ChatCommandConst.MultiPlayerArg },
		},
		Category = "Chat",
		CommandFormat = "\"%s\"",
		Permissions = { "gag" },
		AllValid = {
			{ Size = nil, Indexes = { 1 } }
		},
		CanMute = true,
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchPlayerPart(current)
			end
		end,
		Function = function(sender, text, log, glog, tglog)
			if(table.Count(text) < 1) then
				log(Vermilion:TranslateStr("bad_syntax", nil, sender), NOTIFY_ERROR)
				return false
			end
			local tplayer = VToolkit.LookupPlayer(text[1])
			if(not IsValid(tplayer)) then
				log(Vermilion:TranslateStr("no_users", nil, sender), NOTIFY_ERROR)
				return
			end
			if(Vermilion:GetUser(tplayer):IsImmune(sender)) then
				log(Vermilion:TranslateStr("player_immune", { tplayer:GetName() }, sender), NOTIFY_ERROR)
				return
			end
			local gaggedPlayers = MODULE:GetData("gagged_players", {}, true)
			if(gaggedPlayers[tplayer:SteamID()]) then
				tglog("commands:gag:ungagged:done", { sender:GetName(), tplayer:GetName() })
			else
				tglog("commands:gag:gagged:done", { sender:GetName(), tplayer:GetName() })
				if(sender:SteamID() != "CONSOLE") then
					if(not Vermilion:GetUser(sender).GagHelpNotified) then
						log(MODULE:TranslateStr("gag:help", nil, sender), NOTIFY_HINT)
						Vermilion:GetUser(sender).GagHelpNotified = true
					end
				else
					log(MODULE:TranslateStr("gag:help", nil, sender), NOTIFY_HINT)
				end
			end
			gaggedPlayers[tplayer:SteamID()] = not gaggedPlayers[tplayer:SteamID()]
		end
	})

	--[[ Vermilion:AddChatCommand({
		Name = "setjailpos",
		Description = "Set the new jail position.",
		Permissions = { "jail", "setjailpos" },
		CanMute = true,
		CanRunOnDS = false,
		Function = function(sender, text, log, glog, tglog)
			if(not util.IsInWorld(sender:GetPos())) then
				log(MODULE:TranslateStr("setjailpos:world", nil, sender), NOTIFY_ERROR)
				return
			end
			local pos = sender:GetPos()
			MODULE:SetData("jailpos", pos)
			tglog("commands:setjailpos:done", { sender:GetName(), table.concat({ math.Round(pos.x), math.Round(pos.y), math.Round(pos.z) }, ":") })
		end
	}) ]]


end

function MODULE:InitServer()

	

	self:AddHook("VPlayerSay", function(vplayer)
		if(MODULE:GetData("muted_players", {}, true)[vplayer:SteamID()]) then return "" end
		if(MODULE:GetData("gimped_players", {}, true)[vplayer:SteamID()]) then
			return table.Random(MODULE:GetData("gimps", MODULE.DefaultGimps, true))
		end
	end)

	self:AddHook("PlayerCanHearPlayersVoice", function(listener, talker)
		if(not IsValid(talker)) then return end
		if(MODULE:GetData("gagged_players", {}, true)[talker:SteamID()]) then return false end
	end)

	self:NetHook("VGetGimpList", function(vplayer)
		MODULE:NetStart("VGetGimpList")
		net.WriteTable(MODULE:GetData("gimps", MODULE.DefaultGimps, true))
		net.Send(vplayer)
	end)

	self:NetHook("VAddGimp", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "edit_gimps")) then
			local gimp = net.ReadString()
			if(not table.HasValue(MODULE:GetData("gimps", MODULE.DefaultGimps, true), gimp)) then
				table.insert(MODULE:GetData("gimps", MODULE.DefaultGimps, true), gimp)
			end
		end
	end)

	self:NetHook("VEditGimp", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "edit_gimps")) then
			local oldGimp = net.ReadString()
			local newGimp = net.ReadString()
			if(table.HasValue(MODULE:GetData("gimps", MODULE.DefaultGimps, true), gimp) and not table.HasValue(MODULE:GetData("gimps", MODULE.DefaultGimps, true), newGimp)) then
				MODULE:GetData("gimps", MODULE.DefaultGimps, true)[table.KeyFromValue(oldGimp)] = newGimp
			end
		end
	end)

	self:NetHook("VRemoveGimp", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "edit_gimps")) then
			MODULE:GetData("gimps", MODULE.DefaultGimps, true)[net.ReadInt(32)] = nil
		end
	end)

end

function MODULE:InitClient()

	self:NetHook("VGetGimpList", function()
		local paneldata = Vermilion.Menu.Pages["gimps"]

		paneldata.MessageTable:Clear()
		for i,k in pairs(net.ReadTable()) do
			paneldata.MessageTable:AddLine(k)
		end
	end)

	Vermilion.Menu:AddCategory("player", 4)

	Vermilion.Menu:AddPage({
		ID = "gimps",
		Name = Vermilion:TranslateStr("menu:gimps"),
		Order = 7,
		Category = "player",
		Size = { 785, 540 },
		Conditional = function(vplayer)
			return Vermilion:HasPermission("edit_gimps")
		end,
		Builder = function(panel, paneldata)
			local listings = VToolkit:CreateList({
				cols = MODULE:TranslateTable({ "gimps:list:text" }),
				multiselect = false
			})
			listings:SetPos(10, 30)
			listings:SetSize(765, 460)
			listings:SetParent(panel)

			paneldata.MessageTable = listings

			local listingsLabel = VToolkit:CreateHeaderLabel(listings, MODULE:TranslateStr("gimps:list:title"))
			listingsLabel:SetParent(panel)

			local removeListing = VToolkit:CreateButton(MODULE:TranslateStr("gimps:remove"), function()
				if(table.Count(listings:GetSelected()) == 0) then
					VToolkit:CreateErrorDialog(MODULE:TranslateStr("gimps:remove:g1"))
					return
				end
				local tab = {}
				local rtab = {}
				for i,k in pairs(listings:GetLines()) do
					local add = true
					for i1,k1 in pairs(listings:GetSelected()) do
						if(k1 == k) then add = false break end
					end
					if(add) then
						table.insert(tab, { k:GetValue(1) })
					else
						table.insert(rtab, i)
					end
				end
				for i,k in pairs(rtab) do
					MODULE:NetStart("VRemoveGimp")
					net.WriteInt(k, 32)
					net.SendToServer()
				end

				listings:Clear()
				for i,k in pairs(tab) do
					listings:AddLine(k[1])
				end
			end)
			removeListing:SetPos(670, 500)
			removeListing:SetSize(105, 30)
			removeListing:SetParent(panel)




			local addMessagePanel = VToolkit:CreateRightDrawer(panel)
			paneldata.AddMessagePanel = addMessagePanel

			local addMessageButton = VToolkit:CreateButton(MODULE:TranslateStr("gimps:new"), function()
				addMessagePanel:Open()
			end)
			addMessageButton:SetPos(10, 500)
			addMessageButton:SetSize(105, 30)
			addMessageButton:SetParent(panel)


			local messageBox = VToolkit:CreateTextbox("")
			messageBox:SetPos(10, 40)
			messageBox:SetSize(425, 410)
			messageBox:SetParent(addMessagePanel)
			messageBox:SetMultiline(true)
			messageBox:SetEnterAllowed(false)

			local addListingButton = VToolkit:CreateButton(MODULE:TranslateStr("gimps:new:add"), function()

				if(string.find(messageBox:GetValue(), "\n")) then
					VToolkit:CreateErrorDialog(MODULE:TranslateStr("gimps:newlines"))
					return
				end

				local ln = listings:AddLine(messageBox:GetValue())

				MODULE:NetStart("VAddGimp")
				net.WriteString(ln:GetValue(1))
				net.SendToServer()

				messageBox:SetValue("")
				addMessagePanel:Close()
			end)
			addListingButton:SetPos(326, 495)
			addListingButton:SetSize(105, 30)
			addListingButton:SetParent(addMessagePanel)
		end,
		OnOpen = function(panel, paneldata)
			MODULE:NetCommand("VGetGimpList")
			paneldata.AddMessagePanel:Close()
		end
	})

end
