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


--[[

	//		Networking		\\

]]--

util.AddNetworkString("VBroadcastRankData")
util.AddNetworkString("VBroadcastUserData")
util.AddNetworkString("VBroadcastPermissions")
util.AddNetworkString("VUpdatePlayerLists")
util.AddNetworkString("VModuleConfig")
util.AddNetworkString("VUsePreconfigured")



--[[

	//		Ranks		\\

]]--

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

function Vermilion:BroadcastRankData(target)
	target = target or VToolkit:GetValidPlayers()
	local normalData = {}
	for i,k in pairs(self.Data.Ranks) do
		table.insert(normalData, k:GetNetPacket())
	end
	net.Start("VBroadcastRankData")
	net.WriteTable(normalData)
	net.Send(target)
end





--[[

	//		Users		\\

]]--

function Vermilion:StoreNewUserdata(vplayer)
	if(IsValid(vplayer)) then
		local usr = self:CreateUserObj(vplayer:GetName(), vplayer:SteamID(), self:GetDefaultRank(), {})
		table.insert(self.Data.Users, usr)
	end
end

function Vermilion:BroadcastActiveUserData(target)
	target = target or VToolkit:GetValidPlayers()
	local steamid = nil
	if(not istable(target)) then steamid = target:SteamID() end
	local normalData = {}
	for i,k in pairs(self.Data.Users) do
		if(not k:IsOnline() and k.SteamID != steamid) then continue end
		table.insert(normalData, k:GetNetPacket())
	end
	net.Start("VBroadcastUserData")
	net.WriteString(steamid or "")
	net.WriteTable(normalData)
	net.Send(target)
end



--[[

	//		Data Storage		\\

]]--

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
		Vermilion:CreateRankObj("admin", nil, false, Color(255, 93, 0), "shield"),
		Vermilion:CreateRankObj("player", nil, false, Color(0, 161, 255), "user"),
		Vermilion:CreateRankObj("guest", { "chat" }, false, Color(255, 255, 255), "user_orange")
	}
end

net.Receive("VUsePreconfigured", function(len, vplayer)
	if(not Vermilion:HasPermission(vplayer, "*")) then return end

	local coowner = Vermilion:CreateRankObj("co-owner", nil, false, Color(0, 63, 255), "key")
	local manager = Vermilion:CreateRankObj("server manager", nil, false, Color(0, 255, 255), "cog")
	local sadmin = Vermilion:CreateRankObj("super admin", nil, false, Color(255, 0, 97), "shield_add")
	local donator = Vermilion:CreateRankObj("donator", nil, false, Color(191, 127, 255), "heart")
	local respected = Vermilion:CreateRankObj("respected", nil, false, Color(255, 191, 0), "user_red")
	local owner = Vermilion.Data.Ranks[1]
	local admin = Vermilion.Data.Ranks[2]
	local pplayer = Vermilion.Data.Ranks[3]
	local guest = Vermilion.Data.Ranks[4]
	Vermilion.Data.Ranks = {
		owner,
		coowner,
		manager,
		sadmin,
		admin,
		donator,
		respected,
		pplayer,
		guest
	}

	Vermilion:GetRank("player").InheritsFrom = Vermilion:GetRank("guest"):GetUID()
	Vermilion:GetRank("respected").InheritsFrom = Vermilion:GetRank("player"):GetUID()
	Vermilion:GetRank("donator").InheritsFrom = Vermilion:GetRank("respected"):GetUID()
	Vermilion:GetRank("admin").InheritsFrom = Vermilion:GetRank("donator"):GetUID()
	Vermilion:GetRank("super admin").InheritsFrom = Vermilion:GetRank("admin"):GetUID()
	Vermilion:GetRank("server manager").InheritsFrom = Vermilion:GetRank("super admin"):GetUID()
	Vermilion:GetRank("co-owner").InheritsFrom = Vermilion:GetRank("server manager"):GetUID()

	local nranks = {
		"respected",
		"donator",
		"super admin",
		"server manager",
		"co-owner"
	}

	for irank,nrank in pairs(nranks) do
		local rankData = Vermilion:GetRank(nrank)
		for imod,mod in pairs(Vermilion.Modules) do
			for imodrank, modrank in pairs(mod.DefaultPermissions) do
				if(modrank.Name == nrank) then
					for i1,k1 in pairs(modrank.Permissions) do
						rankData:AddPermission(k1)
					end
				end
			end
		end
	end

	Vermilion:BroadcastRankData()
end)

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
		print("FIRST RUN!")
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
	Vermilion:BroadcastRankData(vplayer)
	net.Start("VBroadcastPermissions")
	net.WriteTable(Vermilion.AllPermissions)
	net.Send(vplayer)
	Vermilion:BroadcastActiveUserData(vplayer)

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
			Vermilion:BroadcastNotify("config:join:first", { vplayer:GetName() })
		else
			Vermilion:BroadcastNotify("config:join", { vplayer:GetName() })
		end
	end)
end)

gameevent.Listen("player_disconnect")

Vermilion:AddHook("player_disconnect", "DisconnectMessage", true, function(data)
	if(not Vermilion:GetData("joinleave_enabled", true, true)) then return end
	if(string.find(data.reason, "Kicked by")) then return end
	Vermilion:BroadcastNotify("config:left", { data.name, data.reason })
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
				hook.Run(Vermilion.Event.AnythingSpawned, vplayer, ent)
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


--[[

	//		Autoconfigure Nag 	  \\

	Yeah, sorry about this. I was told to add it. *grumble*
]]--

util.AddNetworkString("Vermilion_AutoconfigureNag")

Vermilion:AddHook(Vermilion.Event.PlayerChangeRank, "core:autoconfigure", true, function(vplayerObj, old, new)
	if(Vermilion:GetData("done_autoconfigure_nag", false, true)) then return end
	local ownerRank = Vermilion:GetRank("owner")
	if(old != ownerRank.UniqueID and new == ownerRank.UniqueID) then
		if(table.Count(ownerRank:GetUserObjects()) != 1) then return end
		local target = VToolkit.LookupPlayer(vplayerObj.Name)
		if(IsValid(target)) then
			net.Start("Vermilion_AutoconfigureNag")
			net.Send(target)
			Vermilion:SetData("done_autoconfigure_nag", true)
		end
	end
end)

Vermilion:AddHook("PlayerInitialSpawn", "core:autoconfigure", true, function(vplayer)
	if(Vermilion:GetData("done_autoconfigure_nag", false, true)) then return end
	local ownerRank = Vermilion:GetRank("owner")
	if(Vermilion:GetUser(vplayer) == nil) then return end
	if(ownerRank == nil) then return end
	if(Vermilion:GetUser(vplayer):GetRankUID() == ownerRank.UniqueID) then
		if(table.Count(ownerRank:GetUserObjects()) == 1) then
			net.Start("Vermilion_AutoconfigureNag")
			net.Send(vplayer)
			Vermilion:SetData("done_autoconfigure_nag", true)
		end
	end
end)
