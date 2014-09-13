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

Vermilion.AllPermissions = {}
Vermilion.DefaultPermissionSettings = {
	{ "owner", { "*" } },
	{ "admin", {} },
	{ "player", {} },
	{ "guest", {} }
}

Vermilion.Settings = {}
Vermilion.Settings.GlobalData = {}
Vermilion.Settings.ModuleData = {}
Vermilion.Settings.Ranks = { 
	{ Name = "owner", Permissions = { "*" }, Protected = true },
	{ Name = "admin", Permissions = {}, Protected = false },
	{ Name = "player", Permissions = {}, Protected = false },
	{ Name = "guest", Permissions = {}, Protected = false }
}
Vermilion.Settings.Users = {}

local userFuncs = {}
function userFuncs:GetRank()
	return Vermilion:GetRankData(self.Rank)
end

function userFuncs:SetRank(rank)
	if(Vermilion:HasRank(rank)) then
		self.Rank = rank
		local vplayer = Crimson.LookupPlayerBySteamID(self.SteamID)
		if(not IsValid(vplayer)) then return end
		Vermilion:SendNotify(vplayer, "Your rank is now " .. rank .. "!")
		vplayer:SetNWString("Vermilion_Rank", self:GetRank().Name)
		vplayer:SetNWString("Vermilion_Identify_Admin", self:GetRank():HasPermission("identify_as_admin"))
	end
end

function userFuncs:HasPermission(permission)
	if(table.HasValue(self.Permissions, permission) or table.HasValue(self.Permissions, "*")) then return true end
	return self:GetRank():HasPermission(permission)
end


local rankFuncs = {}
function rankFuncs:HasPermission(permission)
	return table.HasValue(self.Permissions, permission) or table.HasValue(self.Permissions, "*")
end

function Vermilion:GetSetting(name, default)
	if(self.Settings.GlobalData[name] == nil) then return default end
	return self.Settings.GlobalData[name]
end

function Vermilion:GetModuleData(mod, name, default)
	if(self.Settings.ModuleData[mod] == nil) then return default end
	if(self.Settings.ModuleData[mod][name] == nil) then return default end
	return self.Settings.ModuleData[mod][name]
end

function Vermilion:SetSetting(name, value)
	self.Settings.GlobalData[name] = value
end

function Vermilion.GetFileName(name)
	if(CLIENT) then
		return "vermilion/vermilion_client_" .. name .. ".txt"
	elseif(SERVER) then
		return "vermilion/vermilion_server_" .. name .. ".txt"
	else
		return "vermilion/vermilion_unknown_" .. name .. ".txt"
	end
end

function Vermilion:AddRank(name, protected, permissions)
	permissions = permissions or {}
	if(self:HasRank(name)) then
		self.Log("Attempt to add duplicate rank '" .. name .. "' failed!")
		return
	end
	table.insert( self.Settings.Ranks, {Name = name, Permissions = permissions, Protected = protected} )
end

function Vermilion:RemoveRank(name)
	if(not self:HasRank(name)) then
		self.Log("Attempt to remove non-existent rank '" .. name .. "' failed!")
		return
	end
	if(self:GetRankData(name).Protected) then
		self.Log("Attempt to remove protected rank '" .. name .. "' failed!")
		return
	end

	for i,k in pairs(self.Settings.Ranks) do
		if(k.Name == name) then
			self.Settings.Ranks[i] = nil
			return
		end
	end
	self.Log("Failed to remove rank '" .. name .. "'; was not found in storage!")
end

function Vermilion:GetRankData(name)
	if(not self:HasRank(name)) then
		self.Log("Attempt to get rank data for non-existent rank '" .. name .. "' failed!")
		return
	end
	for i,k in pairs(self.Settings.Ranks) do
		if(k.Name == name) then
			table.Merge(k, rankFuncs)
			return k
		end
	end
end

function Vermilion:RenameRank(oldname, newname)
	if(not self:HasRank(oldname)) then
		self.Log("Attempt to rename non-existent rank '" .. oldname .. "' failed!")
		return
	end
	if(self:HasRank(newname)) then
		self.Log("Attempt to rename rank '" .. oldname .. "' to '" .. newname .. "' failed because of a conflict!")
		return
	end
	if(self:GetRankData(oldname).Protected) then
		self.Log("Attempt to rename rank '" .. oldname .. "' to '" .. newname .. "' failed because the rank is protected!")
		return
	end
	self:GetRankData(oldname).Name = newname
