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
EXTENSION.Name = "Loadout Manager"
EXTENSION.ID = "loadout"
EXTENSION.Description = "Allows custom loadouts to be defined for each rank."
EXTENSION.Author = "Ned"
EXTENSION.Permissions = {
	"loadout_management"
}
EXTENSION.PermissionDefinitions = {
	["loadout_management"] = "This player can see the Loadouts tab in the Vermilion Menu and modify the settings within."
}
EXTENSION.RankPermissions = {
	{ "admin", {
			"loadout_management"
		}
	}
}
EXTENSION.NetworkStrings = {
	"VRankLoadoutLoad",
	"VRankLoadoutSave",
	"VGetLoadoutDisabled",
	"VSetLoadoutDisabled"
}

EXTENSION.RankLimits = {}
EXTENSION.EditingRank = ""

EXTENSION.DefaultLoadout = {
	"weapon_physgun", -- Physics Gun
	"weapon_pistol", -- 9mm pistol
	"weapon_rpg", -- RPG
	"weapon_crowbar", -- crowbar
	"weapon_357", -- .357 Magnum
	"weapon_shotgun", -- Shotgun
	"weapon_crossbow", -- Crossbow
	"weapon_physcannon", -- Gravity Gun
	"weapon_frag", -- Grenades
	"weapon_ar2", -- Pulse Rifle
	"gmod_camera", -- Camera
	"gmod_tool", -- Tool Gun
	"weapon_smg1" -- SMG
}

function EXTENSION:LoadSettings()
	self.RankLimits = Vermilion:GetSetting("loadouts", {})
	if(table.Count(self.RankLimits) == 0) then 
		self:ResetSettings()
		self:SaveSettings()
	end
end

function EXTENSION:SaveSettings()
	Vermilion:SetSetting("loadouts", self.RankLimits)
end

function EXTENSION:ResetSettings()
	local tab = {}
	for i,rank in pairs(Vermilion.Ranks) do
		tab[rank] = self.DefaultLoadout
	end
	self.RankLimits = tab
end

function EXTENSION:InitServer()
	
	
	self:NetHook("VRankLoadoutSave", function(vplayer)
		if(not Vermilion:HasPermission(vplayer, "loadout_management")) then
			return
		end
		local rnk = net.ReadString()
		local tab = net.ReadTable()
		EXTENSION.RankLimits[rnk] = tab
		EXTENSION:SaveSettings()
	end)
	
	self:NetHook("VRankLoadoutLoad", function(vplayer)
		if(not Vermilion:HasPermission(vplayer, "loadout_management")) then
			return
		end
		local rnk = net.ReadString()
		
		local tab = EXTENSION.RankLimits[rnk]
		if(not tab) then
			tab = {}
		end
		net.Start("VRankLoadoutLoad")
		net.WriteTable(tab)
		net.Send(vplayer)
	end)
	self:AddHook("PlayerLoadout", function(ply)
		if(Vermilion:GetSetting("disable_loadout_on_non_sandbox", true) and engine.ActiveGamemode() != "sandbox") then return end -- allow the gamemode to define the loadout.
		ply:RemoveAllAmmo()
		if (cvars.Bool("sbox_weapons", true)) then
			ply:GiveAmmo(256, "Pistol", true)
			ply:GiveAmmo(256, "SMG1", true)
			ply:GiveAmmo(5, "grenade", true)
			ply:GiveAmmo(64, "Buckshot", true)
			ply:GiveAmmo(32, "357", true)
			ply:GiveAmmo(32, "XBowBolt", true)
			ply:GiveAmmo(6, "AR2AltFire", true)
			ply:GiveAmmo(100, "AR2", true)
		end
		for i,weapon in pairs(EXTENSION.RankLimits[Vermilion.Ranks[Vermilion:GetRank(ply)]]) do
			ply:Give(weapon)
		end
		ply:SwitchToDefaultWeapon()
		return false
	end)
	
	self:NetHook("VGetLoadoutDisabled", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "loadout_management")) then
			net.Start("VGetLoadoutDisabled")
			net.WriteString(tostring(Vermilion:GetSetting("disable_loadout_on_non_sandbox", true)))
			net.Send(vplayer)
		end
	end)
	
	self:NetHook("VSetLoadoutDisabled", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "loadout_management")) then
			Vermilion:SetSetting("disable_loadout_on_non_sandbox", tobool(net.ReadString()))
		end
	end)
	
	self:AddHook(Vermilion.EVENT_EXT_LOADED, "AddGui", function()
		Vermilion:AddInterfaceTab("loadout", "loadout_management")
	end)
	
	self:AddHook("Vermilion-SaveConfigs", "loadout_save", function()
		EXTENSION:SaveSettings()
	end)
	
	EXTENSION:LoadSettings()
