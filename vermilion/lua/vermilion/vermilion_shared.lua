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

if(SERVER) then AddCSLuaFile("vermilion/lang/vermilion_lang_engb.lua") end
include("vermilion/lang/vermilion_lang_engb.lua")

function Vermilion.GetVersion()
	return "1.11.0"
end

Vermilion.Colours = {
	White = Color(255, 255, 255),
	Black = Color(0, 0, 0),
	Red = Color(255, 0, 0),
	Green = Color(0, 128, 0),
	Blue = Color(0, 0, 255),
	Yellow = Color(255, 255, 0),
	Grey = Color(128, 128, 128)
}

function Vermilion.Colour(r, g, b, a)
	return Color(r, g, b, a)
end
Vermilion.Utility = {}

Vermilion.HookTimes = {}

function Vermilion.Utility.GetWeaponName(vclass)
	local target = vclass
	if(not isstring(target)) then -- assume it is a weapon
		target = target:GetClass()
	end
	return list.Get( "Weapon" )[target]['PrintName']
end

function Vermilion.Utility.GetNPCName(vclass)
	local target = vclass
	if(not isstring(target)) then -- assume it is an NPC
		target = target:GetClass()
	end
	return list.Get( "NPC" )[vclass]['Name']
end

function Vermilion.Utility.GetActiveLocale()
	return "en"
end

Vermilion.Extensions = {}
Vermilion.Hooks = {}
Vermilion.SafeHooks = {}
Vermilion.NetworkStrings = {}



if(not file.Exists("vermilion", "DATA")) then
	file.CreateDir("vermilion")
end


--[[
	Get the data structure for a loaded extension
	
	@param id (string) - the extension id
	
	@return extension (table:extension or nil) - the extension
]]--
function Vermilion:GetExtension(id)
	return self.Extensions[id]
end

--[[
	Used at the end of an extension to register it's data structure to Vermilion
	
	@param extension (table:extension) - the extension to register
]]--
function Vermilion:RegisterExtension(extension)
	self.Extensions[extension.ID] = extension
	if(extension.Permissions != nil and SERVER) then
		local tab = {}
		for i,k in pairs(extension.Permissions) do
			table.insert(tab, {Owner = extension.Name, Permission = k})
		end
		Crimson.Merge(self.AllPermissions, tab)
	end
	if(extension.RankPermissions != nil and SERVER) then
		for i, rank in pairs(extension.RankPermissions) do
			for i1,k1 in pairs(Vermilion.DefaultPermissionSettings) do
				if(k1[1] == rank[1]) then
					Crimson.Merge(k1[2], rank[2])
				end
			end
		end
	end
	if(extension.NetworkStrings != nil) then
		for i,k in pairs(extension.NetworkStrings) do
			table.insert(self.NetworkStrings, k)
			if(SERVER) then util.AddNetworkString(k) end
			net.Receive(k, function(len, vplayer)
				hook.Call("VNET_" .. k, nil, vplayer)
			end)
		end
	end
end

