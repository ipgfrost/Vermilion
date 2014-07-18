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
	"ban_management"
}
EXTENSION.RankPermissions = {
	{ "admin", {
			"ban",
			"unban",
			"kick",
			"ban_management"
		}
	}
}
EXTENSION.NetworkStrings = {
	"VBannedPlayersList",
	"VBanPlayer",
	"VUnbanPlayer",
	"VKickPlayer"
}

EXTENSION.Bans = {}

function EXTENSION:LoadBans()
	if(not file.Exists(Vermilion.GetFileName("vermilion", "bans.txt"), "DATA")) then
		Vermilion.Log("Creating bans for the first time!")
		self:ResetBans()
		self:SaveBans()
	end
	local data = file.Read( Vermilion.GetFileName("vermilion", "bans.txt"), "DATA")
	local tab = von.deserialize(data)
	self.Bans = tab
end

function EXTENSION:SaveBans()
	file.Write(Vermilion.GetFileName("vermilion", "bans.txt"), von.serialize(self.Bans))
end

function EXTENSION:ResetBans()
	self.Bans = {}
end

--[[
	Ban a player and unban them using a unix timestamp.
]]--
function Vermilion:BanPlayerFor(vplayer, vplayerBanner, reason, years, months, weeks, days, hours, mins, seconds)
	-- seconds per year = 31557600
	-- average seconds per month = 2592000 
	-- seconds per week = 604800
	-- seconds per day = 86400
	-- seconds per hour = 3600
	
	if(isstring(vplayer)) then
		vplayer = Crimson.LookupPlayerByName(vplayer)
	end
	if(isstring(vplayerBanner)) then
		vplayerBanner = Crimson.LookupByName(vplayerBanner)
	end
	
	local time = 0
	time = time + (years * 31557600)
	time = time + (months * 2592000)
	time = time + (weeks * 604800)
	time = time + (days * 86400)
	time = time + (hours * 3600)
	time = time + (mins * 60)
	time = time + seconds
	
	local str = vplayer:GetName() .. " has been banned by " .. vplayerBanner:GetName() .. " for "
	
	local timestr = ""
	if(years > 0) then
		if(years == 1) then
			timestr = tostring(years) .. " year"
		else
			timestr = tostring(years) .. " years"
		end
	end
	
	if(years > 0 and months > 0) then
		local connective = ", "
		if(weeks < 1 and days < 1 and hours < 1 and mins < 1 and seconds < 1) then
			connective = " and "
		end
		if(months == 1) then
			timestr = timestr .. connective .. tostring(months) .. " month"
		else
			timestr = timestr .. connective .. tostring(months) .. " months"
		end
	elseif(months > 0) then
		if(months == 1) then
			timestr = tostring(months) .. " month"
		else
			timestr = tostring(months) .. " months"
		end
	end
	
	if((years > 0 or months > 0) and weeks > 0) then
		local connective = ", "
		if(days < 1 and hours < 1 and mins < 1 and seconds < 1) then
			connective = " and "
		end
		if(weeks == 1) then
			timestr = timestr .. connective .. tostring(weeks) .. " week"
		else
			timestr = timestr .. connective .. tostring(weeks) .. " weeks"
		end
	elseif(weeks > 0) then
		if(weeks == 1) then
			timestr = tostring(weeks) .. " week"
		else
			timestr = tostring(weeks) .. " weeks"
		end
	end
	
	if((years > 0 or months > 0 or weeks > 0) and days > 0) then
		local connective = ", "
		if(hours < 1 and mins < 1 and seconds < 1) then
			connective = " and "
		end
		if(days == 1) then
			timestr = timestr .. connective .. tostring(days) .. " day"
		else
			timestr = timestr .. connective .. tostring(days) .. " days"
		end
	elseif(days > 0) then
		if(days == 1) then
			timestr = tostring(days) .. " day"
		else
			timestr = tostring(days) .. " days"
		end
	end
	
	if((years > 0 or months > 0 or weeks > 0 or days > 0) and hours > 0) then
		local connective = ", "
		if(mins < 1 and seconds < 1) then
			connective = " and "
		end
		if(hours == 1) then
			timestr = timestr .. connective .. tostring(hours) .. " hour"
		else
			timestr = timestr .. connective .. tostring(hours) .. " hours"
		end
	elseif(hours > 0) then
		if(hours == 1) then
			timestr = tostring(hours) .. " hour"
		else
			timestr = tostring(hours) .. " hours"
		end
	end
	
	if((years > 0 or months > 0 or weeks > 0 or days > 0 or hours > 0) and mins > 0) then
		local connective = ", "
		if(seconds < 1) then
			connective = " and "
		end
		if(mins == 1) then
			timestr = timestr .. connective .. tostring(mins) .. " minute"
		else
			timestr = timestr .. connective .. tostring(mins) .. " minutes"
		end
	elseif(mins > 0) then
		if(mins == 1) then
			timestr = tostring(mins) .. " minute"
		else
			timestr = tostring(mins) .. " minutes"
		end
	end
	
	if((years > 0 or months > 0 or weeks > 0 or days > 0 or hours > 0 or mins > 0) and seconds > 0) then
		if(seconds == 1) then
			timestr = timestr .. " and " .. tostring(seconds) .. " second"
		else
			timestr = timestr .. " and " .. tostring(seconds) .. " seconds"
		end
	elseif(seconds > 0) then
		if(seconds == 1) then
			timestr = tostring(seconds) .. " second"
		else
			timestr = tostring(seconds) .. " seconds"
		end
	end
	
	self:BroadcastNotify(str .. timestr .. " with reason: " .. reason)
	
	-- steamid, reason, expiry time, banner
	table.insert(EXTENSION.Bans, { vplayer:SteamID(), reason, os.time() + time, vplayerBanner:GetName() } )
	self:SetRank(vplayer, "banned")	
	vplayer:Kick("Banned from server for " .. timestr .. ": " .. reason)
	
	
