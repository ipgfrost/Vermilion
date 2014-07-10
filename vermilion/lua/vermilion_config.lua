-- The MIT License
--
-- Copyright 2014 Ned Hyett.
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.

-- The settings object. Don't modify this directly. Use the provided functions!
Vermilion.settings = {}

-- The default settings object
Vermilion.defaultSettings = {
	["enabled"] = true,
	["enable_limit_remover"] = true,
	["limit_remover_min_rank"] = 2
}

Vermilion.permissionsList = {
	"chat", -- can chat
	"no_fall_damage", -- takes no fall damage
	"reduced_fall_damage", -- takes reduced fall damage
	"grav_gun_pickup_own", -- can pickup their own props with grav gun
	"grav_gun_pickup_others", -- can pickup other players props with grav gun
	"grav_gun_pickup_all", -- can pickup anything with the gravity gun
	"grav_gun_punt_own", -- can punt their own props
	"grav_gun_punt_others", -- can punt other players props
	"grav_gun_punt_all", -- can punt anything with the gravity gun
	"prop_colide_others", -- this player's props can collide with other player's props
	"physgun_freeze_own", -- can freeze own props with physgun
	"physgun_freeze_others", -- can freeze other players props with physgun
	"physgun_freeze_all", -- can freeze anything with physgun
	"physgun_unfreeze", -- can unfreeze props when reloading physgun
	"physgun_pickup_own", -- can pickup props with physgun
	"physgun_pickup_others", -- can pickup other player's props with physgun
	"physgun_pickup_all", -- can pickup anything with the physgun
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
	"ban",
	"unban",
	"kick",
	"cmd_set_rank"
}

