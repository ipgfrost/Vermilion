--[[
 Copyright 2014 Ned Hyett

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

local EXTENSION = Vermilion:MakeExtensionBase()
EXTENSION.Name = "Helpful commands"
EXTENSION.ID = "helpcommands"
EXTENSION.Description = "Provides commands that aid players instead of punishing them"
EXTENSION.Author = "Ned"
EXTENSION.Permissions = {
	"teleport",
	"conditional_teleport",
	"speed",
	"respawn",
	"private_message",
	"afk",
	"get_position",
	"sudo",
	"spectate",
	"identity_fraud",
	"vanish",
	"goto",
	"bring",
	"tppos",
	"steamid_others",
	"setspawn",
	"unsetspawn",
	"timescale",
	"stripweapons",
	"ignite",
	"extinguish",
	"kick_vehicle",
	"decals",
	"armour",
	"frags",
	"deaths",
	"convar",
	"ping"
}
EXTENSION.PermissionDefinitions = {
	["teleport"] = "This player is allowed to use the teleport command.",
	["goto"] = "This player is allowed to use the goto command.",
	["bring"] = "This player is allowed to use the bring command.",
	["tppos"] = "This player is allowed to use the tppos command.",
	["conditional_teleport"] = "This player is allowed to use the conditional teleport commands (tpquery, tpaccept, tpdeny).",
	["speed"] = "This player is allowed to use the speed command.",
	["respawn"] = "This player is allowed to use the respawn command.",
	["private_message"] = "This player is allowed to use the private message commands (pm, r).",
	["afk"] = "This player is allowed to use the AFK command.",
	["get_position"] = "This player is allowed to use the getpos command.",
	["sudo"] = "This player is allowed to use the sudo command. This command is dangerous because it allows the user to execute any other command as another player, using the rights of the other player. This means that if a normal user were to sudo an owner, they would be able to do anything they wanted.",
	["spectate"] = "This player can use the spectate and unspectate commands.",
	["identity_fraud"] = "This player can use the identityfraud command.",
	["vanish"] = "This player can use the vanish command.",
	["steamid_others"] = "This player can use the steamid command to obtain the SteamID for other players.",
	["setspawn"] = "This player can use the setspawn command to set the world spawnpoint.",
	["unsetspawn"] = "This player can use the unsetspawn command to reset the world spawnpoint.",
	["timescale"] = "This player can use the timescale command to change the server tick timescale.",
	["stripweapons"] = "This player can use the stripweapons chat command.",
	["ignite"] = "This player can use the ignite chat command.",
	["extinguish"] = "This player can use the extinguish chat command.",
	["kick_vehicle"] = "This player can use the kick_vehicle chat command.",
	["decals"] = "This player can use the decals chat command.",
	["armour"] = "This player can use the armour chat command.",
	["frags"] = "This player can use the frags chat command.",
	["deaths"] = "This player can use the deaths chat command.",
	["convar"] = "This player can use the convar chat command.",
	["ping"] = "This player can use the ping command to get the ping of other players."
}

EXTENSION.TeleportRequests = {}
EXTENSION.PrivateMessageHistory = {}
EXTENSION.AFKPlayers = {}

function EXTENSION:InitServer()

	Vermilion:AddChatCommand("timescale", function(sender, text, log)
		if(Vermilion:HasPermissionError(sender, "timescale", log)) then
			if(table.Count(text) < 1) then
				log("Syntax: !timescale <factor> (where 1 is default)", VERMILION_NOTIFY_ERROR)
				return
			end
			local res = tonumber(text[1])
			if(res == nil) then
				log("That isn't a number!", VERMILION_NOTIFY_ERROR)
				return
			end
			if(res <= 0) then
				log("Can't set the timescale to 0!", VERMILION_NOTIFY_ERROR)
				return
			end
			Vermilion:BroadcastNotify("Server timescale set to " .. tostring(res) .. "x speed!")
			Vermilion.Log({
				Vermilion.Colours.Blue,
				sender:GetName(),
				Vermilion.Colours.White,
				" set the server timescale to ",
				Vermilion.Colours.Red,
				res,
				"x",
				Vermilion.Colours.White,
				" speed."
			})
			RunConsoleCommand("host_timescale", res)
		end
	end, "<factor> (where 1 is default)")

	Vermilion:AddChatCommand("setspawn", function(sender, text, log)
		if(not Vermilion:HasPermissionError(sender, "setspawn", log)) then return end
		EXTENSION:GetData("spawnpoints", {}, true)[game.GetMap()] = { Point = sender:GetPos(), Facing = sender:GetAngles() }
		log("Created spawnpoint.")
		Vermilion.Log({
			Vermilion.Colours.Blue,
			sender:GetName(),
			Vermilion.Colours.White,
			" set the server spawnpoint to ",
			Vermilion.Colours.Red,
			sender:GetPos()
		})
	end)
	
	Vermilion:AddChatCommand("togglespawn", function(sender, text, log)
		log("Feature incomplete.")
	end, "<true|false>")
	
	Vermilion:AddChatCommand("unsetspawn", function(sender, text, log)
		if(not Vermilion:HasPermissionError(sender, "unsetspawn", log)) then return end
		EXTENSION:GetData("spawnpoints", {}, true)[game.GetMap()] = nil
		log("Removed spawnpoint.")
		Vermilion.Log({
			Vermilion.Colours.Blue,
			sender:GetName(),
			Vermilion.Colours.White,
			" removed the server spawnpoint."
		})
	end)
	
	self:AddHook("PlayerSpawn", function(vplayer)
		if(EXTENSION:GetData("spawnpoints", {}, true)[game.GetMap()] != nil) then
			local sp = EXTENSION:GetData("spawnpoints", {}, true)[game.GetMap()]
			vplayer:SetPos(sp.Point)
			vplayer:SetEyeAngles(sp.Facing)
		end
	end)
	
	Vermilion:AddChatCommand("teleport", function(sender, text, log)
		if( not Vermilion:HasPermissionError(sender, "teleport", log) ) then
			return
		end
		if(table.Count(text) == 1) then
			text[2] = text[1]
			text[1] = sender:GetName()
		end
		if( table.Count(text) < 2 ) then
			log("Syntax: !teleport [player to move] <player to move to>")
			return
		end
		
		local tplayer = Crimson.LookupPlayerByName(text[1], false)
		local lplayer = Crimson.LookupPlayerByName(text[2], false)
		if(not IsValid(tplayer)) then
			log("Player to teleport does not exist", VERMILION_NOTIFY_ERROR)
			return
		end
		if(not IsValid(lplayer)) then
			log("Player to teleport to does not exist", VERMILION_NOTIFY_ERROR)
			return
		end

		local Target = lplayer:GetPos()
		Target:Add(Vector(0,0,90))

		tplayer:SetPos(Target)
		
		Vermilion.Log({
			Vermilion.Colours.Blue,
			sender:GetName(),
			Vermilion.Colours.White,
			" teleported ",
			Vermilion.Colours.Blue,
			tplayer:GetName(),
			Vermilion.Colours.White,
			" to ",
			Vermilion.Colours.Blue,
			lplayer:GetName()
		})
	end, "[player to move] <player to move to>")
	
	Vermilion:AliasChatCommand("tp", "teleport")
	
	Vermilion:AddChatPredictor("teleport", function(pos, current)
		if(pos < 3) then
			local tab = {}
			for i,k in pairs(player.GetAll()) do
				if(string.StartWith(string.lower(k:GetName()), string.lower(current))) then
					table.insert(tab, k:GetName())
				end
			end
			return tab
		end
	end)
	
	
	Vermilion:AddChatCommand("goto", function(sender, text, log)
		if(Vermilion:HasPermissionError(sender, "goto", log)) then
			if(table.Count(text) < 1) then
				log("Syntax: !goto <player to go to>")
				return
			end
			local tplayer = Crimson.LookupPlayerByName(text[1], false)
			if(not IsValid(tplayer)) then
				log(Vermilion.Lang.NoSuchPlayer, VERMILION_NOTIFY_ERROR)
				return
			end
			local target = tplayer:GetPos()
			target:Add(Vector(0, 0, 90))
			sender:SetPos(target)
			
			Vermilion.Log({
				Vermilion.Colours.Blue,
				sender:GetName(),
				Vermilion.Colours.White,
				" teleported to ",
				Vermilion.Colours.Blue,
				tplayer:GetName()
			})
		end
	end, "<player to go to>")
	
	Vermilion:AddChatPredictor("goto", function(pos, current)
		if(pos == 1) then
			local tab = {}
			for i,k in pairs(player.GetAll()) do
				if(string.StartWith(string.lower(k:GetName()), string.lower(current))) then
					table.insert(tab, k:GetName())
				end
			end
			return tab
		end
	end)
	
	
	Vermilion:AddChatCommand("bring", function(sender, text, log)
		if(Vermilion:HasPermissionError(sender, "bring", log)) then
			if(table.Count(text) < 1) then
				log("Syntax: !bring <player to bring>")
				return
			end
			local tplayer = Crimson.LookupPlayerByName(text[1], false)
			if(not IsValid(tplayer)) then
				log(Vermilion.Lang.NoSuchPlayer, VERMILION_NOTIFY_ERROR)
				return
			end
			local target = sender:GetPos()
			target:Add(Vector(0, 0, 90))
			tplayer:SetPos(target)
			
			Vermilion.Log({
				Vermilion.Colours.Blue,
				sender:GetName(),
				Vermilion.Colours.White,
				" brought ",
				Vermilion.Colours.Blue,
				tplayer:GetName(),
				Vermilion.Colours.White,
				" to themselves."
			})
		end
	end, "<player to bring>")
	
	Vermilion:AddChatPredictor("bring", function(pos, current)
		if(pos == 1) then
			local tab = {}
			for i,k in pairs(player.GetAll()) do
				if(string.StartWith(string.lower(k:GetName()), string.lower(current))) then
					table.insert(tab, k:GetName())
				end
			end
			return tab
		end
	end)
	
	
	Vermilion:AddChatCommand("tppos", function(sender, text, log)
		if(Vermilion:HasPermissionError(sender, "tppos", log)) then
			if(table.Count(text) < 3) then
				log("Syntax: !tppos [player] <x> <y> <z>")
				return
			end
			local tplayer = sender
			local x = 0
			local y = 0
			local z = 0
			if(table.Count(text) >= 4) then
				tplayer = Crimson.LookupPlayerByName(text[1], false)
				x = tonumber(text[2])
				y = tonumber(text[3])
				z = tonumber(text[4])
			else
				x = tonumber(text[1])
				y = tonumber(text[2])
				z = tonumber(text[3])
			end
			if(not IsValid(tplayer)) then
				log(Vermilion.Lang.NoSuchPlayer, VERMILION_NOTIFY_ERROR)
				return
			end
			if(x == nil or y == nil or z == nil) then
				log("That isn't a number.", VERMILION_NOTIFY_ERROR)
				return
			end
			if(not util.IsInWorld(Vector(x, y, z))) then
				log("Can't put the player in the void.", VERMILION_NOTIFY_ERROR)
				return
			end
			tplayer:SetPos(Vector(x, y, z))
			Vermilion.Log({
				Vermilion.Colours.Blue,
				sender:GetName(),
				Vermilion.Colours.White,
				" teleported ",
				Vermilion.Colours.Blue,
				tplayer:GetName(),
				Vermilion.Colours.White,
				" to ",
				Vermilion.Colours.Red,
				x,
				" ",
				y,
				" ",
				z
			})
		end
	end, "[player] <x> <y> <z>")
	
	Vermilion:AddChatPredictor("tppos", function(pos, current)
		if(pos == 1 and tonumber(current) == nil) then
			local tab = {}
			for i,k in pairs(player.GetAll()) do
				if(string.StartWith(string.lower(k:GetName()), string.lower(current))) then
					table.insert(tab, k:GetName())
				end
			end
			return tab
		end
	end)
	
	
	Vermilion:AddChatCommand("tpquery", function(sender, text, log)
		if(Vermilion:HasPermissionError(sender, "conditional_teleport")) then
			if(table.Count(text) < 1) then
				log("Syntax: !tpquery/tpq <player>")
				return
			end
			local tplayer = Crimson.LookupPlayerByName(text[1], false)
			if(not tplayer) then
				log(Vermilion.Lang.NoSuchPlayer, VERMILION_NOTIFY_ERROR)
				return
			end
			log("Sent request!")
			EXTENSION.TeleportRequests[sender:SteamID() .. tplayer:SteamID()] = false
			Vermilion:SendNotify(tplayer, sender:GetName() .. " is requesting to teleport to you...", 10)
		end
	end, "<player>")
	
	Vermilion:AliasChatCommand("tpq", "tpquery")
	
	Vermilion:AddChatPredictor("tpquery", function(pos, current)
		if(pos == 1) then
			local tab = {}
			for i,k in pairs(player.GetAll()) do
				if(string.StartWith(string.lower(k:GetName()), string.lower(current))) then
					table.insert(tab, k:GetName())
				end
			end
			return tab
		end
	end)
	
	
	Vermilion:AddChatCommand("tpaccept", function(sender, text, log)
		if(table.Count(text) < 1) then
			log("Syntax: !tpaccept/tpa <player>")
			return
		end
		local tplayer = Crimson.LookupPlayerByName(text[1], false)
		if(not tplayer) then
			log(Vermilion.Lang.NoSuchPlayer, VERMILION_NOTIFY_ERROR)
			return
		end
		if(EXTENSION.TeleportRequests[tplayer:SteamID() .. sender:SteamID()] == nil) then
			log("This player has not asked to teleport to you.", VERMILION_NOTIFY_ERROR)
			return
		end
		if(EXTENSION.TeleportRequests[tplayer:SteamID() .. sender:SteamID()] == true) then
			log("This player has already teleported to you and the ticket has been cancelled!", VERMILION_NOTIFY_ERROR)
			return
		end
		Vermilion:SendNotify({sender, tplayer}, "Request accepted! Teleporting in 10 seconds.")
		local sPos = sender:GetPos()
		local tPos = tplayer:GetPos()
		timer.Simple(10, function()
			if(sPos != sender:GetPos() or tPos != tplayer:GetPos()) then
				Vermilion:SendNotify({sender, tplayer}, "Someone moved. Teleportation cancelled!", VERMILION_NOTIFY_ERROR)
				EXTENSION.TeleportRequests[tplayer:SteamID() .. sender:SteamID()] = true
				return
			end
			Vermilion:SendNotify({sender, tplayer}, "Teleporting...")
			tplayer:SetPos(sender:GetPos() + Vector(0, 0, 90))
			EXTENSION.TeleportRequests[tplayer:SteamID() .. sender:SteamID()] = true
		end)
	end, "<player>")
	
	Vermilion:AliasChatCommand("tpa", "tpaccept")
	
	Vermilion:AddChatPredictor("tpaccept", function(pos, current)
		if(pos == 1) then
			local tab = {}
			for i,k in pairs(player.GetAll()) do
				if(string.StartWith(string.lower(k:GetName()), string.lower(current))) then
					table.insert(tab, k:GetName())
				end
			end
			return tab
		end
	end)
	
	
	Vermilion:AddChatCommand("tpdeny", function(sender, text, log)
		if(table.Count(text) < 1) then
			log("Syntax: !tpdeny/tpd <player>")
			return
		end
		local tplayer = Crimson.LookupPlayerByName(text[1], false)
		if(not tplayer) then
			log(Vermilion.Lang.NoSuchPlayer, VERMILION_NOTIFY_ERROR)
			return
		end
		if(EXTENSION.TeleportRequests[tplayer:SteamID() .. sender:SteamID()] == nil) then
			log("This player has not asked to teleport to you.", VERMILION_NOTIFY_ERROR)
			return
		end
		if(EXTENSION.TeleportRequests[tplayer:SteamID() .. sender:SteamID()] == false) then
			log("This player has already teleported to you and the ticket has been cancelled!", VERMILION_NOTIFY_ERROR)
			return
		end
		Vermilion:SendNotify({sender, tplayer}, "Request denied!")
		EXTENSION.TeleportRequests[tplayer:SteamID() .. sender:SteamID()] = true
	end, "<player>")
	
	Vermilion:AliasChatCommand("tpd", "tpdeny")
	
	Vermilion:AddChatPredictor("tpdeny", function(pos, current)
		if(pos == 1) then
			local tab = {}
			for i,k in pairs(player.GetAll()) do
				if(string.StartWith(string.lower(k:GetName()), string.lower(current))) then
					table.insert(tab, k:GetName())
				end
			end
			return tab
		end
	end)
	
	
	Vermilion:AddChatCommand("speed", function(sender, text, log)
		if(Vermilion:HasPermissionError(sender, "speed")) then
			if(table.Count(text) < 1) then
				log("Syntax: !speed <speed multiplier> [player]")
				return
			end
			local times = tonumber(text[1])
			if(times == nil) then
				log("That isn't a number!", VERMILION_NOTIFY_ERROR)
				return
			end
			local target = sender
			if(table.Count(text) > 1) then
				local tplayer = Crimson.LookupPlayerByName(text[2], false)
				if(tplayer == nil) then
					log(Vermilion.Lang.NoSuchPlayer, VERMILION_NOTIFY_ERROR)
					return
				end
				target = tplayer
			end
			local speed = math.abs(200 * times)
			GAMEMODE:SetPlayerSpeed(target, speed, speed * 2)
			log("Speed set!")
			Vermilion.Log({
				Vermilion.Colours.Blue,
				sender:GetName(),
				Vermilion.Colours.White,
				" has changed the speed of ",
				Vermilion.Colours.Blue,
				target:GetName(),
				Vermilion.Colours.White,
				" to ", 
				Vermilion.Colours.Red,
				times,
				"x",
				Vermilion.Colours.White,
				" normal speed."
			})
		end
	end, "<speed multiplier> [player]")
	
	Vermilion:AddChatPredictor("speed", function(pos, current)
		if(pos == 2) then
			local tab = {}
			for i,k in pairs(player.GetAll()) do
				if(string.StartWith(string.lower(k:GetName()), string.lower(current))) then
					table.insert(tab, k:GetName())
				end
			end
			return tab
		end
	end)
	
	
	Vermilion:AddChatCommand("respawn", function(sender, text, log)
		if(Vermilion:HasPermissionError(sender, "respawn")) then
			local target = sender
			if(table.Count(text) > 0) then
				local tplayer = Crimson.LookupPlayerByName(text[1], false)
				if(tplayer == nil) then
					log(Vermilion.Lang.NoSuchPlayer, VERMILION_NOTIFY_ERROR)
					return
				end
				target = tplayer
			end
			if(target != nil) then
				target:Spawn()
			end
			Vermilion.Log({
				Vermilion.Colours.Blue,
				sender:GetName(),
				Vermilion.Colours.White,
				" has forced ",
				Vermilion.Colours.Blue,
				target:GetName(),
				Vermilion.Colours.White,
				" to respawn"
			})
		end
	end, "[player]")
	
	Vermilion:AddChatPredictor("respawn", function(pos, current)
		if(pos == 1) then
			local tab = {}
			for i,k in pairs(player.GetAll()) do
				if(string.StartWith(string.lower(k:GetName()), string.lower(current))) then
					table.insert(tab, k:GetName())
				end
			end
			return tab
		end
	end)
	
	
	Vermilion:AddChatCommand("pm", function(sender, text, log)
		if(Vermilion:HasPermissionError(sender, "private_message")) then
			if(table.Count(text) > 1) then
				local tplayer = Crimson.LookupPlayerByName(text[1], false)
				if(tplayer == nil) then
					log(Vermilion.Lang.NoSuchPlayer, VERMILION_NOTIFY_ERROR)
					return
				end
				tplayer:ChatPrint("[Private] " .. sender:GetName() .. ": " .. table.concat(text, " ", 2))
				EXTENSION.PrivateMessageHistory[tplayer:SteamID()] = sender:GetName()
				Vermilion.Log({
					Vermilion.Colours.Blue,
					sender:GetName(),
					Vermilion.Colours.White,
					" has sent a private message to ",
					Vermilion.Colours.Blue,
					tplayer:GetName(),
					Vermilion.Colours.White,
					": ",
					Vermilion.Colours.Red,
					table.concat(text, " ", 2)
				})
			else
				log("Syntax: !pm <target> <message>", VERMILION_NOTIFY_ERROR)
			end
		end
	end, "<target> <message>")
	
	Vermilion:AddChatPredictor("pm", function(pos, current)
		if(pos == 1) then
			local tab = {}
			for i,k in pairs(player.GetAll()) do
				if(string.StartWith(string.lower(k:GetName()), string.lower(current))) then
					table.insert(tab, k:GetName())
				end
			end
			return tab
		end
	end)
	
	
	Vermilion:AddChatCommand("r", function(sender, text, log)
		if(Vermilion:HasPermissionError(sender, "private_message")) then
			if(table.Count(text) > 0) then
				local tplayer = Crimson.LookupPlayerByName(EXTENSION.PrivateMessageHistory[sender:SteamID()], false)
				if(tplayer == nil) then
					log("You haven't received a private message yet or the player has left the server!", VERMILION_NOTIFY_ERROR)
					return
				end
				tplayer:ChatPrint("[Private] " .. sender:GetName() .. ": " .. table.concat(text, " "))
				EXTENSION.PrivateMessageHistory[tplayer:SteamID()] = sender:GetName()
				Vermilion.Log({
					Vermilion.Colours.Blue,
					sender:GetName(),
					Vermilion.Colours.White,
					" has sent a private message to ",
					Vermilion.Colours.Blue,
					tplayer:GetName(),
					Vermilion.Colours.White,
					": ",
					Vermilion.Colours.Red,
					table.concat(text, " ")
				})
			else
				log("Syntax: !r <message>", VERMILION_NOTIFY_ERROR)
			end
		end
	end, "<message>")
	
	Vermilion:AddChatCommand("time", function(sender, text, log)
		log("The server time is: " .. os.date("%I:%M:%S %p on %d/%m/%Y"), 15)
	end)
	
	Vermilion:AddChatCommand("afk", function(sender, text, log)
		if(Vermilion:HasPermissionError(sender, "afk")) then
			Vermilion:BroadcastNotify(sender:GetName() .. " is now afk.")
			EXTENSION.AFKPlayers[sender:GetName()] = true
		end
	end)
	
	Vermilion:RegisterHook("PlayerButtonDown", function(vplayer)
		if(EXTENSION.AFKPlayers[vplayer:GetName()]) then
			EXTENSION.AFKPlayers[vplayer:GetName()] = false
			Vermilion:BroadcastNotify(sender:GetName() .. " is no longer afk.")
		end
	end)
	
	Vermilion:AddChatCommand("getpos", function(sender, text, log)
		if(table.Count(text) > 0) then
			if(Vermilion:HasPermissionError(sender, "get_position")) then
				local tplayer = Crimson.LookupPlayerByName(text[1], false)
				if(tplayer == nil) then
					log(Vermilion.Lang.NoSuchPlayer, VERMILION_NOTIFY_ERROR)
					return
				end
				log("The position of " .. text[1] .. " is " .. tostring(tplayer:GetPos()))
			end
		else
			log("Your position is " .. tostring(sender:GetPos()))
		end
	end, "[player]")
	
	Vermilion:AddChatPredictor("getpos", function(pos, current)
		if(pos == 1) then
			local tab = {}
			for i,k in pairs(player.GetAll()) do
				if(string.StartWith(string.lower(k:GetName()), string.lower(current))) then
					table.insert(tab, k:GetName())
				end
			end
			return tab
		end
	end)
	
	
	Vermilion:AddChatCommand("sudo", function(sender, text, log)
		if(Vermilion:HasPermissionError(sender, "sudo")) then
			if(table.Count(text) < 2) then
				log("Syntax: !sudo <player> <command>", VERMILION_NOTIFY_ERROR)
				return
			end
			local tplayer = Crimson.LookupPlayerByName(text[1], false)
			if(tplayer == nil) then
				log("Player does not exist!", VERMILION_NOTIFY_ERROR)
				return
			end
			local cmd = table.concat(text, " ", 2)
			if(not string.StartWith(cmd, "!")) then
				cmd = "!" .. cmd
			end
			Vermilion.Log({
					Vermilion.Colours.Blue,
					sender:GetName(),
					Vermilion.Colours.White,
					" has sudoed ",
					Vermilion.Colours.Blue,
					tplayer:GetName(),
					Vermilion.Colours.White,
					": ",
					Vermilion.Colours.Red,
					cmd
				})
			Vermilion:HandleChat(tplayer, cmd, log, false)
		end
	end, "<player> <command>")
	
	Vermilion:AddChatPredictor("sudo", function(pos, current)
		if(pos == 1) then
			local tab = {}
			for i,k in pairs(player.GetAll()) do
				if(string.StartWith(string.lower(k:GetName()), string.lower(current))) then
					table.insert(tab, k:GetName())
				end
			end
			return tab
		end
	end)
	
	Vermilion:AddChatCommand("spectate", function(sender, text, log)
		if(not IsValid(sender)) then
			log("Cannot use this command from the dedicated server console.")
			return
		end
		if(not Vermilion:HasPermissionError(sender, "spectate")) then
			return
		end
		if(text[1] == "-entity") then
			if(tonumber(text[2]) == nil) then
				log("That isn't a number!", VERMILION_NOTIFY_ERROR)
				return
			end
			local tent = ents.GetByIndex(tonumber(text[2]))
			if(IsValid(tent)) then
				if(string.StartWith(tent:GetClass(), "func_")) then
					log("You cannot spectate this entity!", VERMILION_NOTIFY_ERROR)
					return
				end
				log("You are now spectating " .. tent:GetClass())
				sender:Spectate( OBS_MODE_CHASE )
				sender:SpectateEntity( tent )
				sender:StripWeapons()
				sender.VSpectating = true
			else
				log("That isn't a valid entity.", VERMILION_NOTIFY_ERROR)
			end
		elseif(text[1] == "-player") then
			local tplayer = Crimson.LookupPlayerByName(text[2], false)
			if(tplayer == sender) then
				log("You cannot spectate yourself!", VERMILION_NOTIFY_ERROR)
				return
			end
			if(IsValid(tplayer)) then
				sender:Spectate( OBS_MODE_CHASE )
				sender:SpectateEntity( tplayer )
				sender:StripWeapons()
				sender.VSpectating = true
			else
				log(Vermilion.Lang.NoSuchPlayer, VERMILION_NOTIFY_ERROR)
			end
		else
			log("Invalid type!")
		end
	end, "[-entity <entityid>] [-player <name>]")
	
	local bannedClassses = {
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
		"phys_"
	}
	
	Vermilion:AddChatPredictor("spectate", function(pos, current, all)
		if(pos == 1) then
			return { "-entity", "-player" }
		end
		if(pos == 2 and all[1] == "-entity") then
			local tab = {}
			for i,k in pairs(ents.GetAll()) do
				local banned = false
				for i1,k1 in pairs(bannedClassses) do
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
			local tab = {}
			for i,k in pairs(player.GetAll()) do
				if(string.StartWith(string.lower(k:GetName()), string.lower(current))) then
					table.insert(tab, k:GetName())
				end
			end
			return tab
		end
	end)
	
	self:AddHook("EntityRemoved", function(ent)
		for i,k in pairs(player.GetAll()) do
			if(k.VSpectating == true and k:GetObserverTarget() == ent) then
				k:UnSpectate()
				k:Spawn()
				k.VSpectating = false
				Vermilion:SendNotify(k, "The entity you were spectating was removed.")
			end
		end
	end)
	
	
	Vermilion:AddChatCommand("unspectate", function(sender, text, log)
		if(not sender.VSpectating) then
			log("You aren't spectating anything...")
			return
		end
		sender:UnSpectate()
		sender:Spawn()
		sender.VSpectating = false
	end)
	
	Vermilion:AddChatCommand("identityfraud", function(sender, text, log)
		if(Vermilion:HasPermissionError(sender, "identity_fraud")) then
			if(table.Count(text) == 0) then
				if(sender.VIDFraudOriginalModel == nil) then
					log("You haven't disguised as anyone yet...")
					return
				end
				log("Resetting disguise...")
				Vermilion:UnForcePlayerModel(sender)
				sender:SetNWString("Vermilion_Fakename", "[Vermilion_NO_FAKENAME]")
				sender.VIDFraudOriginalModel = nil
				return
			end
			local tplayer = Crimson.LookupPlayerByName(text[1], false)
			if(IsValid(tplayer)) then
				sender.VIDFraudOriginalModel = sender:GetModel()
				Vermilion:ForcePlayerModel(sender, tplayer:GetModel())
				sender:SetNWString("Vermilion_Fakename", text[1])
			else
				log(Vermilion.Lang.NoSuchPlayer, VERMILION_NOTIFY_ERROR)
			end
		end
	end, "<player>")
	
	Vermilion:AddChatPredictor("identityfraud", function(pos, current)
		if(pos == 1) then
			local tab = {}
			for i,k in pairs(player.GetAll()) do
				if(string.StartWith(string.lower(k:GetName()), string.lower(current))) then
					table.insert(tab, k:GetName())
				end
			end
			return tab
		end
	end)
	
	
	Vermilion:AddChatCommand("vanish", function(sender, text, log)
		if(Vermilion:HasPermissionError(sender, "vanish")) then
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
	end)
	
	Vermilion:AddChatCommand("motd", function(sender, text, log)
		Vermilion:SendMOTD(sender)
	end)
	
	Vermilion:AddChatCommand("version", function(sender, text, log)
		log("This server is running Vermilion " .. Vermilion:GetVersion())
	end)
	
	Vermilion:AddChatCommand("steamid", function(sender, text, log)
		if(table.Count(text) == 0) then
			log("Your SteamID is " .. tostring(sender:SteamID()))
		else
			if(Vermilion:HasPermissionError(vplayer, "steamid_others")) then
				local tplayer = Crimson.LookupPlayerByName(text[1], false)
				if(IsValid(tplayer)) then
					log(tplayer:GetName() .. "'s SteamID is " .. tostring(tplayer:SteamID()))
				else
					log(Vermilion.Lang.NoSuchPlayer, VERMILION_NOTIFY_ERROR)
				end
			end
		end
	end, "[player]")
	
	Vermilion:AddChatPredictor("steamid", function(pos, current)
		if(pos == 1) then
			local tab = {}
			for i,k in pairs(player.GetAll()) do
				if(string.StartWith(string.lower(k:GetName()), string.lower(current))) then
					table.insert(tab, k:GetName())
				end
			end
			return tab
		end
	end)
	
	
	Vermilion:AddChatCommand("ping", function(sender, text, log)
		if(table.Count(text) == 0) then
			log("Your ping is " .. tostring(sender:Ping()) .. "ms")
		else
			local tplayer = Crimson.LookupPlayerByName(text[1], false)
			if(IsValid(tplayer)) then
				log(tplayer:GetName() .. "'s ping is " .. tostring(tplayer:Ping()) .. "ms")
			else
				log(Vermilion.Lang.NoSuchPlayer, VERMILION_NOTIFY_ERROR)
			end
		end
	end, "[player]")
	
	Vermilion:AddChatPredictor("ping", function(pos, current)
		if(pos == 1) then
			local tab = {}
			for i,k in pairs(player.GetAll()) do
				if(string.StartWith(string.lower(k:GetName()), string.lower(current))) then
					table.insert(tab, k:GetName())
				end
			end
			return tab
		end
	end)
	
	local allowed = {
		"gm_",
		"sbox_",
		"sv_"
	}
	
	Vermilion:AddChatCommand("convar", function(sender, text, log)
		if(not Vermilion:HasPermissionError(sender, "convar", log)) then return end
		if(table.Count(text) == 1) then
			if(not ConVarExists(text[1])) then
				log("This convar doesn't exist!", VERMILION_NOTIFY_ERROR)
			else
				log(text[1] .. " is set to " .. cvars.String(text[1]))
			end
		elseif(table.Count(text) > 1) then
			if(ConVarExists(text[1])) then
				local allowed = false
				for i,k in pairs(allowed) do
					if(string.StartWith(text[1], k)) then
						allowed = true
						break
					end
				end
				if(not allowed) then
					log("Cannot set the value of this convar.", VERMILION_NOTIFY_ERROR)
					return
				end
				RunConsoleCommand(text[1], text[2])
				log(text[1] .. " was set to " .. text[2])
			else
				log("This convar doesn't exist!", VERMILION_NOTIFY_ERROR)
			end
		end
	end, "<cvar> [value]")
	
	Vermilion:AddChatCommand("deaths", function(sender, text, log)
		if(Vermilion:HasPermissionError(sender, "set_deaths", log)) then
			if(table.Count(text) < 2) then
				log("Syntax: !deaths <player> <deaths>", VERMILION_NOTIFY_ERROR)
				return
			end
			local tplayer = Crimson.LookupPlayerByName(text[1], false)
			if(IsValid(tplayer)) then
				local result = tonumber(text[2])
				if(result == nil) then
					log("That isn't a number!", VERMILION_NOTIFY_ERROR)
					return
				end
				tplayer:SetDeaths(result)
				log("Set " .. text[1] .. "'s death count to " .. text[2])
			else
				log(Vermilion.Lang.NoSuchPlayer, VERMILION_NOTIFY_ERROR)
			end
		end
	end, "<player> <deaths>")
	
	Vermilion:AddChatPredictor("deaths", function(pos, current)
		if(pos == 1) then
			local tab = {}
			for i,k in pairs(player.GetAll()) do
				if(string.StartWith(string.lower(k:GetName()), string.lower(current))) then
					table.insert(tab, k:GetName())
				end
			end
			return tab
		end
	end)
	
	Vermilion:AddChatCommand("frags", function(sender, text, log)
		if(Vermilion:HasPermissionError(sender, "set_frags", log)) then
			if(table.Count(text) < 2) then
				log("Syntax: !frags <player> <frags>", VERMILION_NOTIFY_ERROR)
				return
			end
			local tplayer = Crimson.LookupPlayerByName(text[1], false)
			if(IsValid(tplayer)) then
				local result = tonumber(text[2])
				if(result == nil) then
					log("That isn't a number!", VERMILION_NOTIFY_ERROR)
					return
				end
				tplayer:SetFrags(result)
				log("Set " .. text[1] .. "'s frag count to " .. text[2])
			else
				log(Vermilion.Lang.NoSuchPlayer, VERMILION_NOTIFY_ERROR)
			end
		end
	end, "<player> <frags>")
	
	Vermilion:AddChatPredictor("frags", function(pos, current)
		if(pos == 1) then
			local tab = {}
			for i,k in pairs(player.GetAll()) do
				if(string.StartWith(string.lower(k:GetName()), string.lower(current))) then
					table.insert(tab, k:GetName())
				end
			end
			return tab
		end
	end)
	
	Vermilion:AddChatCommand("armour", function(sender, text, log)
		if(Vermilion:HasPermissionError(sender, "set_armour", log)) then
			if(table.Count(text) < 2) then
				log("Syntax: !armour <player> <armour>", VERMILION_NOTIFY_ERROR)
				return
			end
			local tplayer = Crimson.LookupPlayerByName(text[1], false)
			if(IsValid(tplayer)) then
				local result = tonumber(text[2])
				if(result == nil) then
					log("That isn't a number!", VERMILION_NOTIFY_ERROR)
					return
				end
				tplayer:SetArmor(result)
				log("Set " .. text[1] .. "'s armour to " .. text[2])
			else
				log(Vermilion.Lang.NoSuchPlayer, VERMILION_NOTIFY_ERROR)
			end
		end
	end, "<player> <arnour>")
	
	Vermilion:AddChatPredictor("armour", function(pos, current)
		if(pos == 1) then
			local tab = {}
			for i,k in pairs(player.GetAll()) do
				if(string.StartWith(string.lower(k:GetName()), string.lower(current))) then
					table.insert(tab, k:GetName())
				end
			end
			return tab
		end
	end)
	
	Vermilion:AddChatCommand("decals", function(sender, text, log)
		if(Vermilion:HasPermissionError(sender, "clear_decals", log)) then
			for i,k in pairs(player.GetAll()) do
				k:ConCommand("r_cleardecals")
			end
			Vermilion:BroadcastNotify(sender:GetName() .. " cleared up the decals.")
		end
	end)
	
	Vermilion:AddChatCommand("kick_vehicle", function(sender, text, log)
		if(Vermilion:HasPermissionError(sender, "kick_vehicle", log)) then
			if(table.Count(text) < 1) then
				log("Syntax: !kick_vehicle <player>", VERMILION_NOTIFY_ERROR)
				return
			end
			local tplayer = Crimson.LookupPlayerByName(text[1], false)
			if(IsValid(tplayer)) then
				tplayer:ExitVehicle()				
			else
				log(Vermilion.Lang.NoSuchPlayer, VERMILION_NOTIFY_ERROR)
			end
		end
	end, "<player>")
	
	Vermilion:AddChatPredictor("kick_vehicle", function(pos, current)
		if(pos == 1) then
			local tab = {}
			for i,k in pairs(player.GetAll()) do
				if(string.StartWith(string.lower(k:GetName()), string.lower(current))) then
					table.insert(tab, k:GetName())
				end
			end
			return tab
		end
	end)
	
	Vermilion:AddChatCommand("ignite", function(sender, text, log)
		if(Vermilion:HasPermissionError(sender, "ignite", log)) then
			if(table.Count(text) < 2) then
				log("Syntax: !ignite <player> <time>", VERMILION_NOTIFY_ERROR)
				return
			end
			local tplayer = Crimson.LookupPlayerByName(text[1], false)
			if(IsValid(tplayer)) then
				local result = tonumber(text[2])
				if(result == nil) then
					log("That isn't a number!", VERMILION_NOTIFY_ERROR)
					return
				end
				tplayer:Ignite(result, 5)
				log("Ignited " .. text[1] .. " for " .. text[2] .. "s")
			else
				log(Vermilion.Lang.NoSuchPlayer, VERMILION_NOTIFY_ERROR)
			end
		end
	end, "<player> <time>")
	
	Vermilion:AddChatPredictor("ignite", function(pos, current)
		if(pos == 1) then
			local tab = {}
			for i,k in pairs(player.GetAll()) do
				if(string.StartWith(string.lower(k:GetName()), string.lower(current))) then
					table.insert(tab, k:GetName())
				end
			end
			return tab
		end
	end)
	
	Vermilion:AddChatCommand("extinguish", function(sender, text, log)
		if(Vermilion:HasPermissionError(sender, "extinguish", log)) then
			if(table.Count(text) < 1) then
				log("Syntax: !extinguish <player>", VERMILION_NOTIFY_ERROR)
				return
			end
			local tplayer = Crimson.LookupPlayerByName(text[1], false)
			if(IsValid(tplayer)) then
				tplayer:Extinguish()				
			else
				log(Vermilion.Lang.NoSuchPlayer, VERMILION_NOTIFY_ERROR)
			end
		end
	end, "<player>")
	
	Vermilion:AddChatPredictor("extinguish", function(pos, current)
		if(pos == 1) then
			local tab = {}
			for i,k in pairs(player.GetAll()) do
				if(string.StartWith(string.lower(k:GetName()), string.lower(current))) then
					table.insert(tab, k:GetName())
				end
			end
			return tab
		end
	end)
	
	Vermilion:AddChatCommand("random", function(sender, text, log)
		if(table.Count(text) < 1) then
			log("Syntax: !random <max number>", VERMILION_NOTIFY_ERROR)
			return
		end
		local res = tonumber(text[1])
		if(res == nil) then
			log("That isn't a number!", VERMILION_NOTIFY_ERROR)
			return
		end
		log("Number: " .. tostring(math.random(0, res)))
	end, "<max number>")
	
	Vermilion:AddChatCommand("stripweapons", function(sender, text, log)
		if(Vermilion:HasPermissionError(sender, "stripweapons", log)) then
			if(table.Count(text) < 1) then
				log("Syntax: !stripweapons <player>", VERMILION_NOTIFY_ERROR)
				return
			end
			local target = Crimson.LookupPlayerByName(text[1])
			if(not IsValid(target)) then
				log(Vermilion.Lang.NoSuchPlayer, VERMILION_NOTIFY_ERROR)
				return
			end
			target:StripWeapons()
			log("Stripped the weapons of " .. text[1])
		end
	end, "<player>")
	
	Vermilion:AddChatPredictor("stripweapons", function(pos, current)
		if(pos == 1) then
			local tab = {}
			for i,k in pairs(player.GetAll()) do
				if(string.StartWith(string.lower(k:GetName()), string.lower(current))) then
					table.insert(tab, k:GetName())
				end
			end
			return tab
		end
	end)
	
	Vermilion:AddChatCommand("suicide", function(sender, text, log)
		sender:ConCommand("kill")
	end)
	
end

function EXTENSION:InitClient()

	-- This code is borrowed from the base gamemode, but edited so it can be used more effectively (to mask player identities).
	self:AddHook("HUDDrawTargetID", function()
		local tr = util.GetPlayerTrace( LocalPlayer() )
		local trace = util.TraceLine( tr )
		if (!trace.Hit) then return end
		if (!trace.HitNonWorld) then return end
		
		if(trace.Entity:IsPlayer()) then
			if(trace.Entity:GetNWString("Vermilion_Fakename", "[Vermilion_NO_FAKENAME]") == "[Vermilion_NO_FAKENAME]") then
				return
			end
		end
		
		local text = "ERROR"
		local font = "TargetID"
		
		if (trace.Entity:IsPlayer()) then
			text = trace.Entity:GetNWString("Vermilion_Fakename", nil)
		else
			return
			--text = trace.Entity:GetClass()
		end
		
		surface.SetFont( font )
		local w, h = surface.GetTextSize( text )
		
		local MouseX, MouseY = gui.MousePos()
		
		if ( MouseX == 0 && MouseY == 0 ) then
		
			MouseX = ScrW() / 2
			MouseY = ScrH() / 2
		
		end
		
		local x = MouseX
		local y = MouseY
		
		x = x - w / 2
		y = y + 30
		
		-- The fonts internal drop shadow looks lousy with AA on
		draw.SimpleText( text, font, x+1, y+1, Color(0,0,0,120) )
		draw.SimpleText( text, font, x+2, y+2, Color(0,0,0,50) )
		draw.SimpleText( text, font, x, y, GAMEMODE:GetTeamColor( trace.Entity ) )
		
		y = y + h + 5
		
		local text = trace.Entity:Health() .. "%"
		local font = "TargetIDSmall"
		
		surface.SetFont( font )
		local w, h = surface.GetTextSize( text )
		local x =  MouseX  - w / 2
		
		draw.SimpleText( text, font, x+1, y+1, Color(0,0,0,120) )
		draw.SimpleText( text, font, x+2, y+2, Color(0,0,0,50) )
		draw.SimpleText( text, font, x, y, GAMEMODE:GetTeamColor( trace.Entity ) )
		
		return false
	end)

end

Vermilion:RegisterExtension(EXTENSION)