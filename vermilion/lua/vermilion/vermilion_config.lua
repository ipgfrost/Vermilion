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

-- The settings object. Don't modify this directly. Use the provided functions!
Vermilion.Settings = {}

-- The default settings object
Vermilion.DefaultSettings = {
	["enabled"] = true,
	["enable_limit_remover"] = true,
	["limit_remover_min_rank"] = 2,
	["default_rank"] = "player"
}

Vermilion.PermissionsList = {
	--"chat", -- can chat
	--"no_fall_damage", -- takes no fall damage
	--"reduced_fall_damage", -- takes reduced fall damage
	--"grav_gun_pickup_own", -- can pickup their own props with grav gun
	--"grav_gun_pickup_others", -- can pickup other players props with grav gun
	--"grav_gun_pickup_all", -- can pickup anything with the gravity gun
	--"grav_gun_punt_own", -- can punt their own props
	--"grav_gun_punt_others", -- can punt other players props
	--"grav_gun_punt_all", -- can punt anything with the gravity gun
	"prop_colide_others", -- this player's props can collide with other player's props
	--"physgun_freeze_own", -- can freeze own props with physgun
	--"physgun_freeze_others", -- can freeze other players props with physgun
	--"physgun_freeze_all", -- can freeze anything with physgun
	--"physgun_unfreeze", -- can unfreeze props when reloading physgun
	--"physgun_pickup_own", -- can pickup props with physgun
	--"physgun_pickup_others", -- can pickup other player's props with physgun
	--"physgun_pickup_all", -- can pickup anything with the physgun
	"toolgun_own", -- can use toolgun on own props
	"toolgun_others", -- can use toolgun on other player's props
	"toolgun_all", -- can use the toolgun on anything
	"open_spawnmenu", -- can open the spawnmenu
	"noclip", -- can noclip
	"spray", -- can use sprays
	"flashlight", -- can use the flashlight
	"use_own", -- can use their own props/map props
	"use_others", -- can use other players props
	"use_all", -- can use anything
	"spawn_prop",
	"spawn_npc",
	"spawn_entity",
	"spawn_weapon",
	"spawn_dupe",
	"spawn_vehicle",
	"spawn_effect",
	"spawn_ragdoll",
	"spawn_all",
	"give_swep",
	"can_fire_weapon",
	--"ban",
	--"unban",
	--"kick"
}

Vermilion.DefaultRankPerms = {
	{ "owner", {
			{"*"}
		}
	},
	{ "admin", {
			--{"chat"},
			--{"no_fall_damage"},
			--{"grav_gun_pickup_all"},
			--{"grav_gun_punt_all"},
			{"prop_collide_others"},
			--{"physgun_freeze_all"},
			--{"physgun_unfreeze"},
			--{"physgun_pickup_all"},
			{"toolgun_all"},
			{"open_spawnmenu"},
			{"noclip"},
			{"spray"},
			{"flashlight"},
			{"use_all"},
			{"spawn_all", {"#infinity"}},
			{"give_swep"},
			{"can_fire_weapon"},
			{"ban"},
			{"unban"},
			{"kick"},
			--{"cmd_set_rank"}
		}
	},
	{ "player", {
			--{"chat"},
			--{"reduced_fall_damage"},
			--{"grav_gun_pickup_own"},
			--{"grav_gun_punt_own"},
			{"physgun_freeze_own"},
			{"physgun_unfreeze"},
			{"physgun_pickup_own"},
			{"toolgun_own"},
			{"open_spawnmenu"},
			{"noclip"},
			{"spray"},
			{"flashlight"},
			{"spawn_all", {"#sbox_max"}},
			{"give_swep"},
			{"can_fire_weapon"}
		}
	},
	{ "guest", {
			--{"chat"},
			{"open_spawnmenu"},
			{"spawn_prop", {"5"}}
		}
	},
	{ "banned", {
			{"leave_now_plz"}
		}
	}
}

Vermilion.RankPerms = {}

Vermilion.UserStore = {}
Vermilion.Ranks = {
	"owner",
	"admin",
	"player",
	"guest",
	"banned"
}

-- Structure: steamid, reason, expiry time, banner
Vermilion.Bans = {}

function Vermilion.GetFileName(pre, suf)
	if(CLIENT) then
		return pre .. "_client_" .. suf
	elseif (SERVER) then
		return pre .. "_server_" .. suf
	else
		return pre .. "_unknown_" .. suf
	end
end

function Vermilion:LoadSettings()
	if(not file.Exists(self.GetFileName("vermilion", "settings.txt"), "DATA")) then
		self.Log("Creating settings for the first time!")
		self:ResetSettings()
		self:SaveSettings()
	end
	local data = file.Read( self.GetFileName("vermilion", "settings.txt"), "DATA")
	local tab = von.deserialize(data)
	self.Settings = tab
end

function Vermilion:SaveSettings()
	file.Write(self.GetFileName("vermilion", "settings.txt"), von.serialize(self.Settings))
