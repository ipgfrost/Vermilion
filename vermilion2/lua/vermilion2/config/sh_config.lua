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

	//		Ranks		\\

]]--

function Vermilion:GetDefaultRank()
	local duid = ""
	if(Vermilion:HasRank("player")) then
		if(SERVER) then
			duid = Vermilion:GetRank("player"):GetUID()
		end
	end
	if(SERVER) then
		duid = self:GetData("default_rank", duid)
		if(VToolkit:GetGlobalValue("default_rank") != duid) then VToolkit:SetGlobalValue("default_rank", duid) end
		return duid
	end
	return VToolkit:GetGlobalValue("default_rank")
end

function Vermilion:GetRank(name) -- this is now only to get ranks from player inputs, not used in the code (unless obtaining owner). Use GetRankByID instead!
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

function Vermilion:GetUser(vplayer)
	if(not isfunction(vplayer.SteamID)) then
		return
	end
	if(CLIENT and vplayer:GetNWString("SteamID") != nil) then
		return Vermilion:GetUserBySteamID(vplayer:GetNWString("SteamID"))
	end
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
	if(vplayer != nil and permission == nil and isstring(vplayer)) then
		permission = vplayer
		vplayer = Vermilion.Data.LocalSteamID
	end
	if(permission != "*") then
		local has = false
		for i,k in pairs(self.AllPermissions) do
			if(k.Permission == permission) then has = true break end
		end
		if(not has) then
			Vermilion.Log(Vermilion:TranslateStr("config:unknownpermission", { permission }))
		end
	end
	if(not isstring(vplayer)) then
		if(SERVER and not IsValid(vplayer)) then
			Vermilion.Log(Vermilion:TranslateStr("config:invaliduser"))
			return true
		elseif(CLIENT) then
			return false
		end
	end
	local usr = nil
	if(isstring(vplayer)) then
		usr = self:GetUserBySteamID(vplayer)
	else
		usr = self:GetUser(vplayer)
	end
	if(usr != nil) then
		return usr:HasPermission(permission)
	end
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