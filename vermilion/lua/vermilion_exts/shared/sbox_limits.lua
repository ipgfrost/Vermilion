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
EXTENSION.Name = "Sandbox Limits"
EXTENSION.ID = "sbox_limits"
EXTENSION.Description = "Handles sandbox limits"
EXTENSION.Author = "Ned"
EXTENSION.Permissions = {
	"sbox_manage",
	"no_damage",
	"unlimited_ammo",
	"no_spawn_restrictions",
	"flashlight",
	"noclip",
	"spray",
	"use_voip",
	"hear_voip",
	"no_fall_damage",
	"reduced_fall_damage"
}
EXTENSION.RankPermissions = {
	{ "admin", {
			"sbox_manage",
			"no_damage",
			"unlimited_ammo",
			"no_spawn_restrictions",
			"flashlight",
			"noclip",
			"spray",
			"use_voip",
			"hear_voip",
			"no_fall_damage"
		}
	},
	{ "player", {
			"flashlight",
			"noclip",
			"spray",
			"use_voip",
			"hear_voip",
			"reduced_fall_damage"
		}
	}
}
EXTENSION.NetworkStrings = {
	"VClearDecals",
	"VClearCorpses",
	"VSandboxUpdate",
	"VSandboxGetProperties"
}

function EXTENSION:InitServer()

	local META = FindMetaTable("Player")
	
	timer.Simple(1, function() -- This timer allows Vermilion to overwrite other addons by "waiting" for them to overwrite the function, then subsequently overwriting it after 1 second.
		if(META.Vermilion_CheckLimit == nil) then
			META.Vermilion_CheckLimit = META.CheckLimit
		end
		function META:CheckLimit(str)
			if(not Vermilion:GetSetting("enable_limit_remover", true)) then
				return self:Vermilion_CheckLimit(str)
			end
			if(Vermilion:HasPermission(self, "no_spawn_restrictions")) then
				return true
			end
			return self:Vermilion_CheckLimit(str)
		end
	end)
	
	self:AddHook("EntityTakeDamage", "V_PlayerHurt", function(target, dmg)
		if(not Vermilion:GetSetting("enable_no_damage", true)) then return end
		if(not target:IsPlayer()) then return end
		if(not Vermilion:HasPermission(target, "no_damage")) then return end
		if(Vermilion:GetSetting("global_no_damage", false)) then
			dmg:ScaleDamage(0)
			return dmg
		end
		if(Vermilion:HasPermission(target, "no_damage")) then
			dmg:ScaleDamage(0)
			return dmg
		end
	end)
	self:AddHook("Tick", "V_BulletReload", function(vent, dTab)
		if(not Vermilion:GetSetting("unlimited_ammo", true)) then return end
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
		if(enabled and Vermilion:GetSetting("flashlight_control", true)) then
			if(not Vermilion:HasPermission(vplayer, "flashlight")) then
				return false
			end
		end
	end)
	self:AddHook("PlayerNoclip", "LockNoclip", function(vplayer, enabled)
		if(enabled and Vermilion:GetSetting("noclip_control", true)) then
			if(not Vermilion:HasPermission(vplayer, "noclip")) then
				return false
			end
		end
	end)
	self:AddHook("PlayerSpray", "LockSpray", function(vplayer)
		if(not Vermilion:HasPermission(vplayer, "spray") and Vermilion:GetSetting("spray_control", true)) then
			return false
		end
	end)
	self:AddHook("PlayerCanHearPlayersVoice", "LockVOIP", function(listener, talker)
		if(not Vermilion:GetSetting("voip_control", true)) then return end
		if(not Vermilion:HasPermission(talker, "use_voip")) then
			return false
		end
		if(not Vermilion:HasPermission(listener, "hear_voip")) then
			return false
		end
	end)
	self:AddHook("GetFallDamage", "Vermilion_FallDamage", function(vplayer, speed)
		if(Vermilion:GetSetting("global_no_fall_damage", false)) then
			return 0
		end
		if(Vermilion:HasPermission(vplayer, "no_fall_damage")) then
			return 0
		end
		if(Vermilion:HasPermission(vplayer, "reduced_fall_damage")) then
			return 5
		end
	end)
	self:AddHook("VNET_VClearDecals", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "sbox_manage")) then
			net.Start("VClearDecals")
			net.Broadcast()
		end
	end)
	self:AddHook("VNET_VClearCorpses", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "sbox_manage")) then
			game.RemoveRagdolls()
			net.Start("VClearCorpses")
			net.Broadcast()
		end
	end)
	self:AddHook("VNET_VSandboxGetProperties", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "sbox_manage")) then
			net.Start("VSandboxGetProperties")
			net.WriteString(tostring(Vermilion:GetSetting("unlimited_ammo", true)))
			net.WriteString(tostring(Vermilion:GetSetting("enable_limit_remover", true)))
			net.WriteString(tostring(Vermilion:GetSetting("enable_no_damage", true)))
			net.WriteString(tostring(Vermilion:GetSetting("flashlight_control", true)))
			net.WriteString(tostring(Vermilion:GetSetting("noclip_control", true)))
			net.WriteString(tostring(Vermilion:GetSetting("spray_control", true)))
			net.WriteString(tostring(Vermilion:GetSetting("voip_control", true)))
			net.Send(vplayer)
		end
	end)
	self:AddHook("VNET_VSandboxUpdate", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "sbox_manage")) then
			Vermilion:SetSetting("unlimited_ammo", tobool(net.ReadString()))
			Vermilion:SetSetting("enable_limit_remover", tobool(net.ReadString()))
			Vermilion:SetSetting("enable_no_damage", tobool(net.ReadString()))
			Vermilion:SetSetting("flashlight_Control", tobool(net.ReadString()))
			Vermilion:SetSetting("noclip_control", tobool(net.ReadString()))
			Vermilion:SetSetting("spray_control", tobool(net.ReadString()))
			Vermilion:SetSetting("voip_control", tobool(net.ReadString()))
		end
	end)
	self:AddHook(Vermilion.EVENT_EXT_LOADED, "AddGui", function()
		Vermilion:AddInterfaceTab("sbox_control", "sbox_manage")
	end)
