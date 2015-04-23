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

	//		Hooks		\\

]]--

Vermilion.Hooks = {}
Vermilion.SafeHooks = {}
Vermilion.LowPriorityHooks = {}
Vermilion.SelfDestructHooks = {
	Vermilion.Event.MOD_LOADED,
	Vermilion.Event.MOD_POST
}

function Vermilion:AddSDHookType(name)
	table.insert(self.SelfDestructHooks, name)
end

function Vermilion:AddHook(hookType, hookName, safe, callback)
	if(safe) then
		if(self.SafeHooks[hookType] == nil) then self.SafeHooks[hookType] = {} end
		self.SafeHooks[hookType][hookName] = callback
		return
	end
	if(self.Hooks[hookType] == nil) then self.Hooks[hookType] = {} end
	self.Hooks[hookType][hookName] = callback
end

function Vermilion:DelHook(hookType, hookName, safe)
	if(safe) then
		if(self.SafeHooks[hookType] == nil) then return end
		self.SafeHooks[hookType][hookName] = nil
		return
	end
	if(self.Hooks[hookType] == nil) then return end
	self.Hooks[hookType][hookName] = nil
end

function Vermilion:AddLPHook(hookType, hookName, callback)
	if(self.LowPriorityHooks[hookType] == nil) then self.LowPriorityHooks[hookType] = {} end
	self.LowPriorityHooks[hookType][hookName] = callback
end

function Vermilion:DelLPHook(hookType, hookName)
	if(self.LowPriorityHooks[hookName] == nil) then return end
	self.LowPriorityHooks[hookType][hookName] = nil
end


hook.oldHook = hook.Call

local function destroySDHook(name)
	if(table.HasValue(Vermilion.SelfDestructHooks, name)) then
		Vermilion.Log({"Performing self-destruct on hook: ", Vermilion.Colours.Blue, name})
		Vermilion.SafeHooks[name] = nil
		Vermilion.Hooks[name] = nil
		for i,k in pairs(Vermilion.Modules) do
			k.Hooks[name] = nil
		end
		Vermilion.LowPriorityHooks[name] = nil
		hook.GetTable()[name] = nil
	end
end

local vHookCall = function(evtName, gmTable, ...)
	//if(evtName == "GetFallDamage" or evtName == "EntityTakeDamage") then print("HOOK: ", evtName, ...) end
	local a, b, c, d, e, f
	if(Vermilion.SafeHooks[evtName] != nil) then
		for id,hookFunc in pairs(Vermilion.SafeHooks[evtName]) do
			hookFunc(...)
		end
	end
	if(Vermilion.Hooks[evtName] != nil) then
		for id,hookFunc in pairs(Vermilion.Hooks[evtName]) do
			a, b, c, d, e, f = hookFunc(...)
			if(a != nil) then
				//print("HOOK", id, " RETURNED!")
				destroySDHook(evtName)
				return a, b, c, d, e, f
			end
		end
	end
	for i,mod in pairs(Vermilion.Modules) do
		a, b, c, d, e, f = mod:DistributeEvent(evtName, ...)
		if(a != nil) then
			//print("MODULE", mod.Name, "RETURNED DISTRIBUTED EVENT!")
			destroySDHook(evtName)
			return a, b, c, d, e, f
		end
		if(mod.Hooks != nil) then
			local hookList = mod.Hooks[evtName]
			if(hookList != nil) then
				for i,hookFunc in pairs(hookList) do
					a, b, c, d, e, f = hookFunc(...)
					if(a != nil) then
						//print("MODULE", mod.Name, "RETURNED STANDARD HOOK!")
						destroySDHook(evtName)
						return a, b, c, d, e, f
					end
				end
			end
		end
	end
	local vars = { ... }
	if(not xpcall(function()
		a,b,c,d,e,f = hook.oldHook(evtName, gmTable, unpack(vars))
	end, function(err)
		hook.Run("OnLuaError") -- bring up the standard "script errors" notification.
		Vermilion.Log("An error has been detected in the base GMod hook system. This most likely has nothing to do with Vermilion.")
		print(err)
		debug.Trace()
	end)) then return end



	if(a != nil) then
		destroySDHook(evtName)
		return a, b, c, d, e, f
	end
	for i,mod in pairs(Vermilion.Modules) do
		if(mod.LPHooks != nil) then
			local hookList = mod.LPHooks[evtName]
			if(hookList != nil) then
				for i,hookFunc in pairs(hookList) do
					a, b, c, d, e, f = hookFunc(...)
					if(a != nil) then
						//print("MODULE", mod.Name, "RETURNED LP HOOK!")
						return a, b, c, d, e, f
					end
				end
			end
		end
	end
	if(Vermilion.LowPriorityHooks[evtName] != nil) then
		for id,hookFunc in pairs(Vermilion.LowPriorityHooks[evtName]) do
			a, b, c, d, e, f = hookFunc(...)
			if(a != nil) then
				destroySDHook(evtName)
				return a, b, c, d, e, f
			end
		end
	end
	destroySDHook(evtName) -- one last attempt to destroy the hook.
