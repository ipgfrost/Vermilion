--[[
 The MIT License

 Copyright 2014 Ned Hyett.

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
]]

local EXTENSION = Vermilion:MakeExtensionBase()
EXTENSION.Name = "Rank Controls"
EXTENSION.ID = "rankcontrol"
EXTENSION.Description = "Allows for ranks to be controlled"
EXTENSION.Author = "Ned"
EXTENSION.Permissions = {
	"set_rank",
	"add_permission",
	"remove_permission",
	"create_rank",
	"destroy_rank",
	"reset_ranks"
}

function EXTENSION:InitServer()
	Vermilion:AddChatCommand("resetranks", function(sender, text)
		if(Vermilion:HasPermissionVerboseChat(sender, "reset_ranks")) then
			Vermilion:ResetPerms()
			Vermilion:SavePerms()
			Vermilion:SendNotify(sender, "Ranks reset to defaults!", 5, NOTIFY_GENERIC)
		end
	end)
	
	concommand.Add("vermilion_resetranks", function(vplayer, cmd, args, fullstring)
		if(Vermilion:HasPermissionVerbose(vplayer, "reset_ranks")) then
			Vermilion:ResetPerms()
			Vermilion:SavePerms()
			Vermilion.Log("Ranks reset!")
		end
	end)
	
	Vermilion:AddChatCommand("getrank", function(sender, text)
		if(Crimson.TableLen(text) == 0) then
			Vermilion:SendNotify(sender, tostring(Vermilion:GetRank(sender)) .. " => " .. tostring(Vermilion.Ranks[Vermilion:GetRank(sender)]), 5, NOTIFY_GENERIC)
			return
		end
		local targetPlayer = Crimson.LookupPlayerByName(text[1])
		if(targetPlayer == nil) then
			Vermilion:SendNotify(sender, "Player does not exist!", 5, NOTIFY_ERROR)
			return
		end
		Vermilion:SendNotify(sender, tostring(Vermilion:GetRank(targetPlayer)) .. " => " .. tostring(Vermilion.Ranks[Vermilion:GetRank(targetPlayer)]), 5, NOTIFY_GENERIC)
	end)
	
	Vermilion:AddChatCommand("setrank", function(sender, text)
		if(Vermilion:HasPermissionVerboseChat(sender, "set_rank")) then
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
		if(Vermilion:HasPermissionVerbose(vplayer, "set_rank")) then
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
	
	util.AddNetworkString("RanksListRanksRequest")
	util.AddNetworkString("RanksListRanksResponse")
	util.AddNetworkString("RanksAddRank")
	util.AddNetworkString("SetRankUser")
	util.AddNetworkString("PermissionsListRequest")
	util.AddNetworkString("PermissionsListResponse")
	
	net.Receive("RanksListRanksRequest", function(len, vplayer)
		net.Start("RanksListRanksResponse")
		local ranksTab = {}
		for i,k in pairs(Vermilion.Ranks) do
			local isDefault = "No"
			if(Vermilion:GetSetting("default_rank", "player") == k) then
				isDefault = "Yes"
			end
			table.insert(ranksTab, { k, isDefault })
		end
		net.WriteTable(ranksTab)
		net.Send(vplayer)
	end)
	
	net.Receive("SetRankUser", function(len, vplayer)
		local steamID = net.ReadString()
		local rank = net.ReadString()
		if(Vermilion:LookupRank(rank) == 256) then
			Vermilion:SendMessageBox(vplayer, "This rank doesn't exist!")
			return
		end
		if(Vermilion:HasPermission(vplayer, "set_rank")) then
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
	
	net.Receive("PermissionsListRequest", function(len, vplayer)
		net.Start("PermissionsListResponse")
		net.WriteTable(Vermilion.PermissionsList) -- Replace this with a "nice" permissions list.
		net.Send(vplayer)
	end)
end

function EXTENSION:InitClient()
	self:AddHook("Vermilion_ActivePlayers", "ActivePlayersList", function(tab)
		EXTENSION.ActivePlayersList:Clear()
		for i,k in pairs(tab) do
			EXTENSION.ActivePlayersList:AddLine( k[1], k[2], k[3] )
		end
	end)
	net.Receive("RanksListRanksResponse", function(len)
		EXTENSION.RanksList:Clear()
		local tab = net.ReadTable()
		for i,k in pairs(tab) do
			EXTENSION.RanksList:AddLine(k[1], tostring(i), k[2])
		end
	end)
	net.Receive("PermissionsListResponse", function(len)
		EXTENSION.AllPermissionsList:Clear()
		local tab = net.ReadTable()
		for i,k in pairs(tab) do
			EXTENSION.AllPermissionsList:AddLine(k)
		end
	end)
	self:AddHook(Vermilion.EVENT_EXT_LOADED, "AddGui", function()
		Vermilion:AddInterfaceTab("rank_control", "Ranks", "icon16/group_gear.png", "Rank Control", function(TabHolder)
			local panel = vgui.Create("DPanel", TabHolder)
			panel:StretchToParent(5, 20, 20, 5)
			
			local ranksLabel = Crimson.CreateLabel("Ranks")
			ranksLabel:SetPos(100 - (ranksLabel:GetWide() / 2), 10)
			ranksLabel:SetParent(panel)
			
			local ranksList = vgui.Create("DListView")
			ranksList:SetMultiSelect(true)
			ranksList:AddColumn("Name")
			ranksList:AddColumn("Numerical ID")
			ranksList:AddColumn("Default")
			ranksList:SetParent(panel)
			ranksList:SetPos(10, 30)
			ranksList:SetSize(180, 190)
			ranksList:SetSortable(false)
			function ranksList:SortByColumn(ColumnID, Desc) end
			EXTENSION.RanksList = ranksList
			
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
							ranksList:AddLine(text, i + 1, "N")
							ranksList:AddLine("banned", i + 2, "N")
							break
						end
						ranksList:AddLine(k[1], k[2], k[3])
					end
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
			end)
			removeRankButton:SetPos(200, 150)
			removeRankButton:SetSize(75, 30)
			removeRankButton:SetParent(panel)
			
			local saveRanksButton = Crimson.CreateButton("Save Ranks", function(self)
				Crimson:CreateErrorDialog("Function not implemented!")
			end)
			saveRanksButton:SetPos(200, 190)
			saveRanksButton:SetSize(75, 30)
			saveRanksButton:SetParent(panel)
			
			local activePlayersLabel = Crimson.CreateLabel("Active Players")
			activePlayersLabel:SetPos(385 - (activePlayersLabel:GetWide() / 2), 10)
			activePlayersLabel:SetParent(panel)
			
			local activePlayerList = vgui.Create("DListView")
			activePlayerList:SetMultiSelect(true)
			activePlayerList:AddColumn("Name")
			activePlayerList:AddColumn("Steam ID")
			activePlayerList:AddColumn("Rank")
			activePlayerList:SetParent(panel)
			activePlayerList:SetPos(285, 30)
			activePlayerList:SetSize(200, 190)
			
			EXTENSION.ActivePlayersList = activePlayerList
			
			local setPlayerRankButton = Crimson.CreateButton("Set Rank", function(self)
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
					net.Start("SetRankUser")
					net.WriteString(userLine:GetValue(2)) -- User Steam ID
					net.WriteString(ranksList:GetSelected()[1]:GetValue(1)) -- The rank name to set
					net.SendToServer()
				end
				net.Start("ActivePlayers_Request")
				net.SendToServer()
			end)
			setPlayerRankButton:SetPos(490, 30)
			setPlayerRankButton:SetSize(85, 30)
			setPlayerRankButton:SetParent(panel)
			
			local setDefaultRankButton = Crimson.CreateButton("Set Default Rank", function(self)
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
			
			local rankPermissionsLabel = Crimson.CreateLabel("Rank Permissions")
			rankPermissionsLabel:SetPos(110 - (rankPermissionsLabel:GetWide() / 2), 230)
			rankPermissionsLabel:SetParent(panel)
			
			local guiRankPermissionsList = vgui.Create("DListView")
			guiRankPermissionsList:SetMultiSelect(true)
			guiRankPermissionsList:AddColumn("Name")
			guiRankPermissionsList:SetParent(panel)
			guiRankPermissionsList:SetPos(10, 250)
			guiRankPermissionsList:SetSize(200, 280)
			
			local giveRankPermissionButton = Crimson.CreateButton("Give Permission", function(self)
				Crimson:CreateErrorDialog("Function not implemented!")
			end)
			giveRankPermissionButton:SetPos(220, 350)
			giveRankPermissionButton:SetSize(145, 30)
			giveRankPermissionButton:SetParent(panel)
			
			local removeRankPermissionButton = Crimson.CreateButton("Take Permission", function(self)
				Crimson:CreateErrorDialog("Function not implemented!")
			end)
			removeRankPermissionButton:SetPos(220, 390)
			removeRankPermissionButton:SetSize(145, 30)
			removeRankPermissionButton:SetParent(panel)
			
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
				Crimson:CreateErrorDialog("Function not implemented!")
			end)
			loadRankPermissionsButton:SetPos(220, 250)
			loadRankPermissionsButton:SetSize(145, 30)
			loadRankPermissionsButton:SetParent(panel)
			
			local saveRankPermissionsButton = Crimson.CreateButton("Save Permissions", function(self)
				
			end)
			saveRankPermissionsButton:SetPos(220, 500)
			saveRankPermissionsButton:SetSize(145, 30)
			saveRankPermissionsButton:SetParent(panel)
			
			local allPermissionsLabel = Crimson.CreateLabel("All Permissions")
			allPermissionsLabel:SetPos(475 - (allPermissionsLabel:GetWide() / 2), 230)
			allPermissionsLabel:SetParent(panel)
			
			local guiAllPermissionsList = vgui.Create("DListView")
			guiAllPermissionsList:SetMultiSelect(true)
			guiAllPermissionsList:AddColumn("Name")
			guiAllPermissionsList:SetParent(panel)
			guiAllPermissionsList:SetPos(375, 250)
			guiAllPermissionsList:SetSize(200, 280)
			
			EXTENSION.AllPermissionsList = guiAllPermissionsList
			
			net.Start("RanksListRanksRequest")
			net.SendToServer()
			
			net.Start("PermissionsListRequest")
			net.SendToServer()
			
			return panel
		end)
	end)
end

Vermilion:RegisterExtension(EXTENSION)