end

function Vermilion:HasRank(name)
	for i,k in pairs(self.Settings.Ranks) do
		if(k.Name == name) then return true end
	end
	return false
end

function Vermilion:AddUser(name, steamid, rank)
	rank = rank or Vermilion:GetSetting("default_rank", "player")
	if(self:HasUserSteamID(steamid)) then
		self.Log("Attempt to add duplicate user '" .. name .. "' failed!")
		return
	end
	table.insert(self.Settings.Users, {
		Name = name,
		SteamID = steamid,
		Rank = rank,
		Permissions = {},
		CountryCode = "N/A",
		CountryName = "N/A",
		Playtime = 0,
		Kills = 0,
		Deaths = 0,
		VAchievements = {},
		Karma = { Positive = 0, Negative = 0 }
	})
end

function Vermilion:RemoveUser(name)
	if(not self:HasUser(name)) then
		self.Log("Attempt to remove non-existent user '" .. name .. "' failed!")
		return
	end
	for i,k in pairs(self.Settings.Users) do
		if(k.Name == name) then
			self.Settings.Users[i] = nil
			break
		end
	end
end

function Vermilion:RemoveUserSteamID(steamid)
	if(not self:HasUserSteamID(steamid)) then
		self.Log("Attempt to remove non-existent user '" .. steamid .. "' failed!")
		return
	end
	for i,k in pairs(self.Settings.Users) do
		if(k.SteamID == steamid) then
			self.Settings.Users[i] = nil
			break
		end
	end
end

function Vermilion:GetUser(name)
	if(isentity(name) and name:IsPlayer()) then
		name = name:GetName()
	end
	if(not self:HasUser(name)) then
		local tplayer = Crimson.LookupPlayerByName(name)
		if(tplayer != nil) then
			return Vermilion:GetUserSteamID(tplayer:SteamID()) -- this is a bit hacky.
		end
		self.Log("Attempt to get user data for non-existent user '" .. name .. "' failed!")
		debug.Trace()
		return
	end
	for i,k in pairs(self.Settings.Users) do
		if(k.Name == name) then
			table.Merge(k, userFuncs)
			return k
		end
	end
end

function Vermilion:GetUserSteamID(steamid)
	if(not self:HasUserSteamID(steamid)) then
		self.Log("Attempt to get user data for non-existent user '" .. tostring(steamid) .. "' failed!")
		return
	end
	for i,k in pairs(self.Settings.Users) do
		if(k.SteamID == steamid) then
			table.Merge(k, userFuncs)
			return k
		end
	end
end

function Vermilion:GetUsersWithPermission(permission)
	local users = {}
	for i,k in pairs(player.GetAll()) do
		if(self:GetUser(k):HasPermission(permission)) then table.insert(users, k) end
	end
	return users
end

function Vermilion:HasUser(name)
	if(isentity(name) and name:IsPlayer()) then
		name = name:GetName()
	end
	for i,k in pairs(self.Settings.Users) do
		if(k.Name == name) then
			return true
		end
	end
	return false
end

function Vermilion:HasUserSteamID(steamid)
	for i,k in pairs(self.Settings.Users) do
		if(k.SteamID == steamid) then
			return true
		end
	end
	return false
end

function Vermilion:HasPermission(vplayer, permission)
	if(isstring(vplayer)) then vplayer = Crimson.LookupPlayerByName(vplayer) end
	if(not IsValid(vplayer)) then return true end -- probably the console/duplicator
	local userData = self:GetUser(vplayer)
	if(userData == nil) then return false end
	return userData:HasPermission(permission)
end

function Vermilion:HasPermissionError(vplayer, permission, log)
	if(not self:HasPermission(vplayer, permission)) then
		if(log == nil) then self:SendNotify(vplayer, Vermilion.Lang.AccessDenied, VERMILION_NOTIFY_ERROR) else log(Vermilion.Lang.AccessDenied, VERMILION_NOTIFY_ERROR) end
		return false
	end
	return true
end

function Vermilion:RankHasPermission(rank, permission)
	local rankdat = self:GetRankData(rank)
	if(rankdat != nil) then
		return rankdat:HasPermission(permission)
	end
	return false
end

function Vermilion:AddRankPermission(rank, permission)
	local rankdat = self:GetRankData(rank)
	if(rankdat != nil) then
		if(not table.HasValue(rankdat.Permissions, permission)) then
			table.insert(rankdat.Permissions, permission)
		else
			self.Log("Attempt to give rank '" .. rank .. "' the duplicate permission '" .. permission .. "' failed!")
		end
	end