Vermilion.defaultRankPerms = {
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

Vermilion.rankPerms = {}

Vermilion.UserStore = {}
Vermilion.ranks = {
	"owner",
	"admin",
	"player",
	"guest",
	"banned"
}

function Vermilion.getFileName(pre, suf)
	if(CLIENT) then
		return pre .. "_client_" .. suf
	elseif (SERVER) then
		return pre .. "_server_" .. suf
	else
		return pre .. "_unknown_" .. suf
	end
end

function Vermilion:loadSettings()
	if(not file.Exists(self.getFileName("vermilion", "settings.txt"), "DATA")) then
		self.log("Creating settings for the first time!")
		self:resetSettings()
		self:saveSettings()
	end
	local data = file.Read( self.getFileName("vermilion", "settings.txt"), "DATA")
	local tab = von.deserialize(data)
	self.settings = tab
end

function Vermilion:saveSettings()
	file.Write(self.getFileName("vermilion", "settings.txt"), von.serialize(self.settings))
end

function Vermilion:resetSettings()
	self.settings = self.defaultSettings
end

function Vermilion:getSetting(str, default)
	if(self.settings[str] == nil) then
		return default
	end
	return self.settings[str]
end

function Vermilion:setSetting(str, val)
	if(self.settings[str] != nil) then
		self.log("Warning: overwriting setting " .. str .. " with old value " .. tostring(self.settings[str]) .. " using new value " .. tostring(val))
	end
	self.settings[str] = val
end

function Vermilion:loadPerms()
	if(not file.Exists(self.getFileName("vermilion", "permissions.txt"), "DATA")) then
		self.log("Creating permissions list for the first time!")
		self:resetPerms()
		self:savePerms()
	end
	local data = file.Read( self.getFileName("vermilion", "permissions.txt"), "DATA")
	local tab = von.deserialize(data)
	self.rankPerms = tab
end

function Vermilion:savePerms()
	file.Write(self.getFileName("vermilion", "permissions.txt"), von.serialize(self.rankPerms))
end

function Vermilion:resetPerms()
	self.rankPerms = self.defaultRankPerms
end

function Vermilion:hasPermission(vplayer, permission)
	local userData = self:getPlayer(vplayer)
	if(userData == nil) then
		return false
	end
	local userRankPerms = self.rankPerms[self:lookupRank(userData['rank'])]
	for i,perm in pairs(userRankPerms[2]) do
		if(perm[1] == permission or perm[1] == "*") then
			return true
		end
	end
	return false
end

function Vermilion:hasPermissionVerbose(vplayer, permission)
	if(not self:hasPermission(vplayer, permission)) then
		self.log("Access denied!")
		return
	end
	return true
end

function Vermilion:hasPermissionVerboseChat(vplayer, permission)
	if(not self:hasPermission(vplayer, permission)) then
		self.sendNotify(vplayer, "Access denied!", 5, NOTIFY_ERROR)
		return
	end
	return true
end

function Vermilion:addRankPermission(rank, permission, meta)
	local userRankPerms = self.rankPerms[self:lookupRank(rank)]
	for i,perm in pairs(userRankPerms[2]) do
		if(perm[1] == permission) then
			self.log("Warning: rank " .. rank .. " already has permission " .. permission)
			return
		end
	end
	table.insert(self.rankPerms[self:lookupRank(rank)][2], { permission, meta })
end

function Vermilion:getPermissionMetadata(vplayer, permission)
	local tabl = {}
	local rnk = self:lookupRank(vplayer)
	local perms = self.rankPerms[rnk][2]
	
	for k,v in pairs(perms) do
		if(v[1] == permission) then
			tabl = v[2]
			break
		end
	end
	return tabl
end

function Vermilion:loadUserStore()
	if(not file.Exists(self.getFileName("vermilion", "users.txt"), "DATA")) then
		self.log("Creating data store for first time!")
		Vermilion:saveUserStore()
	end
	local data = file.Read( self.getFileName("vermilion", "users.txt"), "DATA")
	local tab = von.deserialize(data)
	self.UserStore = tab
end

function Vermilion:saveUserStore()
	file.Write(self.getFileName("vermilion", "users.txt"), von.serialize(self.UserStore))
end

function Vermilion:addPlayer(vplayer)
	self.UserStore[vplayer:SteamID()] = {
		["rank"] = "player",
		["name"] = vplayer:GetName()
	}
	if(not Vermilion:ownerExists()) then
		Vermilion.log("Warning: no owner set. Setting " .. vplayer:GetName() .. " as the owner!")
		Vermilion:setRank(vplayer, "owner") -- set the first player to join as the owner
	end
	self:saveUserStore()
end

function Vermilion:getPlayer(vplayer)
	return self:getPlayerBySteamID(vplayer:SteamID())
end

function Vermilion:getPlayerBySteamID(steamid)
	return self.UserStore[steamid]
end

function Vermilion:playerExists(vplayer)
	return self:getPlayer(vplayer) != nil
end

function Vermilion:steamIDExists(steamid)
	return self:getPlayerBySteamID(steamid) != nil
end

function Vermilion:lookupRank(rank)
	if(rank == nil) then
		return 256
	end
	for k,v in pairs(self.ranks) do
		if(v == rank) then
			return k
		end
	end
	return 256
end

function Vermilion:getRank(vplayer)
	if(self:getPlayer(vplayer) == nil) then
		return self:lookupRank("banned")
	end
	for k,v in pairs(self.ranks) do
		if(v == self:getPlayer(vplayer)['rank']) then
			return k
		end
	end
	return self:lookupRank("banned")
end

function Vermilion:setRank(vplayer, rank)
	if(vplayer == nil) then
		self.log("Nil player!")
	end
	if(self:getPlayer(vplayer) == nil) then
		self.log("No such player!")
		return
	end
	if(self:lookupRank(rank) == 256) then
		self.log("No such rank!")
		return
	end
	self.UserStore[vplayer:SteamID()]['rank'] = rank
	self:saveUserStore()
end

function Vermilion:setRankByNumber(vplayer, rank)
	if(vplayer == nil) then
		self.log("Nil player!")
		return
	end
	if(self:getPlayer(vplayer) == nil) then
		self.log("No such player!")
		return
	end
	if(self.ranks[rank] == nil) then
		self.log("No such rank!")
		return
	end
	self.UserStore[vplayer:SteamID()]['rank'] = rank
	self:saveUserStore()
end

function Vermilion:getAllPlayersInRank(rank)
	local playerTable = {}
	for i,plyr in pairs(player.GetAll()) do
		local playerDat = self:getPlayer(plyr)
		if(playerDat != nil) then
			if(playerDat['rank'] == rank) then
				table.insert(playerTable, plyr)
			end
		end
	end
	return playerTable
end

function Vermilion:getAllPlayersInRankAndAbove(rank)
	local playerTable = {}
	local rankID = self:lookupRank(rank)
	for i,plyr in pairs(player.GetAll()) do
		local playerDat = self:getPlayer(plyr)
		if(playerDat != nil) then
			local playerRank = self:lookupRank(playerDat['rank'])
			if(playerRank <= rankID) then
				table.insert(playerTable, plyr)
			end
		end
	end
	return playerTable
end

function Vermilion:getAllPlayersWithPermission(permission)
	local playerTable = {}
	for i,plyr in pairs(player.GetAll()) do
		if(self:hasPermission(plyr, permission)) then
			table.insert(playerTable, plyr)
		end
	end
	return playerTable
end

function Vermilion:isOwner(vplayer)
	return self:getRank(vplayer) == self:lookupRank("owner")
end

function Vermilion:isAdmin(vplayer)
	return self:getRank(vplayer) <= self:lookupRank("admin")
end

function Vermilion:isBanned(vplayer)
	return self:getRank(vplayer) == self:lookupRank("banned")
end

function Vermilion:ownerExists()
	for steamid,playerDat in pairs(self.UserStore) do
		print(playerDat['rank'])
		if(playerDat['rank'] == "owner") then
			return true
		end
	end
	return false
end

Vermilion:loadSettings()
Vermilion:loadPerms()
Vermilion:loadUserStore()

hook.Add("PlayerInitialSpawn", "Vermilion-Config-Add", function(vplayer)
	if(Vermilion:getPlayer(vplayer) == nil) then
		Vermilion:addPlayer(vplayer)
	end
end)

hook.Add("ShutDown", "Vermilion-Config-Save", function()
	Vermilion:saveSettings()
	Vermilion:savePerms()
	Vermilion:saveUserStore()
end)