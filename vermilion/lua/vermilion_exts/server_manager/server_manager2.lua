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
EXTENSION.Name = "Server Settings"
EXTENSION.ID = "server_manager"
EXTENSION.Description = "Handles server settings and generic restrictions"
EXTENSION.Author = "Ned"
EXTENSION.Permissions = {
	"server_manage",
	"no_damage",
	"unlimited_ammo",
	"no_spawn_restrictions",
	"flashlight",
	"noclip",
	"spray",
	"use_voip",
	"hear_voip",
	"no_fall_damage",
	"reduced_fall_damage",
	"chat",
	"broadcast_hint",
	"spawn_prop",
	"spawn_npc",
	"spawn_entity",
	"spawn_weapon",
	"spawn_dupe",
	"spawn_vehicle",
	"spawn_effect",
	"spawn_ragdoll",
	"spawn_all",
	"add_resource",
	"player_collide"
}
EXTENSION.PermissionDefinitions = {
	["server_manage"] = "This player can see the Server Settings tab in the Vermilion Menu and modify the settings within.",
	["no_damage"] = "This player is immune from all damage.",
	["unlimited_ammo"] = "This player has unlimited ammunition in all weapons.",
	["no_spawn_restrictions"] = "This player is exempt from sandbox spawn restrictions.",
	["flashlight"] = "This player can turn on their flashlight.",
	["noclip"] = "This player can turn on noclip.",
	["spray"] = "This player is allowed to use their sprays.",
	["use_voip"] = "This player is allowed to use the VoIP chat to chat to other players.",
	["hear_voip"] = "This player is allowed to hear other players using the VoIP functionality.",
	["no_fall_damage"] = "This player is not subject to fall damage and will not hear the bang noise when they hit the ground (the noise is not disabled by no_damage).",
	["reduced_fall_damage"] = "This player takes half the normal fall damage when they hit the ground.",
	["chat"] = "This player can use the chat.",
	["broadcast_hint"] = "This player can use the broadcast chat command to broadcast a message to all connected players.",
	["spawn_prop"] = "This player is allowed to spawn props. This does not define what prop they can spawn, but without this permission they are banned from spawning any prop.",
	["spawn_npc"] = "This player is allowed to spawn NPCs. This does not define what NPC they can spawn, but without this permission they are banned from spawning any NPC.",
	["spawn_entity"] = "This player is allowed to spawn SENTs. This does not define what SENT they can spawn, but without this permission they are banned from spawning any SENT.",
	["spawn_weapon"] = "This player is allowed to spawn SWEPs. This does not define what SWEP they can spawn, but without this permission they are banned from spawning any SWEP.",
	["spawn_dupe"] = "This player is allowed to paste dupes. This does not define what dupe they can spawn, but without this permission they are banned from pasting any dupes.",
	["spawn_vehicle"] = "This player is allowed to spawn vehicles. This does not define what vehicle they can spawn, but without this permission they are banned from spawning any vehicles.",
	["spawn_effect"] = "This player is allowed to spawn effects. This does not define what effect they can spawn, but without this permission they are banned from spawning any effects.",
	["spawn_ragdoll"] = "This player is allowed to spawn ragdolls. This does not define what ragdoll they can spawn, but without this permission they are banned from spawning any ragdolls.",
	["spawn_all"] = "This player can spawn anything. Same as giving the player all of the spawn_ permissions.",
	["player_collide"] = "This player is allowed to collide with other players."
}
EXTENSION.RankPermissions = {
	{ "admin", {
			"no_damage",
			"unlimited_ammo",
			"no_spawn_restrictions",
			"flashlight",
			"noclip",
			"spray",
			"use_voip",
			"hear_voip",
			"no_fall_damage",
			"chat",
			"broadcast_hint",
			"spawn_all",
			"player_collide"
		}
	},
	{ "player", {
			"flashlight",
			"noclip",
			"spray",
			"use_voip",
			"hear_voip",
			"reduced_fall_damage",
			"chat",
			"spawn_all",
			"player_collide"
		}
	},
	{ "guest", {
			"chat",
			"spawn_prop"
		}
	}
}
EXTENSION.NetworkStrings = {
	"VClearDecals",
	"VClearCorpses",
	"VServerUpdate",
	"VServerGetProperties",
	"VUpdateMOTD",
	"VGetMOTD",
	"VGetMOTDVars"
}