--[[
	
	Extension structure:
	
	- Name (string): the human-readable name for the extension.
	- ID (string): the unique machine-id for the extension. Used to retrieve the structure from the loader.
	- Description (string): a short description of the extension.
	- Author (string): your name
	- InitClient (function): called to activate the extension on the client. If you are writing a server-only extension, this is useless.
	- InitServer (function): called to activate the extension on the server. If you are writing a client-only extension, this is useless.
	- InitShared (function): called to activate the extension on both the client and the server.
	- Destroy (function): called to deactivate the extension when the Lua environment is shutting down or the extension is being reloaded.
	- DistributeEvent (function): called for every event, used to distribute events, regardless of type, to the extension.
	
	Predefined functions/variables (these should not be overridden):
	- Hooks (table): list of hooks that you have addded to your extension. Do not interface directly with this table.
	- AddHook (function with parameters: evtName, id, func): add a hook to the extension table
		- evtName: the name of the hook to listen for.
		- id: the unique id of the function (this can be dropped if you are only registering one listener for the evtName and evtName will be used as the unique id instead)
		- func: the callback function (parameters on this are the same as the parameters of the hook)
	- RemoveHook (function with parameters: evtName, id): remove a hook from the extension table
		- evtName: the name of the hook to remove a listener from
		- id: the unique id of the function to remove from the hook table (if you didn't provide the id parameter to the AddHook function you should just repeat evtName here).
	- NetHook (function with parameters: netstring, id, func): add a networking hook to the extension.
		- netstring: the name of the network message to listen for
		- id: the unique id of the function (this can be dropped if you are only registering one listener for the netstring and netstring will be used as the unique id instead)
		- func: the callback function (parameters on this function are the player instance [serverside] and nothing on the client)
	- UnNetHook (function with parameters: netstring, id): remove a networking hook from the extension.
		- netstring: the name of the network message to remove the hook from
		- id: the unique id of the function (this can be dropped if you didn't provide it to the NetHook function)

]]--

--[[
	Creates the basic extension data structure
	
	This must be extended upon and passed to RegisterExtension when writing the extension.
	
	@return extensionbase (table:extension) - the base structure for an extension
]]--
function Vermilion:MakeExtensionBase()
	local base = {}
	base.Name = "Base Extension"
	base.ID = "BaseExtension"
	base.Description = "The author of this extension doesn't know how to customise the extension data. Get rid of it!"
	base.Author = "n00b"
	base.Hooks = {}
	base.Localisations = {}
	base.Permissions = {}
	base.PermissionDefinitions = {}
	base.DataChangeHooks = {}
	
	function base:InitClient() end
	function base:InitServer() end
	function base:InitShared() end
	function base:Destroy() end
	
	function base:RegisterChatCommands() end
	
	function base:FindData(name, default)
		local dataTable = {}
		if(Vermilion.Settings.ModuleData[self.ID] == nil) then Vermilion.Settings.ModuleData[self.ID] = {} end
		for i,k in pairs(Vermilion.Settings.ModuleData[self.ID]) do
			if(string.find(i, name)) then dataTable[i] = k end
		end
		return dataTable
	end
	
	function base:GetData(name, default, set)
		if(Vermilion.Settings.ModuleData[self.ID] == nil) then Vermilion.Settings.ModuleData[self.ID] = {} end
		if(Vermilion.Settings.ModuleData[self.ID][name] == nil) then
			if(set) then self:SetData(name, default) end
			return default
		end
		return Vermilion.Settings.ModuleData[self.ID][name]
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
	
	function base:RunDataChangeHooks(dataName, value)
		if(self.DataChangeHooks[dataName] == nil) then return end
		for i,k in pairs(self.DataChangeHooks[dataName]) do
			k(value)
		end
	end
	
	function base:Localise(id)
		if(Vermilion.Lang[id] != nil) then return Vermilion.Lang[id] end
		if(self.Localisations[Vermilion.Utility.GetActiveLocale()] != nil) then
			if(self.Localisations[Vermilion.Utility.GetActiveLocale()][id] != nil) then return self.Localisations[Vermilion.Utility.GetActiveLocale()][id] end
		end
		return "{lang." .. id .. "}"
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
			Vermilion.Log(string.format(Vermilion.Lang.ExtHookRemoveFailed, id, evtName, base.ID))
		end
	end
	
	base:AddHook("VDefinePermission", function(permission)
		if(base.PermissionDefinitions[permission] != nil) then return base.PermissionDefinitions[permission] end
	end)
	
	
	function base:NetHook(netstring, id, func)
		self:AddHook("VNET_" .. netstring, id, func)
	end
	function base:UnNetHook(netstring, id)
		self:RemoveHook("VNET_" .. netstring, id)
	end
	
	
	function base:DistributeEvent(event, parameters) end
	
	
	function base:AddSwep(swepfile, swepfolder)
		if(swepfolder != nil) then
			swepfolder = ""
		else
			swepfolder = swepfolder .. "/"
		end
		if(not file.Exists("vermilion_exts/" .. self.ID .. "/weapons/" .. swepfolder .. swepfile, "LUA")) then
			Vermilion.Log("Failed to add swep! Could not find file!")
		end
		SWEP = {}
		SWEP.Folder = swepfolder
		include("vermilion_exts/" .. self.ID .. "/weapons/" .. swepfolder .. swepfile)
		AddCSLuaFile("vermilion_exts/" .. self.ID .. "/weapons/" .. swepfolder .. swepfile)
		weapons.Register(SWEP, string.Replace(swepfile, ".lua", ""))
		SWEP = nil
	end
	return base
end

--[[
	Register a hook to Vermilion. These hooks get priority over hooks added by hook.Add.
	
	@param evtName (string) - the event to listen for
	@param id (any) - the unique ID for this hook
	@param func (function) - the callback function for this hook
]]--
function Vermilion:RegisterHook(evtName, id, func)
	if(self.Hooks[evtName] == nil) then
		self.Hooks[evtName] = {}
	end
	self.Hooks[evtName][id] = func
end

--[[
	Unregister a hook from Vermilion.
	
	@param evtName (string) - the event to remove the hook from
	@param id (any) - the unique ID to remove
]]--
function Vermilion:UnregisterHook(evtName, id)
	if(self.Hooks[evtName] != nil) then
		self.Hooks[evtName][id] = nil
	else
		self.Log(string.format(Vermilion.Lang.HookRemoveFailed, id, evtName))
	end
end

--[[
	Register a "Vermilion SafeHook". SafeHooks cannot return a value to the caller but will always be notified of an event.
	
	@param evtName (string) - the event to listen for
	@param id (any) - the unique ID for this hook
	@param func (function) - the callback function for this hook
]]--
function Vermilion:RegisterSafeHook(evtName, id, func)
	if(self.SafeHooks[evtName] == nil) then
		self.SafeHooks[evtName] = {}
	end
	self.SafeHooks[evtName][id] = func
end

--[[
	Unregister a "Vermilion SafeHook".

	@param evtName (string) - the event to remove the hook from
	@param id (any) - the unique ID to remove
]]--
function Vermilion:UnregisterSafeHook(evtName, id)
	if(self.SafeHooks[evtName] != nil) then
		self.SafeHooks[evtName][id] = nil
	else
		self.Log(string.format(Vermilion.SafeHookRemoveFailed, id, evtName))
	end
end

-- Stores the raw text of the addon info.txts so they can be sent to the clients (who won't have the info.txt files on their filesystem)
Vermilion.InfoStores = {}

function Vermilion:LoadExtensions()
	local invalid, dirs = file.Find("vermilion_exts/*", "LUA")
	for i,dir in pairs(dirs) do
		if(file.Exists("vermilion_exts/" .. dir .. "/info.lua", "LUA") or self.InfoStores[dir] != nil) then
			local tab = nil
			if(SERVER) then
				self.InfoStores[dir] = file.Read("vermilion_exts/" .. dir .. "/info.lua", "LUA")
				tab = util.JSONToTable(self.InfoStores[dir]) --read the handler file
			else
				tab = util.JSONToTable(self.InfoStores[dir])
			end
			if(tab['clInitFile'] != nil and SERVER) then
				AddCSLuaFile("vermilion_exts/" .. dir .. "/" .. tab['clInitFile'])
			end
			if((tab['sideOnly'] == "CLIENT" and CLIENT) or (tab['sideOnly'] == "SERVER" and SERVER) or tab['sideOnly'] == nil) then
				if(tab['csLuaFiles'] != nil and SERVER) then
					for i,luaFile in pairs(tab['csLuaFiles']) do
						AddCSLuaFile("vermilion_exts/" .. dir .. "/" .. luaFile)
					end
				end
				if(tab['clResources'] != nil and SERVER) then
					for i,res in pairs(tab['clResources']) do
						resource.AddSingleFile(res)
					end
				end
				local sidedInit = false
				if(tab['clInitFile'] != nil and file.Exists("vermilion_exts/" .. dir .. "/" .. tab['clInitFile'], "LUA")) then
					if(CLIENT) then 
						self.Log(string.format(Vermilion.Lang.LoadingExtension, dir, tab['clInitFile']))
						include("vermilion_exts/" .. dir .. "/" .. tab['clInitFile'])
					else
						AddCSLuaFile("vermilion_exts/" .. dir .. "/" .. tab['clInitFile'])
					end
					sidedInit = true
				end
				if(tab['svInitFile'] != nil and file.Exists("vermilion_exts/" .. dir .. "/" .. tab['svInitFile'], "LUA") and SERVER) then
					self.Log(string.format(Vermilion.Lang.LoadingExtension, dir, tab['svInitFile']))
					include("vermilion_exts/" .. dir .. "/" .. tab['svInitFile'])
					sidedInit = true
				end
				if(tab['initFile'] != nil and file.Exists("vermilion_exts/" .. dir .. "/" .. tab['initFile'], "LUA")) then
					self.Log(string.format(Vermilion.Lang.LoadingExtension, dir, tab['initFile']))
					if(SERVER) then AddCSLuaFile("vermilion_exts/" .. dir .. "/" .. tab['initFile']) end
					include("vermilion_exts/" .. dir .. "/" .. tab['initFile'])
				elseif(not sidedInit) then
					self.Log(string.format(Vermilion.Lang.NoExtInitFile, dir))
				end
			end
		end
	end
	
	for i,extension in pairs(Vermilion.Extensions) do
		self.Log(string.format(Vermilion.Lang.ExtInit, i))
		if(SERVER) then
			extension:InitServer()
			extension:RegisterChatCommands()
		else
			extension:InitClient()
		end
		extension:InitShared()
	end
	Vermilion.LoadedExtensions = true
	hook.Call(Vermilion.EVENT_EXT_LOADED)
	hook.Call(Vermilion.EVENT_EXT_POST)
end


local originalHook = hook.Call

--[[
	This replacement is intended to let all hooks get informed, but the first to return a value "wins" control of the event. (this isn't true, but is the final intention)
	
	TODO:
	- make it impossible for other addons to overwrite this function at all costs.
	- figure out a way to have notification based-events and/or MODE (most returned value) based events (take into account that some hooks have multiple return values)
]]--
local vhookCall = function(evtName, gmTable, ...)
	-- Run Vermilion "safehooks". All events are triggered and return values ignored.
	if(Vermilion.SafeHooks[evtName] != nil) then
		for id,hookFunc in pairs(Vermilion.SafeHooks[evtName]) do
			hookFunc(...)
		end
	end
	-- Run Vermilion hooks
	if(Vermilion.Hooks[evtName] != nil) then
		for id,hookFunc in pairs(Vermilion.Hooks[evtName]) do
			local hookVal = hookFunc(...)
			if(hookVal != nil) then
				return hookVal
			end
		end
	end
	if(Vermilion.LoadedExtensions) then
		-- Run extension hooks
		for i,extension in pairs(Vermilion.Extensions) do
			local distributionResult = extension:DistributeEvent(evtName, ...)
			if(distributionResult != nil) then return distributionResult end
			if(extension.Hooks != nil) then
				local hookList = extension.Hooks[evtName]
				if(hookList != nil) then
					for i,hookFunc in pairs(hookList) do
						local hookResult = hookFunc(...)
						if(hookResult != nil) then
							return hookResult
						end
					end
				end
			end
		end
	end
	if(string.StartWith(evtName, "VNET_")) then return end
	-- Let everybody else have a go
	return originalHook(evtName, gmTable, ...)
end
hook.Call = vhookCall

timer.Simple(1, function()
	if(originalHook != hook.Call and hook.Call != vhookCall) then
		originalHook = hook.Call
		hook.Call = vhookCall
	end
end)

local originalHookAdd = hook.Add

local vhookAdd = function(hk, name, func)
	if(hk == "OnPlayerChat" and CLIENT) then
		originalHookAdd("VOnPlayerChat", name, func)
		return
	end
	originalHookAdd(hk, name, func)
end

hook.Add = vhookAdd

timer.Simple(1, function()
	if(originalHookAdd != hook.Add and hook.Add != vhookAdd) then
		originalHookAdd = hook.Add
		hook.Add = vhookAdd
	end
end)

if(CLIENT) then
	local originalHooks = hook.GetTable()['OnPlayerChat']
	hook.GetTable()['VOnPlayerChat'] = originalHooks
end


if(SERVER) then
	util.AddNetworkString("VChatPrediction")
	
	net.Receive("VChatPrediction", function(len, vplayer)
		local current = net.ReadString()
		local command = string.Trim(string.sub(current, 1, string.find(current, " ") or nil))
		local response = {}
		for i,k in pairs(Vermilion.ChatCommands) do
			if(string.find(current, " ")) then
				if(command == i) then
					table.insert(response, { Name = i, Syntax = k.Syntax })
				end
			elseif(string.StartWith(i, command)) then
				table.insert(response, { Name = i, Syntax = k.Syntax })
			end
		end
		for i,k in pairs(Vermilion.ChatAliases) do
			if(string.find(current, " ")) then
				if(command == i) then
					table.insert(response, { Name = i, Syntax = "(alias of " .. k .. ") - " .. Vermilion.ChatCommands[k].Syntax })
				end
			elseif(string.StartWith(i, command)) then
				table.insert(response, { Name = i, Syntax = "(alias of " .. k .. ") - " .. Vermilion.ChatCommands[k].Syntax })
			end
		end
		local predictor = nil
		if(Vermilion.ChatAliases[command] != nil) then
			predictor = Vermilion.ChatPredictors[Vermilion.ChatAliases[command]]
		else
			predictor = Vermilion.ChatPredictors[command]
		end
		if(string.find(current, " ") and predictor != nil) then
			local commandText = current
			local parts = string.Explode(" ", commandText, false)
			local parts2 = {}
			local part = ""
			local isQuoted = false
			for i,k in pairs(parts) do
				if(isQuoted and string.find(k, "\"")) then
					table.insert(parts2, string.Replace(part .. " " .. k, "\"", ""))
					isQuoted = false
					part = ""
				elseif(not isQuoted and string.find(k, "\"")) then
					part = k
					isQuoted = true
				elseif(isQuoted) then
					part = part .. " " .. k
				else
					table.insert(parts2, k)
				end
			end
			if(isQuoted) then table.insert(parts2, string.Replace(part, "\"", "")) end
			parts = {}
			for i,k in pairs(parts2) do
				--if(k != nil and k != "") then
					table.insert(parts, k)
				--end
			end
			table.remove(parts, 1)
			local dataTable = predictor(table.Count(parts), parts[table.Count(parts)], parts)
			if(dataTable != nil) then
				for i,k in pairs(dataTable) do
					if(istable(k)) then
						table.insert(response, k)
					else
						table.insert(response, { Name = k, Syntax = "" })
					end					
				end
			end
		end
		net.Start("VChatPrediction")
		net.WriteTable(response)
		net.Send(vplayer)
	end)
	
else
	net.Receive("VChatPrediction", function()
		local response = net.ReadTable()
		Vermilion.ChatPredictions = response
	end)
	
	Vermilion.ChatOpen = false
	
	Vermilion:RegisterHook("StartChat", "VOpenChatbox", function()
		Vermilion.ChatOpen = true
	end)
	
	Vermilion:RegisterHook("FinishChat", "VCloseChatbox", function()
		Vermilion.ChatOpen = false
		Vermilion.ChatPredictions = {}
	end)
	
	Vermilion:RegisterHook("HUDShouldDraw", "ChatHideHUD", function(name)
		if(Vermilion.CurrentChatText == nil) then return end
		if(string.StartWith(Vermilion.CurrentChatText, "!") and (name == "NetGraph" or name == "CHudAmmo")) then return false end
	end)
	
	Vermilion.ChatPredictions = {}
	Vermilion.ChatTabSelected = 1
	Vermilion.ChatBGW = 0
	Vermilion.ChatBGH = 0
	Vermilion.MoveEnabled = true
	
	Vermilion:RegisterHook("Think", "Testing", function()
		if(Vermilion.ChatOpen and Vermilion.MoveEnabled and table.Count(Vermilion.ChatPredictions) > 0) then
			if(input.IsKeyDown(KEY_DOWN)) then
				if(string.find(Vermilion.CurrentChatText, " ")) then
					if(Vermilion.ChatTabSelected + 1 > table.Count(Vermilion.ChatPredictions)) then
						Vermilion.ChatTabSelected = 2
					else
						Vermilion.ChatTabSelected = Vermilion.ChatTabSelected + 1
					end
				else
					if(Vermilion.ChatTabSelected + 1 > table.Count(Vermilion.ChatPredictions)) then
						Vermilion.ChatTabSelected = 1
					else
						Vermilion.ChatTabSelected = Vermilion.ChatTabSelected + 1
					end
				end
				Vermilion.MoveEnabled = false
				timer.Simple(0.1, function()
					Vermilion.MoveEnabled = true
				end)
			elseif(input.IsKeyDown(KEY_UP)) then
				if(string.find(Vermilion.CurrentChatText, " ")) then
					if(Vermilion.ChatTabSelected - 1 < 2) then
						Vermilion.ChatTabSelected = table.Count(Vermilion.ChatPredictions)
					else
						Vermilion.ChatTabSelected = Vermilion.ChatTabSelected - 1
					end
				else
					if(Vermilion.ChatTabSelected - 1 < 1) then
						Vermilion.ChatTabSelected = table.Count(Vermilion.ChatPredictions)
					else
						Vermilion.ChatTabSelected = Vermilion.ChatTabSelected - 1
					end
				end
				Vermilion.MoveEnabled = false
				timer.Simple(0.1, function()
					Vermilion.MoveEnabled = true
				end)
			end
		end
	end)
	
	Vermilion:RegisterHook("OnChatTab", "VInsertPrediction", function()
		if(table.Count(Vermilion.ChatPredictions) > 0 and string.find(Vermilion.CurrentChatText, " ") and table.Count(Vermilion.ChatPredictions) > 1) then
			local commandText = Vermilion.CurrentChatText
			local parts = string.Explode(" ", commandText, false)
			local parts2 = {}
			local part = ""
			local isQuoted = false
			for i,k in pairs(parts) do
				if(isQuoted and string.find(k, "\"")) then
					table.insert(parts2, string.Replace(part .. " " .. k, "\"", ""))
					isQuoted = false
					part = ""
				elseif(not isQuoted and string.find(k, "\"")) then
					part = k
					isQuoted = true
				elseif(isQuoted) then
					part = part .. " " .. k
				else
					table.insert(parts2, k)
				end
			end
			if(isQuoted) then table.insert(parts2, string.Replace(part, "\"", "")) end
			parts = {}
			for i,k in pairs(parts2) do
				--if(k != nil and k != "") then
					table.insert(parts, k)
				--end
			end
			parts[table.Count(parts)] = Vermilion.ChatPredictions[Vermilion.ChatTabSelected].Name
			return table.concat(parts, " ", 1) .. " "
		end
		if(Vermilion.ChatPredictions != nil and table.Count(Vermilion.ChatPredictions) > 0 and Vermilion.ChatTabSelected == 0) then
			return "!" .. Vermilion.ChatPredictions[1].Name .. " "
		end
		if(Vermilion.ChatPredictions != nil and Vermilion.ChatTabSelected > 0) then
			if(Vermilion.ChatPredictions[Vermilion.ChatTabSelected] == nil) then return end
			return "!" .. Vermilion.ChatPredictions[Vermilion.ChatTabSelected].Name .. " "
		end
	end)
	
	Vermilion:RegisterHook("HUDPaint", "PredictDraw", function()
		if(table.Count(Vermilion.ChatPredictions) > 0 and Vermilion.ChatOpen) then
			local pos = 0
			local xpos = 0
			local maxw = 0
			local text = "Press up/down to select a suggestion and press tab to insert it."
			if(Vermilion:GetExtension("chatbox") != nil and GetConVarNumber("vermilion_replace_chat") == 1) then
				text = "Press up/down to select a suggestion and press right arrow key to insert it."
			end
			local mapbx = math.Remap(545, 0, 1366, 0, ScrW())
			local maptx = math.Remap(550, 0, 1366, 0, ScrW())

			if(ScrW() > 1390) then
				mapbx = mapbx + 100
				maptx = maptx + 100
			end
			draw.RoundedBox(2, mapbx, select(2, chat.GetChatBoxPos()) - 15, Vermilion.ChatBGW + 10, Vermilion.ChatBGH + 5, Color(0, 0, 0, 128))
			draw.SimpleText(text, "Default", maptx, select(2, chat.GetChatBoxPos()) - 20, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
			Vermilion.ChatBGH = 0
			for i,k in pairs(Vermilion.ChatPredictions) do
				local text = k.Name
				if(table.Count(Vermilion.ChatPredictions) <= 8 or string.find(Vermilion.CurrentChatText, " ")) then
					text = k.Name .. " " .. k.Syntax
				end
				local colour = Color(255, 255, 255)
				if(i == Vermilion.ChatTabSelected) then colour = Color(255, 0, 0) end
				local w,h = draw.SimpleText(text, "Default", maptx + xpos, select(2, chat.GetChatBoxPos()) + pos, colour, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
				if(maxw < w) then maxw = w end
				pos = pos + h + 5
				if(pos > Vermilion.ChatBGH) then Vermilion.ChatBGH = pos end
				if(pos + select(2, chat.GetChatBoxPos()) + 20 >= ScrH()) then
					xpos = xpos + maxw + 10
					maxw = 0
					pos = 0
				end
			end
			Vermilion.ChatBGW = xpos + maxw
		end
	end)
	
	Vermilion:RegisterHook("ChatTextChanged", "ChatPredict", function(chatText)
		if(Vermilion.CurrentChatText != chatText) then
			if(string.find(chatText, " ")) then
				Vermilion.ChatTabSelected = 2
			else
				Vermilion.ChatTabSelected = 1
			end
		end
		Vermilion.CurrentChatText = chatText
		
		if(string.StartWith(chatText, "!")) then
			net.Start("VChatPrediction")
			local space = nil
			if(string.find(chatText, " ")) then
				space = string.find(chatText, " ") - 1
				
			end
			net.WriteString(string.sub(chatText, 2))
			net.SendToServer()
		else
			Vermilion.ChatPredictions = {}
		end
	end)
end