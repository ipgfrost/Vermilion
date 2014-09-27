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
EXTENSION.Name = "Spawn Limits"
EXTENSION.ID = "spawn_limits"
EXTENSION.Description = "Allows ranks to have custom spawn limits that imitate sbox_max<whatever>"
EXTENSION.Author = "Ned"
EXTENSION.Permissions = {
	"manage_spawn_limits"
}

EXTENSION.NetworkStrings = {
	"VRankSpawnLimitsLoad",
	"VRankSpawnLimitsSave",
	"VGetSpawnLimits"
}

EXTENSION.EditingRank = ""

function EXTENSION:InitServer()
	
	self:AddHook(Vermilion.EVENT_EXT_LOADED, "AddGui", function()
		Vermilion:AddInterfaceTab("spawn_limits", "manage_spawn_limits")
	end)
	
	self:AddHook("VCheckLimit", function(vplayer, limit)
		local rankName = Vermilion:GetUser(vplayer):GetRank().Name
		if(EXTENSION:GetData("limits", {}, true)[rankName] != nil) then
			local rankLimits = EXTENSION:GetData("limits", {}, true)[rankName]
			if(rankLimits[limit] != nil) then
				if(vplayer:GetCount(limit) >= rankLimits[limit]) then 
					Vermilion:SendNotify(vplayer, "You have hit the " .. limit .. " limit!")
					return false
				end
			end
		end
	end)
	
	self:NetHook("VGetSpawnLimits", function(vplayer)
		local tab = {}
		for i,k in pairs(cleanup.GetTable()) do
			if(not GetConVar("sbox_max" .. k)) then
				continue
			end
			table.insert(tab, {PrintName = k, CVAR = "sbox_max" .. k, Default = GetConVarNumber("sbox_max" .. k) })
		end
		net.Start("VGetSpawnLimits")
		net.WriteTable(tab)
		net.Send(vplayer)
	end)
	
	self:NetHook("VRankSpawnLimitsLoad", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_spawn_limits")) then
			local rank = net.ReadString()
			if(EXTENSION:GetData("limits", {}, true)[rank] != nil) then
				local tab = {}
				for i,k in pairs(EXTENSION:GetData("limits", {}, true)[rank]) do
					table.insert(tab, { PrintName = i, CVAR = "sbox_max" .. i, Value = k })
				end
				net.Start("VRankSpawnLimitsLoad")
				net.WriteTable(tab)
				net.Send(vplayer)
			end
		end
	end)
	
	self:NetHook("VRankSpawnLimitsSave", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_spawn_limits")) then
			local rank = net.ReadString()
			if(EXTENSION:GetData("limits", {}, true)[rank] == nil) then
				EXTENSION:GetData("limits", {}, true)[rank] = {}
			end
			local newLimits = {}
			for i,k in pairs(net.ReadTable()) do
				newLimits[k.PrintName] = k.Value
			end
			EXTENSION:GetData("limits", {}, true)[rank] = newLimits
		end
	end)
	
	
end

