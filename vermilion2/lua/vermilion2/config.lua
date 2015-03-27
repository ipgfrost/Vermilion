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


Vermilion.AllPermissions = {}

Vermilion.DataChangeHooks = {}

Vermilion.Data = {}

Vermilion.Data.Global = {}
Vermilion.Data.Module = {}
Vermilion.Data.Ranks = {} -- temp
Vermilion.Data.Users = {}
Vermilion.Data.Bans = {}





--[[

	//		Networking		\\

]]--

util.AddNetworkString("Vermilion_SendRank")
util.AddNetworkString("VBroadcastRankData")
util.AddNetworkString("VBroadcastPermissions")
util.AddNetworkString("VUpdatePlayerLists")
util.AddNetworkString("VModuleConfig")





--[[

	//		Ranks		\\

]]--

function Vermilion:GetDefaultRank()
	local duid = ""
	if(Vermilion:HasRank("player")) then
		duid = Vermilion:GetRank("player"):GetUID()
	end
	return self:GetData("default_rank", duid)
end

function Vermilion:AddRank(name, permissions, protected, colour, icon)
	if(self:GetRank(name) != nil) then return end
	local obj = self:CreateRankObj(name, permissions, protected, colour, icon)
	table.insert(self.Data.Ranks, obj)
	hook.Run(Vermilion.Event.RankCreated, name)
	Vermilion:BroadcastRankData(VToolkit.GetValidPlayers())
end

function Vermilion:CreateRankID()
	local vars = string.ToTable("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789") -- source array, modify this to make more complex IDs.
	local out = ""
	for i=1,15,1 do -- 15 chars long
		out = out .. table.Random(vars)
	end
	
	for i,k in pairs(Vermilion.Data.Ranks) do
		if(k.UniqueID == out) then return self:CreateRankID() end -- make completely sure that we are not duplicating rank IDs.
	end
	
	return out
end

function Vermilion:CreateRankObj(name, permissions, protected, colour, icon, inherits)
	local rnk = {}

	rnk.Name = name
	rnk.UniqueID = Vermilion:CreateRankID()
	rnk.Permissions = permissions or {}
	rnk.Protected = protected or false
	if(colour == nil) then rnk.Colour = { 255, 255, 255 } else
		rnk.Colour = { colour.r, colour.g, colour.b }
	end
	rnk.Icon = icon
	rnk.InheritsFrom = inherits

	rnk.Metadata = {}

	self:AttachRankFunctions(rnk)

	return rnk
end

