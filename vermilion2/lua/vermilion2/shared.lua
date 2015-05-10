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

Vermilion.Languages = {}
Vermilion.Modules = {}

Vermilion.CoreAddon = {
	APIFuncs = {

	}
}

--[[

	//		Languages		\\

]]--

function Vermilion.GetActiveLanguage(vplayer)
	if((not IsValid(vplayer) or vplayer:SteamID() == "CONSOLE") and SERVER) then return Vermilion:GetData("global_lang", "English", true) end
	if(SERVER and vplayer.GetInfo != nil) then return vplayer:GetInfo("vermilion_interfacelang") end
	if(SERVER) then return "English" end
	return GetConVarString("vermilion_interfacelang")
end

function Vermilion.GetActiveLanguageFile(forplayer)
	if(Vermilion.Languages[Vermilion.GetActiveLanguage(forplayer)] != nil) then
		return Vermilion.Languages[Vermilion.GetActiveLanguage(forplayer)]
	end
	if(Vermilion.Languages["English"] != nil) then return Vermilion.Languages["English"] end
	return {}
end

function Vermilion:CreateLangBody(locale)

	local body = {}

	body.Locale = locale
	body.DateTimeFormat = "%I:%M:%S %p on %d/%m/%Y"
	body.ShortDateTimeFormat = "%d/%m/%y %H:%M:%S"
	body.DateFormat = "%d/%m/%Y"
	body.TimeFormat = "%I:%M:%S %p"

	body.Translations = {}

	function body:Add(key, value)
		self.Translations[key] = value
	end

	function body:TranslateStr(key, values, short)
		if(not istable(values)) then return key end
		if(self.Translations[key] == nil) then
			//if(not short) then Vermilion.Log("[WHINE] Language file '" .. body.Locale .. " is missing translation for " .. key .. " please fix!") end
			return key
		end
    if(table.Count(values) != VToolkit.Count_Substring(self.Translations[key], "%s")) then
      Vermilion.Log("Oops... Something called for a translation of " .. key .. " but did not provide enough filler parameters...")
      return key
    end
		return string.format(self.Translations[key], unpack(values))
	end

	return body

end

function Vermilion:RegisterLanguage(body)
	self.Languages[body.Locale] = body
end

function Vermilion:TranslateStr(key, values, forplayer)
	if(CLIENT and forplayer == nil) then forplayer = LocalPlayer() end
	if(self.Languages[self.GetActiveLanguage(forplayer)] != nil) then
		local translation = self.GetActiveLanguageFile(forplayer):TranslateStr(key, values or {})
		if(translation != key or self.Languages["English"] == nil) then return translation end
		return self.Languages["English"]:TranslateStr(key, values or {})
	end
	return key
end

function Vermilion:LoadLanguages()
	for i,langFile in pairs(file.Find("vermilion2/lang/*.lua", "LUA")) do
		self.Log("Compiling language file: vermilion2/lang/" .. langFile)
		local compiled = CompileFile("vermilion2/lang/" .. langFile)
		if(isfunction(compiled)) then
			AddCSLuaFile("vermilion2/lang/" .. langFile)
			compiled()
		else
			self.Log("Failed to compile language file vermilion2/lang/" .. langFile)
		end
	end
end

Vermilion:LoadLanguages()

if(CLIENT) then
	CreateClientConVar("vermilion_interfacelang", "English", true, true)
end


--[[

	//		Client Startup		\\

]]--

if(SERVER) then
	util.AddNetworkString("Vermilion_ClientStart")

	Vermilion:AddHook("PlayerInitialSpawn", "SendVermilionActivate", true, function(ply)
		net.Start("Vermilion_ClientStart")
		net.WriteTable(Vermilion:GetData("addon_load_states", {}, true))
		net.Send(ply)
	end)
else
	net.Receive("Vermilion_ClientStart", function()
		if(Vermilion.AlreadyStarted) then return end
		Vermilion.AlreadyStarted = true
		local tab = net.ReadTable()
		timer.Simple(1, function() Vermilion:LoadModules(tab) end)
	end)
end





--[[
	//		Module Loading		\\
]]--