local options = {
	{ Name = "unlimited_ammo", GuiText = "Unlimited ammunition:", Type = "Combobox", Options = {
			"Off",
			"All Players",
			"Permissions Based"
		}, Category = "Limits", CategoryWeight = 0, Default = 3 },
	{ Name = "enable_limit_remover", GuiText = "Spawn Limit Remover:", Type = "Combobox", Options = {
			"Off",
			"All Players",
			"Permissions Based"
		}, Category = "Limits", CategoryWeight = 0, Default = 3 },
	{ Name = "enable_no_damage", GuiText = "Disable Damage:", Type = "Combobox", Options = {
			"Off",
			"All Players",
			"Permissions Based"
		}, Category = "Limits", CategoryWeight = 0, Default = 3 },
	{ Name = "flashlight_control", GuiText = "Flashlight Control:", Type = "Combobox", Options = {
			"Off",
			"All Players Blocked",
			"All Players Allowed",
			"Permissions Based"
		}, Category = "Limits", CategoryWeight = 0, Default = 4 },
	{ Name = "noclip_control", GuiText = "Noclip Control:", Type = "Combobox", Options = {
			"Off",
			"All Players Blocked",
			"All Players Allowed",
			"Permissions Based"
		}, Category = "Limits", CategoryWeight = 0, Default = 4 },
	{ Name = "spray_control", GuiText = "Spray Control:", Type = "Combobox", Options = {
			"Off",
			"All Players Blocked",
			"All Players Allowed",
			"Permissions Based"
		}, Category = "Limits", CategoryWeight = 0, Default = 4 },
	{ Name = "voip_control", GuiText = "VoIP Control:", Type = "Combobox", Options = {
			"Do not limit",
			"Globally Disable VoIP",
			"Globally Enable VoIP",
			"Permissions Based"
		}, Category = "Limits", CategoryWeight = 0, Default = 4 },
	{ Name = "limit_chat", GuiText = "Chat Blocker:", Type = "Combobox", Options = {
			"Off",
			"Globally Disable Chat",
			"Permissions Based"
		}, Category = "Limits", CategoryWeight = 0, Default = 3 },
	{ Name = "enable_lock_immunity", GuiText = "Lua Lock Immunity:", Type = "Combobox", Options = {
			"Off",
			"All Players",
			"Permissions Based"
		}, Category = "Immunity", CategoryWeight = 2, Default = 3 },
	{ Name = "enable_kill_immunity", GuiText = "Lua Kill Immunity:", Type = "Combobox", Options = {
			"Off",
			"All Players",
			"Permissions Based"
		}, Category = "Immunity", CategoryWeight = 2, Default = 3 },
	{ Name = "enable_kick_immunity", GuiText = "Lua Kick Immunity:", Type = "Combobox", Options = {
			"Off",
			"All Players",
			"Permissions Based"
		}, Category = "Immunity", CategoryWeight = 2, Default = 3 },
	{ Name = "disable_fall_damage", GuiText = "Fall Damage Modifier:", Type = "Combobox", Options = {
			"Off",
			"All Players",
			"All Players suffer reduced damage",
			"Permissions Based"
		}, Category = "Limits", CategoryWeight = 0, Default = 4 },
	{ Name = "disable_owner_nag", GuiText = "Disable 'No owner detected' nag at startup", Type = "Checkbox", Category = "Misc", CategoryWeight = 50, Default = false },
	{ Module = "deathnotice", Name = "enabled", GuiText = "Enable Kill Notices", Type = "Checkbox", Category = "Misc", CategoryWeight = 50, Default = true },
	{ Name = "player_collision_mode", GuiText = "Player Collisions Mode (experimental):", Type = "Combobox", Options = {
			"No change",
			"Always disable collisions",
			"Permissions Based"
		}, Category = "Misc", CategoryWeight = 50, Default = 3 },
	{ Module = "scoreboard", Name = "scoreboard_enabled", GuiText = "Enable Vermilion Scoreboard", Type = "Checkbox", Category = "Misc", CategoryWeight = 50, Default = true },
	{ Module = "gm_customiser", Name = "enabled", GuiText = "Automatically adapt settings to suit supported gamemodes", Type = "Checkbox", Category = "Misc", CategoryWeight = 50, Default = true }
}

function EXTENSION:AddOption(mod, name, guitext, typ, category, categoryweight, defaultval, permission, otherdat)
	otherdat = otherdat or {}
	table.insert(options, table.Merge({ Module = mod, Name = name, GuiText = guitext, Type = typ, Category = category, CategoryWeight = categoryweight, Default = defaultval, Permission = permission}, otherdat))
end
	