end

function Vermilion:ResetSettings()
	self.Settings = self.DefaultSettings
end

function Vermilion:GetSetting(str, default)
	if(self.Settings[str] == nil) then
		return default
	end
	return self.Settings[str]
end

function Vermilion:SetSetting(str, val)
	if(self.Settings[str] != nil) then
		self.Log("Warning: overwriting setting " .. str .. " with old value " .. tostring(self.Settings[str]) .. " using new value " .. tostring(val))
	end
	self.Settings[str] = val
end

function Vermilion:LoadPerms()
	if(not file.Exists(self.GetFileName("vermilion", "permissions.txt"), "DATA")) then
		self.Log("Creating permissions list for the first time!")
		self:ResetPerms()
		self:SavePerms()
	end
	local data = file.Read( self.GetFileName("vermilion", "permissions.txt"), "DATA")
	local tab = von.deserialize(data)
	self.RankPerms = tab
end

function Vermilion:SavePerms()
	file.Write(self.GetFileName("vermilion", "permissions.txt"), von.serialize(self.RankPerms))
end

function Vermilion:ResetPerms()
	self.RankPerms = self.DefaultRankPerms
end

function Vermilion:HasPermission(vplayer, permission)
	local userData = self:GetPlayer(vplayer)
	if(userData == nil) then
		return false
	end
	local userRankPerms = self.RankPerms[self:LookupRank(userData['rank'])]
	for i,perm in pairs(userRankPerms[2]) do
		if(perm[1] == permission or perm[1] == "*") then
			return true
		end
	end
	return false
end

function Vermilion:HasPermissionVerbose(vplayer, permission)
	if(not self:HasPermission(vplayer, permission)) then
		self.Log("Access denied!")
		return
	end
	return true
end

function Vermilion:HasPermissionVerboseChat(vplayer, permission)
	if(not self:HasPermission(vplayer, permission)) then
		self.SendNotify(vplayer, "Access denied!", 5, NOTIFY_ERROR)
		return
	end
	return true
end

function Vermilion:AddRankPermission(rank, permission, meta)
	local userRankPerms = self.RankPerms[self:LookupRank(rank)]
	for i,perm in pairs(userRankPerms[2]) do
		if(perm[1] == permission) then
			self.Log("Warning: rank " .. rank .. " already has permission " .. permission)
			return
		end
	end
	table.insert(self.RankPerms[self:LookupRank(rank)][2], { permission, meta })
end

function Vermilion:GetPermissionMetadata(vplayer, permission)
	local tabl = {}
	local rnk = self:LookupRank(vplayer)
	local perms = self.RankPerms[rnk][2]
	
	for k,v in pairs(perms) do
		if(v[1] == permission) then
			tabl = v[2]
			break
		end
	end
	return tabl
end

function Vermilion:LoadUserStore()
	if(not file.Exists(self.GetFileName("vermilion", "users.txt"), "DATA")) then
		self.Log("Creating data store for first time!")
		self:SaveUserStore()
	end
	local data = file.Read( self.GetFileName("vermilion", "users.txt"), "DATA")
	local tab = von.deserialize(data)
	self.UserStore = tab
end

function Vermilion:SaveUserStore()
	file.Write(self.GetFileName("vermilion", "users.txt"), von.serialize(self.UserStore))
end

function Vermilion:AddPlayer(vplayer)
	self.UserStore[vplayer:SteamID()] = {
		["rank"] = "player",
		["name"] = vplayer:GetName()
	}
	if(not Vermilion:OwnerExists()) then
		Vermilion.Log("Warning: no owner set. Setting " .. vplayer:GetName() .. " as the owner!")
		Vermilion:SetRank(vplayer, "owner") -- set the first player to join as the owner
	end
	self:SaveUserStore()
end

function Vermilion:GetPlayer(vplayer)
	return self:GetPlayerBySteamID(vplayer:SteamID())
end

function Vermilion:GetPlayerBySteamID(steamid)
	return self.UserStore[steamid]
end

function Vermilion:PlayerExists(vplayer)
	return self:GetPlayer(vplayer) != nil
end

function Vermilion:SteamIDExists(steamid)
	return self:GetPlayerBySteamID(steamid) != nil
end

function Vermilion:GetPlayerByName(name)
	for i,k in pairs(self.UserStore) do
		if(k['name'] == name) then
			return k
		end
	end
end

function Vermilion:LookupRank(rank)
	if(rank == nil) then
		return 256
	end
	for k,v in pairs(self.Ranks) do
		if(v == rank) then
			return k
		end
	end
	return 256
end

function Vermilion:GetRank(vplayer)
	if(self:GetPlayer(vplayer) == nil) then
		return self:LookupRank("banned")
	end
	for k,v in pairs(self.Ranks) do
		if(v == self:GetPlayer(vplayer)['rank']) then
			return k
		end
	end
	return self:LookupRank("banned")
