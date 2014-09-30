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
EXTENSION.PermissionDefinitions = {
	["ban_immunity"] = "This player cannot be banned under any circumstances.",
	["kick_immunity"] = "This player cannot be kicked under any circumstances, unless being banned.",
	["ban"] = "This player is allowed to ban other players.",
	["unban"] = "This player is allowed to unban other players.",
	["kick"] = "This player is allowed to kick other players.",
	["ban_management"] = "This player is allowed to access the ban management panel in the Vermilion Menu and change the settings within."
}
EXTENSION.RankPermissions = {
	{ "admin", {
			"ban",
			"unban",
			"kick",
			"ban_management",
			"kick_immunity",
			"ban_immunity"
		}
	}
}
EXTENSION.NetworkStrings = {
	"VBannedPlayersList", -- retrieves the list of banned players for the GUI
	"VBanPlayer", -- sends a command to the server to ban a player
	"VUnbanPlayer", -- sends a command to the server to unban a player
	"VKickPlayer" -- sends a command to the server to kick a player.
}

--[[
	Ban a player and unban them using a unix timestamp.
	
	vplayer - the player to ban (string or player entity)
	vplayerBanner - the player executing the ban (string or player entity)
	reason - the reason for the ban
	years - years to ban for
	months - months to ban for
	weeks - weeks to ban for
	days - days to ban for
	hours - hours to ban for
	mins - minutes to ban for
	seconds - seconds to ban for
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
	
	if(not IsValid(vplayerBanner)) then
		vplayerBanner = {}
		function vplayerBanner:GetName()
			return "Console"
		end
	end
	
	if(Vermilion:HasPermission(vplayer, "ban_immunity")) then
		Vermilion:SendNotify(vplayer, "This player is immune to being banned!", VERMILION_NOTIFY_ERROR)
		return
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
	
	self:BroadcastNotify(str .. timestr .. " with reason: " .. reason, VERMILION_NOTIFY_ERROR)
	
	-- steamid, reason, expiry time, banner
	table.insert(EXTENSION:GetData("bans", {}, true), { vplayer:SteamID(), reason, os.time() + time, vplayerBanner:GetName() } )
	vplayer:Kick("Banned from server for " .. timestr .. ": " .. reason)
	
	
end

--[[
	Unban a player
	
	steamid - the steamid that should be unbanned
	unbanner - the player that is executing the function (player entity or string)
]]--
function Vermilion:UnbanPlayer(steamid, unbanner)
	if(isstring(unbanner)) then
		unbanner = Crimson.LookupPlayerByName(unbanner)
	end
	if(not Vermilion:HasPermission(unbanner, "unban")) then
		return
	end
	if(not IsValid(unbanner)) then -- if the unbanner isn't valid, assume it's the console and create a fake player object.
		unbanner = {}
		function unbanner:GetName()
			return "Console"
		end
	end
	local idxToRemove = {}
	for i,k in pairs(EXTENSION:GetData("bans", {}, true)) do
		if(k[1] == steamid) then
			local playerName = self:GetUserSteamID(k[1]).Name
			self:BroadcastNotify(playerName .. " has been unbanned by " .. unbanner:GetName(), VERMILION_NOTIFY_ERROR)
			table.insert(idxToRemove, i)
			self:GetUserSteamID(k[1]):SetRank(self:GetSetting("default_rank", "player"))
			break
		end
	end
	for i,k in pairs(idxToRemove) do
		table.remove(EXTENSION:GetData("bans", {}, true), k)
	end
end

--[[
	Get the ban data for the steamid
	
	steamid - the steamid to get the data for
]]--
function Vermilion:GetBanData(steamid)
	for i,k in pairs(EXTENSION:GetData("bans", {}, true)) do
		if(k[1] == steamid) then
			return k
		end
	end
end

--[[
	Check if the steamid has been banned.
	
	steamid - the steamid to check
]]--
function Vermilion:IsSteamIDBanned(steamid)
	for i,k in pairs(EXTENSION:GetData("bans", {}, true)) do
		if(k[1] == steamid) then
			return true
		end
	end
	return false
end

function EXTENSION:InitServer()
	
	Vermilion:AddChatCommand("ban", function(sender, text, log)
		if(Vermilion:HasPermissionError(sender, "ban")) then
			if(table.Count(text) < 1) then
				log("Syntax: !ban <player> [time in minutes: default = 60] [reason: default = Because of reasons.]", VERMILION_NOTIFY_ERROR)
				return
			end
			local tplayer = Crimson.LookupPlayerByName(text[1])
			if(not IsValid(tplayer)) then
				log(Vermilion.Lang.NoSuchPlayer, VERMILION_NOTIFY_ERROR)
				return
			end
			local time = 60
			local reason = "Because of reasons."
			if(table.Count(text) > 1) then
				if(tonumber(text[2]) != nil) then
					time = tonumber(text[2])
				end
				if(table.Count(text) > 2) then
					reason = table.concat(text, " ", 3) 
				end
			end
			Vermilion:BanPlayerFor(tplayer, sender, reason, 0, 0, 0, 0, 0, time, 0)
		end
	end, "<player> [time in minutes: default = 60] [reason: default = Because of reasons.]")
	
	Vermilion:AddChatPredictor("ban", function(pos, current)
		if(pos == 1) then
			local tab = {}
			for i,k in pairs(player.GetAll()) do
				if(string.StartWith(string.lower(k:GetName()), string.lower(current))) then
					table.insert(tab, k:GetName())
				end
			end
			return tab
		end
		if(pos == 2) then return { "60" } end
		if(pos == 3) then return { "Because of reasons." } end
	end)
	
	Vermilion:AddChatCommand("unban", function(sender, text, log)
		if(Vermilion:HasPermissionError(sender, "unban")) then
			if(table.Count(text) < 1) then
				log("Syntax: !unban <player>", VERMILION_NOTIFY_ERROR)
				return
			end
			if(Vermilion:HasUser(text[1])) then
				Vermilion:UnbanPlayer(Vermilion:GetUser(text[1]).SteamID, sender)
			else
				log(Vermilion.Lang.NoSuchPlayer, VERMILION_NOTIFY_ERROR)
			end
		end
	end, "<player>")
	
	Vermilion:AddChatPredictor("unban", function(pos, current)
		if(pos == 1) then
			local tab = {}
			for i,k in pairs(EXTENSION:GetData("bans", {}, true)) do
				table.insert(tab, Vermilion:GetUser(text[1]).Name)
			end
			return tab
		end
	end)
	
	Vermilion:AddChatCommand("kick", function(sender, text, log)
		if(Vermilion:HasPermissionError(sender, "kick")) then
			if(table.Count(text) < 1) then
				log("Syntax: !kick <player> [reason]", VERMILION_NOTIFY_ERROR)
				return
			end
			local reason = "Because of reasons."
			if(table.Count(text) > 1) then
				reason = table.concat(text, " ", 2)
			end
			local tplayer = Crimson.LookupPlayerByName(text[1])
			if(IsValid(tplayer)) then
				Vermilion:BroadcastNotify(tplayer:GetName() .. " was kicked by " .. sender:GetName() .. ": " .. reason, 10, VERMILION_NOTIFY_ERROR)
				tplayer:Kick("Kicked by " .. sender:GetName() .. ": " .. reason)
			end
		end
	end, "<player> [reason]")
	
	Vermilion:AddChatPredictor("kick", function(pos, current)
		if(pos == 1) then
			local tab = {}
			for i,k in pairs(player.GetAll()) do
				if(string.StartWith(string.lower(k:GetName()), string.lower(current))) then
					table.insert(tab, k:GetName())
				end
			end
			return tab
		end
	end)

	self:NetHook("VBannedPlayersList", function(vplayer)
		net.Start("VBannedPlayersList")
		local tab = {}
		for i,k in pairs(EXTENSION:GetData("bans", {}, true)) do
			table.insert(tab, {Vermilion:GetUserSteamID(k[1]).Name, k[1], k[2], os.date("%c", k[3]), k[4]})
		end
		net.WriteTable(tab)
		net.Send(vplayer)
	end)
	
	
	self:NetHook("VBanPlayer", function(vplayer)
		if(Vermilion:HasPermissionError(vplayer, "ban")) then
			local times = net.ReadTable()
			local reason = net.ReadString()
			local tplayer = nil
			if(net.ReadBoolean()) then
				tplayer = net.ReadEntity()
			else
				tplayer = Crimson.LookupPlayerBySteamID(net.ReadString())
			end
			if(tplayer != nil) then
				if(Vermilion:HasPermission(tplayer, "ban_immunity")) then
					return
				end
				Vermilion:BanPlayerFor(tplayer, vplayer, reason, times[1], times[2], times[3], times[4], times[5], times[6], times[7])
			else
				Vermilion:SendNotify(vplayer, Vermilion.Lang.NoSuchPlayer, VERMILION_NOTIFY_ERROR)
			end
		end
	end)
	
	
	self:NetHook("VUnbanPlayer", function(vplayer)
		if(Vermilion:HasPermissionError(vplayer, "unban")) then
			local steamid = net.ReadString()
			local playerData = Vermilion:GetUserSteamID(steamid)
			if(playerData != nil) then
				Vermilion:UnbanPlayer(steamid, vplayer)
			else
				Vermilion:SendNotify(vplayer, Vermilion.Lang.NoSuchPlayer, VERMILION_NOTIFY_ERROR)
			end
		end
	end)
	
	
	self:NetHook("VKickPlayer", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "kick")) then
			local tplayer = nil
			if(net.ReadBoolean()) then
				tplayer = net.ReadEntity()
			else
				tplayer = Crimson.LookupPlayerBySteamID(net.ReadString())
			end
			local reason = net.ReadString()
			if(IsValid(tplayer)) then
				Vermilion:BroadcastNotify(tplayer:GetName() .. " was kicked by " .. vplayer:GetName() .. ": " .. reason, 10, VERMILION_NOTIFY_ERROR)
				tplayer:Kick("Kicked by " .. vplayer:GetName() .. ": " .. reason)
			end
		else
			Vermilion:SendMessageBox(vplayer, "You don't have permission to do this!")
		end
	end)

	
	self:AddHook("CheckPassword", "CheckBanned", function( steamID, ip, svPassword, clPassword, name )
		local idxToRemove = {}
		for i,k in pairs(EXTENSION:GetData("bans", {})) do
			if(os.time() > k[3]) then
				local playerName = Vermilion:GetUserSteamID(k[1]).Name
				Vermilion:BroadcastNotify(playerName .. " has been unbanned because their ban has expired!", 10, VERMILION_NOTIFY_ERROR)
				table.insert(idxToRemove, i)
				Vermilion:GetUserSteamID(k[1]):SetRank(Vermilion:GetSetting("default_rank", "player"))
			end
		end
		for i,k in pairs(idxToRemove) do
			table.remove(EXTENSION:GetData("bans", {}), k)
		end
		if(Vermilion:IsSteamIDBanned(util.SteamIDFrom64(steamID))) then
			Vermilion:SendNotify(Vermilion:GetUsersWithPermission("ban_management"), "Warning: " .. name .. " has attempted to join the server!", VERMILION_NOTIFY_ERROR)
			return false, "You are banned from this server!"
		end
	end)
	
	
	self:AddHook(Vermilion.EVENT_EXT_LOADED, "AddGui", function()
		Vermilion:AddInterfaceTab("ban_control", "ban_management")
	end)
	
	