end

function EXTENSION:InitClient()
	self:AddHook("VNET_VClearDecals", function()
		RunConsoleCommand("r_cleardecals")
	end)
	self:AddHook("VNET_VClearCorpses", function()
		game.RemoveRagdolls()
	end)
	self:AddHook("VNET_VSandboxGetProperties", function()
		EXTENSION.unlimitedAmmoEnabled:SetValue( tobool(net.ReadString()) )
		EXTENSION.disableSpawnRestrictions:SetValue( tobool(net.ReadString()) )
		EXTENSION.disableDamage:SetValue( tobool(net.ReadString()) )
		EXTENSION.disableFlashlight:SetValue( tobool(net.ReadString()) )
		EXTENSION.disableNoclip:SetValue( tobool(net.ReadString()) )
		EXTENSION.disableSprays:SetValue( tobool(net.ReadString()) )
		EXTENSION.disableVoip:SetValue( tobool(net.ReadString()) )
	end)
	
	
	self:AddHook(Vermilion.EVENT_EXT_LOADED, "AddGui", function()
		Vermilion:AddInterfaceTab("sbox_control", "Sandbox Control", "world_edit.png", "Manage aspects of the sandbox gamemode", function(panel)
			local function updateSBOX()
				net.Start("VSandboxUpdate")
				net.WriteString(tostring(EXTENSION.unlimitedAmmoEnabled:GetChecked()))
				net.WriteString(tostring(EXTENSION.disableSpawnRestrictions:GetChecked()))
				net.WriteString(tostring(EXTENSION.disableDamage:GetChecked()))
				net.WriteString(tostring(EXTENSION.disableFlashlight:GetChecked()))
				net.WriteString(tostring(EXTENSION.disableNoclip:GetChecked()))
				net.WriteString(tostring(EXTENSION.disableSprays:GetChecked()))
				net.WriteString(tostring(EXTENSION.disableVoip:GetChecked()))
				net.SendToServer()
			end
			
			EXTENSION.unlimitedAmmoEnabled = vgui.Create("DCheckBoxLabel")
			EXTENSION.unlimitedAmmoEnabled:SetText("Unlimited ammunition for permitted players")
			EXTENSION.unlimitedAmmoEnabled:SetParent(panel)
			EXTENSION.unlimitedAmmoEnabled:SetPos(10, 10)
			EXTENSION.unlimitedAmmoEnabled:SetDark(true)
			EXTENSION.unlimitedAmmoEnabled:SizeToContents()
			EXTENSION.unlimitedAmmoEnabled.OnChange = function(self, val)
				updateSBOX()
			end
			
			
			
			EXTENSION.disableSpawnRestrictions = vgui.Create("DCheckBoxLabel")
			EXTENSION.disableSpawnRestrictions:SetText("Disable item spawn restrictions for permitted players")
			EXTENSION.disableSpawnRestrictions:SetParent(panel)
			EXTENSION.disableSpawnRestrictions:SetPos(10, 30)
			EXTENSION.disableSpawnRestrictions:SetDark(true)
			EXTENSION.disableSpawnRestrictions:SizeToContents()
			EXTENSION.disableSpawnRestrictions.OnChange = function(self, val)
				updateSBOX()
			end
			
			
			
			EXTENSION.disableDamage = vgui.Create("DCheckBoxLabel")
			EXTENSION.disableDamage:SetText("Disable damage for permitted players")
			EXTENSION.disableDamage:SetParent(panel)
			EXTENSION.disableDamage:SetPos(10, 50)
			EXTENSION.disableDamage:SetDark(true)
			EXTENSION.disableDamage:SizeToContents()
			EXTENSION.disableDamage.OnChange = function(self, val)
				updateSBOX()
			end
			
			
			
			EXTENSION.disableFlashlight = vgui.Create("DCheckBoxLabel")
			EXTENSION.disableFlashlight:SetText("Disable flashlight for unpermitted players")
			EXTENSION.disableFlashlight:SetParent(panel)
			EXTENSION.disableFlashlight:SetPos(10, 70)
			EXTENSION.disableFlashlight:SetDark(true)
			EXTENSION.disableFlashlight:SizeToContents()
			EXTENSION.disableFlashlight.OnChange = function(self, val)
				updateSBOX()
			end
			
			
			
			EXTENSION.disableNoclip = vgui.Create("DCheckBoxLabel")
			EXTENSION.disableNoclip:SetText("Disable noclip for unpermitted players")
			EXTENSION.disableNoclip:SetParent(panel)
			EXTENSION.disableNoclip:SetPos(10, 90)
			EXTENSION.disableNoclip:SetDark(true)
			EXTENSION.disableNoclip:SizeToContents()
			EXTENSION.disableNoclip.OnChange = function(self, val)
				updateSBOX()
			end
			
			
			
			EXTENSION.disableSprays = vgui.Create("DCheckBoxLabel")
			EXTENSION.disableSprays:SetText("Disable sprays for unpermitted players")
			EXTENSION.disableSprays:SetParent(panel)
			EXTENSION.disableSprays:SetPos(10, 110)
			EXTENSION.disableSprays:SetDark(true)
			EXTENSION.disableSprays:SizeToContents()
			EXTENSION.disableSprays.OnChange = function(self, val)
				updateSBOX()
			end
			
			
			
			EXTENSION.disableVoip = vgui.Create("DCheckBoxLabel")
			EXTENSION.disableVoip:SetText("Disable VoIP for unpermitted players")
			EXTENSION.disableVoip:SetParent(panel)
			EXTENSION.disableVoip:SetPos(10, 130)
			EXTENSION.disableVoip:SetDark(true)
			EXTENSION.disableVoip:SizeToContents()
			EXTENSION.disableVoip.OnChange = function(self, val)
				updateSBOX()
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
			
			
			
			net.Start("VSandboxGetProperties")
			net.SendToServer()
		end)
	end)
end

Vermilion:RegisterExtension(EXTENSION)