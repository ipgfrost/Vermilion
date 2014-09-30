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
EXTENSION.Name = "Model Enforcer"
EXTENSION.ID = "mdl_enforcer"
EXTENSION.Description = "Prevent ranks from using specific models and force other ranks to use specific ones."
EXTENSION.Author = "Ned"
EXTENSION.Permissions = {
	"manage_model_enforcer"
}
EXTENSION.PermissionDefinitions = {
	["manage_model_enforcer"] = "This player is able to access the Model Enforcer tab on the Vermilion Menu and modify the settings within."
}
EXTENSION.NetworkStrings = {
	"VRankModelsLoad",
	"VRankModelsSave",
	"VModelList"
}


EXTENSION.DisplayXPos1 = 0
EXTENSION.DisplayXPos2 = 0
EXTENSION.EditingRank = ""

function EXTENSION:InitServer()
	self:AddHook(Vermilion.EVENT_EXT_LOADED, "AddGui", function()
		Vermilion:AddInterfaceTab("mdl_enforcer", "manage_model_enforcer")
	end)
	
	self:AddHook("PlayerSetModel", function(vplayer)
		local clpm = vplayer:GetInfo("cl_playermodel")
		local modelname = player_manager.TranslatePlayerModel( clpm )
		if(not file.Exists(modelname, "GAME")) then -- the model doesn't exist on the server; we can't guarantee that all players have it either.
			timer.Simple(1, function() Vermilion:SendNotify(vplayer, "You have selected a player model that isn't available on the server and have been reset to default. It recommended that you change it quickly...") end)
			vplayer:SetModel(player_manager.AllValidModels()["kleiner"])
			return false
		end
		local rank = Vermilion:GetUser(vplayer):GetRank().Name
		local rankData = EXTENSION:GetData("models", {}, true)[rank]
		if(rankData != nil and rankData.ModelList != nil) then
			if(rankData.IsBlacklist) then
				if(table.HasValue(rankData.ModelList, modelname)) then
					timer.Simple(1, function() Vermilion:SendNotify(vplayer, "You have selected a player model that has been banned by the administrator and have been reset to default.") end)
					if(not table.HasValue(rankData.ModelList, player_manager.AllValidModels()["kleiner"])) then -- just make sure that the Kleiner model isn't blocked.
						vplayer:SetModel(player_manager.AllValidModels()["kleiner"])
					else
						for i,k in pairs(player_manager.AllValidModels()) do
							if(not table.HasValue(rankData.ModelList, k)) then
								vplayer:SetModel(k)
								break
							end
						end
					end
					return false
				end
			else
				if(not table.HasValue(rankData.ModelList, modelname)) then
					if(table.Count(rankData.ModelList) > 1) then 
						timer.Simple(1, function() Vermilion:SendNotify(vplayer, "You have selected a player model that has been banned by the administrator and have been reset to default.") end)
					end
					if(table.HasValue(rankData.ModelList, player_manager.AllValidModels()["kleiner"])) then -- just make sure that the Kleiner model isn't blocked.
						vplayer:SetModel(player_manager.AllValidModels()["kleiner"])
					else
						for i,k in pairs(player_manager.AllValidModels()) do
							if(table.HasValue(rankData.ModelList, k)) then
								vplayer:SetModel(k)
								break
							end
						end
					end
					return false
				end
			end
		end
	end)
	
	
	self:NetHook("VModelList", function(vplayer)
		net.Start("VModelList")
		net.WriteTable(table.GetKeys(player_manager.AllValidModels()))
		net.Send(vplayer)
	end)
	
	self:NetHook("VRankModelsLoad", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_model_enforcer")) then
			local rank = net.ReadString()
			local rankData = EXTENSION:GetData("models", {}, true)[rank]
			net.Start("VRankModelsLoad")
			if(rankData == nil) then
				net.WriteBoolean(true)
				net.WriteTable({})
			else
				net.WriteBoolean(rankData.IsBlacklist)
				local tab = {}
				if(rankData.ModelList == nil) then rankData.ModelList = {} end
				for i,k in pairs(rankData.ModelList) do
					table.insert(tab, player_manager.TranslateToPlayerModelName(k))
				end
				net.WriteTable(tab)
			end
			net.Send(vplayer)
		end
	end)
	
	self:NetHook("VRankModelsSave", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "manage_model_enforcer")) then
			local rank = net.ReadString()
			local rankData = EXTENSION:GetData("models", {}, true)[rank]
			if(rankData == nil) then
				EXTENSION:GetData("models", {}, true)[rank] = {}
				rankData = EXTENSION:GetData("models", {}, true)[rank]
			end
			rankData.IsBlacklist = net.ReadBoolean()
			rankData.ModelList = net.ReadTable()
		end
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
	
	self:NetHook("VModelList", "ModelList", function()
		if(not IsValid(EXTENSION.AllWeaponsList)) then
			return
		end
		EXTENSION.AllWeaponsList:Clear()
		local tab = net.ReadTable()
		for i,k in pairs(tab) do
			local mdl = player_manager.AllValidModels()[k]
			local ln = EXTENSION.AllWeaponsList:AddLine(k)
			ln.ModelPath = mdl
			
			ln.OldCursorMoved = ln.OnCursorMoved
			ln.OldCursorEntered = ln.OnCursorEntered
			ln.OldCursorExited = ln.OnCursorExited
			
			function ln:OnCursorEntered()
				EXTENSION.PreviewPanel:SetVisible(true)
				EXTENSION.PreviewPanel.dmodel:SetModel(ln.ModelPath)
				
				if(self.OldCursorEntered) then self:OldCursorEntered() end
			end
			
			function ln:OnCursorExited()
				EXTENSION.PreviewPanel:SetVisible(false)
				
				if(self.OldCursorExited) then self:OldCursorExited() end
			end
			
			function ln:OnCursorMoved(x,y)
				if(IsValid(EXTENSION.PreviewPanel)) then
					local x, y = input.GetCursorPos()
					EXTENSION.PreviewPanel:SetPos(x - 455, y - 202)
				end
				
				if(self.OldCursorMoved) then self:OldCursorMoved(x,y) end
			end
		end
	end)
	
	self:NetHook("VRankModelsLoad", function()
		if(not IsValid(EXTENSION.RankPermissionsList)) then
			return
		end
		EXTENSION.RankPermissionsList:Clear()
		EXTENSION.blacklistCB:SetValue(net.ReadBoolean())
		EXTENSION.blacklistCB:SetDisabled(false)
		local tab = net.ReadTable()
		for i,k in pairs(tab) do
			local mdl = player_manager.AllValidModels()[k]
			local ln = EXTENSION.RankPermissionsList:AddLine(k)
			ln.ModelPath = mdl
			
			ln.OldCursorMoved = ln.OnCursorMoved
			ln.OldCursorEntered = ln.OnCursorEntered
			ln.OldCursorExited = ln.OnCursorExited
			
			function ln:OnCursorEntered()
				EXTENSION.PreviewPanel:SetVisible(true)
				EXTENSION.PreviewPanel.dmodel:SetModel(ln.ModelPath)
				
				if(self.OldCursorEntered) then self:OldCursorEntered() end
			end
			
			function ln:OnCursorExited()
				EXTENSION.PreviewPanel:SetVisible(false)
				
				if(self.OldCursorExited) then self:OldCursorExited() end
			end
			
			function ln:OnCursorMoved(x,y)
				if(IsValid(EXTENSION.PreviewPanel)) then
					local x, y = input.GetCursorPos()
					EXTENSION.PreviewPanel:SetPos(x - 275, y - 202)
				end
				
				if(self.OldCursorMoved) then self:OldCursorMoved(x,y) end
			end
		end
	end)


	self:AddHook(Vermilion.EVENT_EXT_LOADED, "AddGui", function()
		Vermilion:AddInterfaceTab("mdl_enforcer", "Model Enforcer", "user_edit.png", "Prevent ranks from using specific models and force other ranks to use specific ones.", function(panel)
			EXTENSION.PreviewPanel = vgui.Create("DPanel")
			local x,y = input.GetCursorPos()
			
			EXTENSION.PreviewPanel:SetPos(x - 250, y - 64)
			EXTENSION.PreviewPanel:SetSize(148, 148)
			EXTENSION.PreviewPanel:SetParent(panel)
			EXTENSION.PreviewPanel:SetDrawOnTop(true)
			
			local dmodel = vgui.Create("DModelPanel")
			dmodel:SetPos(10,10)
			dmodel:SetSize(128, 128)
			dmodel:SetParent(EXTENSION.PreviewPanel)
			function dmodel:LayoutEntity(ent)
				ent:SetAngles( Angle( 0, RealTime()*80,  0) )
			end
			
			EXTENSION.PreviewPanel:SetVisible(false)
			EXTENSION.PreviewPanel.dmodel = dmodel
		
		
			local ranksList = Crimson.CreateList({ "Name" }, true, false)
			ranksList:SetParent(panel)
			ranksList:SetPos(10, 30)
			ranksList:SetSize(250, 190)
			EXTENSION.RanksList = ranksList
			
			local ranksLabel = Crimson:CreateHeaderLabel(ranksList, "Ranks")
			ranksLabel:SetParent(panel)
			
			local disableCheckbox = Crimson.CreateCheckBox("This is a blacklist (models that cannot be used by the rank).")
			disableCheckbox:SetPos(270, 30)
			disableCheckbox:SetParent(panel)
			disableCheckbox:SetDark(true)
			disableCheckbox:SetDisabled(true)
			EXTENSION.blacklistCB = disableCheckbox
			
			local blacklistinfolabel = vgui.Create("DLabel")
			blacklistinfolabel:SetText("Disable to turn the current rank model list into a whitelist, meaning they can only use the models defined.")
			blacklistinfolabel:SizeToContents()
			blacklistinfolabel:SetPos(270, 50)
			blacklistinfolabel:SetParent(panel)
			blacklistinfolabel:SetDark(true)
			
			local guiRankPermissionsList = Crimson.CreateList({ "Name" })
			guiRankPermissionsList:SetParent(panel)
			guiRankPermissionsList:SetPos(10, 250)
			guiRankPermissionsList:SetSize(250, 280)
			EXTENSION.RankPermissionsList = guiRankPermissionsList
			
			local blockedWeaponsLabel = Crimson:CreateHeaderLabel(guiRankPermissionsList, "Models")
			blockedWeaponsLabel:SetParent(panel)
			
			
			
			local guiAllWeaponsList = Crimson.CreateList({ "Name" })
			guiAllWeaponsList:SetParent(panel)
			guiAllWeaponsList:SetPos(525, 250)
			guiAllWeaponsList:SetSize(250, 280)			
			EXTENSION.AllWeaponsList = guiAllWeaponsList
			
			local allWeaponsLabel = Crimson:CreateHeaderLabel(guiAllWeaponsList, "All Models")
			allWeaponsLabel:SetParent(panel)
			
			
			
			local loadRankPermissionsButton = Crimson.CreateButton("Load Model List", function(self)
				if(table.Count(ranksList:GetSelected()) > 1) then
					Crimson:CreateErrorDialog("Cannot load model list for multiple ranks!")
					return
				end
				if(table.Count(ranksList:GetSelected()) == 0) then
					Crimson:CreateErrorDialog("Must select a rank to load the model list for!")
					return
				end
				net.Start("VRankModelsLoad")
				net.WriteString(ranksList:GetSelected()[1]:GetValue(1))
				net.SendToServer()
				blockedWeaponsLabel:SetText("Models - " .. ranksList:GetSelected()[1]:GetValue(1))
				EXTENSION.EditingRank = ranksList:GetSelected()[1]:GetValue(1)
			end)
			loadRankPermissionsButton:SetPos(270, 250)
			loadRankPermissionsButton:SetSize(245, 30)
			loadRankPermissionsButton:SetParent(panel)
			loadRankPermissionsButton:SetTooltip("Load the list of models that a rank can use/cannot use.\nMake sure you have selected a rank in the \"Ranks\" list before clicking this.")
			
			
			
			local saveRankPermissionsButton = Crimson.CreateButton("Save Model List", function(self)
				if(EXTENSION.EditingRank == "") then
					Crimson:CreateErrorDialog("Must be editing rank model list before you can save them!")
					return
				end
				if(not EXTENSION.blacklistCB:GetChecked() and table.Count(guiRankPermissionsList:GetLines()) < 1) then
					Crimson:CreateErrorDialog("Must add at least one model to the whitelist.")
					return
				end
				if(EXTENSION.blacklistCB:GetChecked() and table.Count(guiRankPermissionsList:GetLines()) == table.Count(guiAllWeaponsList:GetLines())) then
					Crimson:CreateErrorDialog("Must leave at least one model unbanned in the blacklist.")
					return
				end
				net.Start("VRankModelsSave")
				net.WriteString(EXTENSION.EditingRank)
				net.WriteBoolean(EXTENSION.blacklistCB:GetChecked())
				local tab = {}
				for i,k in pairs(guiRankPermissionsList:GetLines()) do
					table.insert(tab, k.ModelPath)
				end
				net.WriteTable(tab)
				net.SendToServer()
				guiRankPermissionsList:Clear()
				EXTENSION.EditingRank = ""
				blockedWeaponsLabel:SetText("Models")
				EXTENSION.blacklistCB:SetValue(0)
				EXTENSION.blacklistCB:SetDisabled(true)
			end)
			saveRankPermissionsButton:SetPos(270, 500)
			saveRankPermissionsButton:SetSize(245, 30)
			saveRankPermissionsButton:SetParent(panel)
			saveRankPermissionsButton:SetTooltip("Save the list of models that a rank can/cannot use.\nYou don't have to select a rank on the ranks list, but you\nmust have successfully loaded a list for a rank before\nclicking this button.")
			
			
			
			local giveRankPermissionButton = Crimson.CreateButton("Add Model", function(self)
				if(EXTENSION.EditingRank == "") then
					Crimson:CreateErrorDialog("Must be editing a rank add to the model list!")
					return
				end
				if(table.Count(guiAllWeaponsList:GetSelected()) == 0) then
					Crimson:CreateErrorDialog("Must select at least one model to add to the list for this rank!")
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
					guiRankPermissionsList:AddLine(k:GetValue(1)).ModelPath = k.ModelPath
				end
			end)
			giveRankPermissionButton:SetPos(270, 350)
			giveRankPermissionButton:SetSize(245, 30)
			giveRankPermissionButton:SetParent(panel)
			giveRankPermissionButton:SetTooltip("Add one or more models to the list of models that members\nof this rank can/cannot use. Make sure you have made a selection in\nthe list on the right and have loaded a model list for a rank.")
			
			
			
			local removeRankPermissionButton = Crimson.CreateButton("Remove Model", function(self)
				if(EXTENSION.EditingRank == "") then
					Crimson:CreateErrorDialog("Must be editing a rank to remove from the model list!")
					return
				end
				if(table.Count(guiRankPermissionsList:GetSelected()) == 0) then
					Crimson:CreateErrorDialog("Must select at least one model to remove from the model list for this rank!")
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
			removeRankPermissionButton:SetTooltip("Remove one or more models from the list of models that members\nof this rank can/cannot use. Make sure you have made a selection in the\nmodel list on the left.")
			
			net.Start("VModelList")
			net.SendToServer()
			
		end, 7.5)
	end)
end

Vermilion:RegisterExtension(EXTENSION)