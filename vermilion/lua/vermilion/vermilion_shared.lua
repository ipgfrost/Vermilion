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
		for i,permission in pairs(extension.Permissions) do
			local alreadyHas = false
			for i1,knownPermission in pairs(self.PermissionsList) do
				if(knownPermission == permission) then
					alreadyHas = true
					break
				end
			end
			if(not alreadyHas) then table.insert(self.PermissionsList, permission) end
		end
	end
	if(extension.RankPermissions != nil and SERVER) then
		for i, rank in pairs(extension.RankPermissions) do
			local rankID = self:LookupRank(rank[1])
			for i1, permission in pairs(rank[2]) do
				local alreadyHas = false 
				for i,knownPermission in pairs(self.DefaultRankPerms[rankID][2]) do
					if(knownPermission == permission) then
						alreadyHas = true
						break
					end
				end
				if(not alreadyHas) then table.insert(self.DefaultRankPerms[rankID][2], permission) end
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
	
	
	Predefined functions/variables (these should not be overridden):
	- Hooks (table): list of hooks that you have addded to your extension. Do not interface directly with this table.
	- AddHook (function with parameters: evtName, id, func): add a hook to the extension table
		- evtName: the name of the hook to listen for.
		- id: the unique id of the function (this can be dropped if you are only registering on listener for the evtName and evtName will be used as the unique id instead)
		- func: the callback function (parameters on this are the same as the parameters of the hook)
	- RemoveHook (function with parameters: evtName, id): remove a hook from the extension table
		- evtName: the name of the hook to remove a listener from
		- id: the unique id of the function to remove from the hook table (if you didn't provide the id parameter to the AddHook function you should just repeat evtName here).

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
	function base:InitClient() end
	function base:InitServer() end
	function base:InitShared() end
	function base:Destroy() end
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
			Vermilion.Log("Attempted to remove hook " .. id .. " from event " .. evtName .. " inside extension " .. base.ID .. " but no such event table has been created!")
		end
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
		self.Log("Attempted to remove hook " .. id .. " from event " .. evtName .. " but no such event table has been created!")
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
		self.Log("Attempted to remove safehook " .. id .. " from event " .. evtName .. " but no such event table has been created!")
	end
end



function Vermilion:LoadExtensions()
	
	local expr = nil
	if(SERVER) then
		expr = "vermilion_exts/server/"
	else
		expr = "vermilion_exts/client/"
	end
	
	Vermilion.LoadedExtensions = false

	if(SERVER) then
		for _,ext in ipairs( file.Find("vermilion_exts/client/*.lua", "LUA") ) do
			AddCSLuaFile("vermilion_exts/client/" .. ext)
		end
		for _,ext in ipairs( file.Find("vermilion_exts/shared/*.lua", "LUA") ) do
			AddCSLuaFile("vermilion_exts/shared/" .. ext)
		end
	end

	for _,ext in ipairs( file.Find(expr .. "*.lua", "LUA") ) do
		include(expr .. ext)
	end
	for _,ext in ipairs( file.Find("vermilion_exts/shared/*.lua", "LUA") ) do
		include("vermilion_exts/shared/" .. ext)
	end
	for i,extension in pairs(Vermilion.Extensions) do
		Vermilion.Log("Initialising extension: " .. i)
		if(SERVER) then
			extension:InitServer()
		else
			extension:InitClient()
		end
		extension:InitShared()
	end
	Vermilion.LoadedExtensions = true
	hook.Call(Vermilion.EVENT_EXT_LOADED)
end



local originalHook = hook.Call

--[[
	This replacement is intended to let all hooks get informed, but the first to return a value "wins" control of the event. (this isn't true, but is the final intention)
	
	TODO: make it impossible for other addons to overwrite this function at all costs.
]]--
hook.Call = function(evtName, gmTable, ...)
	local startTime = os.clock()
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
	local ttime = os.clock() - startTime
	if(Vermilion.HookTimes[evtName] == nil) then
		Vermilion.HookTimes[evtName] = ttime
	else
		Vermilion.HookTimes[evtName] = Vermilion.HookTimes[evtName] + ttime
	end
	-- Let everybody else have a go
	return originalHook(evtName, gmTable, ...)
end

concommand.Add("ver_time", function()
	for i,k in pairs(Vermilion.HookTimes) do
		print(i .. " ==> " .. tostring(k) .. " ms")
	end
end)