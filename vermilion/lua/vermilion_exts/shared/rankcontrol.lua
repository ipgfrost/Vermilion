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

-- Note: this is a REQUIRED extension. Vermilion WILL NOT FUNCTION without it.

local EXTENSION = Vermilion:MakeExtensionBase()
EXTENSION.Name = "Rank Controls"
EXTENSION.ID = "rankcontrol"
EXTENSION.Description = "Allows for ranks to be controlled"
EXTENSION.Author = "Ned"
EXTENSION.Permissions = {
	"rank_management",
	"identify_as_admin",
	"lock_immune",
	"kill_immune",
	"kick_immune"
}
EXTENSION.RankPermissions = {
	{ "admin", {
			"identify_as_admin"
		}
	}
}
EXTENSION.NetworkStrings = {
	"VRanksListRanks",
	"VRanksAddRank",
	"VSetRankUser",
	"VRankPermissions",
	"VSaveRanks",
	"VUpdateRankPermissions",
	"VPermissionsList"
}
EXTENSION.EditingRank = ""
EXTENSION.UnsavedRankChanges = false

function EXTENSION:InitServer()
	Vermilion:AddChatCommand("resetranks", function(sender, text)
		if(Vermilion:HasPermissionError(sender, "rank_management")) then
			Vermilion:ResetPermissions()
			Vermilion:SavePermissions()
			Vermilion:ResetRanks()
			Vermilion:SaveRanks()
			Vermilion:SendNotify(sender, "Ranks reset to defaults!", 5, NOTIFY_GENERIC)
		end
	end)
	
	concommand.Add("vermilion_resetranks", function(vplayer, cmd, args, fullstring)
		if(Vermilion:HasPermissionVerbose(vplayer, "rank_management")) then
			Vermilion:ResetPermissions()
			Vermilion:SavePermissions()
			Vermilion.Log("Ranks reset!")
		end
	end)
	
	Vermilion:AddChatCommand("getrank", function(sender, text)
		if(Crimson.TableLen(text) == 0) then
			Vermilion:SendNotify(sender, tostring(Vermilion:GetRank(sender)) .. " => " .. tostring(Vermilion.Ranks[Vermilion:GetRank(sender)]))
			return
		end
		local targetPlayer = Crimson.LookupPlayerByName(text[1])
		if(targetPlayer == nil) then
			Vermilion:SendNotify(sender, "Player does not exist!", 5, NOTIFY_ERROR)
			return
		end
		Vermilion:SendNotify(sender, tostring(Vermilion:GetRank(targetPlayer)) .. " => " .. tostring(Vermilion.Ranks[Vermilion:GetRank(targetPlayer)]))
	end)
	
	Vermilion:AddChatCommand("setrank", function(sender, text)
		if(Vermilion:HasPermissionError(sender, "rank_management")) then
			if(Crimson.TableLen(text) == 1) then
				if(Vermilion:LookupRank(rank) == 256) then
					Vermilion:SendNotify(sender, "Warning: no such rank!", 5, NOTIFY_ERROR)
					return
				end
				Vermilion:SetRank(sender, text[1])
				return
			end
			if(Vermilion:LookupRank(text[2]) == 256) then
				Vermilion:SendNotify(sender, "No such rank!", 5, NOTIFY_ERROR)
				return
			end
			local targetPlayer = Crimson.LookupPlayerByName(text[1])
			if(targetPlayer == nil) then
				local targetPlayerOffline = Vermilion:GetPlayerByName(text[1])
				if(targetPlayerOffline == nil) then
					Vermilion:SendNotify(sender, "Player does not exist!", 5, NOTIFY_ERROR)
				else
					targetPlayerOffline["rank"] = text[2]
					Vermilion:SaveUserStore()
					Vermilion:SendNotify(sender, "Rank updated!", 5, NOTIFY_GENERIC)
				end
				return
			end
			Vermilion:SetRank(targetPlayer, text[2])
			Vermilion:SendNotify(sender, "Rank updated!", 5, NOTIFY_GENERIC)
			Vermilion:SendNotify(targetPlayer, "Your rank is now " .. text[2] .. "!", 5, NOTIFY_GENERIC)
		end
	end)
	
	concommand.Add("vermilion_getrank", function(vplayer, cmd, args, fullstring)
		if(Crimson.TableLen(args) == 0) then
			Vermilion.Log(tostring(Vermilion:GetRank(vplayer)) .. " => " .. tostring(Vermilion.Ranks[Vermilion:GetRank(vplayer)]))
			return
		end
		local targetPlayer = Crimson.LookupPlayerByName(args[1])
		if(targetPlayer == nil) then
			Vermilion.Log("Player does not exist!")
			return
		end
		Vermilion.Log(tostring(Vermilion:GetRank(targetPlayer)) .. " => " .. tostring(Vermilion.Ranks[Vermilion:GetRank(targetPlayer)]))
	end, nil, "Get a user's rank.\n Args: <player>")
	
	concommand.Add("vermilion_setrank", function(vplayer, cmd, args, fullstring)
		if(Vermilion:HasPermissionVerbose(vplayer, "rank_management")) then
			if(Crimson.TableLen(args) == 1) then
				Vermilion:SetRank(vplayer, args[1])
				return
			end
			local targetPlayer = Crimson.LookupPlayerByName(args[1])
			if(targetPlayer == nil) then
				Vermilion.Log("Player does not exist!")
				return
			end
			Vermilion:SetRank(targetPlayer, args[2])
		end
	end, nil, "Set a user's rank.\n Args: <player> <rank>")
	
	
	
	self:AddHook("VNET_VSetRankUser", function(vplayer)
		local steamID = net.ReadString()
		local rank = net.ReadString()
		
		if(Vermilion:HasPermission(vplayer, "rank_management")) then
			if(Vermilion:LookupRank(rank) == 256) then
				Vermilion:SendMessageBox(vplayer, "This rank doesn't exist!")
				return
			end
			local tplayer = Crimson.LookupPlayerBySteamID(steamID)
			if(tplayer == nil) then
				Vermilion:SendMessageBox(vplayer, "Player does not exist!")
				return
			end
			Vermilion:SetRank(tplayer, rank)
			Vermilion:SendNotify(tplayer, "Your rank is now " .. rank .. "!", 5, NOTIFY_GENERIC)
		else
			Vermilion:SendMessageBox(vplayer, "You do not have permission to do this!")
		end
	end)
	
	self:AddHook("VNET_VPermissionsList", function(vplayer)
		net.Start("VPermissionsList")
		net.WriteTable(Vermilion.PermissionsList) -- Replace this with a "nice" permissions list.
		net.Send(vplayer)
	end)
	
	self:AddHook("VNET_VRankPermissions", function(vplayer)
		net.Start("VRankPermissions")
		local tab = {}
		local trank = net.ReadString()
		for i,k in pairs(Vermilion.RankPerms) do
			if(k[1] == trank) then
				for i1,k1 in pairs(k[2]) do
					table.insert(tab, k1)
				end
			end
		end
		net.WriteTable(tab)
		net.Send(vplayer)
	end)
	
	self:AddHook("VNET_VSaveRanks", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "rank_management")) then
			local tab = net.ReadTable()
			Vermilion.Log("Writing ranks...")
			Vermilion.Ranks = {}
			for i,k in ipairs(tab) do
				Vermilion.Log("Writing rank: " .. k[1])
				table.insert(Vermilion.Ranks, k[1])
				if(k[3] == "Yes") then
					Vermilion:SetSetting("default_rank", k[1])
				end
				local exists = false
				for i1, k1 in pairs(Vermilion.RankPerms) do
					if(k1[1] == k[1]) then
						exists = true
						break
					end
				end
				if(not exists) then 
					table.insert(Vermilion.RankPerms, tonumber(k[2]), {k[1], { "blank" }})
				end
			end
			Vermilion:SaveRanks()
			Vermilion:SavePermissions()
		else
			Vermilion:SendMessageBox(vplayer, "You do not have permission to do this!")
		end
	end)
	
	self:AddHook("VNET_VUpdateRankPermissions", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "rank_management")) then
			local rank = net.ReadString()
			local ptab = net.ReadTable()
			
			if(Vermilion:LookupRank(rank) == 256) then
				Vermilion:SendMessageBox(vplayer, "Rank does not exist!")
				return
			end
			
			Vermilion.RankPerms[Vermilion:LookupRank(rank)][2] = ptab
			Vermilion:SavePermissions()
		else
			Vermilion:SendMessageBox(vplayer, "You do not have permission to do this!")
		end
	end)
	
	self:AddHook(Vermilion.EVENT_EXT_LOADED, "AddGui", function()
		Vermilion:AddInterfaceTab("rank_control", "rank_management")
	end)