function Vermilion:AttachRankFunctions(rankObj)

	if(Vermilion.RankMetaTable == nil) then
		local meta = {}
		
		function meta:GetName()
			return self.Name
		end
		
		function meta:GetUID()
			return self.UniqueID
		end

		function meta:IsImmuneToRank(rank)
			return self:GetImmunity() < rank:GetImmunity()
		end

		function meta:GetImmunity()
			return table.KeyFromValue(Vermilion.Data.Ranks, self)
		end

		function meta:MoveUp()
			if(self:GetImmunity() <= 2) then
				Vermilion.Log(Vermilion:TranslateStr("config:rank:cantmoveup"))
				return false
			end
			if(self.Protected) then
				Vermilion.Log(Vermilion:TranslateStr("config:rank:moveprotected"))
				return false
			end
			local immunity = self:GetImmunity()
			table.insert(Vermilion.Data.Ranks, immunity - 1, self)
			table.remove(Vermilion.Data.Ranks, immunity + 1)
			Vermilion:BroadcastRankData(VToolkit.GetValidPlayers())
			return true
		end

		function meta:MoveDown()
			if(self:GetImmunity() == table.Count(Vermilion.Data.Ranks)) then
				Vermilion.Log(Vermilion:TranslateStr("config:rank:cantmovedown"))
				return false
			end
			if(self.Protected) then
				Vermilion.Log(Vermilion:TranslateStr("config:rank:moveprotected"))
				return false
			end
			local immunity = self:GetImmunity()
			table.insert(Vermilion.Data.Ranks, immunity + 2, self)
			table.remove(Vermilion.Data.Ranks, immunity)
			Vermilion:BroadcastRankData(VToolkit.GetValidPlayers())
			return true
		end

		function meta:GetUsers()
			local users = {}
			for i,k in pairs(Vermilion.Data.Users) do
				if(k:GetRankName() == self.Name and k:GetEntity() != nil) then
					table.insert(users, k:GetEntity())
				end
			end
			return users
		end

		function meta:Rename(newName)
			if(self.Protected) then
				Vermilion.Log(Vermilion:TranslateStr("config:rank:renameprotected"))
				return false
			end
			for i,k in pairs(self:GetUsers()) do
				k:SetRank(newName, true)
			end
			Vermilion.Log(Vermilion:TranslateStr("config:rank:renamed", { self.Name, newName }))
			hook.Run(Vermilion.Event.RankRenamed, self.UniqueID, self.Name, newName)
			self.Name = newName
			Vermilion:BroadcastRankData()
			return true
		end

		function meta:Delete()
			if(self.Protected) then
				Vermilion.Log(Vermilion:TranslateStr("config:rank:deleteprotected"))
				return false
			end
			for i,k in pairs(self:GetUsers()) do
				k:SetRank(Vermilion:GetDefaultRank())
			end
			for i,k in pairs(Vermilion.Data.Ranks) do
				if(k.InheritsFrom == self.UniqueID) then
					k.InheritsFrom = nil
				end
			end
			table.RemoveByValue(Vermilion.Data.Ranks, self)
			Vermilion:BroadcastRankData()
			Vermilion.Log(Vermilion:TranslateStr("config:rank:deleted", { self.Name }))
			hook.Run(Vermilion.Event.RankDeleted, self.UniqueID)
			return true
		end

		function meta:SetParent(parent)
			if(parent == nil) then
				self.InheritsFrom = nil
				Vermilion:BroadcastRankData()
				return
			end
			self.InheritsFrom = parent:GetUID()
			Vermilion:BroadcastRankData()
		end

		function meta:AddPermission(permission)
			if(self.Protected) then return end
			if(not istable(permission)) then permission = { permission } end
			for i,perm in pairs(permission) do
				if(not self:HasPermission(perm)) then
					local has = false
					for i,k in pairs(Vermilion.AllPermissions) do
						if(k.Permission == perm) then has = true break end
					end
					if(has) then
						table.insert(self.Permissions, perm)
					end
				end
			end
			for i,k in pairs(self:GetUsers()) do
				Vermilion:SyncClientRank(k)
			end
		end

		function meta:RevokePermission(permission)
			if(self.Protected) then return end
			if(not istable(permission)) then permission = { permission } end
			for i,perm in pairs(permission) do
				if(self:HasPermission(perm)) then
					local has = false
					for i,k in pairs(Vermilion.AllPermissions) do
						if(k.Permission == perm) then has = true break end
					end
					if(has) then
						table.RemoveByValue(self.Permissions, perm)
					end
				end
			end
			for i,k in pairs(self:GetUsers()) do
				Vermilion:SyncClientRank(k)
			end
		end

		function meta:HasPermission(permission)
			if(permission != "*") then
				local has = false
				for i,k in pairs(Vermilion.AllPermissions) do
					if(k.Permission == permission) then has = true break end
				end
				if(not has) then
					Vermilion.Log(Vermilion:TranslateStr("config:unknownpermission", { permission }))
				end
			end
			if(self.InheritsFrom != nil) then
				if(Vermilion:GetRank(self.InheritsFrom) == nil) then
					Vermilion.Log("Bad rank inheritance for '" .. self.Name .. "'; Cannot find parent rank. Removing link.")
					self.InheritsFrom = nil
				else
					if(Vermilion:GetRank(self.InheritsFrom):HasPermission(permission)) then return true end
				end
			end
			return table.HasValue(self.Permissions, permission) or table.HasValue(self.Permissions, "*")
		end

		function meta:SetColour(colour)
			if(IsColor(colour)) then
				self.Colour = { colour.r, colour.g, colour.b }
				Vermilion:BroadcastRankData()
			elseif(istable(colour)) then
				self.Colour = colour
				Vermilion:BroadcastRankData()
			else
				Vermilion.Log(Vermilion:TranslateStr("config:rank:badcolour", { type(colour) }))
			end
		end

		function meta:GetColour()
			return Color(self.Colour[1], self.Colour[2], self.Colour[3])
		end

		function meta:GetIcon()
			return self.Icon
		end

		function meta:SetIcon(icon)
			self.Icon = icon
			Vermilion:BroadcastRankData(VToolkit.GetValidPlayers())
		end
		Vermilion.RankMetaTable = meta
	end
	
	if(rankObj.UniqueID == nil) then -- upgrade existing configurations.
		Vermilion.Log("Old-style rank detected (" .. rankObj.Name .. "); upgrading to UID...")
		rankObj.UniqueID = Vermilion:CreateRankID()
		Vermilion.Log("Rank given UID '" .. rankObj.UniqueID .. "'!")
	end
	
	setmetatable(rankObj, { __index = Vermilion.RankMetaTable }) // <-- The metatable creates phantom functions.
