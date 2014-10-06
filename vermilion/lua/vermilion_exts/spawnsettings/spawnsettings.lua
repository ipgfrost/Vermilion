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
EXTENSION.Name = "Spawn Settings"
EXTENSION.ID = "spawn_settings"
EXTENSION.Description = "Allows players to be spawned with certain parameters."
EXTENSION.Author = "Ned"
EXTENSION.Permissions = {
	"manage_spawn_settings"
}
EXTENSION.NetworkStrings = {
	"VRankSpawnSave",
	"VRankSpawnLoad",
	"VGetSpawnProperties"
}

EXTENSION.EditingRank = ""
EXTENSION.DataTypes = {}

function EXTENSION:AddType(name, applyfunc, validator, formatter, default)
	self.DataTypes[name] = { ApplyFunc = applyfunc, Validator = validator, Formatter = formatter, Default = default }
end

function EXTENSION:InitShared()
	self:AddType("Health", function(vplayer, data)
		vplayer:SetHealth(data)
	end, function(value)
		return tonumber(value) != nil
	end, function(value)
		return tonumber(value)
	end, 100)
	
	self:AddType("Jump Power", function(vplayer, data)
		vplayer:SetJumpPower(data)
	end, function(value)
		return tonumber(value) != nil
	end, function(value)
		return tonumber(value)
	end, 200)
	
	self:AddType("Max Health", function(vplayer, data)
		vplayer.Vermilion_MaxHealth = data
	end, function(value)
		return tonumber(value) != nil
	end, function(value)
		return tonumber(value)
	end, nil)
	
	self:AddType("Run Speed", function(vplayer, data)
		vplayer:SetRunSpeed(data)
	end, function(value)
		return tonumber(value) != nil
	end, function(value)
		return tonumber(value)
	end, 500)
	
	self:AddType("Walk Speed", function(vplayer, data)
		vplayer:SetWalkSpeed(data)
	end, function(value)
		return tonumber(value) != nil
	end, function(value)
		return tonumber(value)
	end, 200)
	
	self:AddType("Armour", function(vplayer, data)
		vplayer:SetArmor(data)
	end, function(value)
		return tonumber(value) != nil
	end, function(value)
		return tonumber(value)
	end, 0)
end