function EXTENSION:UpdatePlayerMeta()
	local META = FindMetaTable("Player")

	-- Prevent lua scripts from killing the player unless they specify "true" as the first parameter.
	if(META.Vermilion_Lock == nil) then META.Vermilion_Lock = META.Lock end
	function META:Lock(override)
		if(not Vermilion:HasPermission(self, "lock_immunity") or not EXTENSION:GetData("enable_lock_immunity", true) or override) then
			self:Vermilion_Lock()
		end
	end

	-- Prevent lua scripts from freezing the player unless they specify "true" as the first parameter.
	if(META.Vermilion_Freeze == nil) then META.Vermilion_Freeze = META.Freeze end
	function META:Freeze( freeze, override )
		if(not Vermilion:HasPermission(self, "lock_immunity") or not EXTENSION:GetData("enable_lock_immunity", true) or override) then
			self:Vermilion_Freeze( freeze )
		end
	end

	-- Prevent lua scripts from killing the player unless they specify "true" as the first parameter.
	if(META.Vermilion_Kill == nil) then META.Vermilion_Kill = META.Kill end
	function META:Kill(override)
		if(not Vermilion:HasPermission(self, "kill_immunity") or not EXTENSION:GetData("enable_kill_immunity", true) or override) then
			self:Vermilion_Kill()
		end
	end

	-- Prevent lua scripts from killing the player unless they specify "true" as the first parameter.
	if(META.Vermilion_KillSilent == nil) then META.Vermilion_KillSilent = META.KillSilent end
	function META:KillSilent(override)
		if(not Vermilion:HasPermission(self, "kill_immunity") or not EXTENSION:GetData("enable_kill_immunity", true) or override) then
			self:Vermilion_KillSilent()
		end
	end

	-- Prevent lua scripts from kicking the player unless they specify "true" as the first parameter.
	if(META.Vermilion_Kick == nil) then META.Vermilion_Kick = META.Kick end
	function META:Kick(reason, override)
		if(not Vermilion:HasPermission(self, "kick_immunity") or not EXTENSION:GetData("enable_kick_immunity", true) or override) then
			self:Vermilion_Kick(reason)
		end
	end
	
	timer.Simple(1, function() -- This timer allows Vermilion to overwrite other addons by "waiting" for them to overwrite the function, then subsequently overwriting it after 1 second.
		if(META.Vermilion_CheckLimit == nil) then
			META.Vermilion_CheckLimit = META.CheckLimit
			Vermilion.Log("Overwrote Player.CheckLimit.")
		end
		function META:CheckLimit(str)
			if(not EXTENSION:GetData("enable_limit_remover", true)) then
				local result = hook.Run("VCheckLimit", self, str)
				if(result == nil) then result = true end
				if(result == false) then return false end
				return self:Vermilion_CheckLimit(str)
			end
			if(Vermilion:HasPermission(self, "no_spawn_restrictions")) then
				return true
			end
			local result = hook.Run("VCheckLimit", self, str)
			if(result == nil) then result = true end
			if(result == false) then return false end
			return self:Vermilion_CheckLimit(str)
		end
	end)
end

function EXTENSION:RegisterChatCommands()
	
	--[[
		Broadcast a notice to all connected players.
		
		!broadcast <message>
	]]--
	Vermilion:AddChatCommand("broadcast", function(sender, text, log)
		if(Vermilion:HasPermissionError(sender, "broadcast_hint", log)) then
			Vermilion:BroadcastNotify(text[1], 10, NOTIFY_HINT)
		end
	end, "<text>")
	
	--[[
		Add a resource to the list of resources to be downloaded by connecting clients.
		
		!addresource <path>
	]]--
	Vermilion:AddChatCommand("addresource", function(sender, text, log)
		if(Vermilion:HasPermissionError(sender, "add_resource", log)) then
			local str = table.concat(text, " ", 1, table.Count(text))
			if(not file.Exists(str, "GAME")) then
				log("File does not exist!", VERMILION_NOTIFY_ERROR)
				return
			end
			resource.AddSingleFile(str)
			log(str .. " has been added to the client resources!")
			Vermilion.Log(str .. " has been added to the client resources.")
			table.insert(EXTENSION:GetData("resources", {}, true), str)
		end
	end, "<resource path>")
	
	--[[
		Print a list of resource that are sent to clients.
	]]--
	Vermilion:AddChatCommand("listresources", function(sender, text, log)
		if(Vermilion:HasPermissionError(sender, "add_resource", log)) then
			log("A list of resources has been printed to the chat.")
			for i,k in pairs(EXTENSION:GetData("resources", {}, true)) do
				sender:ChatPrint(k)
			end
		end
	end)
	
	--[[
		Remove a resource from the list of resources to be downloaded by connecting clients.
		
		!removeresource <path>
	]]--
	Vermilion:AddChatCommand("removeresource", function(sender, text, log)
		if(Vermilion:HasPermissionError(sender, "add_resource", log)) then
			if(not table.HasValue(EXTENSION:GetData("resources", {}, true), table.concat(text, " ", 1, table.Count(text)))) then
				log("This resource has not been added to the download list.", VERMILION_NOTIFY_ERROR)
				return
			end
			table.RemoveByValue(EXTENSION:GetData("resources", {}, true), table.concat(text, " ", 1, table.Count(text)))
			log("Resource will be removed from the download list upon server restart.")
		end
	end)
