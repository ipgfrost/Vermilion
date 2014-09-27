--[[
 Copyright 2014 Ned Hyett, 

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
EXTENSION.Name = "Trouble In Terrorist Town Integration"
EXTENSION.ID = "ttt"
EXTENSION.Description = "Integrates with the Trouble In Terrorist Town gamemode."
EXTENSION.Author = "Ned"
if(engine.ActiveGamemode() == "terrortown") then
	EXTENSION.Permissions = {
		"settraitor",
		"setdetective",
		"setinnocent",
		"setcredits",
		"restartround",
		"haste",
		"roundtime"
	}
	EXTENSION.PermissionDefinitions = {
		["settraitor"] = "This player can use the settraitor chat command in Trouble In Terrorist Town.",
		["setdetective"] = "This player can use the setdetective chat command in Trouble In Terrorist Town.",
		["setinnocent"] = "This player can use the setinnocent chat command in Trouble In Terrorist Town.",
		["setcredits"] = "This player can use the setcredits chat command in Trouble In Terrorist Town.",
		["restartround"] = "This player can use the restartround chat command in Trouble In Terrorist Town.",
		["haste"] = "This player can use the haste chat command in Trouble In Terrorist Town.",
		["roundtime"] = "This player can use the roundtime chat command in Trouble In Terrorist Town."
	}
end

function EXTENSION:InitServer()
	if(engine.ActiveGamemode() != "terrortown") then 
		Vermilion.Log("Not loading TTT Integration; not running TTT.")
		return
	end

	Vermilion:AddChatCommand("settraitor", function(sender, text, log)
		if(Vermilion:HasPermissionError(sender, "settraitor", log)) then
			if(table.Count(text) < 1) then
				log("Syntax: !settraitor <player>", VERMILION_NOTIFY_ERROR)
				return
			end
			local target = Crimson.LookupPlayerByName(text[1])
			if(not IsValid(target)) then
				log(Vermilion.Lang.NoSuchPlayer, VERMILION_NOTIFY_ERROR)
				return
			end
			Vermilion.Log({Color(0, 0, 255), sender:GetName(), Color(255, 255, 255), " has changed ", Color(0, 0, 255), " to the ", Color(255, 0, 0), " TRAITOR ", Color(255, 255, 255), " team." })
			target:SetRole(ROLE_TRAITOR)
			SendFullStateUpdate()
		end
	end, "<player>")
	
	Vermilion:AddChatPredictor("settraitor", function(pos, current)
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
	
	Vermilion:AddChatCommand("setdetective", function(sender, text, log)
		if(Vermilion:HasPermissionError(sender, "setdetective", log)) then
			if(table.Count(text) < 1) then
				log("Syntax: !setdetective <player>", VERMILION_NOTIFY_ERROR)
				return
			end
			local target = Crimson.LookupPlayerByName(text[1])
			if(not IsValid(target)) then
				log(Vermilion.Lang.NoSuchPlayer, VERMILION_NOTIFY_ERROR)
				return
			end
			Vermilion.Log({Color(0, 0, 255), sender:GetName(), Color(255, 255, 255), " has changed ", Color(0, 0, 255), " to the ", Color(255, 0, 0), " DETECTIVE ", Color(255, 255, 255), " team." })
			target:SetRole(ROLE_DETECTIVE)
			SendFullStateUpdate()
		end
	end, "<player>")
	
	Vermilion:AddChatPredictor("setdetective", function(pos, current)
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
	
	Vermilion:AddChatCommand("setinnocent", function(sender, text, log)
		if(Vermilion:HasPermissionError(sender, "setinnocent", log)) then
			if(table.Count(text) < 1) then
				log("Syntax: !setinnocent <player>", VERMILION_NOTIFY_ERROR)
				return
			end
			local target = Crimson.LookupPlayerByName(text[1])
			if(not IsValid(target)) then
				log(Vermilion.Lang.NoSuchPlayer, VERMILION_NOTIFY_ERROR)
				return
			end
			Vermilion.Log({Color(0, 0, 255), sender:GetName(), Color(255, 255, 255), " has changed ", Color(0, 0, 255), " to the ", Color(255, 0, 0), " INNOCENT ", Color(255, 255, 255), " team." })
			target:SetRole(ROLE_INNOCENT)
			SendFullStateUpdate()
		end
	end, "<player>")
	
	Vermilion:AddChatPredictor("setinnocent", function(pos, current)
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
	
	Vermilion:AddChatCommand("setcredits", function(sender, text, log)
		if(Vermilion:HasPermissionError(sender, "setcredits", log)) then
			if(table.Count(text) < 2) then
				log("Syntax: !setcredits <player> <credits>", VERMILION_NOTIFY_ERROR)
				return
			end
			local target = Crimson.LookupPlayerByName(text[1])
			if(not IsValid(target)) then
				log(Vermilion.Lang.NoSuchPlayer, VERMILION_NOTIFY_ERROR)
				return
			end
			local res = tonumber(text[2])
			if(res == nil) then
				log("That isn't a number.", VERMILION_NOTIFY_ERROR)
				return
			end
			target:SetCredits(res)
			Vermilion.Log({Color(0, 0, 255), sender:GetName(), Color(255, 255, 255), " has given ", Color(0, 0, 255), Color(255, 0, 0), tostring(res), Color(255, 255, 255), " credits." })
			log("Set " .. target:GetName() .. "'s credits to " .. tostring(res))
		end
	end, "<player> <credits>")
	
	Vermilion:AddChatPredictor("setcredits", function(pos, current)
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
	
	Vermilion:AddChatCommand("restartround", function(sender, text, log)
		if(Vermilion:HasPermissionError(sender, "restartround", log)) then
			Vermilion.Log({Color(0, 0, 255), vplayer:GetName(), Color(255, 255, 255), " restarted the round."})
			RunConsoleCommand("ttt_roundrestart")
		end
	end)
	
	Vermilion:AddChatCommand("haste", function(sender, text, log)
		if(Vermilion:HasPermissionError(sender, "haste", log)) then
			if(table.Count(text) < 1) then
				log("Syntax: !haste <true|false>", VERMILION_NOTIFY_ERROR)
				return
			end
			local res = tobool(text[1])
			if(res == nil) then
				log("That isn't a boolean.", VERMILION_NOTIFY_ERROR)
				return
			end
			if(res) then
				RunConsoleCommand("ttt_haste", 1)
			else
				RunConsoleCommand("ttt_haste", 0)
			end
			Vermilion.Log({Color(0, 0, 255), vplayer:GetName(), Color(255, 255, 255), " has changed the haste mode."})
		end
	end, "<true|false>")
	
	Vermilion:AddChatCommand("roundtime", function(sender, text, log)
		if(Vermilion:HasPermissionError(sender, "roundtime", log)) then
			if(table.Count(text) < 1) then
				log("Syntax: !roundtime <minutes>", VERMILION_NOTIFY_ERROR)
				return
			end
			local res = tonumber(text[1])
			if(res == nil) then
				log("That isn't a number.", VERMILION_NOTIFY_ERROR)
				return
			end
			RunConsoleCommand("ttt_roundtime_minutes", res)
			Vermilion:BroadcastNotify("Round time changed to " .. tostring(res) .. " minutes.")
			Vermilion.Log({Color(0, 0, 255), vplayer:GetName(), Color(255, 255, 255), " has changed the round time."})
		end
	end, "<minutes>")
	
	self:AddHook(Vermilion.EVENT_EXT_LOADED, "ConfigureServerManager", function() -- tell the server manager to disable some sandbox cheats. NOTE: Move this into the gamemode customiser
		if(engine.ActiveGamemode() != "terrortown") then return end
		if(Vermilion:GetExtension("server_manager") != nil) then
			local ext = Vermilion:GetExtension("server_manager")
			ext:SetData("unlimited_ammo", false)
			ext:SetData("enable_no_damage", false)
			ext:SetData("noclip_control", false)
			ext:SetData("enable_lock_immunity", false)
			ext:SetData("enable_kill_immunity", false)
			ext:SetData("enable_kick_immunity", false)
			ext:SetData("force_noclip_permissions", false)
			Vermilion:SetModuleData("deathnotice", "enabled", false)
			ext:SetData("disable_fall_damage", false)
			Vermilion.Log("Modified internal settings to compensate for non-sandbox gamemode!")
		end
	end)
	
end

function EXTENSION:InitClient()

end

Vermilion:RegisterExtension(EXTENSION)