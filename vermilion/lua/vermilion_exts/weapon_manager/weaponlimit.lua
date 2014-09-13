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
EXTENSION.Name = "Weapon Limits"
EXTENSION.ID = "weplimit"
EXTENSION.Description = "Limits player access to weapons"
EXTENSION.Author = "Ned"
EXTENSION.Permissions = {
	"weplimit_management",
	"give_all_sweps"
}
EXTENSION.PermissionDefintions = {
	["weplimit_management"] = "This player can see the Weapon Limits tab on the Vermilion Menu and modify the settings within.",
	["give_all_sweps"] = "This player is exempt from weapon limitations."
}
EXTENSION.RankPermissions = {
	{ "admin", {
			"give_all_sweps"
		}
	}
}
EXTENSION.NetworkStrings = {
	"VRankWeaponsLoad",
	"VRankWeaponsSave"
}

EXTENSION.EditingRank = ""

function EXTENSION:InitServer()
	
	self:NetHook("VRankWeaponsSave", function(vplayer)
		if(not Vermilion:HasPermission(vplayer, "weplimit_management")) then
			return
		end
		local rnk = net.ReadString()
		local tab = net.ReadTable()
		EXTENSION:GetData("weapon_limits", {}, true)[rnk] = tab
	end)
	
	self:NetHook("VRankWeaponsLoad", function(vplayer)
		if(not Vermilion:HasPermission(vplayer, "weplimit_management")) then
			return
		end
		local rnk = net.ReadString()
		
		local tab = EXTENSION:GetData("weapon_limits", {}, true)[rnk]
		if(not tab) then
			tab = {}
		end
		net.Start("VRankWeaponsLoad")
		net.WriteTable(tab)
		net.Send(vplayer)
	end)
	
	self:AddHook("PlayerGiveSWEP", "SwepOverride", function(vplayer, weapon, swep)
		if(Vermilion:HasPermission(vplayer, "give_all_sweps")) then
			return true
		end
		local pRank = Vermilion:GetUser(vplayer):GetRank().Name
		if(EXTENSION:GetData("weapon_limits", {}, true)[pRank] == nil) then
			return
		end
		if(table.HasValue(EXTENSION:GetData("weapon_limits", {}, true)[pRank], weapon)) then
			Vermilion:SendNotify(vplayer, "You cannot spawn this weapon!", VERMILION_NOTIFY_ERROR)
			return false
		end
	end)
	self:AddHook("PlayerCanPickupWeapon", function(vplayer, weapon)
		if(Vermilion:HasPermission(vplayer, "give_all_sweps")) then
			return true
		end
		local wepclass = weapon:GetClass()
		local pRank = Vermilion:GetUser(vplayer):GetRank().Name
		if(EXTENSION:GetData("weapon_limits", {}, true)[pRank] == nil) then return end
		if(table.HasValue(EXTENSION:GetData("weapon_limits", {}, true)[pRank], wepclass)) then return false end
	end)
	self:AddHook("PlayerSwitchWeapon", function(vplayer, old, new)
		if(Vermilion:HasPermission(vplayer, "give_all_sweps")) then
			return
		end
		local pRank = Vermilion:GetUser(vplayer):GetRank().Name
		if(EXTENSION:GetData("weapon_limits", {}, true)[pRank] == nil) then
			return
		end
		for i,k in pairs(vplayer:GetWeapons()) do
			if(table.HasValue(EXTENSION:GetData("weapon_limits", {}, true)[pRank], k:GetClass())) then
				vplayer:StripWeapon(k:GetClass())
			end
		end
	end)
	self:AddHook("PlayerSpawn", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "give_all_sweps")) then
			return
		end
		local pRank = Vermilion:GetUser(vplayer):GetRank().Name
		if(EXTENSION:GetData("weapon_limits", {}, true)[pRank] == nil) then
			return
		end
		for i,k in pairs(vplayer:GetWeapons()) do
			if(table.HasValue(EXTENSION:GetData("weapon_limits", {}, true)[pRank], k:GetClass())) then
				vplayer:StripWeapon(k:GetClass())
			end
		end
	end)
	
	self:AddHook(Vermilion.EVENT_EXT_LOADED, "AddGui", function()
		Vermilion:AddInterfaceTab("wep_control", "weplimit_management")
	end)
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
		EXTENSION.WeaponCache = tab
		EXTENSION.AllWeaponsList:Clear()
		for i,k in pairs(tab) do
			EXTENSION.AllWeaponsList:AddLine(k.PrintName).WeaponClass = k.Class
		end
	end)
	
	
	self:NetHook("VRankWeaponsLoad", function()
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
	
	
	self:AddHook(Vermilion.EVENT_EXT_LOADED, "AddGui", function()
		Vermilion:AddInterfaceTab("wep_control", "Weapon Limits", "gun.png", "Block players from using specific weapons", function(panel)
			
			--[[
				Rank list
			]]--
			
			local ranksList = Crimson.CreateList({ "Name" }, true, false)
			ranksList:SetParent(panel)
			ranksList:SetPos(10, 30)
			ranksList:SetSize(250, 190)
			EXTENSION.RanksList = ranksList
			
			local ranksLabel = Crimson:CreateHeaderLabel(ranksList, "Ranks")
			ranksLabel:SetParent(panel)
			
			--[[
				List of blocked weapons
			]]--
			
			local guiRankPermissionsList = Crimson.CreateList({ "Name" })
			guiRankPermissionsList:SetParent(panel)
			guiRankPermissionsList:SetPos(10, 250)
			guiRankPermissionsList:SetSize(250, 280)
			EXTENSION.RankPermissionsList = guiRankPermissionsList
			
			local blockedWeaponsLabel = Crimson:CreateHeaderLabel(guiRankPermissionsList, "Blocked Weapons")
			blockedWeaponsLabel:SetParent(panel)
			
			--[[
				List of all weapons installed
			]]--
			
			local guiAllWeaponsList = Crimson.CreateList({ "Name" })
			guiAllWeaponsList:SetParent(panel)
			guiAllWeaponsList:SetPos(525, 250)
			guiAllWeaponsList:SetSize(250, 250)
			EXTENSION.AllWeaponsList = guiAllWeaponsList
			
			local allWeaponsLabel = Crimson:CreateHeaderLabel(guiAllWeaponsList, "All Weapons")
			allWeaponsLabel:SetParent(panel)
			
			local searchBox = vgui.Create("DTextEntry")
			searchBox:SetParent(panel)
			searchBox:SetPos(525, 510)
			searchBox:SetSize(250, 25)
			searchBox:SetUpdateOnType(true)
			function searchBox:OnChange()
				local val = searchBox:GetValue()
				if(val == "" or val == nil) then
					guiAllWeaponsList:Clear()
					for i,k in pairs(EXTENSION.WeaponCache) do
						guiAllWeaponsList:AddLine(k.PrintName).WeaponClass = k.Class
					end
				else
					guiAllWeaponsList:Clear()
					for i,k in pairs(EXTENSION.WeaponCache) do
						if(string.find(string.lower(k.PrintName), string.lower(val))) then
							guiAllWeaponsList:AddLine(k.PrintName).WeaponClass = k.Class
						end
					end
				end
			end
			
			local searchLogo = vgui.Create("DImage")
			searchLogo:SetParent(searchBox)
			searchLogo:SetPos(searchBox:GetWide() - 25, 5)
			searchLogo:SetImage("icon16/magnifier.png")
			searchLogo:SizeToContents()
			
			--[[
				Load rank weapon blocklist button
			]]--
			
			local loadRankPermissionsButton = Crimson.CreateButton("Load Permissions", function(self)
				if(table.Count(ranksList:GetSelected()) > 1) then
					Crimson:CreateErrorDialog("Cannot load permissions for multiple ranks!")
					return
				end
				if(table.Count(ranksList:GetSelected()) == 0) then
					Crimson:CreateErrorDialog("Must select a rank to load the permissions for!")
					return
				end
				if(ranksList:GetSelected()[1]:GetValue(1) == "owner" or ranksList:GetSelected()[1]:GetValue(1) == "banned") then
					Crimson:CreateErrorDialog("Cannot edit the permissions of this rank; it is a protected rank!")
					return
				end
				net.Start("VRankWeaponsLoad")
				net.WriteString(ranksList:GetSelected()[1]:GetValue(1))
				net.SendToServer()
				blockedWeaponsLabel:SetText("Blocked Weapons - " .. ranksList:GetSelected()[1]:GetValue(1))
				EXTENSION.EditingRank = ranksList:GetSelected()[1]:GetValue(1)
			end)
			loadRankPermissionsButton:SetPos(270, 250)
			loadRankPermissionsButton:SetSize(245, 30)
			loadRankPermissionsButton:SetParent(panel)
			
			--[[
				Save rank weapon blocklist button
			]]--
			
			local saveRankPermissionsButton = Crimson.CreateButton("Save Permissions", function(self)
				if(EXTENSION.EditingRank == "") then
					Crimson:CreateErrorDialog("Must be editing rank permissions before you can save them!")
					return
				end
				net.Start("VRankWeaponsSave")
				net.WriteString(EXTENSION.EditingRank)
				local tab = {}
				for i,k in pairs(guiRankPermissionsList:GetLines()) do
					table.insert(tab, k.WeaponClass)
				end
				net.WriteTable(tab)
				net.SendToServer()
				guiRankPermissionsList:Clear()
				EXTENSION.EditingRank = ""
				blockedWeaponsLabel:SetText("Blocked Weapons")
			end)
			saveRankPermissionsButton:SetPos(270, 500)
			saveRankPermissionsButton:SetSize(245, 30)
			saveRankPermissionsButton:SetParent(panel)
			
			--[[
				Block weapon button
			]]--
			
			local giveRankPermissionButton = Crimson.CreateButton("Block Weapon", function(self)
				if(EXTENSION.EditingRank == "") then
					Crimson:CreateErrorDialog("Must be editing a rank to give it permissions!")
					return
				end
				if(table.Count(guiAllWeaponsList:GetSelected()) == 0) then
					Crimson:CreateErrorDialog("Must select at least one weapon to block for this rank!")
					return
				end
				for i,k in pairs(guiAllWeaponsList:GetSelected()) do
					guiRankPermissionsList:AddLine(k:GetValue(1)).WeaponClass = k.WeaponClass
				end
			end)
			giveRankPermissionButton:SetPos(270, 350)
			giveRankPermissionButton:SetSize(245, 30)
			giveRankPermissionButton:SetParent(panel)
			
			--[[
				Unblock weapon button
			]]--
			
			local removeRankPermissionButton = Crimson.CreateButton("Unblock Weapon", function(self)
				if(EXTENSION.EditingRank == "") then
					Crimson:CreateErrorDialog("Must be editing a rank take permissions!")
					return
				end
				if(table.Count(guiRankPermissionsList:GetSelected()) == 0) then
					Crimson:CreateErrorDialog("Must select at least one weapon to unblock for this rank!")
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
		end, 6)
	end)
end

Vermilion:RegisterExtension(EXTENSION)