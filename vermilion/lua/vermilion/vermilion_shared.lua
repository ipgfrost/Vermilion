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

Vermilion.Extensions = {}
Vermilion.Hooks = {}
Vermilion.SafeHooks = {}
Vermilion.NetworkStrings = {}

Vermilion.ChatCommands = {}



--[[ 
	Add a chat command to the Vermilion interpreter
	
	@param: activator (string) - what the player has to type into chat to activate the command
	@param: func (function with params: sender (player), text (table) space split input) - the command handler
]]--
function Vermilion:AddChatCommand(activator, func)
	if(self.ChatCommands[activator] != nil) then
		self.Log("Chat command " .. activator .. " has been overwritten!")
	end
	self.ChatCommands[activator] = func
end

-- Get the data structure for a loaded extension
function Vermilion:GetExtension(id)
	return self.Extensions[id]
end

-- Used at the end of an extension to register it's data structure to Vermilion
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
				print("Calling VNET_" .. k)
				hook.Call("VNET_" .. k, nil, vplayer)
			end)
		end
	end
end

-- Creates the basic extension data structure
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
	function base:Tick() end
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
	function base:Unhook(evtName, id)
		if(self.Hooks[evtName] != nil) then
			self.Hooks[evtName][id] = nil
		else
			Vermilion.Log("Attempted to remove hook " .. id .. " from event " .. evtName .. " inside extension " .. base.ID .. " but no such event table has been created!")
		end
	end
	return base
end

function Vermilion:RegisterHook(evtName, id, func)
	if(self.Hooks[evtName] == nil) then
		self.Hooks[evtName] = {}
	end
	self.Hooks[evtName][id] = func
end

function Vermilion:UnregisterHook(evtName, id)
	if(self.Hooks[evtName] != nil) then
		self.Hooks[evtName][id] = nil
	else
		self.Log("Attempted to remove hook " .. id .. " from event " .. evtName .. " but no such event table has been created!")
	end
end

function Vermilion:RegisterSafeHook(evtName, id, func)
	if(self.SafeHooks[evtName] == nil) then
		self.SafeHooks[evtName] = {}
	end
	self.SafeHooks[evtName][id] = func
end

function Vermilion:UnregisterSafeHook(evtName, id)
	if(self.SafeHooks[evtName] != nil) then
		self.SafeHooks[evtName][id] = nil
	else
		self.Log("Attempted to remove safehook " .. id .. " from event " .. evtName .. " but no such event table has been created!")
	end
end

if(CLIENT) then
	net.Receive("Vermilion_Client_Activate", function(len)
		if(Vermilion.Activated) then
			Vermilion.Log("Got a second activation attempt from the server! Ignoring!")
			return
		end
		Vermilion.Activated = true
		local expr = "vermilion_exts/client/"
		for _,ext in ipairs( file.Find(expr .. "*.lua", "LUA") ) do
			include(expr .. ext)
		end
		for _,ext in ipairs( file.Find("vermilion_exts/shared/*.lua", "LUA") ) do
			include("vermilion_exts/shared/" .. ext)
		end
		for i,extension in pairs(Vermilion.Extensions) do
			Vermilion.Log("Initialising extension: " .. i)
			extension:InitClient()
			extension:InitShared()
		end
		Vermilion.LoadedExtensions = true
		hook.Call(Vermilion.EVENT_EXT_LOADED)
	end)
end

function Vermilion:LoadExtensions()
	-- Load extensions
	local expr = "vermilion_exts/server/"

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
		extension:InitServer()
		extension:InitShared()
	end
	Vermilion.LoadedExtensions = true
	hook.Call(Vermilion.EVENT_EXT_LOADED)
end



local originalHook = hook.Call

-- This replacement is intended to let all hooks get informed, but the first to return a value "wins" control of the event. 
hook.Call = function(evtName, gmTable, ...)
	if(evtName == "Think" and Vermilion.LoadedExtensions) then
		--Tick extensions
		for i,extension in pairs(Vermilion.Extensions) do
			extension:Tick()
		end
	end
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
	-- Let everybody else have a go
	return originalHook(evtName, gmTable, ...)
end