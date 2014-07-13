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
EXTENSION.Name = "Ban Manager"
EXTENSION.ID = "bans"
EXTENSION.Description = "Handles bans"
EXTENSION.Author = "Ned"
EXTENSION.Permissions = {
	"ban_immunity",
	"kick_immunity",
	"ban",
	"unban",
	"kick",
	"bans_alert"
}

function EXTENSION:InitServer()
	util.AddNetworkString("BannedPlayers_Request")
	util.AddNetworkString("BannedPlayers_Response")
	util.AddNetworkString("VBanPlayer")
	util.AddNetworkString("VUnbanPlayer")
	util.AddNetworkString("VKickPlayer")
	
	net.Receive("BannedPlayers_Request", function(len, vplayer)
		net.Start("BannedPlayers_Response")
		local tab = {}
		for i,k in pairs(Vermilion.Bans) do
			table.insert(tab, {Vermilion:GetPlayerBySteamID(k[1])['name'], k[1], k[2], os.date("%c", k[3]), k[4]})
		end
		net.WriteTable(tab)
		net.Send(vplayer)
	end)
	
	net.Receive("VBanPlayer", function(len, vplayer)
		if(Vermilion:HasPermissionVerboseChat(vplayer, "ban")) then
			local times = net.ReadTable()
			local reason = net.ReadString()
			local steamid = net.ReadString()
			local tplayer = Crimson.LookupPlayerBySteamID(steamid)
			if(Vermilion:HasPermission(tplayer, "ban_immunity")) then
				return
			end
			if(tplayer != nil) then
				Vermilion:BanPlayerFor(tplayer, vplayer, reason, times[1], times[2], times[3], times[4], times[5], times[6], times[7])
			else
				Vermilion:SendNotify(vplayer, "This player doesn't exist!", 5, NOTIFY_ERROR)
			end
		end
	end)
	
	net.Receive("VUnbanPlayer", function(len, vplayer)
		if(Vermilion:HasPermissionVerboseChat(vplayer, "unban")) then
			local steamid = net.ReadString()
			local playerData = Vermilion:GetPlayerBySteamID(steamid)
			if(playerData != nil) then
				Vermilion:UnbanPlayer(steamid, vplayer)
				Vermilion:SaveUserStore()
			else
				Vermilion:SendNotify(vplayer, "This player doesn't exist!", 5, NOTIFY_ERROR)
			end
		end
	end)
	
	net.Receive("VKickPlayer", function(len, vplayer)
		if(Vermilion:HasPermission(vplayer, "kick")) then
			local steamID = net.ReadString()
			local reason = net.ReadString()
			local tplayer = Crimson.LookupPlayerBySteamID(steamID)
			if(IsValid(tplayer)) then
				Vermilion:BroadcastNotify(tplayer:GetName() .. " was kicked by " .. vplayer:GetName() .. ": " .. reason, 10, NOTIFY_ERROR)
				tplayer:Kick("Kicked by " .. vplayer:GetName() .. ": " .. reason)
			end
		else
			Vermilion:SendMessageBox(vplayer, "You don't have permission to do this!")
		end
	end)

	self:AddHook("CheckPassword", "CheckBanned", function( steamID, ip, svPassword, clPassword, name )
		local idxToRemove = {}
		for i,k in pairs(Vermilion.Bans) do
			if(os.time() > k[3]) then
				local playerName = Vermilion:GetPlayerBySteamID(k[1])['name']
				Vermilion:BroadcastNotify(playerName .. " has been unbanned because their ban has expired!", 10, NOTIFY_ERROR)
				table.insert(idxToRemove, i)
				Vermilion:GetPlayerBySteamID(k[1])['rank'] = Vermilion:GetSetting("default_rank", "player")
			end
		end
		for i,k in pairs(idxToRemove) do
			table.remove(Vermilion.Bans, k)
		end
		local playerDat = Vermilion:GetPlayerBySteamID(util.SteamIDFrom64(steamID))
		if(playerDat != nil) then
			if(playerDat['rank'] == "banned") then
				Vermilion:SendNotify(Vermilion:GetAllPlayersWithPermission("bans_alert"), "Warning: " .. name .. " has attempted to join the server!", 5, NOTIFY_ERROR)
				return false, "You are banned from this server!"
			end
		end
	end)
end

