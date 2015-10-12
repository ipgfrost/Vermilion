--[[
 Copyright 2015 Ned Hyett

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

DRIVER = {}

DRIVER.Data = {}

DRIVER.Data.Global = {}
DRIVER.Data.Module = {}
DRIVER.Data.Ranks = {} -- temp
DRIVER.Data.Users = {}

if(SERVER) then
	AddCSLuaFile()
end

function DRIVER:GetData(name, default, set)
	if(self.Data.Global[name] == nil) then
		if(set) then
			self.Data.Global[name] = default
			Vermilion:TriggerInternalDataChangeHooks(name)
		end
		return default
	end
	return self.Data.Global[name]
end

function DRIVER:SetData(name, value)
	self.Data.Global[name] = value
	Vermilion:TriggerInternalDataChangeHooks(name)
end

function DRIVER:GetAllModuleData(mod)
	if(self.Data.Module[mod] == nil) then self.Data.Module[mod] = {} end
	return self.Data.Module[mod]
end

function DRIVER:GetModuleData(mod, name, def, set)
	if(self.Data.Module[mod] == nil) then self.Data.Module[mod] = {} end
	if(self.Data.Module[mod][name] == nil) then
		if(set) then self:SetModuleData(mod, name, def) end
		return def
	end
	return self.Data.Module[mod][name]
end

function DRIVER:SetModuleData(mod, name, val)
	if(self.Data.Module[mod] == nil) then self.Data.Module[mod] = {} end
	self.Data.Module[mod][name] = val
	Vermilion:TriggerDataChangeHooks(mod, name)
end

function DRIVER:CreateDefaultDataStructs()
	self.Data.Ranks = {
		Vermilion:CreateRankObj("owner", { "*" }, true, Color(255, 0, 0), "key_add"),
		Vermilion:CreateRankObj("admin", nil, false, Color(255, 93, 0), "shield"),
		Vermilion:CreateRankObj("player", nil, false, Color(0, 161, 255), "user"),
		Vermilion:CreateRankObj("guest", { "chat" }, false, Color(255, 255, 255), "user_orange")
	}
end

function DRIVER:RestoreBackup()
	Vermilion.Log({Vermilion.Colours.Red, "[CRITICAL WARNING]", Vermilion.Colours.White, " I lost the configuration file... Usually a result of GMod unexpectedly stopping, most likely due to a BSoD or Kernel Panic. Sorry about that :( I'll try to restore a backup for you."})

	local fls = file.Find("vermilion2/backup/*.txt", "DATA", "nameasc")

	if(table.Count(fls) == 0) then
		Vermilion.Log({ Vermilion.Colours.Red, "NO BACKUPS FOUND! Did you delete them? Restoring configuration file to defaults." })
		self:CreateDefaultDataStructs()
		return
	end

	local max = 0
	for i,k in pairs(fls) do
		if(tonumber(string.Replace(k, ".txt", "")) > max) then
			max = tonumber(string.Replace(k, ".txt", ""))
		end
	end

	local content = file.Read("vermilion2/backup/" .. tostring(max) .. ".txt")
	file.Write(Vermilion.GetFileName("settings"), content)

	Vermilion.Log("Restored configuration with timestamp " .. tostring(max) .. "!")
end

function DRIVER:Load(crashOnErr)
	if(Vermilion.FirstRun) then
		print("FIRST RUN!")
		self:CreateDefaultDataStructs()
		file.CreateDir("vermilion2/backup")
	else
		if(file.Size(Vermilion.GetFileName("settings"), "DATA") == 0) then
			self:RestoreBackup()
		else
			local fls = file.Find("vermilion2/backup/*.txt", "DATA", "nameasc")
			--if(table.Count(fls) > 100) then
				local oneWeekAgo = os.time() - (60 * 60 * 24 * 7)
				for i,k in pairs(fls) do
					if(tonumber(string.Replace(k, ".txt", "")) < oneWeekAgo) then
						Vermilion.Log("Deleting week-old configuration file; " .. k .. "!")
						file.Delete("vermilion2/backup/" .. k)
						table.RemoveByValue(fls, k)
						if(table.Count(fls) <= 100) then break end
					end
				end
			--end

			Vermilion.Log(Vermilion:TranslateStr("config:backup"))
			local code = tostring(os.time())
			local content = file.Read(Vermilion.GetFileName("settings"), "DATA")

			file.Write("vermilion2/backup/" .. code .. ".txt", content)
		end
		local succ,err = pcall(function()
			self.Data = util.JSONToTable(util.Decompress(file.Read(Vermilion.GetFileName("settings"), "DATA")))
		end)
		if(!succ) then
			if(crashOnErr) then
				Vermilion.Log("There was a fatal error loading the configuration file... oops...")
				self:CreateDefaultDataStructs()
				file.Delete(Vermilion.GetFileName("settings"))
				Vermilion:SetData("UIDUpgraded", true)
				return
			end
			self:RestoreBackup()
			Vermilion:LoadConfiguration(true)
		end
		for i,rank in pairs(self.Data.Ranks) do
			Vermilion:AttachRankFunctions(rank)
		end
		if(not Vermilion:GetData("UIDUpgraded", false)) then
			for i,k in pairs(self.Data.Ranks) do
				if(k.InheritsFrom != nil) then
					k.InheritsFrom = Vermilion:GetRank(k.InheritsFrom):GetUID()
				end
			end
		end
		for i,usr in pairs(self.Data.Users) do
			Vermilion:AttachUserFunctions(usr)
		end
		Vermilion.Log(Vermilion:TranslateStr("config:loaded"))
	end
	Vermilion:SetData("UIDUpgraded", true)
end

function DRIVER:Save(verbose)
	if(verbose == nil) then verbose = true end
	if(verbose) then Vermilion.Log(Vermilion:TranslateStr("config:saving")) end
	local safeTable = VToolkit.NetSanitiseTable(self.Data)
	file.Write(Vermilion.GetFileName("settings"), util.Compress(util.TableToJSON(safeTable)))
end




function DRIVER:AddRank(obj)
	table.insert(self.Data.Ranks, obj)
end

function DRIVER:GetAllRanks()
	return self.Data.Ranks
end

function DRIVER:GetOwnerRank()
	return self.Data.Ranks[1] -- owner will always be at top
end

function DRIVER:GetRank(name)
	for i,k in pairs(self.Data.Ranks) do
		if(k.Name == name) then return k end
	end
end

function DRIVER:GetRankByID(id)
	for i,k in pairs(self.Data.Ranks) do
		if(k.UniqueID == id) then return k end
	end
end

function DRIVER:HasRank(name)
	return self:GetRank(name) != nil
end

function DRIVER:HasRankID(id)
	return self:GetRankByID(id) != nil
end

function DRIVER:GetRankImmunity(rank)
	return table.KeyFromValue(self.Data.Ranks, rank)
end

function DRIVER:IncreaseRankImmunity(rank)
	local immunity = rank:GetImmunity()
	table.insert(self.Data.Ranks, immunity - 1, rank)
	table.remove(self.Data.Ranks, immunity + 1)
end

function DRIVER:DecreaseRankImmunity(rank)
	local immunity = rank:GetImmunity()
	table.insert(self.Data.Ranks, immunity + 2, rank)
	table.remove(self.Data.Ranks, immunity)
end

function DRIVER:RenameRank(rank)
	-- noop on Data driver
end

function DRIVER:DeleteRank(rank)
	table.RemoveByValue(self.Data.Ranks, rank)
end

function DRIVER:SetRankParent(rank)
	-- noop on Data driver
end

function DRIVER:UpdateRankPermissions(rank)
	-- noop on Data driver
end

function DRIVER:SetRankColour(rank)
	-- noop on Data driver
end

function DRIVER:SetRankIcon(rank)
	-- noop on Data driver
end



function DRIVER:AddUser(vplayer)
	if(IsValid(vplayer)) then
		local usr = Vermilion:CreateUserObj(vplayer:GetName(), vplayer:SteamID(), Vermilion:GetDefaultRank(), {})
		table.insert(self.Data.Users, usr)
	end
end

function DRIVER:AddUserObject(obj)
	table.insert(self.Data.Users, obj)
end

function DRIVER:GetUser(vplayer)
	if(not isfunction(vplayer.SteamID)) then
		return
	end
	return self:GetUserBySteamID(vplayer:SteamID())
end

function DRIVER:GetUserByName(name)
	for index,userData in pairs(self.Data.Users) do
		if(userData.Name == name) then return userData end
	end
end

function DRIVER:GetUserBySteamID(steamid)
	for index,userData in pairs(self.Data.Users) do
		if(userData.SteamID == steamid) then return userData end
	end
end

function DRIVER:GetAllUsers()
	return self.Data.Users
end

function DRIVER:HasUser(vplayer)
	return self:GetUser(vplayer) != nil
end

function DRIVER:SetUserRank(user)
	-- noop on Data driver
end

function DRIVER:DeleteUser(steamid)
	for i,k in pairs(self.Data.Users) do
		if(k.SteamID == steamid) then
			table.RemoveByValue(self.Data.Users, k)
			return
		end
	end
end



Vermilion:RegisterDriver("Data", DRIVER)
DRIVER = nil