end

function Vermilion:RemoveRankPermission(rank, permission)
	local rankdat = self:GetRankData(rank)
	if(rankdat != nil) then
		table.RemoveByValue(rankdat.Permissions, permission)
	end
end

function Vermilion:AddPlayerPermission(vplayer, permission)
	local vplayerdat = self:GetUser(vplayer)
	if(vplayerdat != nil) then
		if(not table.HasValue(vplayerdat.Permissions, permission)) then
			table.insert(vplayerdat.Permissions, permission)
		else
			self.Log("Attempt to give duplicate permission '" .. permission .. "' to player '" .. vplayerdat.Name .. "' failed!")
		end
	end
end

function Vermilion:RemovePlayerPermission(vplayer, permission)
	local vplayerdat = self:GetUser(vplayer)
	if(vplayerdat != nil) then
		table.RemoveByValue(vplayerdat.Permissions, permission)
	end
end

function Vermilion:CountPlayersInRank(rank)
	if(not Vermilion:HasRank(rank)) then
		self.Log("Attempt to count players in non-existent rank '" .. rank .. "' failed!")
		return
	end
	local players = 0
	for i,k in pairs(self.Settings.Users) do
		if(k.Rank == rank) then players = players + 1 end
	end
	return players
end

-- Returns true if rank 1 is greater than rank 2.
function Vermilion:CalcImmunity(rank1, rank2)
	if(isentity(rank1) and rank1:IsPlayer()) then
		rank1 = Vermilion:GetUser(rank1):GetRank().Name
	end
	if(isentity(rank2) and rank2:IsPlayer()) then
		rank2 = Vermilion:GetUser(rank2):GetRank().Name
	end
	for i,k in ipairs(self.Settings.Ranks) do
		if(k.Name == rank1) then return true end
		if(k.Name == rank2) then return false end
	end
end

function Vermilion:OwnerExists()
	for i,plyr in pairs(player.GetAll()) do
		local playerDat = self:GetUser(plyr)
		if(playerDat != nil) then
			if(playerDat.Rank == "owner") then
				return true
			end
		end
	end
	return false
end

