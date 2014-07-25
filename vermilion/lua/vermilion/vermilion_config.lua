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
	--"physgun_freeze_own", -- can freeze own props with physgun
	--"physgun_freeze_others", -- can freeze other players props with physgun
	--"physgun_freeze_all", -- can freeze anything with physgun
	--"physgun_unfreeze", -- can unfreeze props when reloading physgun
	--"physgun_pickup_own", -- can pickup props with physgun
	--"physgun_pickup_others", -- can pickup other player's props with physgun
	--"physgun_pickup_all", -- can pickup anything with the physgun
	--"toolgun_own", -- can use toolgun on own props
	--"toolgun_others", -- can use toolgun on other player's props
	--"toolgun_all", -- can use the toolgun on anything
	"open_spawnmenu", -- can open the spawnmenu
	--"noclip", -- can noclip
	--"spray", -- can use sprays
	--"flashlight", -- can use the flashlight
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
	"can_fire_weapon",
}

Vermilion.DefaultRankPerms = {
	{ "owner", {
			"*"
		}
	},
	{ "admin", {
			"open_spawnmenu",
			"use_all",
			"spawn_all",
			"can_fire_weapon",
		}
	},
	{ "player", {
			"open_spawnmenu",
			"spawn_all",
			"can_fire_weapon"
		}
	},
	{ "guest", {
			"open_spawnmenu",
			"spawn_prop"
		}
	},
	{ "banned", {
			"leave_now_plz"
		}
	}
}

Vermilion.RankPerms = {}

Vermilion.UserStore = {}

Vermilion.DefaultRanks = {
	"owner",
	"admin",
	"player",
	"guest",
	"banned"
}

Vermilion.Ranks = {}


function Vermilion.GetFileName(pre, suf)
	if(CLIENT) then
		return "vermilion/" .. pre .. "_client_" .. suf
	elseif (SERVER) then
		return "vermilion/" .. pre .. "_server_" .. suf
	else
		return "vermilion/" .. pre .. "_unknown_" .. suf
	end
end

function Vermilion:LoadFile(name, resetFunc)
	if(not file.Exists(self.GetFileName("vermilion", name .. ".txt"), "DATA")) then
		self.Log("Creating " .. name .. " for the first time!")
		resetFunc()
	end
	return von.deserialize(file.Read(self.GetFileName("vermilion", name .. ".txt"), "DATA"))
end

function Vermilion:SaveFile(name, data)
	file.Write(self.GetFileName("vermilion", name .. ".txt"), von.serialize(data))
end

function Vermilion:LoadSettings()
	self.Settings = self:LoadFile("settings", function() Vermilion:ResetSettings() Vermilion:SaveSettings() end)
end

function Vermilion:SaveSettings() self:SaveFile("settings", self.Settings) end

function Vermilion:ResetSettings() self.Settings = self.DefaultSettings end

function Vermilion:GetSetting(str, default)
	if(self.Settings[str] == nil) then return default end
	return self.Settings[str]
end

function Vermilion:SetSetting(str, val)
	if(self.Settings[str] != nil) then
		--self.Log("Warning: overwriting setting " .. str .. " with old value " .. tostring(self.Settings[str]) .. " using new value " .. tostring(val))
	end
	self.Settings[str] = val
end

function Vermilion:LoadRanks() self.Ranks = self:LoadFile("ranks", function() Vermilion:ResetRanks() Vermilion:SaveRanks() end) end

function Vermilion:SaveRanks() self:SaveFile("ranks", self.Ranks) end

function Vermilion:ResetRanks() self.Ranks = self.DefaultRanks end

function Vermilion:LoadPermissions() self.RankPerms = self:LoadFile("permissions", function() Vermilion:ResetPermissions() Vermilion:SavePermissions() end) end

function Vermilion:SavePermissions() self:SaveFile("permissions", self.RankPerms) end

function Vermilion:ResetPermissions() self.RankPerms = self.DefaultRankPerms end

--[[
	Check if the player has a permission.
	
	@param vplayer (player/string): the player instance or player name to check against
	@param permission (string): the permission to check for
	
	@return hasPermission (boolean): boolean value representing whether or not the player has the permission
]]--
function Vermilion:HasPermission(vplayer, permission) 
	if(isstring(vplayer)) then vplayer = Crimson.LookupPlayerByName(vplayer) end
	if(vplayer == nil) then return true end --is most likely the duplicator or the console.
	local userData = self:GetPlayer(vplayer)
	if(userData == nil) then return false end
	local userRankPerms = self.RankPerms[self:LookupRank(userData['rank'])]
	for i,perm in pairs(userRankPerms[2]) do
		if(perm == permission or perm == "*") then return true end
	end
	return false
end

--[[
	Check if the player has a permission, sending an error notification to the client if they don't have access.
	
	@param vplayer (player/string): the player instance or player name to check against
	@param permission (string): the permission to check for
	
	@return hasPermission (boolean): boolean value representing whether or not the player has the permission
]]--
function Vermilion:HasPermissionError(vplayer, permission)
	if(isstring(vplayer)) then vplayer = Crimson.LookupPlayerByName(vplayer) end
	if(not self:HasPermission(vplayer, permission)) then
		self:SendNotify(vplayer, "Access denied!", 5, NOTIFY_ERROR)
		--self:Vox("access denied", vplayer)
		return false
	end
	return true
end