function EXTENSION:InitServer()
	
	self:AddHook("PlayerSpawn", function(vplayer)
		timer.Simple(0.5, function()
			for i,k in pairs(EXTENSION.DataTypes) do
				k.ApplyFunc(vplayer, k.Default)
			end
			local userData = Vermilion:GetUser(vplayer)
			if(userData != nil) then
				local rankData = userData:GetRank()
				if(rankData != nil) then
					local rankName = rankData.Name
					if(EXTENSION:GetData("properties", {}, true)[rankName] != nil) then
						for i,k in pairs(EXTENSION:GetData("properties", {}, true)[rankName]) do
							local typ = EXTENSION.DataTypes[i]
							typ.ApplyFunc(vplayer, k)
						end
					end
				end
			end
		end)
	end)
	
	self:AddHook("PlayerTick", function(vplayer)
		if(not IsValid(vplayer)) then return end
		if(vplayer.Vermilion_MaxHealth != nil) then
			if(vplayer:Health() > vplayer.Vermilion_MaxHealth) then
				vplayer:SetHealth(vplayer.Vermilion_MaxHealth)
			end
		end
	end)
	
	self:NetHook("VGetSpawnProperties", function(vplayer)
		local tab = {}
		for i,k in pairs(EXTENSION.DataTypes) do
			table.insert(tab, {PrintName = i, Default = k.Default })
		end
		net.Start("VGetSpawnProperties")
		net.WriteTable(tab)
		net.Send(vplayer)
	end)
	
	self:NetHook("VRankSpawnLoad", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_spawn_settings")) then
			local rank = net.ReadString()
			if(EXTENSION:GetData("properties", {}, true)[rank] != nil) then
				local tab = {}
				for i,k in pairs(EXTENSION:GetData("properties", {}, true)[rank]) do
					table.insert(tab, { PrintName = i, Value = k })
				end
				net.Start("VRankSpawnLoad")
				net.WriteTable(tab)
				net.Send(vplayer)
			end
		end
	end)
	
	self:NetHook("VRankSpawnSave", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_spawn_settings")) then
			local rank = net.ReadString()
			if(EXTENSION:GetData("properties", {}, true)[rank] == nil) then
				EXTENSION:GetData("properties", {}, true)[rank] = {}
			end
			local newProps = {}
			for i,k in pairs(net.ReadTable()) do
				newProps[k.PrintName] = k.Value
			end
			EXTENSION:GetData("properties", {}, true)[rank] = newProps
		end
	end)
	
	self:AddHook(Vermilion.EVENT_EXT_LOADED, "AddGui", function()
		Vermilion:AddInterfaceTab("spawn_settings", "manage_spawn_settings")
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
	
	self:NetHook("VGetSpawnProperties", function()
		if(not IsValid(EXTENSION.AllWeaponsList)) then return end
		local tab = net.ReadTable()
		EXTENSION.OptionsCache = tab
		EXTENSION.AllWeaponsList:Clear()
		for i,k in pairs(tab) do
			EXTENSION.AllWeaponsList:AddLine(k.PrintName, k.Default)
		end
	end)
	
	self:NetHook("VRankSpawnLoad", function()
		if(not IsValid(EXTENSION.RankPermissionsList)) then return end
		local tab = net.ReadTable()
		EXTENSION.RankPermissionsList:Clear()
		for i,k in pairs(tab) do
			EXTENSION.RankPermissionsList:AddLine(k.PrintName, k.Value)
		end
	end)
	
	
	self:AddHook(Vermilion.EVENT_EXT_LOADED, "AddGui", function()
		Vermilion:AddInterfaceTab("spawn_settings", "Spawn Properties", "controller.png", "Spawn players with specific properties.", function(panel)
			
			local ranksList = Crimson.CreateList({ "Name" }, true, false)
			ranksList:SetParent(panel)
			ranksList:SetPos(10, 30)
			ranksList:SetSize(250, 190)
			EXTENSION.RanksList = ranksList
			
			local ranksLabel = Crimson:CreateHeaderLabel(ranksList, "Ranks")
			ranksLabel:SetParent(panel)
			
			local guiRankPermissionsList = Crimson.CreateList({ "Property", "Value" })
			guiRankPermissionsList:SetParent(panel)
			guiRankPermissionsList:SetPos(10, 250)
			guiRankPermissionsList:SetSize(250, 280)
			EXTENSION.RankPermissionsList = guiRankPermissionsList
			
			local blockedWeaponsLabel = Crimson:CreateHeaderLabel(guiRankPermissionsList, "Rank Properties")
			blockedWeaponsLabel:SetParent(panel)
			
			local guiAllWeaponsList = Crimson.CreateList({ "Name", "Default" }, false)
			guiAllWeaponsList:SetParent(panel)
			guiAllWeaponsList:SetPos(525, 250)
			guiAllWeaponsList:SetSize(250, 250)			
			EXTENSION.AllWeaponsList = guiAllWeaponsList
			
			local allWeaponsLabel = Crimson:CreateHeaderLabel(guiAllWeaponsList, "All Properties")
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
					for i,k in pairs(EXTENSION.OptionsCache) do
						guiAllWeaponsList:AddLine(k.PrintName, k.Default)
					end
				else
					guiAllWeaponsList:Clear()
					for i,k in pairs(EXTENSION.OptionsCache) do
						if(string.find(string.lower(k.PrintName), string.lower(val))) then
							guiAllWeaponsList:AddLine(k.PrintName, k.Default)
						end
						guiAllWeaponsList:SetDirty(true)
					end
				end
			end
			
			local searchLogo = vgui.Create("DImage")
			searchLogo:SetParent(searchBox)
			searchLogo:SetPos(searchBox:GetWide() - 25, 5)
			searchLogo:SetImage("icon16/magnifier.png")
			searchLogo:SizeToContents()
			
			
			local loadRankPermissionsButton = Crimson.CreateButton("Load Properties", function(self)
				if(table.Count(ranksList:GetSelected()) > 1) then
					Crimson:CreateErrorDialog("Cannot load properties for multiple ranks!")
					return
				end
				if(table.Count(ranksList:GetSelected()) == 0) then
					Crimson:CreateErrorDialog("Must select a rank to load the property list for!")
					return
				end
				net.Start("VRankSpawnLoad")
				net.WriteString(ranksList:GetSelected()[1]:GetValue(1))
				net.SendToServer()
				blockedWeaponsLabel:SetText("Properties - " .. ranksList:GetSelected()[1]:GetValue(1))
				EXTENSION.EditingRank = ranksList:GetSelected()[1]:GetValue(1)
			end)
			loadRankPermissionsButton:SetPos(270, 250)
			loadRankPermissionsButton:SetSize(245, 30)
			loadRankPermissionsButton:SetParent(panel)
			
			
			
			local saveRankPermissionsButton = Crimson.CreateButton("Save Properties", function(self)
				if(EXTENSION.EditingRank == "") then
					Crimson:CreateErrorDialog("Must be editing rank property list before you can save them!")
					return
				end
				net.Start("VRankSpawnSave")
				net.WriteString(EXTENSION.EditingRank)
				local tab = {}
				for i,k in pairs(guiRankPermissionsList:GetLines()) do
					table.insert(tab, { PrintName = k:GetValue(1), Value = EXTENSION.DataTypes[k:GetValue(1)].Formatter(k:GetValue(2)) })
				end
				net.WriteTable(tab)
				net.SendToServer()
				guiRankPermissionsList:Clear()
				EXTENSION.EditingRank = ""
				blockedWeaponsLabel:SetText("Rank Properties")
			end)
			saveRankPermissionsButton:SetPos(270, 500)
			saveRankPermissionsButton:SetSize(245, 30)
			saveRankPermissionsButton:SetParent(panel)
			
			
			
			local giveRankPermissionButton = Crimson.CreateButton("Add Property", function(self)
				if(EXTENSION.EditingRank == "") then
					Crimson:CreateErrorDialog("Must be editing a rank add to the property list!")
					return
				end
				if(table.Count(guiAllWeaponsList:GetSelected()) == 0) then
					Crimson:CreateErrorDialog("Must select a property to add to the list for this rank!")
					return
				end
				local dup = false
				local ln = guiAllWeaponsList:GetSelected()[1]
				for i1,k1 in pairs(guiRankPermissionsList:GetLines()) do
					if(k1:GetValue(1) == ln:GetValue(1)) then
						dup = true
						break
					end
				end
				if(dup) then return end
				Crimson:CreateTextInput("Set the value for this property (" .. ln:GetValue(1) .. "):", function(text)
					if(not EXTENSION.DataTypes[ln:GetValue(1)].Validator(text)) then
						Crimson:CreateErrorDialog("Invalid input type!")
						return
					end
					guiRankPermissionsList:AddLine(ln:GetValue(1), text)
				end)
			end)
			giveRankPermissionButton:SetPos(270, 350)
			giveRankPermissionButton:SetSize(245, 30)
			giveRankPermissionButton:SetParent(panel)
			
			
			
			local removeRankPermissionButton = Crimson.CreateButton("Remove Property", function(self)
				if(EXTENSION.EditingRank == "") then
					Crimson:CreateErrorDialog("Must be editing a rank to remove from the property list!")
					return
				end
				if(table.Count(guiRankPermissionsList:GetSelected()) == 0) then
					Crimson:CreateErrorDialog("Must select at least one property to remove from the limit list for this rank!")
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
			
			net.Start("VGetSpawnProperties")
			net.SendToServer()
		end, 5.5)
	end)
end

Vermilion:RegisterExtension(EXTENSION)