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
	"vanish"
}
EXTENSION.PermissionDefinitions = {
	["teleport"] = "This player is allowed to use the teleport command.",
	["conditional_teleport"] = "This player is allowed to use the conditional teleport commands (tpquery, tpaccept, tpdeny).",
	["speed"] = "This player is allowed to use the speed command.",
	["respawn"] = "This player is allowed to use the respawn command.",
	["private_message"] = "This player is allowed to use the private message commands (pm, r).",
	["afk"] = "This player is allowed to use the AFK command.",
	["get_position"] = "This player is allowed to use the getpos command.",
	["sudo"] = "This player is allowed to use the sudo command. This command is dangerous because it allows the user to execute any other command as another player, using the rights of the other player. This means that if a normal user were to sudo an owner, they would be able to do anything they wanted.",
	["spectate"] = "This player can use the spectate and unspectate commands.",
	["identity_fraud"] = "This player can use the identityfraud command.",
	["vanish"] = "This player can use the vanish command."
}

EXTENSION.TeleportRequests = {}
EXTENSION.PrivateMessageHistory = {}
EXTENSION.AFKPlayers = {}

function EXTENSION:InitServer()
	
	Vermilion:AddChatCommand("teleport", function(sender, text)
		if( not Vermilion:HasPermissionError(sender, "teleport") ) then
			return
		end
		if(table.Count(text) == 1) then
			text[2] = sender:GetName()
		end
		if( table.Count(text) < 2 ) then
			log("Syntax: !teleport <player to move> [player to move to]")
			return
		end
		
		local tplayer = Crimson.LookupPlayerByName(text[1])
		local lplayer = Crimson.LookupPlayerByName(text[2])
		if(not tplayer) then
			log("Player to teleport does not exist", VERMILION_NOTIFY_ERROR)
			return
		end
		if(not lplayer) then
			log("Player to teleport to does not exist", VERMILION_NOTIFY_ERROR)
			return
		end

		local Target = lplayer:GetPos()
		Target:Add(Vector(0,0,90))

		tplayer:SetPos(Target)
	end, "<player to move> [player to move to]")
	
	Vermilion:AddChatCommand("tpquery", function(sender, text, log)
		if(Vermilion:HasPermissionError(sender, "conditional_teleport")) then
			if(table.Count(text) < 1) then
				log("Syntax: !tpquery/tpq <player>")
				return
			end
			local tplayer = Crimson.LookupPlayerByName(text[1])
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
	
	Vermilion:AddChatCommand("tpaccept", function(sender, text, log)
		if(table.Count(text) < 1) then
			log("Syntax: !tpaccept/tpa <player>")
			return
		end
		local tplayer = Crimson.LookupPlayerByName(text[1])
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
	
	Vermilion:AddChatCommand("tpdeny", function(sender, text, log)
		if(table.Count(text) < 1) then
			log("Syntax: !tpdeny/tpd <player>")
			return
		end
		local tplayer = Crimson.LookupPlayerByName(text[1])
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
	
	Vermilion:AddChatCommand("speed", function(sender, text, log)
		if(Vermilion:HasPermissionError(sender, "speed")) then
			if(table.Count(text) < 1) then
				log("Syntax: !speed <speed multiplier> [player]")
				return
			end
			local times = tonumber(text[1])
			if(times == nil) then
				log(Vermilion.Lang.NoSuchPlayer, VERMILION_NOTIFY_ERROR)
				return
			end
			local target = sender
			if(table.Count(text) > 1) then
				local tplayer = Crimson.LookupPlayerByName(text[2])
				if(tplayer == nil) then
					log(Vermilion.Lang.NoSuchPlayer, VERMILION_NOTIFY_ERROR)
					return
				end
				target = tplayer
			end
			local speed = math.abs(250 * times)
			GAMEMODE:SetPlayerSpeed(target, speed, speed * 2)
			Vermilion:SendNotify(sender, "Speed set!")
		end
	end, "<speed multiplier> [player]")
	
	Vermilion:AddChatCommand("respawn", function(sender, text, log)
		if(Vermilion:HasPermissionError(sender, "respawn")) then
			local target = sender
			if(table.Count(text) > 0) then
				local tplayer = Crimson.LookupPlayerByName(text[1])
				if(tplayer == nil) then
					log(Vermilion.Lang.NoSuchPlayer, VERMILION_NOTIFY_ERROR)
					return
				end
				target = tplayer
			end
			if(target != nil) then
				target:Spawn()
			end
		end
	end, "[target]")
	
	Vermilion:AddChatCommand("pm", function(sender, text, log)
		if(Vermilion:HasPermissionError(sender, "private_message")) then
			if(table.Count(text) > 1) then
				local tplayer = Crimson.LookupPlayerByName(text[1])
				if(tplayer == nil) then
					log(Vermilion.Lang.NoSuchPlayer, VERMILION_NOTIFY_ERROR)
					return
				end
				tplayer:ChatPrint("[Private] " .. sender:GetName() .. ": " .. table.concat(text, " ", 2))
				EXTENSION.PrivateMessageHistory[tplayer:SteamID()] = sender:GetName()
			else
				log("Syntax: !pm <target> <message>", VERMILION_NOTIFY_ERROR)
			end
		end
	end, "<target> <message>")
	
	Vermilion:AddChatCommand("r", function(sender, text, log)
		if(Vermilion:HasPermissionError(sender, "private_message")) then
			if(table.Count(text) > 0) then
				local tplayer = Crimson.LookupPlayerByName(EXTENSION.PrivateMessageHistory[sender:SteamID()])
				if(tplayer == nil) then
					log("You haven't received a private message yet or the player has left the server!", VERMILION_NOTIFY_ERROR)
					return
				end
				tplayer:ChatPrint("[Private] " .. sender:GetName() .. ": " .. table.concat(text, " "))
				EXTENSION.PrivateMessageHistory[tplayer:SteamID()] = sender:GetName()
			else
				log("Syntax: !r <message>", VERMILION_NOTIFY_ERROR)
			end
		end
	end, "<message>")
	
	Vermilion:AddChatCommand("time", function(sender, text, log)
		log("The time at the server is: " .. os.date("%I:%M:%S %p on %d/%m/%Y"))
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
				local tplayer = Crimson.LookupPlayerByName(text[1])
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
	
	Vermilion:AddChatCommand("sudo", function(sender, text, log)
		if(Vermilion:HasPermissionError(sender, "sudo")) then
			if(table.Count(text) < 2) then
				log("Syntax: !sudo <player> <command>", VERMILION_NOTIFY_ERROR)
				return
			end
			local tplayer = Crimson.LookupPlayerByName(text[1])
			if(tplayer == nil) then
				log("Player does not exist!", VERMILION_NOTIFY_ERROR)
				return
			end
			Vermilion:HandleChat(tplayer, table.concat(text, " ", 2), log, false)
		end
	end, "<player> <command>")
	
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
				sender:Spectate( OBS_MODE_CHASE )
				sender:SpectateEntity( tent )
				sender:StripWeapons()
				sender.VSpectating = true
			else
				log("That isn't a valid entity.", VERMILION_NOTIFY_ERROR)
			end
		elseif(text[1] == "-player") then
			local tplayer = Crimson.LookupPlayerByName(text[2])
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
			local tplayer = Crimson.LookupPlayerByName(text[1])
			if(IsValid(tplayer)) then
				sender.VIDFraudOriginalModel = sender:GetModel()
				Vermilion:ForcePlayerModel(sender, tplayer:GetModel())
				sender:SetNWString("Vermilion_Fakename", text[1])
			else
				log(Vermilion.Lang.NoSuchPlayer, VERMILION_NOTIFY_ERROR)
			end
		end
	end, "<player>")
	
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