end

function Vermilion:UnbanPlayer(steamid, unbanner)
	if(isstring(unbanner)) then
		unbanner = Crimson.LookupPlayerByName(unbanner)
	end
	local idxToRemove = {}
	for i,k in pairs(EXTENSION.Bans) do
		if(k[1] == steamid) then
			local playerName = self:GetPlayerBySteamID(k[1])['name']
			self:BroadcastNotify(playerName .. " has been unbanned by " .. unbanner:GetName(), 10, NOTIFY_ERROR)
			table.insert(idxToRemove, i)
			self:GetPlayerBySteamID(k[1])['rank'] = self:GetSetting("default_rank", "player")
			break
		end
	end
	for i,k in pairs(idxToRemove) do
		table.remove(EXTENSION.Bans, k)
	end
end

function EXTENSION:InitServer()
	self:AddHook("VNET_VBannedPlayersList", function(vplayer)
		net.Start("VBannedPlayersList")
		local tab = {}
		for i,k in pairs(EXTENSION.Bans) do
			table.insert(tab, {Vermilion:GetPlayerBySteamID(k[1])['name'], k[1], k[2], os.date("%c", k[3]), k[4]})
		end
		net.WriteTable(tab)
		net.Send(vplayer)
	end)
	
	self:AddHook("VNET_VBanPlayer", function(vplayer)
		if(Vermilion:HasPermissionError(vplayer, "ban")) then
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
	
	self:AddHook("VNET_VUnbanPlayer", function(vplayer)
		if(Vermilion:HasPermissionError(vplayer, "unban")) then
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
	
	self:AddHook("VNET_VKickPlayer", function(vplayer)
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
		for i,k in pairs(EXTENSION.Bans) do
			if(os.time() > k[3]) then
				local playerName = Vermilion:GetPlayerBySteamID(k[1])['name']
				Vermilion:BroadcastNotify(playerName .. " has been unbanned because their ban has expired!", 10, NOTIFY_ERROR)
				table.insert(idxToRemove, i)
				Vermilion:GetPlayerBySteamID(k[1])['rank'] = Vermilion:GetSetting("default_rank", "player")
			end
		end
		for i,k in pairs(idxToRemove) do
			table.remove(EXTENSION.Bans, k)
		end
		local playerDat = Vermilion:GetPlayerBySteamID(util.SteamIDFrom64(steamID))
		if(playerDat != nil) then
			if(playerDat['rank'] == "banned") then
				Vermilion:SendNotify(Vermilion:GetAllPlayersWithPermission("ban_management"), "Warning: " .. name .. " has attempted to join the server!", 5, NOTIFY_ERROR)
				return false, "You are banned from this server!"
			end
		end
	end)
	
	self:AddHook(Vermilion.EVENT_EXT_LOADED, "AddGui", function()
		Vermilion:AddInterfaceTab("ban_control", "ban_management")
	end)
	
	self:AddHook("ShutDown", "toollimit_save", function()
		EXTENSION:SaveBans()
	end)
	
	self:LoadBans()
end

function EXTENSION:InitClient()
	self:AddHook("VActivePlayers", "ActivePlayersList", function(tab)
		if(not IsValid(EXTENSION.ActivePlayerList)) then
			return
		end
		EXTENSION.ActivePlayerList:Clear()
		for i,k in pairs(tab) do
			EXTENSION.ActivePlayerList:AddLine( k[1], k[2], k[3] )
		end
	end)
	self:AddHook("VNET_VBannedPlayersList", function()
		if(not IsValid(EXTENSION.ActivePlayerList)) then
			return
		end
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
						net.Start("VBannedPlayersList")
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
				net.Start("VBannedPlayersList")
				net.SendToServer()
			end)
			unbanPlayerButton:SetPos(panel:GetWide() - 105, 240)
			unbanPlayerButton:SetSize(105, 30)
			unbanPlayerButton:SetParent(panel)
			
			net.Start("VBannedPlayersList")
			net.SendToServer()
			
			return panel
		end)
	end)
end

Vermilion:RegisterExtension(EXTENSION)