end

function Vermilion:SyncClientRank(client)
	local userData = self:GetUser(client)
	if(userData != nil) then
		local rankData = userData:GetRank()
		if(rankData != nil) then
			net.Start("Vermilion_SendRank")
			net.WriteTable(VToolkit.NetSanitiseTable(rankData))
			net.Send(client)
		end
	end
end

function Vermilion:BroadcastRankData(target)
	target = target or VToolkit:GetValidPlayers()
	local normalData = {}
	for i,k in pairs(self.Data.Ranks) do
		table.insert(normalData, { Name = k.Name, UniqueID = k.UniqueID, Colour = k:GetColour(), IsDefault = k.UniqueID == Vermilion:GetDefaultRank(), Protected = k.Protected, Icon = k.Icon, InheritsFrom = k.InheritsFrom })
	end
	net.Start("VBroadcastRankData")
	net.WriteTable(normalData)
	net.Send(target)
end

function Vermilion:GetRank(name) -- this is now only to get ranks from player inputs, not used in the code. Use GetRankByID instead!
	for i,k in pairs(self.Data.Ranks) do
		if(k.Name == name) then return k end
	end
end

function Vermilion:GetRankByID(id)
	for i,k in pairs(self.Data.Ranks) do
		if(k.UniqueID == id) then return k end
	end
end

function Vermilion:HasRank(name)
	return self:GetRank(name) != nil
end

function Vermilion:HasRankID(id)
	return self:GetRankByID(id) != nil
end





--[[

	//		Users		\\

]]--

function Vermilion:CreateUserObj(name, steamid, rank, permissions)
	local usr = {}

	usr.Name = name
	usr.SteamID = steamid
	usr.Rank = rank
	usr.Permissions = permissions
	usr.Playtime = 0
	usr.Kills = 0
	usr.Deaths = 0
	usr.Achievements = {}
	usr.Karma = { Positive = {}, Negative = {} }


	usr.Metadata = {}

	self:AttachUserFunctions(usr)

	return usr
end

function Vermilion:AttachUserFunctions(usrObject)
	if(Vermilion.PlayerMetaTable == nil) then
		local meta = {}
		function meta:GetRank()
			return Vermilion:GetRankByID(self.Rank)
		end

		function meta:GetRankUID()
			return self.Rank
		end
		
		function meta:GetRankName()
			return self:GetRank():GetName()
		end

		function meta:GetEntity()
			for i,k in pairs(VToolkit.GetValidPlayers()) do
				if(k:SteamID() == self.SteamID) then return k end
			end
		end

		function meta:IsImmune(other)
			if(istable(other)) then
				return self:GetRank():IsImmuneToRank(other)
			end
			if(IsValid(other)) then
				return self:GetRank():IsImmuneToRank(Vermilion:GetUser(other):GetRank())
			end
		end

		function meta:SetRank(rank, override)
			if(Vermilion:HasRankID(rank) or override) then
				local old = self.Rank
				self.Rank = rank
				hook.Run(Vermilion.Event.PlayerChangeRank, self, old, rank)
				local ply = self:GetEntity()
				if(IsValid(ply)) then
					Vermilion:AddNotification(ply, Vermilion:TranslateStr("change_rank", { self.Rank }, ply))
					ply:SetNWString("Vermilion_Rank", self.Rank)
					Vermilion:SyncClientRank(ply)
				end
			end
		end

		function meta:HasPermission(permission)
			if(permission != "*") then
				local has = false
				for i,k in pairs(Vermilion.AllPermissions) do
					if(k.Permission == permission) then has = true break end
				end
				if(not has) then
					Vermilion.Log(Vermilion:TranslateStr("config:unknownpermission", { permission }))
				end
			end
			if(table.HasValue(self.Permissions, permission) or table.HasValue(self.Permissions, "*")) then return true end
			return self:GetRank():HasPermission(permission)
		end

		function meta:GetColour()
			return self:GetRank():GetColour()
		end
		Vermilion.PlayerMetaTable = meta
	end
	
	if(not Vermilion:GetData("UIDUpgraded", false)) then
		if(Vermilion:GetRank(usrObject.Rank) != nil) then 
			usrObject.Rank = Vermilion:GetRank(usrObject.Rank):GetUID()
		end
	end
	
	setmetatable(usrObject, { __index = Vermilion.PlayerMetaTable }) // <-- The metatable creates phantom functions.