function EXTENSION:InitClient()
	self:NetHook("VGetSpawnLimits", function()
		if(not IsValid(EXTENSION.AllWeaponsList)) then return end
		local tab = net.ReadTable()
		EXTENSION.OptionsCache = tab
		EXTENSION.AllWeaponsList:Clear()
		for i,k in pairs(tab) do
			EXTENSION.AllWeaponsList:AddLine(k.PrintName, k.Default).CVAR = k.CVAR
		end
	end)
	
	self:NetHook("VRankSpawnLimitsLoad", function()
		if(not IsValid(EXTENSION.RankPermissionsList)) then return end
		local tab = net.ReadTable()
		EXTENSION.RankPermissionsList:Clear()
		for i,k in pairs(tab) do
			EXTENSION.RankPermissionsList:AddLine(k.PrintName, k.Value).CVAR = k.CVAR
		end
	end)
	
	self:AddHook("VRanksList", function(tab)
		if(not IsValid(EXTENSION.RanksList)) then return end
		EXTENSION.RanksList:Clear()
		for i,k in pairs(tab) do
			EXTENSION.RanksList:AddLine(k[1])
		end
	end)

	self:AddHook(Vermilion.EVENT_EXT_LOADED, "AddGui", function()
		Vermilion:AddInterfaceTab("spawn_limits", "Spawn Limits", "exclamation.png", EXTENSION.Description, function(panel)
			local ranksList = Crimson.CreateList({ "Name" }, true, false)
			ranksList:SetParent(panel)
			ranksList:SetPos(10, 30)
			ranksList:SetSize(250, 190)
			EXTENSION.RanksList = ranksList
			
			local ranksLabel = Crimson:CreateHeaderLabel(ranksList, "Ranks")
			ranksLabel:SetParent(panel)
			
			local infonotice = Crimson.CreateLabel("Note: this will not work unless the rank does not have the permission to override spawn limits.")
			infonotice:SetParent(panel)
			infonotice:SetPos(270, 30)
			
			local guiRankPermissionsList = Crimson.CreateList({ "Property", "Value" })
			guiRankPermissionsList:SetParent(panel)
			guiRankPermissionsList:SetPos(10, 250)
			guiRankPermissionsList:SetSize(250, 280)
			EXTENSION.RankPermissionsList = guiRankPermissionsList
			
			local blockedWeaponsLabel = Crimson:CreateHeaderLabel(guiRankPermissionsList, "Limits")
			blockedWeaponsLabel:SetParent(panel)
			
			local guiAllWeaponsList = Crimson.CreateList({ "Name", "Default" }, false)
			guiAllWeaponsList:SetParent(panel)
			guiAllWeaponsList:SetPos(525, 250)
			guiAllWeaponsList:SetSize(250, 250)			
			EXTENSION.AllWeaponsList = guiAllWeaponsList
			
			local allWeaponsLabel = Crimson:CreateHeaderLabel(guiAllWeaponsList, "All Limits")
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
						guiAllWeaponsList:AddLine(k.PrintName, k.Default).CVAR = k.CVAR
					end
				else
					guiAllWeaponsList:Clear()
					for i,k in pairs(EXTENSION.OptionsCache) do
						if(string.find(string.lower(k.PrintName), string.lower(val))) then
							guiAllWeaponsList:AddLine(k.PrintName, k.Default).CVAR = k.CVAR
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
			
			
			local loadRankPermissionsButton = Crimson.CreateButton("Load Limits", function(self)
				if(table.Count(ranksList:GetSelected()) > 1) then
					Crimson:CreateErrorDialog("Cannot load limits for multiple ranks!")
					return
				end
				if(table.Count(ranksList:GetSelected()) == 0) then
					Crimson:CreateErrorDialog("Must select a rank to load the limit list for!")
					return
				end
				net.Start("VRankSpawnLimitsLoad")
				net.WriteString(ranksList:GetSelected()[1]:GetValue(1))
				net.SendToServer()
				blockedWeaponsLabel:SetText("Limits - " .. ranksList:GetSelected()[1]:GetValue(1))
				EXTENSION.EditingRank = ranksList:GetSelected()[1]:GetValue(1)
			end)
			loadRankPermissionsButton:SetPos(270, 250)
			loadRankPermissionsButton:SetSize(245, 30)
			loadRankPermissionsButton:SetParent(panel)
			
			
			
			local saveRankPermissionsButton = Crimson.CreateButton("Save Limits", function(self)
				if(EXTENSION.EditingRank == "") then
					Crimson:CreateErrorDialog("Must be editing rank limit list before you can save them!")
					return
				end
				net.Start("VRankSpawnLimitsSave")
				net.WriteString(EXTENSION.EditingRank)
				local tab = {}
				for i,k in pairs(guiRankPermissionsList:GetLines()) do
					table.insert(tab, { PrintName = k:GetValue(1), Value = tonumber(k:GetValue(2)) })
				end
				net.WriteTable(tab)
				net.SendToServer()
				guiRankPermissionsList:Clear()
				EXTENSION.EditingRank = ""
				blockedWeaponsLabel:SetText("Limits")
			end)
			saveRankPermissionsButton:SetPos(270, 500)
			saveRankPermissionsButton:SetSize(245, 30)
			saveRankPermissionsButton:SetParent(panel)
			
			
			
			local giveRankPermissionButton = Crimson.CreateButton("Add Limit", function(self)
				if(EXTENSION.EditingRank == "") then
					Crimson:CreateErrorDialog("Must be editing a rank add to the limit list!")
					return
				end
				if(table.Count(guiAllWeaponsList:GetSelected()) == 0) then
					Crimson:CreateErrorDialog("Must select a limit to add to the list for this rank!")
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
				Derma_StringRequest("Set Limit - " .. ln:GetValue(1), "Set the value for this limit:", "Limit (as number)", function(text)
					local num = tonumber(text)
					if(num == nil) then
						Derma_Message(tostring(text) .. " isn't a number!", "Input Error", "OK")
						return
					end
					if(num < 0) then
						Derma_Message(tostring(text) .. " is outside the valid range. Defaulting to 0.", "Input Warning", "OK")
						num = 0
					end
					
					guiRankPermissionsList:AddLine(ln:GetValue(1), num).CVAR = ln.CVAR
				end)
			end)
			giveRankPermissionButton:SetPos(270, 350)
			giveRankPermissionButton:SetSize(245, 30)
			giveRankPermissionButton:SetParent(panel)
			
			
			
			local removeRankPermissionButton = Crimson.CreateButton("Remove Limit", function(self)
				if(EXTENSION.EditingRank == "") then
					Crimson:CreateErrorDialog("Must be editing a rank to remove from the limit list!")
					return
				end
				if(table.Count(guiRankPermissionsList:GetSelected()) == 0) then
					Crimson:CreateErrorDialog("Must select at least one limit to remove from the limit list for this rank!")
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
			
			net.Start("VGetSpawnLimits")
			net.SendToServer()
		end, 7.2)
	end)
end

Vermilion:RegisterExtension(EXTENSION)