end

hook.Call = vHookCall

-- hax to allow other addons with chat commands to run properly.

hook.oHookA = hook.Add
local vHookAdd = function(evt, name, func)
	if(evt == "PlayerSay") then
		hook.oHookA("VPlayerSay", name, func)
	else
		hook.oHookA(evt, name, func)
	end
end
hook.Add = vHookAdd

hook.oHookR = hook.Remove
local vHookRemove = function(evt, name)
	if(evt == "PlayerSay") then
		hook.oHookR("VPlayerSay", name)
	else
		hook.oHookR(evt, name)
	end
end
hook.Remove = vHookRemove


if(hook.GetTable()["PlayerSay"] != nil) then
	hook.GetTable()["VPlayerSay"] = hook.GetTable()["PlayerSay"]
	hook.GetTable()["PlayerSay"] = nil
end

Vermilion.DHOStarted = false

local function doHookOverride()
	if(hook.Call != vHookCall) then
		hook.Call = vHookCall
	end
	if(hook.Add != vHookAdd) then
		hook.Add = vHookAdd
	end
	if(hook.Remove != vHookRemove) then
		hook.Remove = vHookRemove
	end
	if(not isfunction(doHookOverride)) then
		Vermilion.Log("Hook override loop failed. This isn't bad. It's just a protection measure put in place to stop startup bugs.")
		return
	end
	timer.Simple(1, doHookOverride)
end
if(not Vermilion.DHOStarted) then
	doHookOverride()
	Vermilion.DHOStarted = true
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