function EXTENSION:InitClient()
	self:AddHook("Vermilion_ActivePlayers", "ActivePlayersList", function(tab)
		EXTENSION.ActivePlayerList:Clear()
		for i,k in pairs(tab) do
			EXTENSION.ActivePlayerList:AddLine( k[1], k[2], k[3] )
		end
	end)
	net.Receive("BannedPlayers_Response", function(len)
		EXTENSION.BannedPlayerList:Clear()
		local tab = net.ReadTable()
		for i,k in pairs(tab) do
			EXTENSION.BannedPlayerList:AddLine(k[1], k[2], k[3], k[4], k[5])
		end
	end)
	self:AddHook(Vermilion.EVENT_EXT_LOADED, "AddGui", function()
		Vermilion:AddInterfaceTab("ban_control", "Bans", "icon16/delete.png", "Ban Control", function(TabHolder)
			local panel = vgui.Create("DPanel", TabHolder)
			panel:StretchToParent(5, 20, 20, 5)
			
			local activePlayersLabel = Crimson.CreateLabel("Active Players")
			activePlayersLabel:SetPos((panel:GetWide() / 2) - (activePlayersLabel:GetWide() / 2), 10)
			activePlayersLabel:SetParent(panel)
			
			local activePlayersList = vgui.Create("DListView")
			activePlayersList:SetMultiSelect(true)
			activePlayersList:AddColumn("Name")
			activePlayersList:AddColumn("Steam ID")
			activePlayersList:AddColumn("Rank")
			activePlayersList:SetParent(panel)
			activePlayersList:SetPos(10, 30)
			activePlayersList:SetSize(panel:GetWide() - 10, 200)
			
			EXTENSION.ActivePlayerList = activePlayersList
			
			local banPlayerButton = Crimson.CreateButton("Ban Selected", function(self)
				if(table.Count(activePlayersList:GetSelected()) == 0) then
					Crimson:CreateErrorDialog("You must select at least one player to ban!")
					return
				end
				local bTimePanel = Crimson.CreateFrame(
					{
						['size'] = { 640, 90 },
						['pos'] = { (ScrW() / 2) - 320, (ScrH() / 2) - 45 },
						['closeBtn'] = true,
						['draggable'] = true,
						['title'] = "Input ban time",
						['bgBlur'] = true
					}
				)
				
				Crimson:SetDark(false)
				
				local yearsLabel = Crimson.CreateLabel("Years:")
				yearsLabel:SetPos(10 + ((64 - yearsLabel:GetWide()) / 2), 30)
				yearsLabel:SetParent(bTimePanel)
				
				local yearsWang = Crimson.CreateNumberWang(0, 1000)
				yearsWang:SetPos(10, 45)
				yearsWang:SetParent(bTimePanel)
				
				local monthsLabel = Crimson.CreateLabel("Months:")
				monthsLabel:SetPos(84 + ((64 - monthsLabel:GetWide()) / 2), 30)
				monthsLabel:SetParent(bTimePanel)
				
				local monthsWang = Crimson.CreateNumberWang(0, 12)
				monthsWang:SetPos(84, 45)
				monthsWang:SetParent(bTimePanel)
				monthsWang.OnValueChanged = function(wang, val)
					if(tonumber(val) == 12) then
						wang:SetValue(0)
						yearsWang:SetValue(yearsWang:GetValue() + 1)
					end
				end
				
				local weeksLabel = Crimson.CreateLabel("Weeks:")
				weeksLabel:SetPos(158 + ((64 - weeksLabel:GetWide()) / 2), 30)
				weeksLabel:SetParent(bTimePanel)
				
				local weeksWang = Crimson.CreateNumberWang(0, 4)
				weeksWang:SetPos(158, 45)
				weeksWang:SetParent(bTimePanel)
				weeksWang.OnValueChanged = function(wang, val)
					if(tonumber(val) == 4) then
						wang:SetValue(0)
						monthsWang:SetValue(monthsWang:GetValue() + 1)
					end
				end
				
				local daysLabel = Crimson.CreateLabel("Days:")
				daysLabel:SetPos(232 + ((64 - daysLabel:GetWide()) / 2), 30)
				daysLabel:SetParent(bTimePanel)
				
				local daysWang = Crimson.CreateNumberWang(0, 7)
				daysWang:SetPos(232, 45)
				daysWang:SetParent(bTimePanel)
				daysWang.OnValueChanged = function(wang, val)
					if(tonumber(val) == 7) then
						wang:SetValue(0)
						weeksWang:SetValue(weeksWang:GetValue() + 1)
					end
				end
				
				local hoursLabel = Crimson.CreateLabel("Hours:")
				hoursLabel:SetPos(306 + ((64 - hoursLabel:GetWide()) / 2), 30)
				hoursLabel:SetParent(bTimePanel)
				
				local hoursWang = Crimson.CreateNumberWang(0, 24)
				hoursWang:SetPos(306, 45)
				hoursWang:SetParent(bTimePanel)
				hoursWang.OnValueChanged = function(wang, val)
					if(tonumber(val) == 24) then
						wang:SetValue(0)
						daysWang:SetValue(daysWang:GetValue() + 1)
					end
				end
				
				local minsLabel = Crimson.CreateLabel("Minutes:")
				minsLabel:SetPos(380 + ((64 - minsLabel:GetWide()) / 2), 30)
				minsLabel:SetParent(bTimePanel)
				
				local minsWang = Crimson.CreateNumberWang(0, 60)
				minsWang:SetPos(380, 45)
				minsWang:SetParent(bTimePanel)
				minsWang.OnValueChanged = function(wang, val)
					if(tonumber(val) == 60) then
						wang:SetValue(0)
						hoursWang:SetValue(hoursWang:GetValue() + 1)
					end
				end
				
				local secondsLabel = Crimson.CreateLabel("Seconds:")
				secondsLabel:SetPos(454 + ((64 - secondsLabel:GetWide()) / 2), 30)
				secondsLabel:SetParent(bTimePanel)
				
				local secondsWang = Crimson.CreateNumberWang(0, 60)
				secondsWang:SetPos(454, 45)
				secondsWang:SetParent(bTimePanel)
				secondsWang.OnValueChanged = function(wang, val)
					if(tonumber(val) == 60) then
						wang:SetValue(0)
						minsWang:SetValue(minsWang:GetValue() + 1)
					end
				end
				
				local confirmButton = Crimson.CreateButton("OK", function(self)
					local times = { yearsWang:GetValue(), monthsWang:GetValue(), weeksWang:GetValue(), daysWang:GetValue(), hoursWang:GetValue(), minsWang:GetValue(), secondsWang:GetValue() }
					bTimePanel:Close()
					Crimson:CreateTextInput("For what reason are you banning this/these player(s)?", function(text)
						for i,k in pairs(EXTENSION.ActivePlayerList:GetSelected()) do
							net.Start("VBanPlayer")
							net.WriteTable(times)
							net.WriteString(text)
							net.WriteString(k:GetValue(2))
							net.SendToServer()
						end
						net.Start("BannedPlayers_Request")
						net.SendToServer()
					end)
				end)
				confirmButton:SetPos(528, 30)
				confirmButton:SetSize(100, 20)
				confirmButton:SetParent(bTimePanel)
				
				local cancelButton = Crimson.CreateButton("Cancel", function(self)
					bTimePanel:Close()
				end)
				cancelButton:SetPos(528, 60)
				cancelButton:SetSize(100, 20)
				cancelButton:SetParent(bTimePanel)
						
				Crimson:SetDark(true)
				
				bTimePanel:MakePopup()
				bTimePanel:DoModal()
				bTimePanel:SetAutoDelete(true)
				
			end)
			banPlayerButton:SetPos(10, 240)
			banPlayerButton:SetSize(105, 30)
			banPlayerButton:SetParent(panel)
			
			local kickPlayerButton = Crimson.CreateButton("Kick Selected", function(self)
				if(table.Count(activePlayersList:GetSelected()) == 0) then
					Crimson:CreateErrorDialog("You must select at least one player to kick!")
					return
				end
				Crimson:CreateTextInput("For what reason are you kicking this/these player(s)?", function(text)
					for i,k in pairs(EXTENSION.ActivePlayerList:GetSelected()) do
						net.Start("VKickPlayer")
						net.WriteString(k:GetValue(2))
						net.WriteString(text)
						net.SendToServer()
					end
				end)
			end)
			kickPlayerButton:SetPos(125, 240)
			kickPlayerButton:SetSize(105, 30)
			kickPlayerButton:SetParent(panel)
			
			local bannedPlayersLabel = Crimson.CreateLabel("Banned Players")
			bannedPlayersLabel:SetPos((panel:GetWide() / 2) - (bannedPlayersLabel:GetWide() / 2), 280)
			bannedPlayersLabel:SetParent(panel)
			
			local bannedPlayersList = vgui.Create("DListView")
			bannedPlayersList:SetMultiSelect(true)
			bannedPlayersList:AddColumn("Name")
			bannedPlayersList:AddColumn("Steam ID")
			bannedPlayersList:AddColumn("Reason")
			bannedPlayersList:AddColumn("Expires")
			bannedPlayersList:AddColumn("Banned By")
			bannedPlayersList:SetParent(panel)
			bannedPlayersList:SetPos(10, 300)
			bannedPlayersList:SetSize(panel:GetWide() - 10, 230)
			
			EXTENSION.BannedPlayerList = bannedPlayersList
			
			local unbanPlayerButton = Crimson.CreateButton("Unban Selected", function(self)
				if(table.Count(bannedPlayersList:GetSelected()) == 0) then
					Crimson:CreateErrorDialog("Must select at least one player to unban!")
					return
				end
				for i,k in pairs(bannedPlayersList:GetSelected()) do
					net.Start("VUnbanPlayer")
					net.WriteString(k:GetValue(2))
					net.SendToServer()
				end
				net.Start("BannedPlayers_Request")
				net.SendToServer()
			end)
			unbanPlayerButton:SetPos(panel:GetWide() - 105, 240)
			unbanPlayerButton:SetSize(105, 30)
			unbanPlayerButton:SetParent(panel)
			
			net.Start("BannedPlayers_Request")
			net.SendToServer()
			
			return panel
		end)
	end)
end

Vermilion:RegisterExtension(EXTENSION)