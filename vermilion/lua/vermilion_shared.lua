-- The MIT License
--
-- Copyright 2014 Ned Hyett.
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.

Vermilion.extensions = {}
Vermilion.hooks = {}

Vermilion.chatCommands = {}

-- Add a chat command to the Vermilion interpreter
function Vermilion:addChatCommand(activator, func)
	self.chatCommands[activator] = func
end

-- Get the data structure for a loaded extension
function Vermilion:getExtension(id)
	return self.extensions[id]
end

-- Used at the end of an extension to register it's data structure to Vermilion
function Vermilion:registerExtension(extension)
	self.extensions[extension.ID] = extension
	if(extension.Permissions != nil) then
		for i,p in pairs(extension.Permissions) do
			table.insert(self.permissionsList, p)
		end
	end
	if(extension.RankPermissions != nil) then
		for i, rank in pairs(extension.RankPermissions) do
			local rankID = self:lookupRank(rank[1])
			for i1, perm in pairs(rank[2]) do
				local alreadyHas = false
				for i,k in pairs(self.defaultRankPerms[rankID][2]) do
					if(k[1] == perm[1]) then
						alreadyHas = true
						break
					end
				end
				if(not alreadyHas) then table.insert(self.defaultRankPerms[rankID][2], perm) end
			end
		end
	end
end

-- Creates the basic extension data structure
function Vermilion:makeExtensionBase()
	local base = {}
	base.Name = "Base Extension"
	base.ID = "BaseExtension"
	base.Description = "The author of this extension doesn't know how to customise the extension data. Get rid of it!"
	base.Author = "n00b"
	base.hooks = {}
	function base:init() end
	function base:destroy() end
	function base:tick() end
	function base:addHook(evtName, id, func)
		if(self.hooks[evtName] == nil) then
			self.hooks[evtName] = {}
		end
		self.hooks[evtName][id] = func
	end
	function base:unhook(evtName, id)
		if(self.hooks[evtName] != nil) then
			self.hooks[evtName][id] = nil
		else
			Vermilion.log("Attempted to remove hook " .. id .. " from event " .. evtName .. " inside extension " .. base.ID .. " but no such event table has been created!")
		end
	end
	return base
end

function Vermilion:registerHook(evtName, id, func)
	if(self.hooks[evtName] == nil) then
		self.hooks[evtName] = {}
	end
	self.hooks[evtName][id] = func
end

function Vermilion:unregisterHook(evtName, id)
	if(self.hooks[evtName] != nil) then
		self.hooks[evtName][id] = nil
	else
		self.log("Attempted to remove hook " .. id .. " from event " .. evtName .. " but no such event table has been created!")
	end
end

-- Load extensions
local expr = nil

if(SERVER) then
	expr = "vermilion_exts/server/"
elseif(CLIENT) then
	expr = "vermilion_exts/client/"
end

if(SERVER) then
	for _,ext in ipairs( file.Find("vermilion_exts/client/*.lua", "LUA") ) do
		AddCSLuaFile("vermilion_exts/client/" .. ext)
	end
	for _,ext in ipairs( file.Find("vermilion_exts/shared/*.lua", "LUA") ) do
		AddCSLuaFile("vermilion_exts/client/" .. ext)
	end
end

for _,ext in ipairs( file.Find(expr .. "*.lua", "LUA") ) do
	include(expr .. ext)
end
for _,ext in ipairs( file.Find("vermilion_exts/shared/*.lua", "LUA") ) do
	include("vermilion_exts/shared/" .. ext)
end
if(SERVER) then
	for i,extension in pairs(Vermilion.extensions) do
		Vermilion.log("Initialising extension: " .. i)
		extension:init()
	end
end

if(CLIENT) then
	net.Receive("Vermilion_Client_Activate", function(len)
		if(Vermilion.activated) then
			Vermilion.log("Got a second activation attempt from the server! Ignoring!")
			return
		end
		Vermilion.activated = true
		for i,extension in pairs(Vermilion.extensions) do
			Vermilion.log("Initialising extension: " .. i)
			extension:init()
		end
	end)
end

local originalHook = hook.Call

-- Let Vermilion hooks take precedence 
hook.Call = function(evtName, gmTable, ...)
	if(evtName == "Think") then
		--Tick extensions
		for i,extension in pairs(Vermilion.extensions) do
			extension:tick()
		end
	end
	-- Run Vermilion hooks
	if(Vermilion.hooks[evtName] != nil) then
		for id,hook1 in pairs(Vermilion.hooks[evtName]) do
			local hookVal = hook1(...)
			if(hookVal != nil) then
				return hookVal
			end
		end
	end
	-- Run extension hooks
	for i,extension in pairs(Vermilion.extensions) do
		if(extension.hooks != nil) then
			local hookList = extension.hooks[evtName]
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
	-- Let everybody else have a go
	return originalHook(evtName, gmTable, ...)
end
