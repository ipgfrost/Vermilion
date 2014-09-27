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
EXTENSION.Name = "Entity Limits"
EXTENSION.ID = "entlimit"
EXTENSION.Description = "Limits player access to entities"
EXTENSION.Author = "Ned"
EXTENSION.Permissions = {
	"entlimit_management"
}
EXTENSION.PermissionDefinitions = {
	["entlimit_management"] = "This player is allowed to see the Entity Limits tab in the Vermilion Menu and change the settings within."
}
EXTENSION.NetworkStrings = {
	"VRankEntsLoad",
	"VRankEntsSave"
}

EXTENSION.EditingRank = ""

function EXTENSION:InitServer()
	
	self:NetHook("VRankEntsSave", function(vplayer)
		if(not Vermilion:HasPermission(vplayer, "entlimit_management")) then
			return
		end
		local rnk = net.ReadString()
		local tab = net.ReadTable()
		EXTENSION:GetData("entity_limits", {}, true)[rnk] = tab
	end)
	
	self:NetHook("VRankEntsLoad", function(vplayer)
		if(not Vermilion:HasPermission(vplayer, "entlimit_management")) then
			return
		end
		local rnk = net.ReadString()
		
		local tab = EXTENSION:GetData("entity_limits", {}, true)[rnk]
		if(not tab) then
			tab = {}
		end
		net.Start("VRankEntsLoad")
		net.WriteTable(tab)
		net.Send(vplayer)
	end)
	
	self:AddHook("VPlayerSpawnSENT", "SentOverride", function(vplayer, class)
		local pRank = Vermilion:GetUser(vplayer):GetRank().Name
		if(EXTENSION:GetData("entity_limits", {}, true)[pRank] == nil) then
			return
		end
		if(table.HasValue(EXTENSION:GetData("entity_limits", {}, true)[pRank], class)) then
			Vermilion:SendNotify(vplayer, "You cannot spawn this entity!", VERMILION_NOTIFY_ERROR)
			return false
		end
	end)
	self:AddHook(Vermilion.EVENT_EXT_LOADED, "AddGui", function()
		Vermilion:AddInterfaceTab("ent_control", "entlimit_management")
	end)
end

function EXTENSION:LoadSettings()
	self.RankLimits = Vermilion:GetSetting("entity_limits", {})
	if(table.Count(self.RankLimits) == 0) then 
		self:ResetSettings()
		self:SaveSettings()
	end
end

function EXTENSION:SaveSettings()
	Vermilion:SetSetting("entity_limits", self.RankLimits)
end