function Vermilion:LoadModules(cl_loaddata)
	if(CLIENT) then
		Vermilion.ModuleLoadData = cl_loaddata
	end
	self.Log("Loading modules...")
	local files,dirs = file.Find("vermilion2/modules/*", "LUA")
	for index,dir in pairs(dirs) do
		if(file.Exists("vermilion2/modules/" .. dir .. "/init.lua", "LUA")) then
			local fle = CompileFile("vermilion2/modules/" .. dir .. "/init.lua")
			if(isfunction(fle)) then
				if(SERVER) then AddCSLuaFile("vermilion2/modules/" .. dir .. "/init.lua") end
				MODULE = self:CreateBaseModule()
				xpcall(fle, function(err)
					Vermilion.Log("Error loading module: " .. err)
					debug.Trace()
				end)
				Vermilion:RegisterModule(MODULE)
				MODULE = nil
			end
		end
	end
	for index,mod in pairs(self.Modules) do
		if(SERVER) then
			if(Vermilion:GetData("addon_load_states", {}, true)[mod.ID] == nil and mod.StartDisabled) then
				Vermilion:GetData("addon_load_states", {}, true)[mod.ID] = false
			end
			if(Vermilion:GetData("addon_load_states", {}, true)[mod.ID] == false and not mod.PreventDisable) then
				continue
			end
		end
		if(CLIENT) then
			if(cl_loaddata[mod.ID] == false and not mod.PreventDisable) then
				continue
			end
		end
		mod:InitShared()
		if(SERVER) then
			mod:InitServer()
		else
			mod:InitClient()
		end
		mod:RegisterChatCommands()
	end
	hook.Run(Vermilion.Event.MOD_LOADED)
	hook.Run(Vermilion.Event.MOD_POST)
end

function Vermilion:RegisterModule(mod)
	self.Modules[mod.ID] = mod
	if(SERVER) then
		for i,k in pairs(mod.Permissions) do
			table.insert(self.AllPermissions, { Permission = k, Owner = mod.ID })
		end
		if(self.FirstRun and mod.DefaultPermissions != nil) then
			for i,k in pairs(mod.DefaultPermissions) do
				local rank = Vermilion:GetRank(k.Name)
				if(rank != nil) then
					for i1,k1 in pairs(k.Permissions) do
						rank:AddPermission(k1)
					end
				end
			end
		end
		if(mod.NetworkStrings != nil and table.Count(mod.NetworkStrings) > 0) then
			util.AddNetworkString("V:" .. mod.ID)
			net.Receive("V:" .. mod.ID, function(len, vplayer)
				mod:DidGetNetStr(net.ReadString(), vplayer)
			end)
		end
	else
		if(mod.NetworkStrings != nil and table.Count(mod.NetworkStrings) > 0) then
			net.Receive("V:" .. mod.ID, function()
				mod:DidGetNetStr(net.ReadString())
			end)
		end
	end
	if(mod.ConVars != nil) then
		if(SERVER and mod.ConVars.Server != nil) then
			for i,k in pairs(mod.ConVars.Server) do
				local flags = k.Flags or {}
				CreateConVar(k.Name, k.Value, flags, k.HelpText)
			end
		end
		if(CLIENT and mod.ConVars.Client != nil) then
			for i,k in pairs(mod.ConVars.Client) do
				CreateClientConVar(k.Name, k.Value, k.Keep or true, k.Userdata or false)
			end
		end
	end
end

function Vermilion:GetModule(name)
	if(SERVER and Vermilion:GetData("addon_load_states", {}, true)[name] == false) then return end
	if(CLIENT and Vermilion.ModuleLoadData[name] == false) then return end
	return self.Modules[name]
end

if(SERVER) then
	util.AddNetworkString("VModuleDataEnableChange")
	util.AddNetworkString("VModuleDataUpdate")

	net.Receive("VModuleDataUpdate", function(len, vplayer)
		local mod = net.ReadString()
		net.Start("VModuleDataUpdate")
		net.WriteString(mod)
		net.WriteBoolean(Vermilion:GetData("addon_load_states", {}, true)[mod] != false)
		net.Send(vplayer)
	end)

	net.Receive("VModuleDataEnableChange", function(len, vplayer)
		if(Vermilion:HasPermission(vplayer, "*")) then
			local mod = net.ReadString()
			Vermilion:GetData("addon_load_states", {}, true)[mod] = net.ReadBoolean()
		end
	end)

	util.AddNetworkString("VPlayerInitialSpawn")

	Vermilion:AddHook("PlayerInitialSpawn", "VClientNotify", true, function(vplayer)
		net.Start("VPlayerInitialSpawn")
		net.WriteTable({vplayer:GetName(), vplayer:SteamID(), Vermilion:GetUser(vplayer):GetRankName(), vplayer:EntIndex()})
		net.Broadcast()
	end)
else
	net.Receive("VPlayerInitialSpawn", function()
		hook.Run("VPlayerInitialSpawn", unpack(net.ReadTable()))
	end)
end




--[[

	//		Duplicator Hacks		\\

]]--
if(SERVER) then
	local oldDupePaste = duplicator.Paste

	function duplicator.Paste(vplayer, entlist, constraints)
		local entlist2 = {}
		local count = 0
		for i,k in pairs(entlist) do
			if(hook.Run("Vermilion_IsEntityDuplicatable", vplayer, k.Class, k.Model) != false) then
				entlist2[i] = k
			else
				count = count + 1
			end
		end

		if(count > 0) then Vermilion:AddNotify(vplayer, NOTIFY_ERROR, "Removed " .. tostring(count) .. " banned entities from this duplication.") end

		return oldDupePaste(vplayer, entlist2, constraints)
	end
end