end


function EXTENSION:InitClient()
	self:AddHook("VRanksList", "RanksList", function(tab)
		if(not IsValid(EXTENSION.RanksList)) then
			return
		end
		EXTENSION.RanksList:Clear()
		for i,k in pairs(tab) do
			EXTENSION.RanksList:AddLine(k[1])
		end
	end)
	
	self:AddHook("VWeaponsList", function(tab)
		if(not IsValid(EXTENSION.AllWeaponsList)) then
			return
		end
		EXTENSION.AllWeaponsList:Clear()
		for i,k in pairs(tab) do
			EXTENSION.AllWeaponsList:AddLine(k.PrintName).WeaponClass = k.ClassName
		end
	end)
	
	self:NetHook("VRankLoadoutLoad", function()
		if(not IsValid(EXTENSION.RankPermissionsList)) then
			return
		end
		EXTENSION.RankPermissionsList:Clear()
		local tab = net.ReadTable()
		for i,k in pairs(tab) do
			local name = Vermilion.Utility.GetWeaponName(k)
			EXTENSION.RankPermissionsList:AddLine(name).WeaponClass = k
		end
	end)
	
	self:NetHook("VGetLoadoutDisabled", function()
		if(IsValid(EXTENSION.DisableLoadoutsCB)) then
			EXTENSION.DisableLoadoutsCB:SetValue(tobool(net.ReadString()))
		end
	end)
	
	self:AddHook(Vermilion.EVENT_EXT_LOADED, "AddGui", function()
		Vermilion:AddInterfaceTab("loadout", "Loadouts", "cart.png", "Change the set of weapons that a player spawns with", function(panel)
			local ranksList = Crimson.CreateList({ "Name" }, true, false)
			ranksList:SetParent(panel)
			ranksList:SetPos(10, 30)
			ranksList:SetSize(250, 190)
			EXTENSION.RanksList = ranksList
			
			local ranksLabel = Crimson:CreateHeaderLabel(ranksList, "Ranks")
			ranksLabel:SetParent(panel)
			
			local disableCheckbox = vgui.Create("DCheckBoxLabel")
			disableCheckbox:SetText("Disable loadout management on any gamemode that isn't sandbox.")
			disableCheckbox:SetPos(270, 30)
			disableCheckbox:SizeToContents()
			disableCheckbox:SetParent(panel)
			disableCheckbox.OnChange = function()
				net.Start("VSetLoadoutDisabled")
				net.WriteString(tostring(disableCheckbox:GetChecked()))
				net.SendToServer()
			end
			disableCheckbox:SetDark(true)
			EXTENSION.DisableLoadoutsCB = disableCheckbox
			
			
			local guiRankPermissionsList = Crimson.CreateList({ "Name" })
			guiRankPermissionsList:SetParent(panel)
			guiRankPermissionsList:SetPos(10, 250)
			guiRankPermissionsList:SetSize(250, 280)
			EXTENSION.RankPermissionsList = guiRankPermissionsList
			
			local blockedWeaponsLabel = Crimson:CreateHeaderLabel(guiRankPermissionsList, "Loadout")
			blockedWeaponsLabel:SetParent(panel)
			
			
			
			local guiAllWeaponsList = Crimson.CreateList({ "Name" })
			guiAllWeaponsList:SetParent(panel)
			guiAllWeaponsList:SetPos(525, 250)
			guiAllWeaponsList:SetSize(250, 280)			
			EXTENSION.AllWeaponsList = guiAllWeaponsList
			
			local allWeaponsLabel = Crimson:CreateHeaderLabel(guiAllWeaponsList, "All Weapons")
			allWeaponsLabel:SetParent(panel)
			
			
			
			local loadRankPermissionsButton = Crimson.CreateButton("Load Loadout", function(self)
				if(table.Count(ranksList:GetSelected()) > 1) then
					Crimson:CreateErrorDialog("Cannot load loadout for multiple ranks!")
					return
				end
				if(table.Count(ranksList:GetSelected()) == 0) then
					Crimson:CreateErrorDialog("Must select a rank to load the loadout for!")
					return
				end
				if(ranksList:GetSelected()[1]:GetValue(1) == "banned") then
					Crimson:CreateErrorDialog("Cannot edit the loadout of this rank; it is a protected rank!")
					return
				end
				net.Start("VRankLoadoutLoad")
				net.WriteString(ranksList:GetSelected()[1]:GetValue(1))
				net.SendToServer()
				blockedWeaponsLabel:SetText("Loadout - " .. ranksList:GetSelected()[1]:GetValue(1))
				EXTENSION.EditingRank = ranksList:GetSelected()[1]:GetValue(1)
			end)
			loadRankPermissionsButton:SetPos(270, 250)
			loadRankPermissionsButton:SetSize(245, 30)
			loadRankPermissionsButton:SetParent(panel)
			loadRankPermissionsButton:SetTooltip("Load the list of weapons to be given to a rank on spawn.\nMake sure you have selected a rank in the \"Ranks\" list before clicking this.")
			
			
			
			local saveRankPermissionsButton = Crimson.CreateButton("Save Loadout", function(self)
				if(EXTENSION.EditingRank == "") then
					Crimson:CreateErrorDialog("Must be editing rank loadout before you can save them!")
					return
				end
				net.Start("VRankLoadoutSave")
				net.WriteString(EXTENSION.EditingRank)
				local tab = {}
				for i,k in pairs(guiRankPermissionsList:GetLines()) do
					table.insert(tab, k.WeaponClass)
				end
				net.WriteTable(tab)
				net.SendToServer()
				guiRankPermissionsList:Clear()
				EXTENSION.EditingRank = ""
				blockedWeaponsLabel:SetText("Loadout")
				blockedWeaponsLabel:SizeToContents()
				blockedWeaponsLabel:SetPos(110 - (blockedWeaponsLabel:GetWide() / 2), 230)
			end)
			saveRankPermissionsButton:SetPos(270, 500)
			saveRankPermissionsButton:SetSize(245, 30)
			saveRankPermissionsButton:SetParent(panel)
			saveRankPermissionsButton:SetTooltip("Save the list of weapons to be given to a rank on spawn.\nYou don't have to select a rank on the ranks list, but you\nmust have successfully loaded a list for a rank before\nclicking this button.")
			
			
			
			local giveRankPermissionButton = Crimson.CreateButton("Add Weapon", function(self)
				if(EXTENSION.EditingRank == "") then
					Crimson:CreateErrorDialog("Must be editing a rank add to the loadout!")
					return
				end
				if(table.Count(guiAllWeaponsList:GetSelected()) == 0) then
					Crimson:CreateErrorDialog("Must select at least one weapon to add to the loadout for this rank!")
					return
				end
				for i,k in pairs(guiAllWeaponsList:GetSelected()) do
					guiRankPermissionsList:AddLine(k:GetValue(1)).WeaponClass = k.WeaponClass
				end
			end)
			giveRankPermissionButton:SetPos(270, 350)
			giveRankPermissionButton:SetSize(245, 30)
			giveRankPermissionButton:SetParent(panel)
			giveRankPermissionButton:SetTooltip("Add one or more weapons to the list of weapons to be given to members\nof this rank when they spawn. Make sure you have made a selection in\nthe list on the right and have loaded a loadout list for a rank.")
			
			
			
			local removeRankPermissionButton = Crimson.CreateButton("Remove Weapon", function(self)
				if(EXTENSION.EditingRank == "") then
					Crimson:CreateErrorDialog("Must be editing a rank remove from the loadout!")
					return
				end
				if(table.Count(guiRankPermissionsList:GetSelected()) == 0) then
					Crimson:CreateErrorDialog("Must select at least one weapon to remove from the loadout for this rank!")
					return
				end
				local tab = {}
				for i,k in ipairs(guiRankPermissionsList:GetLines()) do
					if(not k:IsSelected()) then
						table.insert(tab, k:GetValue(1))
					end
				end
				guiRankPermissionsList:Clear()
				for i,k in ipairs(tab) do
					guiRankPermissionsList:AddLine(k)
				end
			end)
			removeRankPermissionButton:SetPos(270, 390)
			removeRankPermissionButton:SetSize(245, 30)
			removeRankPermissionButton:SetParent(panel)
			removeRankPermissionButton:SetTooltip("Remove one or more weapons from the list of weapons to be given to members\nof this rank when they spawn. Make sure you have made a selection in the\nloadout list on the left.")
			
			net.Start("VGetLoadoutDisabled")
			net.SendToServer()
		end, 5)
	end)
end

Vermilion:RegisterExtension(EXTENSION)