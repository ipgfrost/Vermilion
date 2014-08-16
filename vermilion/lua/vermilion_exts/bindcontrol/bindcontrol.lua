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
EXTENSION.Name = "Bind Control"
EXTENSION.ID = "bindcontrol"
EXTENSION.Description = "Handles client binds"
EXTENSION.Author = "Ned"
EXTENSION.Permissions = {
	"bind_control"
}
EXTENSION.PermissionDefintions = {
	["bind_control"] = "This player is allowed to view the Binds tab in the Vermilion Menu and change the settings within."
}
EXTENSION.NetworkStrings = {
	"VBindBlockUpdate",
	"VBindListLoad",
	"VBindListSave"
}
EXTENSION.EditingRank = ""

-- Server side list
EXTENSION.GlobalBans = {}

-- Client side list
EXTENSION.BannedBinds = {}

function EXTENSION:LoadSettings()
	self.GlobalBans = Vermilion:GetSetting("blocked_binds", {})
	if(table.Count(self.GlobalBans) == 0) then 
		self:ResetSettings()
		self:SaveSettings()
	end
end

function EXTENSION:SaveSettings()
	Vermilion:SetSetting("blocked_binds", self.GlobalBans)
end

function EXTENSION:ResetSettings()
	EXTENSION.GlobalBans = {}
end

function EXTENSION:BroadcastNewBinds()
	for i,k in pairs(player.GetAll()) do
		net.Start("VBindBlockUpdate")
		local tab = {}
		for i,k1 in pairs(self.GlobalBans) do
			if(k1[1] == Vermilion.Ranks[Vermilion:GetRank(k)]) then
				tab = k1[2]
				break
			end
		end
		net.WriteTable(tab)
		net.Send(k)
	end
end

function EXTENSION:InitServer()

	self:NetHook("VBindBlockUpdate", function(vplayer)
		net.Start("VBindBlockUpdate")
		local tab = {}
		for i,k in pairs(EXTENSION.GlobalBans) do
			if(k[1] == Vermilion.Ranks[Vermilion:GetRank(vplayer)]) then
				tab = k[2]
				break
			end
		end
		net.WriteTable(tab)
		net.Send(vplayer)
	end)
	
	self:NetHook("VBindListLoad", function(vplayer)
		local rank = net.ReadString()
		if(Vermilion:LookupRank(rank) == VERMILION_BAD_RANK) then
			return -- bad rank name
		end
		for i,k in pairs(EXTENSION.GlobalBans) do
			if(k[1] == rank) then
				net.Start("VBindListLoad")
				net.WriteTable(k[2])
				net.Send(vplayer)
				return
			end
		end
	end)
	
	self:NetHook("VBindListSave", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "bind_control")) then
			local rank = net.ReadString()
			local tab = net.ReadTable()
			
			if(Vermilion:LookupRank(rank) == VERMILION_BAD_RANK) then
				return -- bad rank name
			end
			
			for i,k in pairs(EXTENSION.GlobalBans) do
				if(k[1] == rank) then
					k[2] = tab
					EXTENSION:BroadcastNewBinds()
					return
				end
			end
			
			table.insert(EXTENSION.GlobalBans, { rank, tab })
			EXTENSION:BroadcastNewBinds()
		end
	end)
	
	concommand.Add("update_bind_blocks", function(sender)
		net.Start("VBindBlockUpdate")
		local tab = {}
		for i,k in pairs(EXTENSION.GlobalBans) do
			if(k[1] == Vermilion.Ranks[Vermilion:GetRank(sender)]) then
				tab = k[2]
				break
			end
		end
		net.WriteTable(tab)
		net.Send(sender)
	end)
	
	self:AddHook(Vermilion.EVENT_EXT_LOADED, "AddGui", function()
		Vermilion:AddInterfaceTab("binds", "bind_control")
	end)
	
	self:AddHook("Vermilion-SaveConfigs", "bind_save", function()
		EXTENSION:SaveSettings()
	end)
	
	EXTENSION:LoadSettings()
end