end

function Vermilion:StoreNewUserdata(vplayer)
	if(IsValid(vplayer)) then
		local usr = self:CreateUserObj(vplayer:GetName(), vplayer:SteamID(), self:GetDefaultRank(), {})
		table.insert(self.Data.Users, usr)
	end
end

function Vermilion:GetUser(vplayer)
	if(not isfunction(vplayer.SteamID)) then return end
	return Vermilion:GetUserBySteamID(vplayer:SteamID())
end

function Vermilion:GetUserByName(name)
	for index,userData in pairs(self.Data.Users) do
		if(userData.Name == name) then return userData end
	end
end

function Vermilion:GetUserBySteamID(steamid)
	for index,userData in pairs(self.Data.Users) do
		if(userData.SteamID == steamid) then return userData end
	end
end

function Vermilion:HasUser(vplayer)
	return Vermilion:GetUser(vplayer) != nil
end

function Vermilion:HasPermission(vplayer, permission)
	if(permission != "*") then
		local has = false
		for i,k in pairs(self.AllPermissions) do
			if(k.Permission == permission) then has = true break end
		end
		if(not has) then
			Vermilion.Log(Vermilion:TranslateStr("config:unknownpermission", { permission }))
		end
	end
	if(not IsValid(vplayer)) then
		Vermilion.Log(Vermilion:TranslateStr("config:invaliduser"))
		return true
	end
	local usr = self:GetUser(vplayer)
	if(usr != nil) then
		return usr:HasPermission(permission)
	end
end

function Vermilion:HasPermissionError(vplayer, permission, log)
	if(not self:HasPermission(vplayer, permission)) then
		log(self:TranslateStr("access_denied"), NOTIFY_ERROR)
		return false
	end
	return true
end

function Vermilion:GetUsersWithPermission(permission)
	local tab = {}
	for i,k in pairs(VToolkit.GetValidPlayers()) do
		if(self:HasPermission(k, permission)) then table.insert(tab, k) end
	end
	return tab
end





--[[

	//		Data Storage		\\

]]--

function Vermilion:GetData(name, default, set)
	if(self.Data.Global[name] == nil) then
		if(set) then
			self.Data.Global[name] = default
			self:TriggerInternalDataChangeHooks(name)
		end
		return default
	end
	return self.Data.Global[name]
end

function Vermilion:SetData(name, value)
	self.Data.Global[name] = value
	self:TriggerInternalDataChangeHooks(name)
end

function Vermilion:AddDataChangeHook(name, id, func)
	if(self.DataChangeHooks[name] == nil) then self.DataChangeHooks[name] = {} end
	self.DataChangeHooks[name][id] = func
end

function Vermilion:RemoveDataChangeHook(name, id)
	if(self.DataChangeHooks[name] == nil) then return end
	self.DataChangeHooks[name][id] = nil
end

function Vermilion:TriggerInternalDataChangeHooks(name)
	if(self.DataChangeHooks[name] != nil) then
		for i,k in pairs(self.DataChangeHooks[name]) do
			k(self.Data.Global[name])
		end
	end
end

function Vermilion:GetModuleData(mod, name, def)
	if(self.Data.Module[mod] == nil) then self.Data.Module[mod] = {} end
	if(self.Data.Module[mod][name] == nil) then return def end
	return self.Data.Module[mod][name]
end

function Vermilion:SetModuleData(mod, name, val)
	if(self.Data.Module[mod] == nil) then self.Data.Module[mod] = {} end
	self.Data.Module[mod][name] = val
	self:TriggerDataChangeHooks(mod, name)
end

function Vermilion:TriggerDataChangeHooks(mod, name)
	local modStruct = Vermilion:GetModule(mod)
	if(modStruct != nil) then
		if(modStruct.DataChangeHooks != nil) then
			if(modStruct.DataChangeHooks[name] != nil) then
				for index,DCHook in pairs(modStruct.DataChangeHooks[name]) do
					DCHook(self.Data.Module[mod][name])
				end
			end
		end
	end