--[[
	Check if a rank has a permission.
	
	@param rank (string): the rank to check
	@param permission (string): the permission to check for
	
	@return hasPermission (boolean): boolean value representing whether or not the rank has the permission
]]--
function Vermilion:RankHasPermission(rank, permission)
	local userRankPerms = self.RankPerms[self:LookupRank(rank)]
	for i,rpermission in pairs(userRankPerms[2]) do
		if(rpermission == permission) then return true end --this was rpermission[1]
	end
	return false
end

--[[
	Add a permission to a rank
	
	@param rank (string): the rank to add the permission to
	@param permission (string): the permission to add
]]--
function Vermilion:AddRankPermission(rank, permission)
	if(self:RankHasPermission(rank, permission)) then
		self.Log("Warning: rank " .. rank .. " already has permission " .. permission)
		return
	end
	table.insert(self.RankPerms[self:LookupRank(rank)][2], permission)
end

function Vermilion:LoadUserStore()
	self.UserStore = self:LoadFile("users", function() Vermilion:SaveUserStore() end)
end

function Vermilion:SaveUserStore()
	self:SaveFile("users", self.UserStore)
end

--[[
	!! WARNING !!
	Do not call this function. It is an internal function that adds a player to the database and prints out join messages.
	
	@param vplayer (player/string): the player that is to be added to the database
]]--
function Vermilion:AddPlayer(vplayer)
	if(isstring(vplayer)) then vplayer = Crimson.LookupPlayerByName(vplayer) end
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

--[[
	Get the data that Vermilion has stored about the player.
	
	@param vplayer (player/string): the player to look for
	
	@return data (table/nil): the held data, if it exists
]]--
function Vermilion:GetPlayer(vplayer)
	if(isstring(vplayer)) then
		vplayer = Crimson.LookupPlayerByName(vplayer)
	end
	return self:GetPlayerBySteamID(vplayer:SteamID())
end

--[[
	Look up a player with a raw Steam ID string.
	
	@param steamid (string): the Steam ID of the player to look for
	
	@return data (table/nil): the held data, if it exists
]]--
function Vermilion:GetPlayerBySteamID(steamid)
	return self.UserStore[steamid]
end

--[[
	Check if Vermilion has stored data for the player.
	
	@param vplayer (player/string): the player to check for
	
	@return exists (boolean): a boolean value representing the result
]]--
function Vermilion:PlayerExists(vplayer)
	return self:GetPlayer(vplayer) != nil
end

--[[
	Check if Vermilion has stored data for the player represented by the provided Steam ID.
	
	@param steamid (string): the Steam ID of the player to look for
	
	@return exists (boolean): a boolean value representing the result
]]--
function Vermilion:SteamIDExists(steamid)
	return self:GetPlayerBySteamID(steamid) != nil
end

--[[
	Look up the numerical ID for a rank
	
	@param rank (string): the rank to look up
	
	@return rankid (number): the rank ID or 256 if the rank doesn't exist.
]]--
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

--[[
	Get the numerical ID of the rank that a player belongs to
	
	@param vplayer (player/string): the player to query
	
	@return rankid (number): the rank ID or the numerical ID of the "banned" rank if the player isn't assigned to a rank (this should never be the case)
]]--
function Vermilion:GetRank(vplayer)
	if(isstring(vplayer)) then
		vplayer = Crimson.LookupPlayerByName(vplayer)
	end
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

--[[
	Assign the player to a rank
	
	@param vplayer (player/string): the player to assign to the new rank
	@param rank (string): the rank to assign the player to
]]--
function Vermilion:SetRank(vplayer, rank)
	if(isstring(vplayer)) then
		vplayer = Crimson.LookupPlayerByName(vplayer)
	end
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

--[[
	Return a list of all players in the specified rank
	
	@param rank (string): the rank to query
	
	@return players (table containing player instances): the result of the query
]]--
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

--[[
	Get all data stored for a specific rank
	
	@param rank (string): the rank to query
	
	@return rankdata (table): the raw rank data stored in the engine
]]--
function Vermilion:GetHeldDataForRank(rank)
	local playerTable = {}
	for steamid,data in pairs(self.UserStore) do
		if(data['rank'] == rank) then
			playerTable[steamid] = data
		end
	end
	return playerTable
end

--[[
	Get a list of all players in the specified rank or in a rank with a lower numerical ID (more privileged rank)
	
	@param rank (string): the rank to query
	
	@return playerlist (table containing player instances): the result of the query
]]--
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

--[[
	Get a list of all players (regardless of rank) who have a specific permission
	
	@param permission (string): the permission to check for
	
	@return playerlist (table containing player instances): the result of the query
]]--
function Vermilion:GetAllPlayersWithPermission(permission)
	local playerTable = {}
	for i,plyr in pairs(player.GetAll()) do
		if(self:HasPermission(plyr, permission)) then
			table.insert(playerTable, plyr)
		end
	end
	return playerTable
end

--[[
	Utility function to check if there is at least one player in the "owner" rank.
	
	@return exists (boolean): boolean value representing the result
]]--
function Vermilion:OwnerExists()
	return table.Count(self:GetAllPlayersInRank("owner")) > 0
end

Vermilion:LoadSettings()
Vermilion:LoadPermissions()
Vermilion:LoadUserStore()
Vermilion:LoadRanks()

Vermilion:RegisterHook("ShutDown", "Vermilion-Config-Save", function()
	Vermilion:SaveSettings()
	Vermilion:SavePermissions()
	Vermilion:SaveUserStore()
	Vermilion:SaveRanks()
end)