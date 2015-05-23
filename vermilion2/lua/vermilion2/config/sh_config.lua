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
Vermilion.Drivers = {}
Vermilion.Data = {}

if(SERVER) then
	CreateConVar("vermilion2_driver", "Data")
end

function Vermilion:RegisterDriver(name, driver)
	self.Drivers[name] = driver
	self.Log("Registered driver \"" .. name .. "\"!")
end

function loadDrivers()
	local f,d = file.Find("vermilion2/config/drivers/*", "LUA")
	for i,k in pairs(d) do
		include("vermilion2/config/drivers/" .. k .. "/driver_sh.lua")
	end
end

function Vermilion:GetDriver()
	if(CLIENT) then return self.Drivers["Data"] end
	return self.Drivers[GetConVarString("vermilion2_driver")]
end

loadDrivers()



--[[

	//		Ranks		\\

]]--

function Vermilion:GetDefaultRank()
	if(SERVER) then
		local duid = ""
		if(Vermilion:HasRank("player")) then
			duid = Vermilion:GetRank("player"):GetUID()
		end
		duid = self:GetData("default_rank", duid, true)
		if(VToolkit:GetGlobalValue("default_rank") != duid) then VToolkit:SetGlobalValue("default_rank", duid) end
		return duid
	end
	return VToolkit:GetGlobalValue("default_rank")
end

function Vermilion:GetRank(name) -- this is now only to get ranks from player inputs, not used in the code (unless obtaining owner). Use GetRankByID instead!
	return self:GetDriver():GetRank(name)
end

function Vermilion:GetRankByID(id)
	return self:GetDriver():GetRankByID(id)
end

function Vermilion:HasRank(name)
	return self:GetDriver():HasRank(name)
end

function Vermilion:HasRankID(id)
	return self:GetDriver():HasRankID(id)
end



--[[

	//		Users		\\

]]--

function Vermilion:GetUser(vplayer)
	if(CLIENT and vplayer:GetNWString("SteamID") != nil) then
		return self:GetUserBySteamID(vplayer:GetNWString("SteamID"))
	end
	return self:GetDriver():GetUser(vplayer)
end

function Vermilion:GetUserByName(name)
	return self:GetDriver():GetUserByName(name)
end

function Vermilion:GetUserBySteamID(steamid)
	return self:GetDriver():GetUserBySteamID(steamid)
end

function Vermilion:HasUser(vplayer)
	return self:GetDriver():HasUser(vplayer)
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
	return self:GetDriver():GetData(name, default, set)
end

function Vermilion:SetData(name, value)
	self:GetDriver():SetData(name, value)
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

function Vermilion:GetModuleData(mod, name, def, set)
	return self:GetDriver():GetModuleData(mod, name, def, set)
end

function Vermilion:SetModuleData(mod, name, val)
	self:GetDriver():SetModuleData(mod, name, val)
end

function Vermilion:TriggerDataChangeHooks(mod, name)
	local modStruct = Vermilion:GetModule(mod)
	if(modStruct != nil) then
		if(modStruct.DataChangeHooks != nil) then
			if(modStruct.DataChangeHooks[name] != nil) then
				local data = self:GetModuleData(mod, name)
				for index,DCHook in pairs(modStruct.DataChangeHooks[name]) do
					DCHook(data)
				end
			end
		end
	end
end

Vermilion:AddHook(Vermilion.Event.MOD_LOADED, "SendDRGVAR", true, function()
	if(SERVER) then Vermilion:GetDefaultRank() end
end)