function EXTENSION:ResetSettings()
	self.RankLimits = {}
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
	
	
	self:AddHook("VEntsList", function(tab)
		if(not IsValid(EXTENSION.AllWeaponsList)) then
			return
		end
		EXTENSION.AllWeaponsList:Clear()
		EXTENSION.EntsCache = tab
		for i,k in pairs(tab) do
			EXTENSION.AllWeaponsList:AddLine(k.PrintName).EntClass = k.Class
		end
	end)
	
	
	self:NetHook("VRankEntsLoad", function()
		if(not IsValid(EXTENSION.RankPermissionsList)) then
			return
		end
		EXTENSION.RankPermissionsList:Clear()
		local tab = net.ReadTable()
		for i,k in pairs(tab) do
			local name = list.Get("SpawnableEntities")[k].PrintName
			EXTENSION.RankPermissionsList:AddLine(name).EntClass = k
		end
	end)
	
	
	self:AddHook(Vermilion.EVENT_EXT_LOADED, "AddGui", function()
		Vermilion:AddInterfaceTab("ent_control", "Entity Limits", "bricks.png", "Block players from using specific entities", function(panel)
			
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
				List of blocked ents
			]]--
			
			local guiRankPermissionsList = Crimson.CreateList({ "Name" })
			guiRankPermissionsList:SetParent(panel)
			guiRankPermissionsList:SetPos(10, 250)
			guiRankPermissionsList:SetSize(250, 280)
			EXTENSION.RankPermissionsList = guiRankPermissionsList
			
			local blockedWeaponsLabel = Crimson:CreateHeaderLabel(guiRankPermissionsList, "Blocked Entities")
			blockedWeaponsLabel:SetParent(panel)
			
			--[[
				List of all ents installed
			]]--
			
			local guiAllWeaponsList = Crimson.CreateList({ "Name" })
			guiAllWeaponsList:SetParent(panel)
			guiAllWeaponsList:SetPos(525, 250)
			guiAllWeaponsList:SetSize(250, 250)
			EXTENSION.AllWeaponsList = guiAllWeaponsList
			
			local allWeaponsLabel = Crimson:CreateHeaderLabel(guiAllWeaponsList, "All Entities")
			allWeaponsLabel:SetParent(panel)
			
			local searchBox = Crimson.CreateTextbox("", panel)
			searchBox:SetParent(panel)
			searchBox:SetPos(525, 510)
			searchBox:SetSize(250, 25)
			searchBox:SetUpdateOnType(true)
			function searchBox:OnChange()
				local val = searchBox:GetValue()
				if(val == "" or val == nil) then
					guiAllWeaponsList:Clear()
					for i,k in pairs(EXTENSION.EntsCache) do
						guiAllWeaponsList:AddLine(k.PrintName).EntClass = k.Class
					end
				else
					guiAllWeaponsList:Clear()
					for i,k in pairs(EXTENSION.EntsCache) do
						if(string.find(string.lower(k.PrintName), string.lower(val))) then
							guiAllWeaponsList:AddLine(k.PrintName).EntClass = k.Class
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
				Load rank ent blocklist button
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
				net.Start("VRankEntsLoad")
				net.WriteString(ranksList:GetSelected()[1]:GetValue(1))
				net.SendToServer()
				blockedWeaponsLabel:SetText("Blocked Entities - " .. ranksList:GetSelected()[1]:GetValue(1))
				EXTENSION.EditingRank = ranksList:GetSelected()[1]:GetValue(1)
			end)
			loadRankPermissionsButton:SetPos(270, 250)
			loadRankPermissionsButton:SetSize(245, 30)
			loadRankPermissionsButton:SetParent(panel)
			
			--[[
				Save rank ent blocklist button
			]]--
			
			local saveRankPermissionsButton = Crimson.CreateButton("Save Permissions", function(self)
				if(EXTENSION.EditingRank == "") then
					Crimson:CreateErrorDialog("Must be editing rank permissions before you can save them!")
					return
				end
				net.Start("VRankEntsSave")
				net.WriteString(EXTENSION.EditingRank)
				local tab = {}
				for i,k in pairs(guiRankPermissionsList:GetLines()) do
					table.insert(tab, k.EntClass)
				end
				net.WriteTable(tab)
				net.SendToServer()
				guiRankPermissionsList:Clear()
				EXTENSION.EditingRank = ""
				blockedWeaponsLabel:SetText("Blocked Entities")
			end)
			saveRankPermissionsButton:SetPos(270, 500)
			saveRankPermissionsButton:SetSize(245, 30)
			saveRankPermissionsButton:SetParent(panel)
			
			--[[
				Block ent button
			]]--
			
			local giveRankPermissionButton = Crimson.CreateButton("Block Entity", function(self)
				if(EXTENSION.EditingRank == "") then
					Crimson:CreateErrorDialog("Must be editing a rank to give it permissions!")
					return
				end
				if(table.Count(guiAllWeaponsList:GetSelected()) == 0) then
					Crimson:CreateErrorDialog("Must select at least one entity to block for this rank!")
					return
				end
				for i,k in pairs(guiAllWeaponsList:GetSelected()) do
					local dup = false
					for i1,k1 in pairs(guiRankPermissionsList:GetLines()) do
						if(k1:GetValue(1) == k:GetValue(1)) then
							dup = true
							break
						end
					end
					if(dup) then continue end
					guiRankPermissionsList:AddLine(k:GetValue(1)).EntClass = k.EntClass
				end
			end)
			giveRankPermissionButton:SetPos(270, 350)
			giveRankPermissionButton:SetSize(245, 30)
			giveRankPermissionButton:SetParent(panel)
			
			--[[
				Unblock ent button
			]]--
			
			local removeRankPermissionButton = Crimson.CreateButton("Unblock Entity", function(self)
				if(EXTENSION.EditingRank == "") then
					Crimson:CreateErrorDialog("Must be editing a rank take permissions!")
					return
				end
				if(table.Count(guiRankPermissionsList:GetSelected()) == 0) then
					Crimson:CreateErrorDialog("Must select at least one entity to unblock for this rank!")
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
		end, 7.1)
	end)
end

Vermilion:RegisterExtension(EXTENSION)