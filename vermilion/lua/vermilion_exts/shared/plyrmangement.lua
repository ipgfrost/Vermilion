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
EXTENSION.Functions = {}

function EXTENSION:InitServer()
	self:AddHook(Vermilion.EVENT_EXT_LOADED, "AddGui", function()
		Vermilion:AddInterfaceTab("player_manager", "player_management")
	end)
	
	function EXTENSION:AddCommand(name, validator, executor)
		if(self.Functions[name] != nil) then
			Vermilion.Log("Player Management command " .. name .. " is being overwritten!")
		end
		self.Functions[name] = { validator, executor }
	end
end

function EXTENSION:InitClient()
	self:AddHook("VActivePlayers", "ActivePlayersList", function(tab)
		if(not IsValid(EXTENSION.ActivePlayersList)) then
			return
		end
		EXTENSION.ActivePlayersList:Clear()
		for i,k in pairs(tab) do
			EXTENSION.ActivePlayersList:AddLine( k[1], k[3] )
		end
	end)

	self:AddHook(Vermilion.EVENT_EXT_LOADED, "AddGui", function()
		Vermilion:AddInterfaceTab("player_manager", "Player Management", "user.png", "Run reward/punishment/utility commands on large groups of players", function(panel)
			
			local playerList = Crimson.CreateList({ "Name", "Rank" })
			playerList:SetParent(panel)
			playerList:SetPos(10, 30)
			playerList:SetSize(200, panel:GetTall() - 50)
			EXTENSION.ActivePlayersList = playerList
			
			local activePlayersLabel = Crimson:CreateHeaderLabel(playerList, "Active Players")
			activePlayersLabel:SetParent(panel)
			
			
			
			local actionList = Crimson.CreateList({ "Name" })
			actionList:SetParent(panel)
			actionList:SetPos(220, 30)
			actionList:SetSize(200, panel:GetTall() - 50)
			EXTENSION.ActionList = actionList
			
			local actionsLabel = Crimson:CreateHeaderLabel(actionList, "Actions")
			actionsLabel:SetParent(panel)
			
			
			
			local runCommandButton = Crimson.CreateButton("Run", function(self)
				
			end)
			runCommandButton:SetPos(430, (panel:GetTall() / 2) - 15)
			runCommandButton:SetSize(panel:GetWide() - 430, 30)
			runCommandButton:SetParent(panel)
		end)
	end)
end

Vermilion:RegisterExtension(EXTENSION)