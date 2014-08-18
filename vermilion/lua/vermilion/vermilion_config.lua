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
Vermilion.OldSettings = nil

util.AddNetworkString("VUpdateClientSettings")

-- The default settings object
Vermilion.DefaultSettings = {
	["enabled"] = true,
	["enable_limit_remover"] = true,
	["limit_remover_min_rank"] = 2,
	["default_rank"] = "player"
}

Vermilion.PermissionsList = {
	"open_spawnmenu", -- can open the spawnmenu

}

Vermilion.DefaultRankPerms = {
	{ "owner", {
			"*"
		}
	},
	{ "admin", {
			"open_spawnmenu"
		}
	},
	{ "player", {
			"open_spawnmenu"
		}
	},
	{ "guest", {
			"open_spawnmenu"
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
	if(name == "settings") then
		if(not file.Exists(self.GetFileName("vermilion", name .. "-2.txt"), "DATA") and file.Exists(self.GetFileName("vermilion", name .. ".txt"), "DATA")) then
			local tab = von.deserialize(util.Decompress(file.Read(self.GetFileName("vermilion", name .. ".txt"), "DATA")))
			if(tab != nil) then
				file.Write(self.GetFileName("vermilion", name .. "-2.txt"), util.Compress(util.TableToJSON(tab)))
			end
		end
		name = name .. "-2"
	end
	if(not file.Exists(self.GetFileName("vermilion", name .. ".txt"), "DATA")) then
		self.Log(string.format(Vermilion.Lang.CreatingFile, name))
		resetFunc()
	end
	return util.JSONToTable(util.Decompress(file.Read(self.GetFileName("vermilion", name .. ".txt"), "DATA")))
end

function Vermilion:SaveFile(name, data)
	if(name == "settings") then
		name = name .. "-2"
	end
	file.Write(self.GetFileName("vermilion", name .. ".txt"), util.Compress(util.TableToJSON(data)))
end

function Vermilion:LoadSettings()
	self.Settings = self:LoadFile("settings", function() Vermilion:ResetSettings() Vermilion:SaveSettings() end)
	self.OldSettings = util.CRC(util.TableToJSON(self.Settings))
end

function Vermilion:SaveSettings() self:SaveFile("settings", self.Settings) end

function Vermilion:ResetSettings()
	self.Settings = self.DefaultSettings
	self.OldSettings = util.CRC(util.TableToJSON(self.Settings))
end

function Vermilion:GetSetting(str, default)
	if(self.Settings[str] == nil) then return default end
	return self.Settings[str]
end

-- note: The settings table is networked to the client. Do NOT place sensitive info anywhere but the "protected" table.
function Vermilion:SetSetting(str, val)
	if(self.Settings[str] != nil) then
		--self.Log("Warning: overwriting setting " .. str .. " with old value " .. tostring(self.Settings[str]) .. " using new value " .. tostring(val))
	end
	self.Settings[str] = val
	self.OldSettings = util.CRC(util.TableToJSON(self.Settings))
end

timer.Create("Vermilion_Config_Distributor", 30, 0, function() -- redistribute the configuration every 30 seconds if it has been changed.
	local crc = util.CRC(util.TableToJSON(Vermilion.Settings))
	if(crc == Vermilion.OldSettings) then return end
	Vermilion.OldSettings = crc
	
	local tab = {}
	for i,k in pairs(Vermilion.Settings) do
		if(i != "protected") then
			tab[i] = k
		end
	end
	net.Start("VUpdateClientSettings")
	net.WriteTable(Crimson.NetSanitiseTable(tab))
	net.Broadcast()
end)

Vermilion:RegisterHook("PlayerInitialSpawn", "UpdateClientConfig", function(vplayer)
	local tab = {}
	for i,k in pairs(Vermilion.Settings) do
		if(i != "protected") then
			tab[i] = k
		end
	end
	net.Start("VUpdateClientSettings")
	net.WriteTable(Crimson.NetSanitiseTable(tab))
	net.Send(vplayer)
end)

function Vermilion:LoadRanks()
	self.Ranks = self:GetSetting("ranks", {})
	if(table.Count(self.Ranks) == 0) then 
		self:ResetRanks()
	end
end

function Vermilion:SaveRanks() self:SetSetting("ranks", self.Ranks) end

function Vermilion:ResetRanks() self.Ranks = self.DefaultRanks end

function Vermilion:LoadPermissions() 
	self.RankPerms = self:GetSetting("permissions", {})
	if(table.Count(self.RankPerms) == 0) then
		self:ResetPermissions()
	end
end

function Vermilion:SavePermissions() self:SetSetting("permissions", self.RankPerms) end

function Vermilion:ResetPermissions() self.RankPerms = self.DefaultRankPerms end

--[[
	Check if the player has a permission.
	
	@param vplayer (player/string): the player instance or player name to check against
	@param permission (string): the permission to check for
	
	@return hasPermission (boolean): boolean value representing whether or not the player has the permission
]]--
function Vermilion:HasPermission(vplayer, permission) 
	if(not IsValid(vplayer)) then return true end -- is probably the console
	if(isstring(vplayer)) then vplayer = Crimson.LookupPlayerByName(vplayer) end
	if(vplayer == nil) then return true end --is most likely the duplicator or the console.
	local userData = self:GetPlayer(vplayer)
	if(userData == nil) then return false end
	local userRankPerms = self.RankPerms[self:LookupRank(userData['rank'])]
	if(userRankPerms == nil) then -- uhoh, we don't have a rank set for this user!
		return
	end
	for i,perm in pairs(userRankPerms[2]) do
		if(perm == permission or perm == "*") then return true end
	end
	return false
end

--[[
	Check if the player has a permission, sending an error notification to the client if they don't have access.
	
	@param vplayer (player/string): the player instance or player name to check against
	@param permission (string): the permission to check for
	@param log (function): output the error to this command.
	
	@return hasPermission (boolean): boolean value representing whether or not the player has the permission
]]--
function Vermilion:HasPermissionError(vplayer, permission, log)
	if(isstring(vplayer)) then vplayer = Crimson.LookupPlayerByName(vplayer) end
	if(not self:HasPermission(vplayer, permission)) then
		if(log == nil) then self:SendNotify(vplayer, Vermilion.Lang.AccessDenied, 5, VERMILION_NOTIFY_ERROR) else
			log(Vermilion.Lang.AccessDenied, VERMILION_NOTIFY_ERROR)
		end
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
		self.Log(string.format(Vermilion.Lang.DuplicatePermission, rank, permission))
		return
	end
	table.insert(self.RankPerms[self:LookupRank(rank)][2], permission)
end

function Vermilion:LoadUserStore()
	self.UserStore = self:GetSetting("user_store", {})
	if(table.Count(self.UserStore) == 0) then 
		self.UserStore = {}
		self:SaveUserStore()
	end
end

function Vermilion:SaveUserStore()
	self:SetSetting("user_store", self.UserStore)
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
	if(not self:OwnerExists() and (game.SinglePlayer() or vplayer:IsListenServerHost())) then
		self.Log(string.format(Vermilion.Lang.SettingOwner, vplayer:GetName()))
		self.UserStore[vplayer:SteamID()]['rank'] = "owner" -- set the first player to join as the owner
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
		local tvplayer = Crimson.LookupPlayerByName(vplayer)
		if(tvplayer == nil) then
			for i,k in pairs(self.UserStore) do
				if(k.name == vplayer) then
					return k
				end
			end
			return
		else
			vplayer = tvplayer
		end
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

function Vermilion:PlayerWithNameExists(name)
	for i,k in pairs(self.UserStore) do
		if(k.name == name) then return true end
	end
	return false
end

function Vermilion:GetPlayerSteamID(name)
	if(isentity(name)) then
		if(name:IsPlayer()) then return name:SteamID() end
		return
	end
	for i,k in pairs(self.UserStore) do
		if(k.name == name) then return i end
	end
end

function Vermilion:CountAllPlayers()
	return table.Count(self.UserStore)
end

--[[
	Look up the numerical ID for a rank
	
	@param rank (string): the rank to look up
	
	@return rankid (number): the rank ID or VERMILION_BAD_RANK if the rank doesn't exist.
]]--
function Vermilion:LookupRank(rank)
	if(rank == nil) then
		return VERMILION_BAD_RANK
	end
	for k,v in pairs(self.Ranks) do
		if(v == rank) then
			return k
		end
	end
	return VERMILION_BAD_RANK
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
		self.Log(Vermilion.Lang.NoSuchPlayer)
		return
	end
	if(self:LookupRank(rank) == VERMILION_BAD_RANK) then
		self.Log("No such rank!")
		return
	end
	self.UserStore[vplayer:SteamID()]['rank'] = rank
	self:SaveUserStore()
	vplayer:SetNWString("Vermilion_Rank", rank)
	vplayer:SetNWBool("Vermilion_Identify_Admin", self:HasPermission(vplayer, "identify_as_admin"))
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

function Vermilion:CountPlayersInRank(rank)
	return table.Count(self:GetAllPlayersInRank(rank))
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

concommand.Add("vermilion_dump_settings", function(sender)
	PrintTable(Vermilion.Settings)
	--Crimson.PrintTable(Vermilion.Settings, nil, nil, function(text) sender:PrintMessage(HUD_PRINTCONSOLE, text) end)
end)

Vermilion:LoadSettings()
Vermilion:LoadPermissions()
Vermilion:LoadUserStore()
Vermilion:LoadRanks()

timer.Create("Vermilion_Autosave", 60, 0, function()
	hook.Call("Vermilion-SaveConfigs")
	Vermilion:SavePermissions()
	Vermilion:SaveUserStore()
	Vermilion:SaveRanks()
	Vermilion:SaveSettings()
end)

Vermilion:RegisterHook("ShutDown", "Vermilion-Config-Save", function()
	Vermilion.Log("Saving data...")
	hook.Call("Vermilion-SaveConfigs")
	hook.Call("Vermilion-Pre-Shutdown")
	Vermilion:SavePermissions()
	Vermilion:SaveUserStore()
	Vermilion:SaveRanks()
	Vermilion:SaveSettings()
end)