end

function Vermilion:SetRank(vplayer, rank)
	if(vplayer == nil) then
		self.Log("Nil player!")
	end
	if(self:GetPlayer(vplayer) == nil) then
		self.Log("No such player!")
		return
	end
	if(self:LookupRank(rank) == 256) then
		self.Log("No such rank!")
		return
	end
	self.UserStore[vplayer:SteamID()]['rank'] = rank
	self:SaveUserStore()
end

function Vermilion:SetRankByNumber(vplayer, rank)
	if(vplayer == nil) then
		self.Log("Nil player!")
		return
	end
	if(self:GetPlayer(vplayer) == nil) then
		self.Log("No such player!")
		return
	end
	if(self.Ranks[rank] == nil) then
		self.Log("No such rank!")
		return
	end
	self.UserStore[vplayer:SteamID()]['rank'] = rank
	self:SaveUserStore()
end

function Vermilion:GetAllPlayersInRank(rank)
	local playerTable = {}
	for i,plyr in pairs(player.GetAll()) do
		local playerDat = self:GetPlayer(plyr)
		if(playerDat != nil) then
			if(playerDat['rank'] == rank) then
				table.insert(playerTable, plyr)
			end
		end
	end
	return playerTable
end

function Vermilion:GetHeldDataForRank(rank)
	local playerTable = {}
	for steamid,data in pairs(self.UserStore) do
		if(data['rank'] == rank) then
			playerTable[steamid] = data
		end
	end
	return playerTable
end

function Vermilion:GetAllPlayersInRankAndAbove(rank)
	local playerTable = {}
	local rankID = self:LookupRank(rank)
	for i,plyr in pairs(player.GetAll()) do
		local playerDat = self:GetPlayer(plyr)
		if(playerDat != nil) then
			local playerRank = self:LookupRank(playerDat['rank'])
			if(playerRank <= rankID) then
				table.insert(playerTable, plyr)
			end
		end
	end
	return playerTable
end

function Vermilion:GetAllPlayersWithPermission(permission)
	local playerTable = {}
	for i,plyr in pairs(player.GetAll()) do
		if(self:HasPermission(plyr, permission)) then
			table.insert(playerTable, plyr)
		end
	end
	return playerTable
end

function Vermilion:IsOwner(vplayer)
	return self:GetRank(vplayer) == self:LookupRank("owner")
end

function Vermilion:IsAdmin(vplayer)
	return self:GetRank(vplayer) <= self:LookupRank("admin")
end

function Vermilion:IsBanned(vplayer)
	return self:GetRank(vplayer) == self:LookupRank("banned")
end

function Vermilion:OwnerExists()
	for steamid,playerDat in pairs(self.UserStore) do
		print(playerDat['rank'])
		if(playerDat['rank'] == "owner") then
			return true
		end
	end
	return false
end

function Vermilion:LoadBans()
	if(not file.Exists(self.GetFileName("vermilion", "bans.txt"), "DATA")) then
		self.Log("Creating bans for the first time!")
		self:ResetBans()
		self:SaveBans()
	end
	local data = file.Read( self.GetFileName("vermilion", "bans.txt"), "DATA")
	local tab = von.deserialize(data)
	self.Bans = tab
end

function Vermilion:SaveBans()
	file.Write(self.GetFileName("vermilion", "bans.txt"), von.serialize(self.Bans))
end

function Vermilion:ResetBans()
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
	
	self:BroadcastNotify(str .. timestr .. " with reason: " .. reason, 10, NOTIFY_GENERIC)
	
	-- steamid, reason, expiry time, banner
	table.insert(self.Bans, { vplayer:SteamID(), reason, os.time() + time, vplayerBanner:GetName() } )
	self:SetRank(vplayer, "banned")	
	vplayer:Kick("Banned from server for " .. timestr .. ": " .. reason)
	
	
end

function Vermilion:UnbanPlayer(steamid, unbanner)
	local idxToRemove = {}
	for i,k in pairs(Vermilion.Bans) do
		if(k[1] == steamid) then
			local playerName = Vermilion:GetPlayerBySteamID(k[1])['name']
			Vermilion:BroadcastNotify(playerName .. " has been unbanned by " .. unbanner:GetName(), 10, NOTIFY_ERROR)
			table.insert(idxToRemove, i)
			Vermilion:GetPlayerBySteamID(k[1])['rank'] = Vermilion:GetSetting("default_rank", "player")
			break
		end
	end
	for i,k in pairs(idxToRemove) do
		table.remove(Vermilion.Bans, k)
	end
end

Vermilion:LoadSettings()
Vermilion:LoadPerms()
Vermilion:LoadUserStore()
Vermilion:LoadBans()

Vermilion:RegisterHook("ShutDown", "Vermilion-Config-Save", function()
	Vermilion:SaveSettings()
	Vermilion:SavePerms()
	Vermilion:SaveUserStore()
	Vermilion:SaveBans()
end)