end

function Vermilion:NetworkModuleConfig(vplayer, mod)
	if(self.Data.Module[mod] != nil) then
		net.Start("VModuleConfig")
		net.WriteString(mod)
		net.WriteTable(self.Data.Module[mod])
		net.Send(vplayer)
	end
end





--[[

	//		Loading/saving		\\

]]--

function Vermilion:CreateDefaultDataStructs()
	Vermilion.Data.Ranks = {
		Vermilion:CreateRankObj("owner", { "*" }, true, Color(255, 0, 0), "key_add"),
		Vermilion:CreateRankObj("co-owner", nil, false, Color(0, 63, 255), "key"),
		Vermilion:CreateRankObj("server manager", nil, false, Color(0, 255, 255), "cog"),
		Vermilion:CreateRankObj("super admin", nil, false, Color(255, 0, 97), "shield_add"),
		Vermilion:CreateRankObj("admin", nil, false, Color(255, 93, 0), "shield"),
		Vermilion:CreateRankObj("donator", nil, false, Color(191, 127, 255), "heart"),
		Vermilion:CreateRankObj("respected", nil, false, Color(255, 191, 0), "user_red"),
		Vermilion:CreateRankObj("player", nil, false, Color(0, 161, 255), "user"),
		Vermilion:CreateRankObj("guest", { "chat" }, false, Color(255, 255, 255), "user_orange")
	}
	Vermilion:GetRank("player").InheritsFrom = Vermilion:GetRank("guest"):GetUID()
	Vermilion:GetRank("respected").InheritsFrom = Vermilion:GetRank("player"):GetUID()
	Vermilion:GetRank("donator").InheritsFrom = Vermilion:GetRank("respected"):GetUID()
	Vermilion:GetRank("admin").InheritsFrom = Vermilion:GetRank("donator"):GetUID()
	Vermilion:GetRank("super admin").InheritsFrom = Vermilion:GetRank("admin"):GetUID()
	Vermilion:GetRank("server manager").InheritsFrom = Vermilion:GetRank("super admin"):GetUID()
	Vermilion:GetRank("co-owner").InheritsFrom = Vermilion:GetRank("server manager"):GetUID()
	
	Vermilion.Data.Global = {}
	Vermilion.Data.Module = {}
	Vermilion.Data.Ranks = {} -- temp
	Vermilion.Data.Users = {}
	Vermilion.Data.Bans = {}
end

function Vermilion:RestoreBackup()
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
	file.Write(self.GetFileName("settings"), content)

	Vermilion.Log("Restored configuration with timestamp " .. tostring(max) .. "!")
end

function Vermilion:LoadConfiguration(crashOnErr)
	if(Vermilion.FirstRun) then
		self:CreateDefaultDataStructs()
		file.CreateDir("vermilion2/backup")
	else
		if(file.Size(self.GetFileName("settings"), "DATA") == 0) then
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
			local content = file.Read(self.GetFileName("settings"), "DATA")

			file.Write("vermilion2/backup/" .. code .. ".txt", content)
		end
		local succ,err = pcall(function() 
			Vermilion.Data = util.JSONToTable(util.Decompress(file.Read(self.GetFileName("settings"), "DATA")))
		end)
		if(!succ) then
			if(crashOnErr) then
				Vermilion.Log("There was a fatal error loading the configuration file... oops...")
				self:CreateDefaultDataStructs()
				file.Delete(self.GetFileName("settings"))
				Vermilion:SetData("UIDUpgraded", true)
				return
			end
			self:RestoreBackup()
			Vermilion:LoadConfiguration(true)
		end
		for i,rank in pairs(Vermilion.Data.Ranks) do
			self:AttachRankFunctions(rank)
		end
		if(not Vermilion:GetData("UIDUpgraded", false)) then
			for i,k in pairs(Vermilion.Data.Ranks) do
				if(k.InheritsFrom != nil) then
					k.InheritsFrom = Vermilion:GetRank(k.InheritsFrom):GetUID()
				end
			end
		end
		for i,usr in pairs(Vermilion.Data.Users) do
			self:AttachUserFunctions(usr)
		end
		self.Log(Vermilion:TranslateStr("config:loaded"))
	end
	Vermilion:SetData("UIDUpgraded", true)
end

Vermilion:LoadConfiguration()