function Vermilion:CreateBaseModule()
	if(Vermilion.ModuleBase == nil) then
		local base = {}
		base.Name = "Base Module"
		base.ID = "BaseModule"
		base.Description = "The author of this module doesn't know how to customise the module data. Get rid of it!"
		base.Author = "n00b"


		function base:InitClient() end
		function base:InitServer() end
		function base:InitShared() end
		function base:Destroy() end

		function base:RegisterChatCommands() end

		function base:GetAllData()
			return Vermilion.Data.Module[self.ID] or {}
		end

		function base:GetData(name, default, set)
			if(Vermilion.Data.Module[self.ID] == nil) then Vermilion.Data.Module[self.ID] = {} end
			if(Vermilion.Data.Module[self.ID][name] == nil) then
				if(set) then self:SetData(name, default) end
				return default
			end
			return Vermilion:GetModuleData(self.ID, name, default)
		end

		function base:SetData(name, value)
			Vermilion:SetModuleData(self.ID, name, value)
		end

		function base:AddDataChangeHook(dataName, hookName, cHook)
			if(self.DataChangeHooks[dataName] == nil) then self.DataChangeHooks[dataName] = {} end
			self.DataChangeHooks[dataName][hookName] = cHook
		end

		function base:RemoveDataChangeHook(dataName, hookName)
			if(self.DataChangeHooks[dataName] == nil) then return end
			self.DataChangeHooks[dataName][hookName] = nil
		end

		function base:AddHook(evtName, id, func)
			if(func == nil) then
				func = id
				id = evtName
			end
			if(self.Hooks[evtName] == nil) then
				self.Hooks[evtName] = {}
			end
			self.Hooks[evtName][id] = func
		end

		function base:RemoveHook(evtName, id)
			if(self.Hooks[evtName] != nil) then
				self.Hooks[evtName][id] = nil
			else

			end
		end

		function base:AddLPHook(evtName, id, func)
			if(func == nil) then
				func = id
				id = evtName
			end
			if(self.LPHooks[evtName] == nil) then self.LPHooks[evtName] = {} end
			self.LPHooks[evtName][id] = func
		end

		function base:RemoveLPHook(evtName, id)
			if(self.LPHooks[evtName] != nil) then
				self.LPHooks[evtName][id] = nil
			end
		end

		function base:NetHook(nstr, func)
			self.NetworkHooks[nstr] = func
		end

		function base:NetStart(msg)
			net.Start("V:" .. self.ID)
			net.WriteString(msg)
		end

		function base:NetCommand(msg, target)
			net.Start("V:" .. self.ID)
			net.WriteString(msg)
			if(SERVER) then
				net.Send(target)
			else
				net.SendToServer()
			end
		end

		function base:DidGetNetStr(str, vplayer)
			if(self.NetworkHooks[str] != nil) then
				self.NetworkHooks[str](vplayer)
			end
		end

		function base:TranslateStr(key, parameters, foruser)
			local translation = Vermilion:TranslateStr(self.ID .. ":" .. key, parameters, foruser)
			if(translation != self.ID .. ":" .. key) then return translation end
			return Vermilion:TranslateStr(key, parameters, foruser, true)
		end

		function base:TranslateTable(keys, parameters, foruser)
			local tab = {}
			parameters = parameters or {}
			for i,k in pairs(keys) do
				tab[i] = self:TranslateStr(k, parameters[i], foruser)
			end
			return tab
		end

		function base:DistributeEvent(event, parameters) end

		Vermilion.ModuleBase = base
	end

	local base = {}
	base.Hooks = {}
	base.LPHooks = {}
	base.Localisations = {}
	base.Permissions = {}
	base.PermissionDefinitions = {}
	base.DataChangeHooks = {}
	base.NetworkHooks = {}

	setmetatable(base, { __index = Vermilion.ModuleBase })

	base:AddHook("VDefinePermission", function(permission)
		if(base.PermissionDefinitions[permission] != nil) then return base.PermissionDefinitions[permission] end
	end)

	return base
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



--[[

	//		Notifications		\\

]]--

--[[
	GENERIC = Blue ("Exclamation")
	ERROR = Red ("Error Triangle")
	HINT = Green ("Help Orb")
]]--

Vermilion:AddHook(Vermilion.Event.MOD_LOADED, "AddJoinLeaveOption", true, function()
	local mod = Vermilion:GetModule("server_settings")
	if(mod != nil) then
		mod:AddOption({
			Module = "Vermilion",
			Name = "joinleave_enabled",
			GuiText = Vermilion:TranslateStr("config:joinleave_enabled"),
			Type = "Checkbox",
			Category = "Misc",
			Default = true
			})
	end
end)