function EXTENSION:InitClient()
	self:NetHook("VBindBlockUpdate", function()
		EXTENSION.BannedBinds = net.ReadTable()
	end)
	self:AddHook("PlayerBindPress", function(vplayer, bind, pressed)
		for i,k in pairs(EXTENSION.BannedBinds) do
			if(string.find(bind, k)) then return true end
		end
	end)
	
	self:AddHook("VRanksList", "RanksList", function(tab)
		if(not IsValid(EXTENSION.RanksList)) then
			return
		end
		EXTENSION.RanksList:Clear()
		for i,k in pairs(tab) do
			EXTENSION.RanksList:AddLine(k[1])
		end
	end)
	
	self:NetHook("VBindListLoad", function()
		if(not IsValid(EXTENSION.RankPermissionsList)) then
			return
		end
		EXTENSION.RankPermissionsList:Clear()
		local tab = net.ReadTable()
		for i,k in pairs(tab) do
			EXTENSION.RankPermissionsList:AddLine(k)
		end
	end)
	
	self:AddHook(Vermilion.EVENT_EXT_LOADED, "GetList", function()
		net.Start("VBindBlockUpdate")
		net.SendToServer()
	end)
	
	
	
	self:AddHook(Vermilion.EVENT_EXT_LOADED, "AddGui", function()
		Vermilion:AddInterfaceTab("binds", "Binds", "link_break.png", "Block players from using keybinds", function(panel)
			
			local ranksList = Crimson.CreateList({ "Name" }, true, false)
			ranksList:SetParent(panel)
			ranksList:SetPos(10, 30)
			ranksList:SetSize(250, 190)
			EXTENSION.RanksList = ranksList
			
			local ranksLabel = Crimson:CreateHeaderLabel(ranksList, "Ranks")
			ranksLabel:SetParent(panel)
			
			
			
			local guiRankPermissionsList = Crimson.CreateList({ "Bind" })
			guiRankPermissionsList:SetParent(panel)
			guiRankPermissionsList:SetPos(10, 250)
			guiRankPermissionsList:SetSize(550, 280)
			EXTENSION.RankPermissionsList = guiRankPermissionsList
			
			local blockedBindsLabel = Crimson:CreateHeaderLabel(guiRankPermissionsList, "Blocked Binds")
			blockedBindsLabel:SetParent(panel)
			
			
			
			local loadRankPermissionsButton = Crimson.CreateButton("Load Binds", function(self)
				if(table.Count(ranksList:GetSelected()) > 1) then
					Crimson:CreateErrorDialog("Cannot load the list of blocked binds for multiple ranks!")
					return
				end
				if(table.Count(ranksList:GetSelected()) == 0) then
					Crimson:CreateErrorDialog("Must select a rank to load the list of blocked binds for!")
					return
				end
				if(ranksList:GetSelected()[1]:GetValue(1) == "banned") then
					Crimson:CreateErrorDialog("Cannot edit the list of blocked binds for this rank; it is a protected rank!")
					return
				end
				net.Start("VBindListLoad")
				net.WriteString(ranksList:GetSelected()[1]:GetValue(1))
				net.SendToServer()
				blockedBindsLabel:SetText("Blocked Binds - " .. ranksList:GetSelected()[1]:GetValue(1))
				EXTENSION.EditingRank = ranksList:GetSelected()[1]:GetValue(1)
			end)
			loadRankPermissionsButton:SetPos(565, 250)
			loadRankPermissionsButton:SetSize(210, 30)
			loadRankPermissionsButton:SetParent(panel)
			
			
			
			local saveRankPermissionsButton = Crimson.CreateButton("Save Binds", function(self)
				if(EXTENSION.EditingRank == "") then
					Crimson:CreateErrorDialog("Must be editing a list of binds for a rank before you can save them!")
					return
				end
				net.Start("VBindListSave")
				net.WriteString(EXTENSION.EditingRank)
				local tab = {}
				for i,k in pairs(guiRankPermissionsList:GetLines()) do
					table.insert(tab, k:GetValue(1))
				end
				net.WriteTable(tab)
				net.SendToServer()
				guiRankPermissionsList:Clear()
				EXTENSION.EditingRank = ""
				blockedBindsLabel:SetText("Blocked Binds")
			end)
			saveRankPermissionsButton:SetPos(565, 500)
			saveRankPermissionsButton:SetSize(210, 30)
			saveRankPermissionsButton:SetParent(panel)
			
			
			
			local giveRankPermissionButton = Crimson.CreateButton("Add Bind", function(self)
				if(EXTENSION.EditingRank == "") then
					Crimson:CreateErrorDialog("Must be editing a rank add to the list of blocked binds!")
					return
				end
				Crimson:CreateTextInput("Enter the bind text to look for:", function(result)
					if(string.find(result, "vermilion_menu")) then
						Crimson:CreateErrorDialog("Cannot block the Vermilion Menu!")
						return
					end	
					guiRankPermissionsList:AddLine(result)
				end)
			end)
			giveRankPermissionButton:SetPos(565, 350)
			giveRankPermissionButton:SetSize(210, 30)
			giveRankPermissionButton:SetParent(panel)
			
			
			
			local removeRankPermissionButton = Crimson.CreateButton("Remove Bind", function(self)
				if(EXTENSION.EditingRank == "") then
					Crimson:CreateErrorDialog("Must be editing a rank to remove from the list of blocked binds!")
					return
				end
				if(table.Count(guiRankPermissionsList:GetSelected()) == 0) then
					Crimson:CreateErrorDialog("Must select at least one bind to remove from the list of blocked binds for this rank!")
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
			removeRankPermissionButton:SetPos(565, 390)
			removeRankPermissionButton:SetSize(210, 30)
			removeRankPermissionButton:SetParent(panel)
			
			
		end, 8)
	end)
end

Vermilion:RegisterExtension(EXTENSION)