function Vermilion:LoadSettings()
	if(file.Exists(self.GetFileName("settings-2"), "DATA")) then
		local tab = util.JSONToTable(util.Decompress(file.Read(self.GetFileName("settings-2"), "DATA")))
		if(tab != nil) then
			for i,k in pairs(tab) do
				if(i == "prop_protect_physgun" or i == "prop_protect_toolgun" or i == "prop_protect_world" or i == "prop_protect_gravgun" or i == "prop_protect_use") then
					if(self.Settings.ModuleData["prop_protect"] == nil) then self.Settings.ModuleData["prop_protect"] = {} end
					self.Settings.ModuleData["prop_protect"][i] = k
				elseif(i == "enable_limit_remover" or i == "limit_remover_min_rank" or i == "noclip_control" or i == "disable_fall_damage" or i == "voip_control" or i == "enable_no_damage" or i == "spray_control" or i == "flashlight_Control" or i == "enable_kill_immunity" or i == "unlimited_ammo" or i == "force_noclip_permissions" or i == "enable_kick_immunity" or i == "enable_lock_immunity" or i == "motd") then
					if(self.Settings.ModuleData["server_manager"] == nil) then self.Settings.ModuleData["server_manager"] = {} end
					if(i == "flashlight_Control") then
						self.Settings.ModuleData["server_manager"]["flashlight_control"] = k
					else
						self.Settings.ModuleData["server_manager"][i] = k
					end
				elseif(i == "protect_skybox") then
					if(self.Settings.ModuleData["skybox_protect"] == nil) then self.Settings.ModuleData["skybox_protect"] = {} end
					self.Settings.ModuleData["skybox_protect"]["protect_skybox"] = k
				elseif(i == "skyboxes") then
					if(self.Settings.ModuleData["skybox_protect"] == nil) then self.Settings.ModuleData["skybox_protect"] = {} end
					self.Settings.ModuleData["skybox_protect"]["skyboxes"] = k
				elseif(i == "default_rank" or i == "enabled") then
					self.Settings.GlobalData[i] = k
				elseif(i == "blocked_binds") then
					if(self.Settings.ModuleData["bindcontrol"] == nil) then self.Settings.ModuleData["bindcontrol"] = {} end
					self.Settings.ModuleData["bindcontrol"][i] = k
				elseif(i == "entity_limits") then
					if(self.Settings.ModuleData["entlimit"] == nil) then self.Settings.ModuleData["entlimit"] = {} end
					self.Settings.ModuleData["entlimit"][i] = k
				elseif(i == "soundcloud_playlists") then
					if(self.Settings.ModuleData["sound"] == nil) then self.Settings.ModuleData["sound"] = {} end
					self.Settings.ModuleData["sound"][i] = k
				elseif(i == "loadouts" or i == "disable_loadout_on_non_sandbox") then
					if(self.Settings.ModuleData["loadout"] == nil) then self.Settings.ModuleData["loadout"] = {} end
					self.Settings.ModuleData["loadout"][i] = k
				elseif(i == "zones") then
					if(self.Settings.ModuleData["zones"] == nil) then self.Settings.ModuleData["zones"] = {} end
					self.Settings.ModuleData["zones"][i] = k
				elseif(i == "warps") then
					if(self.Settings.ModuleData["warps"] == nil) then self.Settings.ModuleData["warps"] = {} end
					self.Settings.ModuleData["warps"][i] = k
				elseif(i == "bans") then
					if(self.Settings.ModuleData["bans"] == nil) then self.Settings.ModuleData["bans"] = {} end
					self.Settings.ModuleData["bans"][i] = k
				elseif(i == "weapon_limits") then
					if(self.Settings.ModuleData["weplimit"] == nil) then self.Settings.ModuleData["weplimit"] = {} end
					self.Settings.ModuleData["weplimit"][i] = k
				elseif(i == "tool_gun_limits") then
					if(self.Settings.ModuleData["toollimit"] == nil) then self.Settings.ModuleData["toollimit"] = {} end
					self.Settings.ModuleData["toollimit"][i] = k
				elseif(i == "ranks") then
					for i1,k1 in ipairs(k) do
						local oldperms = {}
						for i2,k2 in ipairs(tab.permissions) do
							if(k2[1] == k1) then oldperms = k2[2] break end
						end
						if(not self:HasRank(k1)) then
							self:AddRank(k1, k1 == "owner", oldperms)
						else
							self:GetRankData(k1).Permissions = oldperms
						end
					end
				elseif(i == "permissions") then
					-- ignore this one
				elseif(i == "user_store") then
					for i1,k1 in pairs(k) do
						if(self:HasUserSteamID(i1)) then
							local userdata = self:GetUserSteamID(i1)
							userdata.Rank = k1.rank
						else
							self:AddUser(k1.name, i1, k1.rank)
						end
					end
				else
					self.Settings.ModuleData[i] = k
				end
			end
		end
		file.Write(self.GetFileName("settings-mk2"), util.Compress(util.TableToJSON(Crimson.NetSanitiseTable(self.Settings))))
		file.Write(self.GetFileName("settings-2-old"), file.Read(self.GetFileName("settings-2"), "DATA"))
		file.Delete(self.GetFileName("settings-2"))
		return
	end
	if(file.Exists(self.GetFileName("settings-mk2"), "DATA")) then
		self.Settings = util.JSONToTable(util.Decompress(file.Read(self.GetFileName("settings-mk2"), "DATA")))
	else
		for i,k in pairs(self.DefaultPermissionSettings) do
			self:GetRankData(k[1]).Permissions = k[2]
		end
		file.Write(self.GetFileName("settings-mk2"), util.Compress(util.TableToJSON(Crimson.NetSanitiseTable(self.Settings))))
	end
end

function Vermilion:SaveSettings()
	file.Write(self.GetFileName("settings-mk2"), util.Compress(util.TableToJSON(Crimson.NetSanitiseTable(self.Settings))))
end

Vermilion:LoadSettings()

concommand.Add("vermilion_dump_settings", function()
	PrintTable(Vermilion.Settings)
end)

timer.Create("V-UpdatePlaytime", 5, 0, function()
	for i,k in pairs(player.GetHumans()) do
		local vdata = Vermilion:GetUser(k)
		vdata.Playtime = vdata.Playtime + 5
	end
end)

Vermilion:RegisterHook("ShutDown", "V-CFG-Save", function()
	Vermilion.Log("Saving data...")
	hook.Call("Vermilion-Pre-Shutdown")
	Vermilion:SaveSettings()
end)