end

function EXTENSION:InitClient()
	self:AddHook("VActivePlayers", "ActivePlayersList", function(tab)
		if(not IsValid(EXTENSION.ActivePlayersList)) then
			return
		end
		EXTENSION.ActivePlayersList:Clear()
		for i,k in pairs(tab) do
			EXTENSION.ActivePlayersList:AddLine( k[1], k[2], k[3] )
		end
	end)
	self:AddHook("Vermilion_RanksList", "RanksList", function(tab)
		if(not IsValid(EXTENSION.RanksList)) then
			return
		end
		EXTENSION.RanksList:Clear()
		for i,k in pairs(tab) do
			EXTENSION.RanksList:AddLine(k[1], tostring(i), k[2])
		end
	end)
	self:AddHook("VNET_VPermissionsList", function()
		if(not IsValid(EXTENSION.AllPermissionsList)) then
			return
		end
		EXTENSION.AllPermissionsList:Clear()
		local tab = net.ReadTable()
		for i,k in pairs(tab) do
			EXTENSION.AllPermissionsList:AddLine(k)
		end
	end)
	self:AddHook("VNET_VRankPermissions", function(len)
		if(not IsValid(EXTENSION.RankPermissionsList)) then
			return
		end
		EXTENSION.RankPermissionsList:Clear()
		local tab = net.ReadTable()
		for i,k in pairs(tab) do
			EXTENSION.RankPermissionsList:AddLine(k)
		end
	end)
	self:AddHook(Vermilion.EVENT_EXT_LOADED, "AddGui", function()
		Vermilion:AddInterfaceTab("rank_control", "Ranks", "group_gear.png", "Put players in groups to assign permission sets to different types of players", function(panel)
			EXTENSION.EditingRank = ""
			EXTENSION.UnsavedRankChanges = false
			
			
			local ranksList = Crimson.CreateList({ "Name", "Numerical ID", "Default" }, true, false)
			ranksList:SetParent(panel)
			ranksList:SetPos(10, 30)
			ranksList:SetSize(180, 190)
			EXTENSION.RanksList = ranksList
			
			local ranksLabel = Crimson:CreateHeaderLabel(ranksList, "Ranks")
			ranksLabel:SetParent(panel)
			
			
			
			local addRankButton = Crimson.CreateButton("Add Rank", function(self)
				Crimson:CreateTextInput("Please type the new name of the rank you wish to add...", function(text)
					for i,k in pairs(ranksList:GetLines()) do
						if(k:GetValue(1) == text) then
							Crimson:CreateErrorDialog("Cannot create duplicate rank!")
							return
						end
					end
					local oldranks = ranksList:GetLines()
					local ranksTab = {}
					for i,k in pairs(oldranks) do
						ranksTab[i] = { k:GetValue(1), k:GetValue(2), k:GetValue(3) }
					end
					ranksList:Clear()
					for i,k in pairs(ranksTab) do
						if(i == table.Count(oldranks) - 1) then
							ranksList:AddLine(k[1], k[2], k[3])
							ranksList:AddLine(text, i + 1, "No")
							ranksList:AddLine("banned", i + 2, "No")
							break
						end
						ranksList:AddLine(k[1], k[2], k[3])
					end
					EXTENSION.UnsavedRankChanges = true
				end)
			end)
			addRankButton:SetPos(200, 30)
			addRankButton:SetSize(75, 30)
			addRankButton:SetParent(panel)
			
			
			
			local moveRankUpButton = Crimson.CreateButton("Move Up", function(self)
				if(table.Count(ranksList:GetSelected()) == 0) then
					Crimson:CreateErrorDialog("Must select a rank to move!")
					return
				end
				if(table.Count(ranksList:GetSelected()) > 1) then
					Crimson:CreateErrorDialog("Cannot move multiple ranks!")
					return
				end
				if(ranksList:GetSelected()[1]:GetValue(1) == "owner" or ranksList:GetSelected()[1]:GetValue(1) == "banned") then
					Crimson:CreateErrorDialog("Cannot move this rank; it is a protected rank!")
					return
				end
				if(tonumber(ranksList:GetSelected()[1]:GetValue(2)) == 2) then
					Crimson:CreateErrorDialog("Cannot move this rank here; it is interfering with a protected rank!")
					return
				end
				local targetIndex = tonumber(ranksList:GetSelected()[1]:GetValue(2)) - 1
				local toMove = { ranksList:GetSelected()[1]:GetValue(1), ranksList:GetSelected()[1]:GetValue(2), ranksList:GetSelected()[1]:GetValue(3) }
				
				local oldranks = ranksList:GetLines()
				local ranksTab = {}
				for i,k in pairs(oldranks) do
					ranksTab[i] = { k:GetValue(1), k:GetValue(2), k:GetValue(3) }
				end
				ranksList:Clear()
				for i,k in pairs(ranksTab) do
					if(i == targetIndex) then
						ranksList:AddLine(toMove[1], i, toMove[3])
						ranksList:AddLine(k[1], i + 1, k[3])
					elseif (i > targetIndex + 1) then
						ranksList:AddLine(k[1], i, k[3])
					elseif (i == targetIndex + 1) then
						
					else
						ranksList:AddLine(k[1], k[2], k[3])
					end
				end
				ranksList:SelectItem(ranksList:GetLine(targetIndex))
				EXTENSION.UnsavedRankChanges = true
			end)
			moveRankUpButton:SetPos(200, 70)
			moveRankUpButton:SetSize(75, 30)
			moveRankUpButton:SetParent(panel)
			
			
			
			local moveRankDownButton = Crimson.CreateButton("Move Down", function(self)
				if(table.Count(ranksList:GetSelected()) == 0) then
					Crimson:CreateErrorDialog("Must select a rank to move!")
					return
				end
				if(table.Count(ranksList:GetSelected()) > 1) then
					Crimson:CreateErrorDialog("Cannot move multiple ranks!")
					return
				end
				if(ranksList:GetSelected()[1]:GetValue(1) == "owner" or ranksList:GetSelected()[1]:GetValue(1) == "banned") then
					Crimson:CreateErrorDialog("Cannot move this rank; it is a protected rank!")
					return
				end
				if(tonumber(ranksList:GetSelected()[1]:GetValue(2)) == table.Count(ranksList:GetLines()) - 1) then
					Crimson:CreateErrorDialog("Cannot move this rank here; it is interfering with a protected rank!")
					return
				end
				local targetIndex = tonumber(ranksList:GetSelected()[1]:GetValue(2)) + 1
				local toMove = { ranksList:GetSelected()[1]:GetValue(1), ranksList:GetSelected()[1]:GetValue(2), ranksList:GetSelected()[1]:GetValue(3) }
				
				local oldranks = ranksList:GetLines()
				local ranksTab = {}
				for i,k in pairs(oldranks) do
					ranksTab[i] = { k:GetValue(1), k:GetValue(2), k:GetValue(3) }
				end
				ranksList:Clear()
				for i,k in pairs(ranksTab) do
					if(i == targetIndex - 1) then
						ranksList:AddLine(ranksTab[i + 1][1], i, ranksTab[i + 1][3])
					elseif(i == targetIndex) then
						ranksList:AddLine(toMove[1], i, toMove[3])
					elseif(i > targetIndex) then
						ranksList:AddLine(k[1], i, k[3])
					else
						ranksList:AddLine(k[1], k[2], k[3])
					end
				end
				ranksList:SelectItem(ranksList:GetLine(targetIndex))
				EXTENSION.UnsavedRankChanges = true
			end)
			moveRankDownButton:SetPos(200, 110)
			moveRankDownButton:SetSize(75, 30)
			moveRankDownButton:SetParent(panel)
			
			
			
			local removeRankButton = Crimson.CreateButton("Remove Rank", function(self)
				if(table.Count(ranksList:GetSelected()) > 1) then
					Crimson:CreateErrorDialog("Cannot remove multiple ranks!")
					return
				end
				if(table.Count(ranksList:GetSelected()) == 0) then
					Crimson:CreateErrorDialog("Must select a rank to remove!")
					return
				end
				if(ranksList:GetSelected()[1]:GetValue(1) == "owner" or ranksList:GetSelected()[1]:GetValue(1) == "banned") then
					Crimson:CreateErrorDialog("Cannot delete this rank; it is a protected rank!")
					return
				end
				if(ranksList:GetSelected()[1]:GetValue(3) == "Yes") then
					Crimson:CreateErrorDialog("Cannot delete the default rank. Please re-assign the default rank and try again!")
					return
				end
				local targetIndex = tonumber(ranksList:GetSelected()[1]:GetValue(2))
				local toMove = { ranksList:GetSelected()[1]:GetValue(1), ranksList:GetSelected()[1]:GetValue(2), ranksList:GetSelected()[1]:GetValue(3) }
				
				local oldranks = ranksList:GetLines()
				local ranksTab = {}
				for i,k in pairs(oldranks) do
					ranksTab[i] = { k:GetValue(1), k:GetValue(2), k:GetValue(3) }
				end
				ranksList:Clear()
				for i,k in pairs(ranksTab) do
					if(i == targetIndex) then
					
					elseif(i > targetIndex) then
						ranksList:AddLine(k[1], i - 1, k[3])
					else
						ranksList:AddLine(k[1], k[2], k[3])
					end
				end
				EXTENSION.UnsavedRankChanges = true
			end)
			removeRankButton:SetPos(200, 150)
			removeRankButton:SetSize(75, 30)
			removeRankButton:SetParent(panel)
			
			
			
			local saveRanksButton = Crimson.CreateButton("Save Ranks", function(self)
				local tab = {}
				for i,k in ipairs(ranksList:GetLines()) do
					table.insert(tab, { k:GetValue(1), k:GetValue(2), k:GetValue(3) })
				end
				net.Start("VSaveRanks")
				net.WriteTable(tab)
				net.SendToServer()
				EXTENSION.UnsavedRankChanges = false
			end)
			saveRanksButton:SetPos(200, 190)
			saveRanksButton:SetSize(75, 30)
			saveRanksButton:SetParent(panel)
			
			
			
			local activePlayerList = Crimson.CreateList({ "Name", "Steam ID", "Rank" })
			activePlayerList:SetParent(panel)
			activePlayerList:SetPos(285, 30)
			activePlayerList:SetSize(200, 190)
			EXTENSION.ActivePlayersList = activePlayerList
			
			local activePlayersLabel = Crimson:CreateHeaderLabel(activePlayerList, "Active Players")
			activePlayersLabel:SetParent(panel)
			
			
			
			local setPlayerRankButton = Crimson.CreateButton("Set Rank", function(self)
				if(EXTENSION.UnsavedRankChanges) then
					Crimson:CreateErrorDialog("Must save changes to ranks before assigning ranks to players!")
					return
				end
				if(table.Count(ranksList:GetSelected()) > 1) then
					Crimson:CreateErrorDialog("Cannot assign a user to multiple ranks!")
					return
				end
				if(table.Count(ranksList:GetSelected()) == 0) then
					Crimson:CreateErrorDialog("Must select a rank to assign this/these user(s) to!")
					return
				end
				if(table.Count(activePlayerList:GetSelected()) == 0) then
					Crimson:CreateErrorDialog("Must select at least one user to assign to a rank!")
					return
				end
				if(ranksList:GetSelected()[1]:GetValue(1) == "banned") then
					Crimson:CreateErrorDialog("Cannot manually set user to \"banned\" rank!")
					return
				end
				for i,userLine in pairs(activePlayerList:GetSelected()) do
					net.Start("VSetRankUser")
					net.WriteString(userLine:GetValue(2)) -- User Steam ID
					net.WriteString(ranksList:GetSelected()[1]:GetValue(1)) -- The rank name to set
					net.SendToServer()
				end
				net.Start("VActivePlayers")
				net.SendToServer()
			end)
			setPlayerRankButton:SetPos(490, 30)
			setPlayerRankButton:SetSize(85, 30)
			setPlayerRankButton:SetParent(panel)
			
			
			
			local setDefaultRankButton = Crimson.CreateButton("Set Default Rank", function(self)
				if(EXTENSION.UnsavedRankChanges) then
					Crimson:CreateErrorDialog("Must save changes to ranks before assigning a default rank!")
					return
				end
				if(table.Count(ranksList:GetSelected()) > 1) then
					Crimson:CreateErrorDialog("Cannot set multiple ranks as default!")
					return
				end
				if(table.Count(ranksList:GetSelected()) == 0) then
					Crimson:CreateErrorDialog("Must select a rank to assign this/these user(s) to!")
					return
				end
				if(ranksList:GetSelected()[1]:GetValue(1) == "owner" or ranksList:GetSelected()[1]:GetValue(1) == "banned") then
					Crimson:CreateErrorDialog("Cannot set a protected rank as the default. Doing so is insecure and/or stupid.")
					return
				end
				for i,k in pairs(ranksList:GetLines()) do
					k:SetValue(3, "No")
				end
				ranksList:GetSelected()[1]:SetValue(3, "Yes")
			end)
			setDefaultRankButton:SetPos(490, 70)
			setDefaultRankButton:SetSize(85, 30)
			setDefaultRankButton:SetParent(panel)
			
			
			
			local guiRankPermissionsList = Crimson.CreateList({ "Name" })
			guiRankPermissionsList:SetParent(panel)
			guiRankPermissionsList:SetPos(10, 250)
			guiRankPermissionsList:SetSize(200, 280)
			EXTENSION.RankPermissionsList = guiRankPermissionsList
			
			local rankPermissionsLabel = Crimson:CreateHeaderLabel(guiRankPermissionsList, "Rank Permissions")
			rankPermissionsLabel:SetParent(panel)
			
			
			
			local guiAllPermissionsList = Crimson.CreateList({ "Name" })
			guiAllPermissionsList:SetParent(panel)
			guiAllPermissionsList:SetPos(375, 250)
			guiAllPermissionsList:SetSize(200, 280)
			EXTENSION.AllPermissionsList = guiAllPermissionsList
			
			local allPermissionsLabel = Crimson:CreateHeaderLabel(guiAllPermissionsList, "All Permissions")
			allPermissionsLabel:SetParent(panel)
			
			
			
			local giveRankPermissionButton = Crimson.CreateButton("Give Permission", function(self)
				if(EXTENSION.UnsavedRankChanges) then
					Crimson:CreateErrorDialog("Must save changes to ranks before editing rank permissions!")
					return
				end
				if(EXTENSION.EditingRank == "") then
					Crimson:CreateErrorDialog("Must be editing a rank to give it permissions!")
					return
				end
				if(table.Count(guiAllPermissionsList:GetSelected()) == 0) then
					Crimson:CreateErrorDialog("Must select at least one permission to give to this rank!")
					return
				end
				for i,k in pairs(guiAllPermissionsList:GetSelected()) do
					guiRankPermissionsList:AddLine(k:GetValue(1))
				end
			end)
			giveRankPermissionButton:SetPos(220, 350)
			giveRankPermissionButton:SetSize(145, 30)
			giveRankPermissionButton:SetParent(panel)
			
			
			
			local removeRankPermissionButton = Crimson.CreateButton("Take Permission", function(self)
				if(EXTENSION.UnsavedRankChanges) then
					Crimson:CreateErrorDialog("Must save changes to ranks before editing rank permissions!")
					return
				end
				if(table.Count(guiRankPermissionsList:GetSelected()) == 0) then
					Crimson:CreateErrorDialog("Must select at least one permission to remove from this rank!")
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
			removeRankPermissionButton:SetPos(220, 390)
			removeRankPermissionButton:SetSize(145, 30)
			removeRankPermissionButton:SetParent(panel)
			
			
			
			local loadRankPermissionsButton = Crimson.CreateButton("Load Permissions", function(self)
				if(EXTENSION.UnsavedRankChanges) then
					Crimson:CreateErrorDialog("Must save changes to ranks before editing rank permissions!")
					return
				end
				if(EXTENSION.EditingRank != "") then
					Crimson:CreateErrorDialog("Must finish editing current rank permissions before loading another set.")
					return
				end
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
				net.Start("VRankPermissions")
				net.WriteString(ranksList:GetSelected()[1]:GetValue(1))
				net.SendToServer()
				rankPermissionsLabel:SetText("Rank Permissions - " .. ranksList:GetSelected()[1]:GetValue(1))
				EXTENSION.EditingRank = ranksList:GetSelected()[1]:GetValue(1)
			end)
			loadRankPermissionsButton:SetPos(220, 250)
			loadRankPermissionsButton:SetSize(145, 30)
			loadRankPermissionsButton:SetParent(panel)
			
			
			
			local saveRankPermissionsButton = Crimson.CreateButton("Save Permissions", function(self)
				if(EXTENSION.UnsavedRankChanges) then
					Crimson:CreateErrorDialog("Must save changes to ranks before editing rank permissions!")
					return
				end
				if(EXTENSION.EditingRank == "") then
					Crimson:CreateErrorDialog("Must be editing rank permissions before you can save them!")
					return
				end
				net.Start("VUpdateRankPermissions")
				net.WriteString(EXTENSION.EditingRank)
				local tab = {}
				for i,k in pairs(guiRankPermissionsList:GetLines()) do
					table.insert(tab, k:GetValue(1))
				end
				net.WriteTable(tab)
				net.SendToServer()
				guiRankPermissionsList:Clear()
				EXTENSION.EditingRank = ""
				rankPermissionsLabel:SetText("Rank Permissions")
			end)
			saveRankPermissionsButton:SetPos(220, 500)
			saveRankPermissionsButton:SetSize(145, 30)
			saveRankPermissionsButton:SetParent(panel)
			
			
			
			net.Start("VPermissionsList")
			net.SendToServer()
		end)
	end)
end

Vermilion:RegisterExtension(EXTENSION)