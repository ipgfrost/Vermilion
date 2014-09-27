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
EXTENSION.Name = "Toolgun Limits"
EXTENSION.ID = "toollimit"
EXTENSION.Description = "Limits player access to toolgun tools"
EXTENSION.Author = "Ned"
EXTENSION.Permissions = {
	"toollimit_management",
	"toolgun_players"
}
EXTENSION.PermissionDefintions = {
	["toollimit_management"] = "This player is allowed to see the Tool Limits tab in the Vermilion Menu and modify the settings within."
}
EXTENSION.RankPermissions = {
	{"admin", {
			"toolgun_players"
		}
	}
}
EXTENSION.NetworkStrings = {
	"VToolsList",
	"VRankToolsLoad",
	"VRankToolsSave"
}

EXTENSION.EditingRank = ""

function EXTENSION:GetToolgunTool(name)
	if(EXTENSION.Toolgun == nil) then EXTENSION.Toolgun = weapons.Get("gmod_tool") end
	return EXTENSION.Toolgun.Tool[name]
end

function EXTENSION:InitServer()
	self:NetHook("VToolsList", function(vplayer)
		net.Start("VToolsList")
		local tab = {}
		if(weapons.Get("gmod_tool") == nil) then
			net.WriteTable(tab)
			net.Send(vplayer)
			return
		end
		for i,k in pairs(weapons.Get("gmod_tool").Tool) do
			table.insert(tab, i)
		end
		net.WriteTable(tab)
		net.Send(vplayer)
	end)
	self:NetHook("VRankToolsSave", function(vplayer)
		if(not Vermilion:HasPermission(vplayer, "toollimit_management")) then
			return
		end
		local rnk = net.ReadString()
		local tab = net.ReadTable()
		
		EXTENSION:GetData("tool_gun_limits", {}, true)[rnk] = tab
	end)
	self:NetHook("VRankToolsLoad", function(vplayer)
		if(not Vermilion:HasPermission(vplayer, "toollimit_management")) then
			return
		end
		local rnk = net.ReadString()
		local tab = EXTENSION:GetData("tool_gun_limits", {}, true)[rnk]
		if(not tab) then
			tab = {}
		end
		net.Start("VRankToolsLoad")
		net.WriteTable(tab)
		net.Send(vplayer)
	end)
	
	self:AddHook("CanTool", "ToolOverride", function(vplayer, tr, tool)
		if(tr.Hit and IsValid(tr.Entity) and tr.Entity:IsPlayer()) then
			return Vermilion:HasPermissionError(vplayer, "toolgun_players")
		end
		local pRank = Vermilion:GetUser(vplayer):GetRank().Name
		if(EXTENSION:GetData("tool_gun_limits", {}, true)[pRank] == nil) then
			return
		end
		if(table.HasValue(EXTENSION:GetData("tool_gun_limits", {}, true)[pRank], tool)) then
			Vermilion:SendNotify(vplayer, "You cannot use this tool!", VERMILION_NOTIFY_ERROR)
			return false
		end
		if(Vermilion:GetExtension("prop_protect") != nil) then
			if(not Vermilion:GetExtension("prop_protect"):CanTool(vplayer, tr.Entity, tool)) then return false end
		end
	end)
	self:AddHook(Vermilion.EVENT_EXT_LOADED, "AddGui", function()
		timer.Simple(1, function()
			if(weapons.Get("gmod_tool") != nil) then
				Vermilion:AddInterfaceTab("tool_control", "toollimit_management")
			end
		end)
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
	self:NetHook("VToolsList", function()
		if(not IsValid(EXTENSION.AllWeaponsList)) then
			return
		end
		EXTENSION.AllWeaponsList:Clear()
		local tab = net.ReadTable()
		EXTENSION.ToolCache = tab
		for i,k in pairs(tab) do
			local name = EXTENSION:GetToolgunTool(k).Name
			local ln = EXTENSION.AllWeaponsList:AddLine(name)
			ln.ToolClass = k
			ln.OnRightClick = function()
				local mnu = DermaMenu(ln)
				mnu:AddOption("Details", function()
					local tool = EXTENSION:GetToolgunTool(k)
					local details = {
						"Name: " .. tostring(tool.Name),
						"Tab: " .. tostring(tool.Tab),
						"Category: " .. tostring(tool.Category)
					}
					Derma_Message(string.Implode("\n", details), "Tool Details", "Close")
				end):SetIcon("icon16/book_open.png")
				mnu:Open()
			end
		end
	end)
	self:NetHook("VRankToolsLoad", function()
		if(not IsValid(EXTENSION.RankPermissionsList)) then
			return
		end
		EXTENSION.RankPermissionsList:Clear()
		local tab = net.ReadTable()
		for i,k in pairs(tab) do
			local name = EXTENSION:GetToolgunTool(k).Name
			EXTENSION.RankPermissionsList:AddLine(name).ToolClass = k
		end
	end)
	
	self:AddHook(Vermilion.EVENT_EXT_LOADED, "AddGui", function()
		Vermilion:AddInterfaceTab("tool_control", "Tool Limits", "wrench_orange.png", "Block players from using specific toolgun tools", function(panel)
			
			local ranksList = Crimson.CreateList({ "Name" }, true, false)
			ranksList:SetParent(panel)
			ranksList:SetPos(10, 30)
			ranksList:SetSize(250, 190)
			EXTENSION.RanksList = ranksList
			
			local ranksLabel = Crimson:CreateHeaderLabel(ranksList, "Ranks")
			ranksLabel:SetParent(panel)
			
			
			
			local guiRankPermissionsList = Crimson.CreateList({ "Name" })
			guiRankPermissionsList:SetParent(panel)
			guiRankPermissionsList:SetPos(10, 250)
			guiRankPermissionsList:SetSize(250, 280)
			EXTENSION.RankPermissionsList = guiRankPermissionsList
			
			local blockedWeaponsLabel = Crimson:CreateHeaderLabel(guiRankPermissionsList, "Blocked Tools")
			blockedWeaponsLabel:SetParent(panel)
			
			
			
			local guiAllWeaponsList = Crimson.CreateList({ "Name" })
			guiAllWeaponsList:SetParent(panel)
			guiAllWeaponsList:SetPos(525, 250)
			guiAllWeaponsList:SetSize(250, 250)
			EXTENSION.AllWeaponsList = guiAllWeaponsList
			
			local allWeaponsLabel = Crimson:CreateHeaderLabel(guiAllWeaponsList, "All Tools")
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
					for i,k in pairs(EXTENSION.ToolCache) do
						local name = EXTENSION:GetToolgunTool(k).Name
						if(name == nil) then continue end
						guiAllWeaponsList:AddLine(name).ToolClass = k
					end
				else
					guiAllWeaponsList:Clear()
					for i,k in pairs(EXTENSION.ToolCache) do
						local name = EXTENSION:GetToolgunTool(k).Name
						if(name == nil) then continue end
						if(string.find(string.lower(name), string.lower(val))) then
							guiAllWeaponsList:AddLine(name).ToolClass = k
						end
					end
				end
			end
			
			local searchLogo = vgui.Create("DImage")
			searchLogo:SetParent(searchBox)
			searchLogo:SetPos(searchBox:GetWide() - 25, 5)
			searchLogo:SetImage("icon16/magnifier.png")
			searchLogo:SizeToContents()
			
			
			
			local loadRankPermissionsButton = Crimson.CreateButton("Load Permissions", function(self)
				if(table.Count(ranksList:GetSelected()) > 1) then
					Crimson:CreateErrorDialog("Cannot load permissions for multiple ranks!")
					return
				end
				if(table.Count(ranksList:GetSelected()) == 0) then
					Crimson:CreateErrorDialog("Must select a rank to load the permissions for!")
					return
				end
				net.Start("VRankToolsLoad")
				net.WriteString(ranksList:GetSelected()[1]:GetValue(1))
				net.SendToServer()
				blockedWeaponsLabel:SetText("Blocked Tools - " .. ranksList:GetSelected()[1]:GetValue(1))
				EXTENSION.EditingRank = ranksList:GetSelected()[1]:GetValue(1)
			end)
			loadRankPermissionsButton:SetPos(270, 250)
			loadRankPermissionsButton:SetSize(245, 30)
			loadRankPermissionsButton:SetParent(panel)
			
			
			
			local saveRankPermissionsButton = Crimson.CreateButton("Save Permissions", function(self)
				if(EXTENSION.EditingRank == "") then
					Crimson:CreateErrorDialog("Must be editing rank permissions before you can save them!")
					return
				end
				net.Start("VRankToolsSave")
				net.WriteString(EXTENSION.EditingRank)
				local tab = {}
				for i,k in pairs(guiRankPermissionsList:GetLines()) do
					table.insert(tab, k.ToolClass)
				end
				net.WriteTable(tab)
				net.SendToServer()
				guiRankPermissionsList:Clear()
				EXTENSION.EditingRank = ""
				blockedWeaponsLabel:SetText("Blocked Tools")
			end)
			saveRankPermissionsButton:SetPos(270, 500)
			saveRankPermissionsButton:SetSize(245, 30)
			saveRankPermissionsButton:SetParent(panel)
			
			
			
			local giveRankPermissionButton = Crimson.CreateButton("Block Tool", function(self)
				if(EXTENSION.EditingRank == "") then
					Crimson:CreateErrorDialog("Must be editing a rank to give it permissions!")
					return
				end
				if(table.Count(guiAllWeaponsList:GetSelected()) == 0) then
					Crimson:CreateErrorDialog("Must select at least one tool to block for this rank!")
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
					guiRankPermissionsList:AddLine(k:GetValue(1)).ToolClass = k.ToolClass
				end
			end)
			giveRankPermissionButton:SetPos(270, 350)
			giveRankPermissionButton:SetSize(245, 30)
			giveRankPermissionButton:SetParent(panel)
			
			
			
			local removeRankPermissionButton = Crimson.CreateButton("Unblock Tool", function(self)
				if(table.Count(guiRankPermissionsList:GetSelected()) == 0) then
					Crimson:CreateErrorDialog("Must select at least one tool to unblock for this rank!")
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
			
			net.Start("VToolsList")
			net.SendToServer()
		end, 7)
	end)
end

Vermilion:RegisterExtension(EXTENSION)