end

function EXTENSION:InitClient()

	--[[
		Create a panel that allows the user to enter a time that a group of players should be banned for.
		
		playersToBan - the player(s) to ban (table of steamids or steamid)
	]]--
	function EXTENSION:CreateBanForPanel(playersToBan)
		if(not istable(playersToBan)) then playersToBan = { playersToBan } end
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
				for i,k in pairs(playersToBan) do
					net.Start("VBanPlayer")
					net.WriteTable(times)
					net.WriteString(text)
					net.WriteBoolean(isentity(k))
					if(isentity(k)) then
						net.WriteEntity(k)
					else
						net.WriteString(k)
					end
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
		
	end
	
	-- Populate the Active Players list
	self:AddHook("VActivePlayers", "ActivePlayersList", function(tab)
		if(not IsValid(EXTENSION.ActivePlayerList)) then
			return
		end
		EXTENSION.ActivePlayerList:Clear()
		for i,k in pairs(tab) do
			local ln = EXTENSION.ActivePlayerList:AddLine( k[1], k[2], k[3] )
			ln.V_SteamID = k[2]
			ln.OnRightClick = function()
				local conmenu = DermaMenu()
				conmenu:SetParent(ln)
				conmenu:AddOption("Ban", function()
					EXTENSION:CreateBanForPanel(ln.V_SteamID)
				end):SetIcon("icon16/delete.png")
				conmenu:AddOption("Kick", function()
					Crimson:CreateTextInput("For what reason are you kicking this player?", function(text)
						net.Start("VKickPlayer")
						net.WriteString(ln.V_SteamID)
						net.WriteString(text)
						net.SendToServer()
					end)
				end):SetIcon("icon16/disconnect.png")
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
	
	-- Populate the banned players list
	self:NetHook("VBannedPlayersList", function()
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
		Vermilion:AddInterfaceTab("ban_control", "Bans", "delete.png", "Ban/kick large groups of troublesome players and unban players manually", function(panel)
			
			
			local activePlayersList = Crimson.CreateList({ "Name", "Steam ID", "Rank" })
			activePlayersList:SetParent(panel)
			activePlayersList:SetPos(10, 30)
			activePlayersList:SetSize(panel:GetWide() - 10, 200)
			EXTENSION.ActivePlayerList = activePlayersList
			
			local activePlayersLabel = Crimson:CreateHeaderLabel(activePlayersList, "Active Players")
			activePlayersLabel:SetParent(panel)
			
			
			
			local banPlayerButton = Crimson.CreateButton("Ban Selected", function(self)
				if(table.Count(activePlayersList:GetSelected()) == 0) then
					Crimson:CreateErrorDialog("You must select at least one player to ban!")
					return
				end
				local ptb = {}
				for i,k in pairs(activePlayersList:GetSelected()) do
					table.insert(ptb, k:GetValue(2))
				end
				EXTENSION:CreateBanForPanel(ptb)
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
						net.WriteBoolean(false)
						net.WriteString(k:GetValue(2))
						net.WriteString(text)
						net.SendToServer()
					end
				end)
			end)
			kickPlayerButton:SetPos(125, 240)
			kickPlayerButton:SetSize(105, 30)
			kickPlayerButton:SetParent(panel)
			
			
			
			local bannedPlayersList = Crimson.CreateList({ "Name", "Steam ID", "Reason", "Expires", "Banned By" })
			bannedPlayersList:SetParent(panel)
			bannedPlayersList:SetPos(10, 300)
			bannedPlayersList:SetSize(panel:GetWide() - 10, 230)
			EXTENSION.BannedPlayerList = bannedPlayersList
			
			local bannedPlayersLabel = Crimson:CreateHeaderLabel(bannedPlayersList, "Banned Players")
			bannedPlayersLabel:SetParent(panel)
			
			
			
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
		end, 3)
	end)