function Vermilion:SaveConfiguration(verbose)
	if(verbose == nil) then verbose = true end
	if(verbose) then Vermilion.Log(Vermilion:TranslateStr("config:saving")) end
	local safeTable = VToolkit.NetSanitiseTable(Vermilion.Data)
	file.Write(self.GetFileName("settings"), util.Compress(util.TableToJSON(safeTable)))
end

Vermilion:AddHook("ShutDown", "SaveConfiguration", true, function()
	hook.Run(Vermilion.Event.ShuttingDown)
	Vermilion:SaveConfiguration()
end)

timer.Create("Vermilion:SaveConfiguration", 30, 0, function()
	Vermilion:SaveConfiguration(false)
end)






--[[

	//		Player Registration		\\

]]--

Vermilion:AddHook("PlayerInitialSpawn", "RegisterPlayer", true, function(vplayer)
	vplayer:SetNWString("SteamID", vplayer:SteamID())
	local new = false
	if(not Vermilion:HasUser(vplayer)) then
		Vermilion:StoreNewUserdata(vplayer)
		new = true
	end
	if(Vermilion:GetUser(vplayer).Name != vplayer:GetName()) then
		Vermilion:GetUser(vplayer).Name = vplayer:GetName()
	end
	if(table.Count(Vermilion:GetRank("owner"):GetUsers()) == 0 and (game.SinglePlayer() or vplayer:IsListenServerHost())) then
		Vermilion:GetUser(vplayer):SetRank(Vermilion:GetRank("owner"):GetUID())
	end
	vplayer:SetNWString("Vermilion_Rank", Vermilion:GetUser(vplayer):GetRank():GetUID())
	Vermilion:SyncClientRank(vplayer)
	Vermilion:BroadcastRankData(vplayer)
	net.Start("VBroadcastPermissions")
	net.WriteTable(Vermilion.AllPermissions)
	net.Send(vplayer)

	net.Start("VUpdatePlayerLists")
	local tab = {}
	for i,k in pairs(VToolkit.GetValidPlayers()) do
		table.insert(tab, { Name = k:GetName(), Rank = Vermilion:GetUser(k):GetRankName(), EntityID = k:EntIndex() })
	end
	net.WriteTable(tab)
	net.Broadcast()


	timer.Simple(1, function()
		if(not Vermilion:GetData("joinleave_enabled", true, true)) then return end
		if(new) then
			Vermilion:TransBroadcastNotify("config:join:first", { vplayer:GetName() })
		else
			Vermilion:TransBroadcastNotify("config:join", { vplayer:GetName() })
		end
	end)
end)

gameevent.Listen("player_disconnect")

Vermilion:AddHook("player_disconnect", "DisconnectMessage", true, function(data)
	if(not Vermilion:GetData("joinleave_enabled", true, true)) then return end
	if(string.find(data.reason, "Kicked by")) then return end
	Vermilion:TransBroadcastNotify("config:left", { data.name, data.reason })
end)





--[[

	//		Entity Ownership		\\

]]--

duplicator.RegisterEntityModifier("Vermilion_Owner", function(vplayer, entity, data)
	entity.Vermilion_Owner = data.Owner
	entity:SetNWString("Vermilion_Owner", data.Owner)
end)

duplicator.RegisterEntityModifier("Vermilion_Type", function(vplayer, entity, data)
	entity.Vermilion_Type = data.Type
end)

local setOwnerFunc = function(vplayer, model, entity, hkType)
	local tEnt = entity
	if(tEnt == nil) then tEnt = model end
	if(IsValid(tEnt)) then
		local str = ""
		if(hkType == "PlayerSpawnedRagdoll") then str = "ragdolls" end
		if(hkType == "PlayerSpawnedProp") then str = "props" end
		if(hkType == "PlayerSpawnedEffect") then str = "effects" end
		if(hkType == "PlayerSpawnedVehicle") then str = "vehicles" end
		if(hkType == "PlayerSpawnedSWEP") then str = "sents" end
		if(hkType == "PlayerSpawnedSENT") then str = "sents" end
		if(hkType == "PlayerSpawnedNPC") then str = "npcs" end
		tEnt.Vermilion_Type = str

		tEnt.Vermilion_Owner = vplayer:SteamID()
		tEnt:SetNWString("Vermilion_Owner", vplayer:SteamID())
		duplicator.StoreEntityModifier(tEnt, "Vermilion_Owner", { Owner = vplayer:SteamID() })
		duplicator.StoreEntityModifier(tEnt, "Vermilion_Type", { Type = str })
	end