if(CLIENT) then
	local notifications = {}

	local notifybg = nil

	timer.Simple(1, function()
		notifybg = vgui.Create("DPanel")
		notifybg:SetDrawBackground(false)
		notifybg:SetPos(ScrW() - 298, 100)
		notifybg:SetSize(300, ScrH() + 100)


	end)


	timer.Create("VOrganiseNotify", 0.1, 0, function()
		local currentY = 0
		for i,k in pairs(notifications) do
			if(IsValid(k)) then
				k.OldIY = k.IntendedY
				k.IntendedY = (currentY + (k.MaxH / 2))
				if(k.OldIY != k.IntendedY and k.DoneMain) then
					local mt = k.IntendedY - (k.MaxH / 2)
					k:MoveTo(k:GetX(), mt, 0.2, 0, -3)
				end
				currentY = currentY + (k.MaxH + 5)
			end
		end
	end)

	local function DrawErrorSign( x, y, w, h )
		local clr = ( CurTime() % 0.8 > 0.2 ) and Vermilion.Colours.Red or Color( 0, 0, 0, 0 )
		surface.SetDrawColor( clr )
		surface.SetTextColor( clr )
		surface.DrawLine( x, y + h, x + w / 2, y )
		surface.DrawLine( x + w, y + h, x + w / 2, y )
		surface.DrawLine( x + w, y + h, x, y + h )
		surface.SetFont( 'DermaDefaultBold' )
		if(system.IsOSX()) then
			surface.SetTextPos( (x + w / 2) - 2.75, y + h / 3 )
		else
			surface.SetTextPos( (x + w / 2) - 0.25, y + h / 3 )
		end
		surface.DrawText( '!' )
	end

	local function DrawNoteSign( x, y, w, h )
		surface.SetTextColor( 100, 150, 255, 255 * math.Clamp( math.sin( CurTime() * 4 ), 0.5, 1 ) )
		surface.SetFont( 'DermaLarge' )
		if(system.IsOSX()) then
			surface.SetTextPos( x + w / 2 - surface.GetTextSize( '!' ) / 2, y - 2)
		else
			surface.SetTextPos( x + w / 2 - surface.GetTextSize( '!' ) / 2, y )
		end
		surface.DrawText( '!' )
	end

	local function DrawHintSign(x, y, w, h)
		surface.SetTextColor( 50, 255, 50, 255 * math.Clamp(math.sin(CurTime() * 4), 0.5, 1))
		surface.SetFont('DermaLarge')
		if(system.IsOSX()) then
			surface.SetTextPos( x + w / 2 - surface.GetTextSize( '?' ) / 2, y - 2 )
		else
			surface.SetTextPos( x + w / 2 - surface.GetTextSize( '?' ) / 2, y )
		end
		surface.DrawText("?")
	end

	local function breakNotification(text, max)
		local wordsBuffer = {}
		local lines = {}

		local u = string.Split(text, " ")
		local f = {}
		for i,k in pairs(u) do
			local m = string.Split(k, "\n")
			local j = {}
			for q,r in pairs(m) do
				table.insert(j, r)
				table.insert(j, "\n")
			end
			table.remove(j, table.Count(j))
			table.Add(f, j)
		end

		for i,word in ipairs(f) do -- iterate over words
			local w, h = surface.GetTextSize(table.concat(wordsBuffer, " "))
			if (w > max or word == "\n") then
				table.insert(lines, table.concat(wordsBuffer, " "))
				table.Empty(wordsBuffer)
				if(word != "\n") then table.insert(wordsBuffer, word) end
			elseif(word != "\n") then
				table.insert(wordsBuffer, word)
			end
		end

		if (table.Count(wordsBuffer) > 0) then
			table.insert(lines, table.concat(wordsBuffer, " "))
		end

		return lines
	end

	local function buildNotify(text, typ)
		local notify = vgui.Create("DPanel")
		notify:DockMargin(0, 0, 0, 5)

		surface.SetFont('DermaDefaultBold')
		local size = select(2, surface.GetTextSize("Vermilion")) + 3
		surface.SetFont("DermaDefault")
		local data = breakNotification(text, 220)
		for i,k in pairs(data) do
			if(k == "\n") then continue end
			size = size + select(2, surface.GetTextSize(k)) + 1
		end
		notify.MaxW = 300
		notify.MaxH = size + 5
		notify:SetSize(0, 0)

		notify.TYPE = typ or NOTIFY_GENERIC
		notify.TEXT = data

		notify.Paint = function( self, w, h )
			surface.SetDrawColor( 5, 5, 5, 220 )
			surface.DrawRect( 0, 0, w, h )
			local iconsize = h - 10
			if(self.TYPE == NOTIFY_ERROR) then DrawErrorSign( w - 30, 5, 20, 20 ) surface.SetDrawColor( Vermilion.Colours.Red ) surface.SetTextColor( Vermilion.Colours.Red ) end
			if(self.TYPE == NOTIFY_GENERIC) then DrawNoteSign( w - 30, 2, 20, 20 ) surface.SetDrawColor( 100, 150, 255, 255 ) surface.SetTextColor( 100, 150, 255, 255 ) end
			if(self.TYPE == NOTIFY_HINT) then DrawHintSign( w - 30, 2, 20, 20 ) surface.SetDrawColor( 50, 255, 50, 255) surface.SetTextColor( 50, 255, 50, 255) end
			surface.DrawOutlinedRect( 0, 0, w, h )

			surface.SetTextPos( 5, 2 )
			surface.SetFont( 'DermaDefaultBold' )
			surface.DrawText( 'Vermilion' )

			local offset = 1
			surface.SetTextPos( 5, select(2, surface.GetTextSize("Vermilion")) + 4)
			surface.SetFont( 'DermaDefault' )
			for i,k in pairs(data) do
				if(k == "\n") then continue end
				surface.SetTextPos( 5, select(2, surface.GetTextSize("Vermilion")) + 3 + (select(2, surface.GetTextSize(data[1])) * (i - 1)))
				surface.DrawText(k)
			end

		end

		return notify
	end

	function Vermilion:AddNotification(text, typ, time)
		if(notifybg == nil) then
			Vermilion.Log("Warning: notification area not initialised while sending notification: " .. text)
			return
		end
		local notify = buildNotify(text, typ)
		notify.IntendedX = 300
		local stser = 0
		for i,k in pairs(notifybg:GetChildren()) do
			stser = stser + k.MaxH + 5
		end
		--if(table.Count(notifybg:GetChildren()) != 0) then
			stser = stser - 5
		--end
		notify.IntendedY = stser + (notify.MaxH / 2)
		notify:SetParent(notifybg)
		table.insert(notifications, notify)

		local anim = VToolkit:CreateNotificationAnimForPanel(notify)
		local finished = false
		local animData = {
			Pos = -1,
			OnlyOne = table.Count(notifybg:GetChildren()) == 1,
			NotifyPanel = notifybg,
			Callback = function()
				finished = true
				notify.DoneMain = true
				timer.Simple(time or 10, function()
					if(not IsValid(notify) or not table.HasValue(notifications, notify)) then return end
					notify:AlphaTo(0, 2, 0, function()
						table.RemoveByValue(notifications, notify)
						notify:Remove()
					end)
				end)
			end
		}

		notify.AnimationThink = function()
			if(not finished) then anim:Run() else notify.AnimationThink = nil end
		end

		anim:Start(3, animData)
		return function()
			notify:AlphaTo(0, 2, 0, function()
				table.RemoveByValue(notifications, notify)
				notify:Remove()
			end)
		end
	end

	function Vermilion:AddNotify(text, typ, time)
		self:AddNotification(text, typ, time)
	end

	net.Receive("VNotify", function()
		local notifyData = net.ReadTable()
		Vermilion:AddNotification(Vermilion:TranslateStr(notifyData.BaseString, notifyData.Replacements), net.ReadInt(32), net.ReadInt(32))
	end)

else
	util.AddNetworkString("VNotify")

	function Vermilion:AddNotification(recipient, baseString, replacements, typ, time)
		typ = typ or NOTIFY_GENERIC
		time = time or 10
		net.Start("VNotify")
		net.WriteTable({ BaseString = baseString, Replacements = replacements })
		net.WriteInt(typ, 32)
		net.WriteInt(time, 32)
		net.Send(recipient)
	end

	function Vermilion:AddNotify(recipient, baseString, replacements, typ, time)
		self:AddNotification(recipient, baseString, replacements, typ, time)
	end

	function Vermilion:BroadcastNotification(baseString, replacements, typ, time)
		Vermilion.Log("[Notification:Broadcast] " .. Vermilion:TranslateStr(baseString, replacements))
		self:AddNotification(VToolkit.GetValidPlayers(false), baseString, replacements, typ, time)
	end

	function Vermilion:BroadcastNotify(baseString, replacements, typ, time)
		self:BroadcastNotification(baseString, replacements, typ, time)
	end

end
