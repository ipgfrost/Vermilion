--[[
 The MIT License

 Copyright 2014 Ned Hyett.

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
]]

Vermilion.Extensions = {}
Vermilion.Hooks = {}
Vermilion.SafeHooks = {}

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
		for i,p in pairs(extension.Permissions) do
			table.insert(self.PermissionsList, p)
		end
	end
	if(extension.RankPermissions != nil and SERVER) then
		for i, rank in pairs(extension.RankPermissions) do
			local rankID = self:LookupRank(rank[1])
			for i1, perm in pairs(rank[2]) do
				local alreadyHas = false 
				for i,k in pairs(self.DefaultRankPerms[rankID][2]) do
					if(k[1] == perm[1]) then
						alreadyHas = true
						break
					end
				end
				if(not alreadyHas) then table.insert(self.DefaultRankPerms[rankID][2], perm) end
			end
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
	function base:Destroy() end
	function base:Tick() end
	function base:AddHook(evtName, id, func)
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
		for id,hook1 in pairs(Vermilion.SafeHooks[evtName]) do
			hook1(...)
		end
	end
	-- Run Vermilion hooks
	if(Vermilion.Hooks[evtName] != nil) then
		for id,hook1 in pairs(Vermilion.Hooks[evtName]) do
			local lHookVal = hook1(...)
			if(lHookVal != nil) then
				return lHookVal
			end
		end
	end
	if(Vermilion.LoadedExtensions) then
		-- Run extension hooks
		for i,extension in pairs(Vermilion.Extensions) do
			if(extension.Hooks != nil) then
				local hookList = extension.Hooks[evtName]
				if(hookList != nil) then
					for i,hook1 in pairs(hookList) do
						local hookResult = hook1(...)
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