end

local spawnedFuncs = {
	"PlayerSpawnedProp",
	"PlayerSpawnedSENT",
	"PlayerSpawnedNPC",
	"PlayerSpawnedVehicle",
	"PlayerSpawnedEffect",
	"PlayerSpawnedRagdoll",
	"PlayerSpawnedSWEP"
}

for i,spHook in pairs(spawnedFuncs) do
	Vermilion:AddHook(spHook, "Vermilion_SpawnCreatorSet" .. i, true, function(vplayer, model, entity)
		setOwnerFunc(vplayer, model, entity, spHook)
	end)
end

local spawnFuncsPatch = {
	"PlayerSpawnRagdoll",
	"PlayerSpawnProp",
	"PlayerSpawnEffect",
	"PlayerSpawnVehicle",
	"PlayerSpawnSWEP",
	"PlayerSpawnSENT",
	"PlayerSpawnNPC"
}

for i,spHook in pairs(spawnFuncsPatch) do
	Vermilion:AddHook(spHook, "Vermilion_CheckLimitFixer" .. i, false, function(vplayer)
		local str = ""
		if(spHook == "PlayerSpawnRagdoll") then str = "ragdolls" end
		if(spHook == "PlayerSpawnProp") then str = "props" end
		if(spHook == "PlayerSpawnEffect") then str = "effects" end
		if(spHook == "PlayerSpawnVehicle") then str = "vehicles" end
		if(spHook == "PlayerSpawnSWEP") then str = "sents" end
		if(spHook == "PlayerSpawnSENT") then str = "sents" end
		if(spHook == "PlayerSpawnNPC") then str = "npcs" end


		local hookResult = hook.Run(Vermilion.Event.CheckLimit, vplayer, str)
		if(hookResult != nil) then return hookResult end
	end)
end

timer.Simple(1, function()
	local meta = FindMetaTable("Player")
	if(meta.Vermilion_CheckLimit == nil) then
		meta.Vermilion_CheckLimit = meta.CheckLimit
		function meta:CheckLimit(str)
			local hookResult = hook.Run(Vermilion.Event.CheckLimit, self, str)
			if(hookResult != nil) then return hookResult end
			return self:Vermilion_CheckLimit(str)
		end
	end
	function meta:VermilionPropCount(str)

	end
	if(meta.Vermilion_AddCount == nil) then
		meta.Vermilion_AddCount = meta.AddCount
		function meta:AddCount(str, ent)
			ent.Vermilion_Owner = self:SteamID()
			ent:SetNWString("Vermilion_Owner", self:SteamID())
			self:Vermilion_AddCount(str, ent)
		end
	end

	if(cleanup) then
		cleanup.OldAdd = cleanup.Add
		function cleanup.Add(vplayer, typ, ent)
			if(IsValid(vplayer) and IsValid(ent)) then
				if(ent.Vermilion_Owner == nil) then
					ent.Vermilion_Owner = vplayer:SteamID()
					ent:SetNWString("Vermilion_Owner", vplayer:SteamID())
					duplicator.StoreEntityModifier(ent, "Vermilion_Owner", { Owner = vplayer:SteamID() })
				end
			end
			cleanup.OldAdd(vplayer, typ, ent)
		end
	end
end)

local spawnFuncs = {
	{ "PlayerSpawnProp", "props" },
	{ "PlayerSpawnSENT", "sents" },
	{ "PlayerSpawnNPC", "npcs" },
	{ "PlayerSpawnVehicle", "vehicles" },
	{ "PlayerSpawnEffect", "effects" },
	{ "PlayerSpawnSWEP", "sents" }
}

for i,k in pairs(spawnFuncs) do
	Vermilion:AddHook(k[1], "Vermilion_CheckLimit" .. k[1], false, function(vplayer)
		if(not IsValid(vplayer)) then return end
		if(not vplayer:CheckLimit(k[2])) then return false end
	end)
end




--[[

	//		Stat Updating	\\

]]--
timer.Create("V-UpdatePlaytime", 5, 0, function()
	for i,k in pairs(VToolkit.GetValidPlayers(false)) do
		local vdata = Vermilion:GetUser(k)
		if(vdata == nil) then
			Vermilion.Log("Cannot update playtime; the management engine is missing userdata...")
			return
		end
		vdata.Playtime = vdata.Playtime + 5
	end
end)
