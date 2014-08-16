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
EXTENSION.Name = "Player Manager"
EXTENSION.ID = "players"
EXTENSION.Description = "Handles Player Management"
EXTENSION.Author = "Ned"
EXTENSION.Permissions = {
	"player_management"
}
EXTENSION.PermissionDefinitions = {
	["player_management"] = "This player can see the Player Management tab in the Vermilion Menu and modify the settings within."
}
EXTENSION.NetworkStrings = {
	"VPlayerManagementList",
	"VPlayerManagementActivate"
}

EXTENSION.Functions = {}

function EXTENSION:InitServer()
	self:AddHook(Vermilion.EVENT_EXT_LOADED, "AddGui", function()
		Vermilion:AddInterfaceTab("player_manager", "player_management")
	end)
	
	self:NetHook("VPlayerManagementList", function(vplayer)
		net.Start("VPlayerManagementList")
		local tab = {}
		for i,k in pairs(EXTENSION.Functions) do
			table.insert(tab, i)
		end
		net.WriteTable(tab)
		net.Send(vplayer)
	end)
	
	self:NetHook("VPlayerManagementActivate", function(vplayer)
		if(not Vermilion:HasPermission(vplayer, "player_management")) then
			return
		end
		local command = net.ReadString()
		local players = net.ReadTable()
		if(EXTENSION.Functions[command] != nil) then
			if(EXTENSION.Functions[command][1](vplayer, players)) then
				if(EXTENSION.Functions[command][3]) then
					EXTENSION.Functions[command][2](players)
					return
				end
				for i,k in pairs(players) do
					EXTENSION.Functions[command][2](Crimson.LookupPlayerByName(k))
				end
			end
		end
	end)
	
	
	function EXTENSION:AddCommand(name, validator, executor, passTable)
		passTable = passTable or false
		if(self.Functions[name] != nil) then
			Vermilion.Log("Player Management command " .. name .. " is being overwritten!")
		end
		self.Functions[name] = { validator, executor, passTable }
	end
end

function EXTENSION:InitClient()
	self:AddHook("VActivePlayers", "ActivePlayersList", function(tab)
		if(not IsValid(EXTENSION.ActivePlayersList)) then return end
		EXTENSION.ActivePlayersList:Clear()
		for i,k in pairs(tab) do
			local ln = EXTENSION.ActivePlayersList:AddLine( k[1], k[3] )
			ln.V_SteamID = k[2]
			ln.OnRightClick = function()
				local conmenu = DermaMenu()
				conmenu:SetParent(ln)
				conmenu:AddOption("Open Steam Profile", function()
					local tplayer = Crimson.LookupPlayerBySteamID(ln.V_SteamID)
					if(IsValid(tplayer)) then tplayer:ShowProfile() end
				end):SetIcon("icon16/page_find.png")
				conmenu:AddOption("Open Vermilion Profile", function()
					
				end):SetIcon("icon16/comment.png")
				conmenu:Open()
			end
		end
	end)
	
	self:NetHook("VPlayerManagementList", function()
		if(not IsValid(EXTENSION.ActionList)) then return end
		EXTENSION.ActionList:Clear()
		local tab = net.ReadTable()
		for i,k in pairs(tab) do
			EXTENSION.ActionList:AddLine( k )
		end
	end)

	self:AddHook(Vermilion.EVENT_EXT_LOADED, "AddGui", function()
		Vermilion:AddInterfaceTab("player_manager", "Player Management", "user.png", "Run reward/punishment/utility commands on large groups of players", function(panel)
			
			local playerList = Crimson.CreateList({ "Name", "Rank" })
			playerList:SetParent(panel)
			playerList:SetPos(10, 30)
			playerList:SetSize(300, panel:GetTall() - 50)
			EXTENSION.ActivePlayersList = playerList
			
			local activePlayersLabel = Crimson:CreateHeaderLabel(playerList, "Active Players")
			activePlayersLabel:SetParent(panel)
			
			
			
			local actionList = Crimson.CreateList({ "Name" }, false)
			actionList:SetParent(panel)
			actionList:SetPos(320, 30)
			actionList:SetSize(300, panel:GetTall() - 50)
			EXTENSION.ActionList = actionList
			
			local actionsLabel = Crimson:CreateHeaderLabel(actionList, "Actions")
			actionsLabel:SetParent(panel)
			
			
			
			local runCommandButton = Crimson.CreateButton("Run", function(self)
				if(table.Count(playerList:GetSelected()) == 0) then
					Crimson:CreateErrorDialog("Must select at least one player to perform an action on!")
					return
				end
				if(table.Count(actionList:GetSelected()) == 0) then
					Crimson:CreateErrorDialog("Must select an action to perform on the selected player(s)!")
					return
				end
				local ptab = {}
				for i,k in pairs(playerList:GetSelected()) do
					table.insert(ptab, k:GetValue(1))
				end
				net.Start("VPlayerManagementActivate")
				net.WriteString(actionList:GetSelected()[1]:GetValue(1))
				net.WriteTable(ptab)
				net.SendToServer()
			end)
			runCommandButton:SetPos(630, (panel:GetTall() / 2) - 15)
			runCommandButton:SetSize(panel:GetWide() - 630, 30)
			runCommandButton:SetParent(panel)
			
			net.Start("VPlayerManagementList")
			net.SendToServer()
		end, 4)
	end)
end

Vermilion:RegisterExtension(EXTENSION)