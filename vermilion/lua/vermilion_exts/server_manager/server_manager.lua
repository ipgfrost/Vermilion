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
	["spawn_all"] = "This player can spawn anything. Same as giving the player all of the spawn_ permissions."
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
			"spawn_all"
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
			"spawn_all"
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

function EXTENSION:InitServer()
	
	local META = FindMetaTable("Player")
	
	function META:IsAdmin()
		if(CLIENT) then
			return self:GetNWBool("Vermilion_Identify_Admin", false)
		end
		return Vermilion:HasPermission(self, "identify_as_admin")
	end


	if(META.Vermilion_Lock == nil) then META.Vermilion_Lock = META.Lock end
	function META:Lock()
		if(not Vermilion:HasPermission(self, "lock_immunity") or not EXTENSION:GetData("enable_lock_immunity", true)) then
			self:Vermilion_Lock()
		end
	end

	if(META.Vermilion_Freeze == nil) then META.Vermilion_Freeze = META.Freeze end
	function META:Freeze( freeze )
		if(not Vermilion:HasPermission(self, "lock_immunity") or not EXTENSION:GetData("enable_lock_immunity", true)) then
			self:Vermilion_Freeze( freeze )
		end
	end

	if(META.Vermilion_Kill == nil) then META.Vermilion_Kill = META.Kill end
	function META:Kill()
		if(not Vermilion:HasPermission(self, "kill_immunity") or not EXTENSION:GetData("enable_kill_immunity", true)) then
			self:Vermilion_Kill()
		end
	end

	if(META.Vermilion_KillSilent == nil) then META.Vermilion_KillSilent = META.KillSilent end
	function META:KillSilent()
		if(not Vermilion:HasPermission(self, "kill_immunity") or not EXTENSION:GetData("enable_kill_immunity", true)) then
			self:Vermilion_KillSilent()
		end
	end

	if(META.Vermilion_Kick == nil) then META.Vermilion_Kick = META.Kick end
	function META:Kick(reason)
		if(not Vermilion:HasPermission(self, "kick_immunity") or not EXTENSION:GetData("enable_kick_immunity", true)) then
			self:Vermilion_Kick(reason)
		end
	end
	
	Vermilion:AddChatCommand("broadcast", function(sender, text)
		if(Vermilion:HasPermissionError(sender, "broadcast_hint")) then
			Vermilion:BroadcastNotify(table.concat(text, " ", 1, table.Count(text)), 10, NOTIFY_HINT)
		end
	end, "<text>")
	
	Vermilion:AddChatCommand("addresource", function(sender, text)
		if(Vermilion:HasPermissionError(sender, "vermilion_add_resource")) then
			local str = table.concat(text, " ", 1, table.Count(text))
			resource.AddSingleFile(str)
			Vermilion:SendNotify(sender, str .. " has been added to the client resources!")
		end
	end, "<resource path>")
	
	timer.Simple(1, function() -- This timer allows Vermilion to overwrite other addons by "waiting" for them to overwrite the function, then subsequently overwriting it after 1 second.
		if(META.Vermilion_CheckLimit == nil) then
			META.Vermilion_CheckLimit = META.CheckLimit
		end
		function META:CheckLimit(str)
			if(not EXTENSION:GetData("enable_limit_remover", true)) then
				return self:Vermilion_CheckLimit(str)
			end
			if(Vermilion:HasPermission(self, "no_spawn_restrictions")) then
				return true
			end
			return self:Vermilion_CheckLimit(str)
		end
	end)
	
	
	self:AddHook("EntityTakeDamage", "V_PlayerHurt", function(target, dmg)
		if(not EXTENSION:GetData("enable_no_damage", true)) then return end
		if(not target:IsPlayer()) then return end
		if(not Vermilion:HasPermission(target, "no_damage")) then return end
		if(EXTENSION:GetData("global_no_damage", false)) then
			dmg:ScaleDamage(0)
			return dmg
		end
		if(Vermilion:HasPermission(target, "no_damage")) then
			dmg:ScaleDamage(0)
			return dmg
		end
	end)
	
	
	self:AddHook("Tick", "V_BulletReload", function(vent, dTab)
		if(not EXTENSION:GetData("unlimited_ammo", true)) then return end
		for i,vplayer in pairs(player.GetAll()) do
			if(Vermilion:HasPermission(vplayer, "unlimited_ammo")) then
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
	
	
	self:AddHook("PlayerSwitchFlashlight", "LockFlashlight", function(vplayer, enabled)
		if(enabled and EXTENSION:GetData("flashlight_control", true)) then
			if(not Vermilion:HasPermission(vplayer, "flashlight")) then
				return false
			end
		end
	end)
	
	
	self:AddHook("PlayerNoClip", "LockNoclip", function(vplayer, enabled)
		if(enabled and EXTENSION:GetData("noclip_control", true)) then
			if(not Vermilion:HasPermission(vplayer, "noclip")) then
				return false
			end
		end
		if(EXTENSION:GetData("force_noclip_permissions", true)) then
			return true
		end
	end)
	
	
	self:AddHook("PlayerSpray", "LockSpray", function(vplayer)
		if(not Vermilion:HasPermission(vplayer, "spray") and EXTENSION:GetData("spray_control", true)) then
			return false
		end
	end)
	
	
	self:AddHook("PlayerCanHearPlayersVoice", "LockVOIP", function(listener, talker)
		if(not EXTENSION:GetData("voip_control", true)) then return end
		if(not Vermilion:HasPermission(talker, "use_voip")) then
			return false
		end
		if(not Vermilion:HasPermission(listener, "hear_voip")) then
			return false
		end
	end)
	
	
	self:AddHook("GetFallDamage", "Vermilion_FallDamage", function(vplayer, speed)
		if(not EXTENSION:GetData("disable_fall_damage", true)) then
			return
		end
		if(EXTENSION:GetData("global_no_fall_damage", false)) then
			return 0
		end
		if(Vermilion:HasPermission(vplayer, "no_fall_damage")) then
			return 0
		end
		if(Vermilion:HasPermission(vplayer, "reduced_fall_damage")) then
			return 5
		end
	end)
	
	
	self:AddHook("PlayerSay", "Vermilion_SayOverride", function(vplayer, text, teamChat)
		if(not Vermilion:HasPermission(vplayer, "chat")) then
			return ""
		end
	end)
	
	
	self:NetHook("VClearDecals", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "server_manage")) then
			net.Start("VClearDecals")
			net.Broadcast()
		end
	end)
	
	
	self:NetHook("VClearCorpses", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "server_manage")) then
			game.RemoveRagdolls()
			net.Start("VClearCorpses")
			net.Broadcast()
		end
	end)
	
	
	self:NetHook("VServerGetProperties", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "server_manage")) then
			net.Start("VServerGetProperties")
			net.WriteString(tostring(EXTENSION:GetData("unlimited_ammo", true)))
			net.WriteString(tostring(EXTENSION:GetData("enable_limit_remover", true)))
			net.WriteString(tostring(EXTENSION:GetData("enable_no_damage", true)))
			net.WriteString(tostring(EXTENSION:GetData("flashlight_control", true)))
			net.WriteString(tostring(EXTENSION:GetData("noclip_control", true)))
			net.WriteString(tostring(EXTENSION:GetData("spray_control", true)))
			net.WriteString(tostring(EXTENSION:GetData("voip_control", true)))
			net.WriteString(tostring(EXTENSION:GetData("enable_lock_immunity", true)))
			net.WriteString(tostring(EXTENSION:GetData("enable_kill_immunity", true)))
			net.WriteString(tostring(EXTENSION:GetData("enable_kick_immunity", true)))
			net.WriteString(tostring(EXTENSION:GetData("disable_fall_damage", true)))
			net.WriteString(tostring(EXTENSION:GetData("force_noclip_permissions", true)))
			net.WriteString(tostring(EXTENSION:GetData("disable_owner_nag", false)))
			net.Send(vplayer)
		end
	end)
	
	
	self:NetHook("VServerUpdate", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "server_manage")) then
			EXTENSION:SetData("unlimited_ammo", tobool(net.ReadString()))
			EXTENSION:SetData("enable_limit_remover", tobool(net.ReadString()))
			EXTENSION:SetData("enable_no_damage", tobool(net.ReadString()))
			EXTENSION:SetData("flashlight_Control", tobool(net.ReadString()))
			EXTENSION:SetData("noclip_control", tobool(net.ReadString()))
			EXTENSION:SetData("spray_control", tobool(net.ReadString()))
			EXTENSION:SetData("voip_control", tobool(net.ReadString()))
			EXTENSION:SetData("enable_lock_immunity", tobool(net.ReadString()))
			EXTENSION:SetData("enable_kill_immunity", tobool(net.ReadString()))
			EXTENSION:SetData("enable_kick_immunity", tobool(net.ReadString()))
			EXTENSION:SetData("disable_fall_damage", tobool(net.ReadString()))
			EXTENSION:SetData("force_noclip_permissions", tobool(net.ReadString()))
			EXTENSION:SetData("disable_owner_nag", tobool(net.ReadString()))
		end
	end)
	
	self:NetHook("VGetMOTD", function(vplayer)
		net.Start("VGetMOTD")
		net.WriteString(EXTENSION:GetData("motd", "Welcome to %servername%!\nThis server is running the Vermilion Server Administration Tool!\nBe on your best behaviour!"))
		net.Send(vplayer)
	end)
	
	self:NetHook("VUpdateMOTD", function(vplayer)
		if(Vermilion:HasPermissionError(vplayer, "server_manage")) then
			EXTENSION:SetData("motd", net.ReadString())
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
	self:NetHook("VClearDecals", function()
		RunConsoleCommand("r_cleardecals")
	end)
	self:NetHook("VClearCorpses", function()
		game.RemoveRagdolls()
	end)
	self:NetHook("VServerGetProperties", function()
		EXTENSION.unlimitedAmmoEnabled:SetValue( tobool(net.ReadString()) )
		EXTENSION.disableSpawnRestrictions:SetValue( tobool(net.ReadString()) )
		EXTENSION.disableDamage:SetValue( tobool(net.ReadString()) )
		EXTENSION.disableFlashlight:SetValue( tobool(net.ReadString()) )
		EXTENSION.disableNoclip:SetValue( tobool(net.ReadString()) )
		EXTENSION.disableSprays:SetValue( tobool(net.ReadString()) )
		EXTENSION.disableVoip:SetValue( tobool(net.ReadString()) )
		EXTENSION.lockImmunity:SetValue( tobool(net.ReadString()) )
		EXTENSION.killImmunity:SetValue( tobool(net.ReadString()) )
		EXTENSION.kickImmunity:SetValue( tobool(net.ReadString()) )
		EXTENSION.fallDamage:SetValue( tobool(net.ReadString()) )
		EXTENSION.forceNoclip:SetValue( tobool(net.ReadString()) )
		EXTENSION.disableOwnerNag:SetValue( tobool(net.ReadString()) )
	end)
	
	
	self:NetHook("VGetMOTD", function()
		if(IsValid(EXTENSION.MOTDText)) then
			EXTENSION.MOTDText:SetValue(net.ReadString())
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
	
	self:AddHook(Vermilion.EVENT_EXT_LOADED, "AddGui", function()
		Vermilion:AddInterfaceTab("server_control", "Server Settings", "server.png", "Manage generic limitations/restrictions and settings for the server.", function(panel)
			local function updateServer()
				net.Start("VServerUpdate")
				net.WriteString(tostring(EXTENSION.unlimitedAmmoEnabled:GetChecked()))
				net.WriteString(tostring(EXTENSION.disableSpawnRestrictions:GetChecked()))
				net.WriteString(tostring(EXTENSION.disableDamage:GetChecked()))
				net.WriteString(tostring(EXTENSION.disableFlashlight:GetChecked()))
				net.WriteString(tostring(EXTENSION.disableNoclip:GetChecked()))
				net.WriteString(tostring(EXTENSION.disableSprays:GetChecked()))
				net.WriteString(tostring(EXTENSION.disableVoip:GetChecked()))
				net.WriteString(tostring(EXTENSION.lockImmunity:GetChecked()))
				net.WriteString(tostring(EXTENSION.killImmunity:GetChecked()))
				net.WriteString(tostring(EXTENSION.kickImmunity:GetChecked()))
				net.WriteString(tostring(EXTENSION.fallDamage:GetChecked()))
				net.WriteString(tostring(EXTENSION.forceNoclip:GetChecked()))
				net.WriteString(tostring(EXTENSION.disableOwnerNag:GetChecked()))
				net.SendToServer()
			end
			
			EXTENSION.unlimitedAmmoEnabled = vgui.Create("DCheckBoxLabel")
			EXTENSION.unlimitedAmmoEnabled:SetText("Unlimited ammunition for permitted players")
			EXTENSION.unlimitedAmmoEnabled:SetParent(panel)
			EXTENSION.unlimitedAmmoEnabled:SetPos(10, 10)
			EXTENSION.unlimitedAmmoEnabled:SetDark(true)
			EXTENSION.unlimitedAmmoEnabled:SizeToContents()
			EXTENSION.unlimitedAmmoEnabled.OnChange = function(self, val)
				updateServer()
			end
			
			
			
			EXTENSION.disableSpawnRestrictions = vgui.Create("DCheckBoxLabel")
			EXTENSION.disableSpawnRestrictions:SetText("Disable item spawn restrictions for permitted players")
			EXTENSION.disableSpawnRestrictions:SetParent(panel)
			EXTENSION.disableSpawnRestrictions:SetPos(10, 30)
			EXTENSION.disableSpawnRestrictions:SetDark(true)
			EXTENSION.disableSpawnRestrictions:SizeToContents()
			EXTENSION.disableSpawnRestrictions.OnChange = function(self, val)
				updateServer()
			end
			
			
			
			EXTENSION.disableDamage = vgui.Create("DCheckBoxLabel")
			EXTENSION.disableDamage:SetText("Disable damage for permitted players")
			EXTENSION.disableDamage:SetParent(panel)
			EXTENSION.disableDamage:SetPos(10, 50)
			EXTENSION.disableDamage:SetDark(true)
			EXTENSION.disableDamage:SizeToContents()
			EXTENSION.disableDamage.OnChange = function(self, val)
				updateServer()
			end
			
			
			
			EXTENSION.disableFlashlight = vgui.Create("DCheckBoxLabel")
			EXTENSION.disableFlashlight:SetText("Disable flashlight for unpermitted players")
			EXTENSION.disableFlashlight:SetParent(panel)
			EXTENSION.disableFlashlight:SetPos(10, 70)
			EXTENSION.disableFlashlight:SetDark(true)
			EXTENSION.disableFlashlight:SizeToContents()
			EXTENSION.disableFlashlight.OnChange = function(self, val)
				updateServer()
			end
			
			
			
			EXTENSION.disableNoclip = vgui.Create("DCheckBoxLabel")
			EXTENSION.disableNoclip:SetText("Disable noclip for unpermitted players")
			EXTENSION.disableNoclip:SetParent(panel)
			EXTENSION.disableNoclip:SetPos(10, 90)
			EXTENSION.disableNoclip:SetDark(true)
			EXTENSION.disableNoclip:SizeToContents()
			EXTENSION.disableNoclip.OnChange = function(self, val)
				updateServer()
			end
			
			
			
			EXTENSION.disableSprays = vgui.Create("DCheckBoxLabel")
			EXTENSION.disableSprays:SetText("Disable sprays for unpermitted players")
			EXTENSION.disableSprays:SetParent(panel)
			EXTENSION.disableSprays:SetPos(10, 110)
			EXTENSION.disableSprays:SetDark(true)
			EXTENSION.disableSprays:SizeToContents()
			EXTENSION.disableSprays.OnChange = function(self, val)
				updateServer()
			end
			
			
			
			EXTENSION.disableVoip = vgui.Create("DCheckBoxLabel")
			EXTENSION.disableVoip:SetText("Disable VoIP for unpermitted players")
			EXTENSION.disableVoip:SetParent(panel)
			EXTENSION.disableVoip:SetPos(10, 130)
			EXTENSION.disableVoip:SetDark(true)
			EXTENSION.disableVoip:SizeToContents()
			EXTENSION.disableVoip.OnChange = function(self, val)
				updateServer()
			end
			
			
			
			EXTENSION.lockImmunity = vgui.Create("DCheckBoxLabel")
			EXTENSION.lockImmunity:SetText("Prevent permitted players from being locked by Lua scripts")
			EXTENSION.lockImmunity:SetParent(panel)
			EXTENSION.lockImmunity:SetPos(10, 150)
			EXTENSION.lockImmunity:SetDark(true)
			EXTENSION.lockImmunity:SizeToContents()
			EXTENSION.lockImmunity.OnChange = function(self, val)
				updateServer()
			end
			
			
			EXTENSION.killImmunity = vgui.Create("DCheckBoxLabel")
			EXTENSION.killImmunity:SetText("Prevent permitted players from being killed by Lua scripts")
			EXTENSION.killImmunity:SetParent(panel)
			EXTENSION.killImmunity:SetPos(10, 170)
			EXTENSION.killImmunity:SetDark(true)
			EXTENSION.killImmunity:SizeToContents()
			EXTENSION.killImmunity.OnChange = function(self, val)
				updateServer()
			end
			
			
			
			EXTENSION.kickImmunity = vgui.Create("DCheckBoxLabel")
			EXTENSION.kickImmunity:SetText("Prevent permitted players from being kicked by Lua scripts")
			EXTENSION.kickImmunity:SetParent(panel)
			EXTENSION.kickImmunity:SetPos(10, 190)
			EXTENSION.kickImmunity:SetDark(true)
			EXTENSION.kickImmunity:SizeToContents()
			EXTENSION.kickImmunity.OnChange = function(self, val)
				updateServer()
			end
			
			
			
			EXTENSION.fallDamage = vgui.Create("DCheckBoxLabel")
			EXTENSION.fallDamage:SetText("Disable fall damage for permitted players")
			EXTENSION.fallDamage:SetParent(panel)
			EXTENSION.fallDamage:SetPos(10, 210)
			EXTENSION.fallDamage:SetDark(true)
			EXTENSION.fallDamage:SizeToContents()
			EXTENSION.fallDamage.OnChange = function(self, val)
				updateServer()
			end
			
			
			
			EXTENSION.forceNoclip = vgui.Create("DCheckBoxLabel")
			EXTENSION.forceNoclip:SetText("Forcibly apply noclip settings (useful for gamemodes which disable noclip)")
			EXTENSION.forceNoclip:SetParent(panel)
			EXTENSION.forceNoclip:SetPos(10, 230)
			EXTENSION.forceNoclip:SetDark(true)
			EXTENSION.forceNoclip:SizeToContents()
			EXTENSION.forceNoclip.OnChange = function(self, val)
				updateServer()
			end
			
			EXTENSION.disableOwnerNag = vgui.Create("DCheckBoxLabel")
			EXTENSION.disableOwnerNag:SetText("Disable 'no owner' alert on join.")
			EXTENSION.disableOwnerNag:SetParent(panel)
			EXTENSION.disableOwnerNag:SetPos(10, 250)
			EXTENSION.disableOwnerNag:SetDark(true)
			EXTENSION.disableOwnerNag:SizeToContents()
			EXTENSION.disableOwnerNag.OnChange = function(self, val)
				updateServer()
			end
			
			
			
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
				
				local confirmButton = Crimson.CreateButton("OK", function()
					net.Start("VUpdateMOTD")
					net.WriteString(motd:GetValue())
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
end

Vermilion:RegisterExtension(EXTENSION)