end

function EXTENSION:InitServer()
	self:UpdatePlayerMeta()
	
	for i,k in pairs(EXTENSION:GetData("resources", {}, true)) do -- register the resources that were added by !addresource
		Vermilion.Log("Adding user-specified resource '" .. k .. "' to client resources.")
		resource.AddSingleFile(k)
	end
	
	-- player invincibility
	self:AddHook("EntityTakeDamage", "PlayerInvincibility", function(target, dmg)
		if(EXTENSION:GetData("enable_no_damage", 3) == 1) then return end
		if(not target:IsPlayer()) then return end
		if(not Vermilion:HasPermission(target, "no_damage") and EXTENSION:GetData("enable_no_damage", 3) != 2) then return end
		dmg:ScaleDamage(0)
		return dmg
	end)
	
	-- unlimited ammo
	self:AddHook("Tick", "UnlimitedAmmo", function(vent, dTab)
		if(EXTENSION:GetData("unlimited_ammo", 3) == 1) then return end
		for i,vplayer in pairs(player.GetAll()) do
			if(Vermilion:HasPermission(vplayer, "unlimited_ammo") or EXTENSION:GetData("unlimited_ammo", 3) == 2) then
				if(IsValid(vplayer:GetActiveWeapon())) then
					local twep = vplayer:GetActiveWeapon()
					if(twep:Clip1() < 5000) then
						twep:SetClip1(5000)
					end
					if(twep:Clip2() < 5000) then
						twep:SetClip2(5000)
					end
					if(twep:GetPrimaryAmmoType() == 10 or twep:GetPrimaryAmmoType() == 8) then
						vplayer:GiveAmmo(1, twep:GetPrimaryAmmoType(), true)
					elseif(twep:GetSecondaryAmmoType() == 9 or twep:GetSecondaryAmmoType() == 2) then
						vplayer:GiveAmmo(1, twep:GetSecondaryAmmoType(), true)
					end
				end
			end
		end
	end)
	
	-- flashlight blocking
	self:AddHook("PlayerSwitchFlashlight", "LockFlashlight", function(vplayer, enabled)
		if(EXTENSION:GetData("flashlight_control", 4) == 1) then return end
		if(EXTENSION:GetData("flashlight_control", 4) == 2) then return false end
		if(EXTENSION:GetData("flashlight_control", 4) == 3) then return true end
		if(enabled) then
			if(not Vermilion:HasPermission(vplayer, "flashlight")) then
				Vermilion.Log({Color(0, 0, 255), vplayer:GetName(), Color(255, 255, 255), " was blocked from using their flashlight."})
				return false
			end
		end
	end)
	
	-- noclip blocking
	self:AddHook("PlayerNoClip", "LockNoclip", function(vplayer, enabled)
		if(EXTENSION:GetData("noclip_control", 4) == 1) then return end
		if(EXTENSION:GetData("noclip_control", 4) == 2) then return false end
		if(EXTENSION:GetData("noclip_control", 4) == 3) then return true end
		if(enabled) then
			if(not Vermilion:HasPermission(vplayer, "noclip")) then
				Vermilion.Log({Color(0, 0, 255), vplayer:GetName(), Color(255, 255, 255), " was blocked from using noclip."})
				return false
			end
			if(EXTENSION:GetData("force_noclip_permissions", true)) then
				return true
			end
		end
	end)
	
	-- spray blocking
	self:AddHook("PlayerSpray", "LockSpray", function(vplayer)
		if(EXTENSION:GetData("spray_control", 4) == 1) then return end
		if(EXTENSION:GetData("spray_control", 4) == 2) then return false end
		if(EXTENSION:GetData("spray_control", 4) == 3) then return true end
		if(not Vermilion:HasPermission(vplayer, "spray")) then
			Vermilion.Log({Color(0, 0, 255), vplayer:GetName(), Color(255, 255, 255), " was blocked from spraying."})
			return false
		end
	end)
	
	-- voip blocking
	self:AddHook("PlayerCanHearPlayersVoice", "LockVOIP", function(listener, talker)
		if(EXTENSION:GetData("voip_control", 4) == 1) then return end
		if(EXTENSION:GetData("voip_control", 4) == 2) then return false end
		if(EXTENSION:GetData("voip_control", 4) == 3) then return true end
		if(not Vermilion:HasPermission(talker, "use_voip")) then
			return false
		end
		if(not Vermilion:HasPermission(listener, "hear_voip")) then
			return false
		end
	end)
	
	-- falldamage blocking
	self:AddHook("GetFallDamage", "FalldamageBlocker", function(vplayer, speed)
		if(EXTENSION:GetData("disable_fall_damage", 4) == 1) then
			return
		end
		if(EXTENSION:GetData("disable_fall_damage", 4) == 2) then
			return 0
		end
		if(Vermilion:HasPermission(vplayer, "no_fall_damage") and EXTENSION:GetData("disable_fall_damage", 4) == 4) then
			return 0
		end
		if(Vermilion:HasPermission(vplayer, "reduced_fall_damage") or EXTENSION:GetData("disable_fall_damage", 4) == 3) then
			return 5
		end
	end)
	
	-- chat blocking
	self:AddHook("PlayerSay", "ChatBlocker", function(vplayer, text, teamChat)
		if(EXTENSION:GetData("limit_chat", 3) == 1) then return end
		if(EXTENSION:GetData("limit_chat", 3) == 2) then return text end
		if(not Vermilion:HasPermission(vplayer, "chat")) then
			Vermilion.Log({Color(0, 0, 255), vplayer:GetName(), Color(255, 255, 255), " was blocked from using the chat."})
			return ""
		end
	end)
	
	-- player collision
	self:AddHook("PlayerSpawn", function(vplayer)
		vplayer:SetCustomCollisionCheck(true)
	end)
	
	self:AddHook("ShouldCollide", function(ent1, ent2)
		local mode = EXTENSION:GetData("player_collision_mode", 1, true)
		if(mode == 1) then return end -- disabled
		if(IsValid(ent1) and IsValid(ent2)) then
			if(ent1:IsPlayer() and ent2:IsPlayer()) then
				if(mode == 2) then return false else -- always disable
					if(not Vermilion:HasPermission(ent1, "player_collide") or not Vermilion:HasPermission(ent2, "player_collide")) then return false end -- disable if one or both players doesn't have the collision permission.
				end
			end
		end
	end)
	
	self:AddDataChangeHook("player_collision_mode", "updatePlayerCollide", function(val)
		SetGlobalBool("Vermilion_PlayerCollideMode", val)
	end)
	
	
	--[[
		Networking hooks
	]]--
	
	
	-- responder to the "clear decals" button on the gui
	self:NetHook("VClearDecals", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "server_manage")) then -- separate to own permission
			Vermilion.Log({Color(0, 0, 255), vplayer:GetName(), Color(255, 255, 255), " cleared the decals."})
			for i,k in pairs(player.GetHumans()) do
				k:ConCommand("r_cleardecals")
			end
		end
	end)
	
	-- responder to the "clear corpses" button on the gui
	self:NetHook("VClearCorpses", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "server_manage")) then -- separate to own permission
			Vermilion.Log({Color(0, 0, 255), vplayer:GetName(), Color(255, 255, 255), " cleared the corpses."})
			game.RemoveRagdolls()
			for i,k in pairs(player.GetHumans()) do
				k:SendLua("game.RemoveRagdolls()")
			end
		end
	end)
	
	
	if(self:GetData("config_version", 0, true) < 1) then
		for i,k in pairs(options) do
			if(k.Type != "Combobox") then continue end
			if(k.Module != nil) then
				if(Vermilion:GetModuleData(k.Module, k.Name) != nil) then
					if(Vermilion:GetModuleData(k.Module, k.Name) == true) then
						Vermilion:SetModuleData(k.Module, k.Name, k.Default)
					else
						Vermilion:SetModuleData(k.Module, k.Name, 1)
					end
				end
			else
				if(self:GetData(k.Name) != nil) then
					if(self:GetData(k.Name) == true) then
						self:SetData(k.Name, k.Default)
					else
						self:SetData(k.Name, 1)
					end
				end
			end
		end
		self:SetData("config_version", 1)
	end
	
	
	self:NetHook("VServerUpdate", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "server_manage")) then
			local data = net.ReadTable()
			for i,k in pairs(data) do
				if(k.Module != nil) then
					Vermilion:SetModuleData(k.Module, k.Name, k.Value)
				else
					self:SetData(k.Name, k.Value)
				end
			end
		end
	end)
	
	self:NetHook("VServerGetProperties", function(vplayer)
		local tab = {}
		for i,k in pairs(options) do
			if(k.Permission != nil) then
				if(not Vermilion:HasPermission(vplayer, k.Permission)) then continue end
			end
			local val = nil
			if(k.Module != nil) then
				val = Vermilion:GetModuleData(k.Module, k.Name, k.Default)
			else
				val = EXTENSION:GetData(k.Name, k.Default, false)
			end
			local indTab = table.Copy(k)
			indTab.Value = val
			table.insert(tab, indTab)			
		end
		net.Start("VServerGetProperties")
		net.WriteTable(tab)
		net.Send(vplayer)
	end)
	
	--[[
		MOTD base
	]]--
	
	self:NetHook("VGetMOTD", function(vplayer)
		net.Start("VGetMOTD")
		net.WriteString(EXTENSION:GetData("motd", "Welcome to %servername%!\nThis server is running the Vermilion Server Administration Tool!\nBe on your best behaviour!"))
		net.WriteBoolean(EXTENSION:GetData("motdishtml", false, true))
		net.WriteBoolean(EXTENSION:GetData("motdisurl", false, true))
		net.Send(vplayer)
	end)
	
	self:NetHook("VUpdateMOTD", function(vplayer)
		if(Vermilion:HasPermissionError(vplayer, "server_manage")) then
			Vermilion.Log({Color(0, 0, 255), vplayer:GetName(), Color(255, 255, 255), " updated the MOTD."})
			EXTENSION:SetData("motd", net.ReadString())
			EXTENSION:SetData("motdishtml", net.ReadBoolean())
			EXTENSION:SetData("motdisurl", net.ReadBoolean())
		end
	end)
	
	self:NetHook("VGetMOTDVars", function(vplayer)
		net.Start("VGetMOTDVars")
		local tab = {}
		for i,k in pairs(Vermilion.MOTDKeywords) do
			table.insert(tab, { Name = i, Description = k.Description })
		end
		net.WriteTable(tab)
		net.Send(vplayer)
	end)
	
	self:AddHook(Vermilion.EVENT_EXT_LOADED, "AddGui", function()
		Vermilion:AddInterfaceTab("server_control", "server_manage")
	end)
