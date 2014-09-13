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
	"lock_immunity",
	"kill_immunity"
}
EXTENSION.PermissionDefinitions = {
	["rank_management"] = "This player can see the Ranks tab in the Vermilion Menu and modify the settings within.",
	["identify_as_admin"] = "This player can do things that require admin status. For example, spawn admin only SWEPs, admin only SENTs ect.",
	["lock_immunity"] = "This player is immune from being locked/frozen by Lua scripting.",
	["kill_immunity"] = "This player is immune from being killed by Lua scripting."
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
	"VPermissionsList",
	"VDefinePermission"
}
EXTENSION.EditingRank = ""
EXTENSION.UnsavedRankChanges = false

function EXTENSION:InitServer()
	
	Vermilion:AddChatCommand("getrank", function(sender, text)
		if(table.Count(text) == 0) then
			Vermilion:SendNotify(sender, Vermilion:GetUser(sender):GetRank().Name)
			return
		end
		local targetPlayer = Crimson.LookupPlayerByName(text[1])
		if(targetPlayer == nil) then
			Vermilion:SendNotify(sender, Vermilion.Lang.NoSuchPlayer, VERMILION_NOTIFY_ERROR)
			return
		end
		if(not Vermilion:HasUser(text[1])) then
			Vermilion:SendNotify(sender, Vermilion.Lang.NoSuchPlayer, VERMILION_NOTIFY_ERROR)
			return
		end
		Vermilion:SendNotify(sender, Vermilion:GetUser(targetPlayer):GetRank().Name)
	end, "[player]")
	
	Vermilion:AddChatPredictor("getrank", function(pos, current)
		if(pos == 1) then
			local tab = {}
			for i,k in pairs(player.GetAll()) do
				if(string.StartWith(k:GetName(), current)) then
					table.insert(tab, k:GetName())
				end
			end
			return tab
		end
	end)
	
	Vermilion:AddChatCommand("setrank", function(sender, text, log)
		if(Vermilion:HasPermissionError(sender, "rank_management")) then
			if(table.Count(text) == 1) then
				if(not Vermilion:HasRank(text[1])) then
					log("No such rank!", VERMILION_NOTIFY_ERROR)
					return
				end
				Vermilion:GetUser(sender):SetRank(text[1])
				return
			end
			if(not Vermilion:HasRank(text[2])) then
				log("No such rank!", VERMILION_NOTIFY_ERROR)
				return
			end
			local targetPlayer = Crimson.LookupPlayerByName(text[1])
			if(targetPlayer == nil) then
				local targetPlayerOffline = Vermilion:GetUser(text[1])
				if(targetPlayerOffline == nil) then
					log("Player does not exist!", VERMILION_NOTIFY_ERROR)
				else
					targetPlayerOffline:SetRank(text[2])
					log("Rank updated!")
				end
				return
			end
			Vermilion:GetUser(targetPlayer):SetRank(text[2])
			log("Rank updated!")
			--Vermilion:SendNotify(targetPlayer, "Your rank is now " .. text[2] .. "!")
		end
	end, "[player] <rank>")
	
	Vermilion:AddChatPredictor("setrank", function(pos, current)
		if(pos == 1) then
			local tab = {}
			for i,k in pairs(player.GetAll()) do
				if(string.StartWith(string.lower(k:GetName()), string.lower(current))) then
					table.insert(tab, k:GetName())
				end
			end
			return tab
		end
		if(pos == 2) then
			local tab = {}
			for i,k in pairs(Vermilion.Settings.Ranks) do
				if(string.StartWith(string.lower(k.Name), string.lower(current))) then
					table.insert(tab, k.Name)
				end
			end
			return tab
		end
	end)
	
	Vermilion:AddChatCommand("setrank_steamid", function(sender, text, log)
		if(Vermilion:HasPermissionError(sender, "rank_management", log)) then
			if(table.Count(text) < 2) then
				log("Syntax: !setrank_steamid <steamid> <rank>", VERMILION_NOTIFY_ERROR)
				return
			end
			local tplayerdata = Vermilion:GetUserSteamID(text[1])
			if(tplayerdata == nil) then
				if(not Vermilion:HasRank(text[2])) then
					log("No such rank!", VERMILION_NOTIFY_ERROR)
				else
					tplayerdata:SetRank(text[2])
					log("Rank updated!")
				end
			else
				log(Vermilion.Lang.NoSuchPlayer, VERMILION_NOTIFY_ERROR)
			end
		end
	end, "<steamid> <rank>")
	
	self:NetHook("VSetRankUser", function(vplayer)
		local steamID = net.ReadString()
		local rank = net.ReadString()
		
		if(Vermilion:HasPermission(vplayer, "rank_management")) then
			if(not Vermilion:HasRank(rank)) then
				Vermilion:SendMessageBox(vplayer, "This rank doesn't exist!")
				return
			end
			local tplayer = Crimson.LookupPlayerBySteamID(steamID)
			if(tplayer == nil) then
				Vermilion:SendMessageBox(vplayer, "Player does not exist!")
				return
			end
			if(tplayer == vplayer and Vermilion:GetUser(vplayer):GetRank().Name == "owner" and Vermilion:CountPlayersInRank("owner") == 1) then
				Vermilion:SendMessageBox(vplayer, "You cannot demote yourself because you are the only owner!")
				return
			end
			Vermilion:GetUser(tplayer):SetRank(rank)
		else
			Vermilion:SendMessageBox(vplayer, "You do not have permission to do this!")
		end
	end)
	
	self:NetHook("VPermissionsList", function(vplayer)
		net.Start("VPermissionsList")
		net.WriteTable(Vermilion.AllPermissions) -- Replace this with a "nice" permissions list.
		net.Send(vplayer)
	end)
	
	self:NetHook("VRankPermissions", function(vplayer)
		net.Start("VRankPermissions")
		local tab = {}
		local trank = net.ReadString()
		if(not Vermilion:HasRank(trank)) then
			net.WriteTable({})
			net.Send(vplayer)
			return
		end
		for i,k in pairs(Vermilion:GetRankData(trank).Permissions) do
			local owner = "Vermilion"
			for i1,k1 in pairs(Vermilion.AllPermissions) do
				if(k1.Permission == k) then
					owner = k1.Owner
				end
			end
			table.insert(tab, { Owner = owner, Permission = k })
		end
		net.WriteTable(tab)
		net.Send(vplayer)
	end)
	
	self:NetHook("VSaveRanks", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "rank_management")) then
			local tab = net.ReadTable()
			Vermilion.Log("Writing ranks...")
			
			-- convert the data to the standard rank format
			local ntab = {}
			for i,k in ipairs(tab) do
				if(k[3] == "Yes") then Vermilion:SetSetting("default_rank", k[1]) end
				table.insert(ntab, { Name = k[1], Permissions = {}, Protected = k[1] == "owner" })
			end
			
			-- remove duplicates
			for i,k in pairs(ntab) do
				for i1,k1 in pairs(ntab) do
					if(k.Name == k1.Name and k != k1) then
						table.RemoveByValue(k)
						break
					end
				end
			end
			
			-- merge the existing permissions into the new table
			for i,k in ipairs(Vermilion.Settings.Ranks) do
				for i1,k1 in ipairs(ntab) do
					if(k.Name == k1.Name) then
						k1.Permissions = k.Permissions
					end
				end
			end
			
			Vermilion.Settings.Ranks = ntab
			
			-- move all players that were in a rank that was deleted into the default rank.
			for i,k in pairs(Vermilion.Settings.Users) do
				if(not Vermilion:HasRank(k.Rank)) then
					Vermilion:GetUser(k.Name):SetRank(Vermilion:GetSetting("default_rank", "player"))
				end
			end
			
			
		else
			Vermilion:SendMessageBox(vplayer, "You do not have permission to do this!")
		end
	end)
	
	self:NetHook("VUpdateRankPermissions", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "rank_management")) then
			local rank = net.ReadString()
			local ptab = net.ReadTable()
			
			if(not Vermilion:HasRank(rank)) then
				Vermilion:SendMessageBox(vplayer, "Rank does not exist!")
				return
			end
			
			Vermilion:GetRankData(rank).Permissions = ptab
			
			for i,vplayer in pairs(player.GetAll()) do
				vplayer:SetNWBool("Vermilion_Identify_Admin", Vermilion:HasPermission(vplayer, "identify_as_admin"))
			end
		else
			Vermilion:SendMessageBox(vplayer, "You do not have permission to do this!")
		end
	end)
	
	self:NetHook("VDefinePermission", function(vplayer)
		local definition = hook.Call("VDefinePermission", nil, net.ReadString())
		if(definition != nil) then
			net.Start("VDefinePermission")
			net.WriteString(definition)
			net.Send(vplayer)
		else
			Vermilion:SendMessageBox(vplayer, "This permission does not have an available definition.")
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
			local ln = EXTENSION.ActivePlayersList:AddLine( k[1], k[2], k[3] )
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
	self:AddHook("VRanksList", "RanksList", function(tab)
		if(not IsValid(EXTENSION.RanksList)) then
			return
		end
		EXTENSION.RanksList:Clear()
		for i,k in pairs(tab) do
			local ln = EXTENSION.RanksList:AddLine(k[1], tostring(i), k[2])
			ln.OnRightClick = function()
				local conmenu = DermaMenu()
				conmenu:SetParent(ln)
				conmenu:AddOption("Display Rank Summary", function()
					Crimson:CreateErrorDialog("Feature not implemented.")
				end):SetIcon("icon16/book_open.png")
				conmenu:AddOption("Remove rank", function()
					Crimson:CreateErrorDialog("Feature not implemented.")
				end):SetIcon("icon16/delete.png")
				conmenu:AddOption("Set as default rank", function()
					Crimson:CreateErrorDialog("Feature not implemented.")
				end):SetIcon("icon16/accept.png")
				conmenu:Open()
			end
		end
	end)
	self:NetHook("VPermissionsList", function()
		if(not IsValid(EXTENSION.AllPermissionsList)) then
			return
		end
		EXTENSION.AllPermissionsList:Clear()
		local tab = net.ReadTable()
		for i,k in pairs(tab) do
			local ln = EXTENSION.AllPermissionsList:AddLine(k.Permission, k.Owner)
			ln.OnRightClick = function()
				local conmenu = DermaMenu()
				conmenu:SetParent(ln)
				conmenu:AddOption("Define", function()
					net.Start("VDefinePermission")
					net.WriteString(ln:GetValue(1))
					net.SendToServer()
				end):SetIcon("icon16/book_open.png")
				conmenu:AddOption("Show ranks with this permission", function()
					Crimson:CreateErrorDialog("Feature not implemented.")
				end):SetIcon("icon16/find.png")
				conmenu:AddOption("Give this permission to all ranks", function()
					Crimson:CreateErrorDialog("Feature not implemented.")
				end):SetIcon("icon16/group_add.png")
				conmenu:AddOption("Remove this permission from all ranks", function()
					Crimson:CreateErrorDialog("Feature not implemented.")
				end):SetIcon("icon16/group_delete.png")
				conmenu:Open()
			end
		end
	end)
	self:NetHook("VRankPermissions", function(len)
		if(not IsValid(EXTENSION.RankPermissionsList)) then
			return
		end
		EXTENSION.RankPermissionsList:Clear()
		local tab = net.ReadTable()
		for i,k in pairs(tab) do
			local ln = EXTENSION.RankPermissionsList:AddLine(k.Permission, k.Owner)
			ln.OnRightClick = function()
				local conmenu = DermaMenu()
				conmenu:SetParent(ln)
				conmenu:AddOption("Define", function()
					net.Start("VDefinePermission")
					net.WriteString(ln:GetValue(1))
					net.SendToServer()
				end):SetIcon("icon16/book_open.png")
				conmenu:Open()
			end
		end
	end)
	self:NetHook("VDefinePermission", function()
		Derma_Message(net.ReadString(), "Permission Defintion", "Close")
	end)
	self:AddHook(Vermilion.EVENT_EXT_LOADED, "AddGui", function()
		Vermilion:AddInterfaceTab("rank_control", "Ranks", "group_gear.png", "Put players in groups to assign permission sets to different types of players", function(panel)
			EXTENSION.EditingRank = ""
			EXTENSION.UnsavedRankChanges = false
			
			
			local ranksList = Crimson.CreateList({ "Name", "Numerical ID", "Default" }, true, false)
			ranksList:SetParent(panel)
			ranksList:SetPos(10, 30)
			ranksList:SetSize(225, 190)
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
			addRankButton:SetPos(245, 30)
			addRankButton:SetSize(95, 30)
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
				if(ranksList:GetSelected()[1]:GetValue(1) == "owner") then
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
			moveRankUpButton:SetPos(245, 70)
			moveRankUpButton:SetSize(95, 30)
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
				if(ranksList:GetSelected()[1]:GetValue(1) == "owner") then
					Crimson:CreateErrorDialog("Cannot move this rank; it is a protected rank!")
					return
				end
				if(tonumber(ranksList:GetSelected()[1]:GetValue(2)) == table.Count(ranksList:GetLines())) then
					Crimson:CreateErrorDialog("Cannot move this rank here; it is at the end of the table!")
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
			moveRankDownButton:SetPos(245, 110)
			moveRankDownButton:SetSize(95, 30)
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
				if(ranksList:GetSelected()[1]:GetValue(1) == "owner") then
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
			removeRankButton:SetPos(245, 150)
			removeRankButton:SetSize(95, 30)
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
			saveRanksButton:SetPos(245, 190)
			saveRanksButton:SetSize(95, 30)
			saveRanksButton:SetParent(panel)
			
			
			
			local activePlayerList = Crimson.CreateList({ "Name", "Steam ID", "Rank" })
			activePlayerList:SetParent(panel)
			activePlayerList:SetPos(455, 30)
			activePlayerList:SetSize(215, 190)
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
					if(userLine:GetValue(2) == LocalPlayer():SteamID()) then
						local selectedNumId = tonumber(ranksList:GetSelected()[1]:GetValue(2))
						local currentNumId = nil
						
						for i1,k in pairs(ranksList:GetLines()) do
							if(k:GetValue(1) == userLine:GetValue(3)) then
								currentNumId = tonumber(k:GetValue(2))
							end
						end
						
						
						if(selectedNumId > currentNumId) then
							Crimson:CreateConfirmDialog("You are about to demote yourself. Are you sure?", function()
								net.Start("VSetRankUser")
								net.WriteString(LocalPlayer():SteamID())
								net.WriteString(ranksList:GetSelected()[1]:GetValue(1))
								net.SendToServer()
							end)
						else
							net.Start("VSetRankUser")
							net.WriteString(LocalPlayer():SteamID())
							net.WriteString(ranksList:GetSelected()[1]:GetValue(1))
							net.SendToServer()
						end
					else
						net.Start("VSetRankUser")
						net.WriteString(userLine:GetValue(2)) -- User Steam ID
						net.WriteString(ranksList:GetSelected()[1]:GetValue(1)) -- The rank name to set
						net.SendToServer()
					end
				end
				net.Start("VActivePlayers")
				net.SendToServer()
			end)
			setPlayerRankButton:SetPos(680, 30)
			setPlayerRankButton:SetSize(95, 30)
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
			setDefaultRankButton:SetPos(350, 30)
			setDefaultRankButton:SetSize(95, 30)
			setDefaultRankButton:SetParent(panel)
			
			
			
			local guiRankPermissionsList = Crimson.CreateList({ "Name", "Owner" })
			guiRankPermissionsList:SetParent(panel)
			guiRankPermissionsList:SetPos(10, 250)
			guiRankPermissionsList:SetSize(300, 280)
			EXTENSION.RankPermissionsList = guiRankPermissionsList
			
			local rankPermissionsLabel = Crimson:CreateHeaderLabel(guiRankPermissionsList, "Rank Permissions")
			rankPermissionsLabel:SetParent(panel)
			
			
			
			local guiAllPermissionsList = Crimson.CreateList({ "Name", "Owner" })
			guiAllPermissionsList:SetParent(panel)
			guiAllPermissionsList:SetPos(475, 250)
			guiAllPermissionsList:SetSize(300, 280)
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
					guiRankPermissionsList:AddLine(k:GetValue(1), k:GetValue(2))
				end
			end)
			giveRankPermissionButton:SetPos(320, 350)
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
						table.insert(tab, k:GetValue(1), k:GetValue(2))
					end
				end
				guiRankPermissionsList:Clear()
				for i,k in ipairs(tab) do
					guiRankPermissionsList:AddLine(k)
				end
			end)
			removeRankPermissionButton:SetPos(320, 390)
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
			loadRankPermissionsButton:SetPos(320, 250)
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
			saveRankPermissionsButton:SetPos(320, 500)
			saveRankPermissionsButton:SetSize(145, 30)
			saveRankPermissionsButton:SetParent(panel)
			
			
			
			net.Start("VPermissionsList")
			net.SendToServer()
		end, 2)
	end)
end

Vermilion:RegisterExtension(EXTENSION)