end

function EXTENSION:InitShared()
	
	properties.Add( "vban",
		{
			MenuLabel = "Ban",
			Order = 0,
			MenuIcon = "icon16/delete.png",
			Filter = function(self, ent, ply)
				if(not IsValid(ent)) then return false end
				if(not LocalPlayer():IsAdmin()) then return false end
				if(not ent:IsPlayer()) then return false end
				return true
			end,
			Action = function(self, ent)
				if(LocalPlayer():IsAdmin()) then
					EXTENSION:CreateBanForPanel(ent)
				end
			end,
			Receive = function(self, length, ply)
				
			end
		}
	)
	
	properties.Add("vkick",
		{
			MenuLabel = "Kick",
			Order = 1,
			MenuIcon = "icon16/disconnect.png",
			Filter = function(self, ent, ply)
				if(not IsValid(ent)) then return false end
				if(not LocalPlayer():IsAdmin()) then return false end
				if(not ent:IsPlayer()) then return false end
				return true
			end,
			Action = function(self, ent)
				if(LocalPlayer():IsAdmin()) then
					Crimson:CreateTextInput("For what reason are you kicking this player?", function(text)
						net.Start("VKickPlayer")
						net.WriteBoolean(true)
						net.WriteEntity(ent)
						net.WriteString(text)
						net.SendToServer()
					end)
				end
			end,
			Receive = function(self, length, ply)
			
			end
		}
	)
	
end

Vermilion:RegisterExtension(EXTENSION)