end

function EXTENSION:InitClient()
	
	self:NetHook("VGetMOTD", function()
		if(IsValid(EXTENSION.MOTDText)) then
			EXTENSION.MOTDText:SetValue(net.ReadString())
			EXTENSION.IsHTML = net.ReadBoolean()
			EXTENSION.IsURL = net.ReadBoolean()
		end
	end)
	
	self:NetHook("VGetMOTDVars", function()
		if(IsValid(EXTENSION.VarList)) then
			local tab = net.ReadTable()
			EXTENSION.VarList:Clear()
			for i,k in pairs(tab) do
				EXTENSION.VarList:AddLine(k.Name, k.Description)
			end
		end
	end)
	
	self:NetHook("VServerGetProperties", function()
		local tab = net.ReadTable()
		
		local categories = {}
		
		for i,k in pairs(tab) do
			local has = false
			for i1,k1 in pairs(categories) do
				if(k1.Category == k.Category) then has = true break end
			end
			if(not has) then
				table.insert(categories, { Category = k.Category, CategoryWeight = k.CategoryWeight })
			end
		end
		
		local nCats = {}
		
		table.SortByMember(categories, "CategoryWeight", true)
		
		
		for i,k in pairs(categories) do
			nCats[k.Category] = EXTENSION.ScrollPanel:Add(k.Category)
		end
		
		
		for i,k in pairs(tab) do
			if(k.Type == "Combobox") then
				local panel = vgui.Create("DPanel")
			
				local label = Crimson.CreateLabel(k.GuiText)
				label:SetDark(true)
				label:SetPos(10, 3 + 3)
				label:SetParent(panel)
				
				local combobox = Crimson.CreateComboBox()
				combobox:SetPos(EXTENSION.ScrollPanel:GetWide() - 230, 3)
				combobox:SetParent(panel)
				for i1,k1 in pairs(k.Options) do
					combobox:AddChoice(k1)
				end
				combobox:SetWide(200)
				
				function combobox:OnSelect(index)
					net.Start("VServerUpdate")
					net.WriteTable({{ Module = k.Module, Name = k.Name, Value = index}})
					net.SendToServer()
				end
				
				panel:SetSize(select(1, combobox:GetPos()) + combobox:GetWide() + 10, combobox:GetTall() + 5)
				panel:SetPaintBackground(false)
				
				local cat = nCats[k.Category]
				
				panel:SetContentAlignment( 4 )
				panel:DockMargin( 1, 0, 1, 0 )
				
				panel:Dock(TOP)
				panel:SetParent(cat)
				
				combobox:ChooseOptionID(k.Value)
			elseif(k.Type == "Checkbox") then
				local panel = vgui.Create("DPanel")
				
				local cb = Crimson.CreateCheckBox(k.GuiText)
				cb:SetDark(true)
				cb:SetPos(10, 3)
				cb:SetParent(panel)
				
				cb:SetValue(k.Value)
				
				function cb:OnChange()
					net.Start("VServerUpdate")
					net.WriteTable({{Module = k.Module, Name = k.Name, Value = cb:GetChecked()}})
					net.SendToServer()
				end
				
				
				panel:SetSize(cb:GetWide() + 10, cb:GetTall() + 5)
				panel:SetPaintBackground(false)
				
				local cat = nCats[k.Category]
				
				panel:SetContentAlignment( 4 )
				panel:DockMargin( 1, 0, 1, 0 )
				
				panel:Dock(TOP)
				panel:SetParent(cat)
			elseif(k.Type == "Slider") then
				local panel = vgui.Create("DPanel")
				
				local slider = Crimson.CreateSlider(k.GuiText, k.Bounds.Min, k.Bounds.Max, 2)
				slider:SetPos(10, 3)
				slider:SetParent(panel)
				slider:SetWide(300)
				
				slider:SetValue(k.Value)
				
				function slider:OnChange(index)
					net.Start("VServerUpdate")
					net.WriteTable({{ Module = k.Module, Name = k.Name, Value = index}})
					net.SendToServer()
				end
				
				panel:SetSize(slider:GetWide() + 10, slider:GetTall() + 5)
				panel:SetPaintBackground(false)
				
				local cat = nCats[k.Category]
				
				panel:SetContentAlignment( 4 )
				panel:DockMargin( 1, 0, 1, 0 )
				
				panel:Dock(TOP)
				panel:SetParent(cat)
				
			elseif(k.Type == "Colour") then
				-- Implement Me!
			elseif(k.Type == "NumberWang") then
				-- Implement Me!
			elseif(k.Type == "Text") then
				-- Implement Me!
			end
		end
	end)
	
	self:AddHook(Vermilion.EVENT_EXT_LOADED, "AddGui", function()
		Vermilion:AddInterfaceTab("server_control", "Server Settings", "server.png", "Manage generic limitations/restrictions and settings for the server.", function(panel)
			local scroll = vgui.Create("DCategoryList")
			scroll:SetSize(panel:GetWide() - 160, panel:GetTall() - 11)
			scroll:SetPos(0, 0)
			scroll:SetParent(panel)
			
			EXTENSION.ScrollPanel = scroll
			
			local clearDecals = Crimson.CreateButton("Clear Decals", function(self)
				net.Start("VClearDecals")
				net.SendToServer()
			end)
			clearDecals:SetPos(panel:GetWide() - 135, 10)
			clearDecals:SetSize(125, 30)
			clearDecals:SetParent(panel)
			clearDecals:SetTooltip("Clear all decals. Decals are the marks left behind when a bullet hits a surface or when something bleeds onto a surface. Clearing decals can offer a small performance boost.")
			
			
			
			local clearCorpses = Crimson.CreateButton("Clear Corpses", function(self)
				net.Start("VClearCorpses")
				net.SendToServer()
			end)
			clearCorpses:SetPos(panel:GetWide() - 135, 50)
			clearCorpses:SetSize(125, 30)
			clearCorpses:SetParent(panel)
			clearCorpses:SetTooltip("Clear the corpses of dead NPCs. Doing this can offer a small performance boost.")
			
			
			
			local setMOTD = Crimson.CreateButton("Set MOTD", function()
				local motdpanel = Crimson.CreateFrame(
					{
						['size'] = { 500, 300 },
						['pos'] = { (ScrW() / 2) - 250, (ScrH() / 2) - 150 },
						['closeBtn'] = true,
						['draggable'] = true,
						['title'] = "Set MOTD",
						['bgBlur'] = true
					}
				)
				
				local motd = vgui.Create("DTextEntry")
				motd:SetPos(10, 30)
				motd:SetSize(480, 240)
				motd:SetParent(motdpanel)
				motd:SetMultiline(true)
				EXTENSION.MOTDText = motd
				
				
				local optionsButton = Crimson.CreateButton("Options", function()
					local motdpanel2 = Crimson.CreateFrame(
						{
							['size'] = { 500, 300 },
							['pos'] = { (ScrW() / 2) - 250, (ScrH() / 2) - 150 },
							['closeBtn'] = true,
							['draggable'] = true,
							['title'] = "MOTD Variables",
							['bgBlur'] = false
						}
					)
					
					
					local ishtmlcb = nil
					local isurlcb = nil
					
					ishtmlcb = vgui.Create("DCheckBoxLabel")
					ishtmlcb:SetPos(10, 30)
					ishtmlcb:SetText("HTML Based")
					ishtmlcb:SizeToContents()
					ishtmlcb:SetParent(motdpanel2)
					ishtmlcb:SetBright(true)
					ishtmlcb:SetValue(EXTENSION.IsHTML)
					ishtmlcb.OnChange = function()
						EXTENSION.IsHTML = ishtmlcb:GetChecked()
						isurlcb:SetDisabled(ishtmlcb:GetChecked())
					end
					
					isurlcb = vgui.Create("DCheckBoxLabel")
					isurlcb:SetPos(10, 50)
					isurlcb:SetText("Is URL")
					isurlcb:SizeToContents()
					isurlcb:SetParent(motdpanel2)
					isurlcb:SetBright(true)
					isurlcb:SetValue(EXTENSION.IsURL)
					isurlcb.OnChange = function()
						EXTENSION.IsURL = isurlcb:GetChecked()
						ishtmlcb:SetDisabled(isurlcb:GetChecked())
					end
					
					ishtmlcb:SetDisabled(isurlcb:GetChecked())
					isurlcb:SetDisabled(ishtmlcb:GetChecked())
					
					EXTENSION.IsHTMLCB = ishtmlcb
					EXTENSION.IsURLCB = isurlcb
					
					local confirmButton = Crimson.CreateButton("OK", function()
						motdpanel2:Close()
					end)
					confirmButton:SetPos((500 - 100) / 2, 275)
					confirmButton:SetSize(100, 20)
					confirmButton:SetParent(motdpanel2)
					
					motdpanel2:MakePopup()
					motdpanel2:DoModal()
					motdpanel2:SetAutoDelete(true)
				end)
				optionsButton:SetPos(365, 275)
				optionsButton:SetSize(100, 20)
				optionsButton:SetParent(motdpanel)
				
				
				
				local confirmButton = Crimson.CreateButton("OK", function()
					net.Start("VUpdateMOTD")
					net.WriteString(motd:GetValue())
					net.WriteBoolean(EXTENSION.IsHTML)
					net.WriteBoolean(EXTENSION.IsURL)
					net.SendToServer()
					motdpanel:Close()
				end)
				confirmButton:SetPos(255, 275)
				confirmButton:SetSize(100, 20)
				confirmButton:SetParent(motdpanel)
				
				local cancelButton = Crimson.CreateButton("Cancel", function()
					motdpanel:Close()
				end)
				cancelButton:SetPos(145, 275)
				cancelButton:SetSize(100, 20)
				cancelButton:SetParent(motdpanel)
				
				local activeValuesButton = Crimson.CreateButton("Variables", function()
					local motdpanel2 = Crimson.CreateFrame(
						{
							['size'] = { 500, 300 },
							['pos'] = { (ScrW() / 2) - 250, (ScrH() / 2) - 150 },
							['closeBtn'] = true,
							['draggable'] = true,
							['title'] = "MOTD Variables",
							['bgBlur'] = false
						}
					)
					local varList = Crimson.CreateList({"Name", "Description"})
					varList:SetPos(10, 30)
					varList:SetSize(480, 260)
					varList:SetParent(motdpanel2)
					
					EXTENSION.VarList = varList
					
					net.Start("VGetMOTDVars")
					net.SendToServer()
					
					motdpanel2:MakePopup()
					motdpanel2:DoModal()
					motdpanel2:SetAutoDelete(true)
				end)
				activeValuesButton:SetPos(35, 275)
				activeValuesButton:SetSize(100, 20)
				activeValuesButton:SetParent(motdpanel)
				
				
				
				net.Start("VGetMOTD")
				net.SendToServer()
				
				motdpanel:MakePopup()
				motdpanel:DoModal()
				motdpanel:SetAutoDelete(true)
			end)
			setMOTD:SetPos(panel:GetWide() - 135, 90)
			setMOTD:SetSize(125, 30)
			setMOTD:SetParent(panel)
			
			net.Start("VServerGetProperties")
			net.SendToServer()
		end, 1)
	end)
	
	self:AddHook("ShouldCollide", function(ent1, ent2)
		local mode = tonumber(GetGlobalString("Vermilion_PlayerCollideMode", "1"))
		if(mode == 1) then return end -- disabled
		if(IsValid(ent1) and IsValid(ent2)) then
			if(ent1:IsPlayer() and ent2:IsPlayer()) then
				if(mode == 2) then return false else -- always disable
					-- figure out reliable and light way of predicting this on the client.
					--if(not Vermilion:HasPermission(ent1, "player_collide") or not Vermilion:HasPermission(ent2, "player_collide")) then return false end -- disable if one or both players doesn't have the collision permission.
				end
			end
		end
	end)
	
end

function EXTENSION:InitShared()
	local META = FindMetaTable("Player")
	
	function META:IsAdmin()
		if(CLIENT) then
			return self:GetNWBool("Vermilion_Identify_Admin", false)
		end
		return Vermilion:HasPermission(self, "identify_as_admin")
	end
	
	properties.Add("vsteamprofile",
		{
			MenuLabel = "Open Steam Profile",
			Order = 5,
			MenuIcon = "icon16/page_find.png",
			Filter = function(self, ent, ply)
				if(not IsValid(ent)) then return false end
				if(not ent:IsPlayer()) then return false end
				return true
			end,
			Action = function(self, ent)
				ent:ShowProfile()
			end,
			Receive = function(self, length, ply)
			
			end
		}
	)
end

Vermilion:RegisterExtension(EXTENSION)