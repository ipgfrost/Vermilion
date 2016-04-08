--[[
 Copyright 2015-16 Ned Hyett

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
	It is standard practice to ignore any errors that happen with this code, unless they take place in sporadic locations.
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
						//print("MODULE", mod.Name, "RETURNED STANDARD HOOK!", evtName)
						destroySDHook(evtName)
						return a, b, c, d, e, f
					end
				end
			end
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

	local vars = { ... }

	-- I don't like doing this, but I don't appear to have a choice. GMod keeps blaming Vermilion for
	-- bugs in other addons because of these lines of code. Alternative fixes would be appreciated.
	-- TODO: make ALL Vermilion hooks use the Vermilion-standard hook system and keep them out of
	-- the vanilla hook system so I can change the message to make it more scathing.
	-- I'm bored of this. Really, I am.

	if(not xpcall(function()
		a,b,c,d,e,f = hook.oldHook(evtName, gmTable, unpack(vars))
	end, function(err)
		hook.Run("OnLuaError") -- bring up the standard "script errors" notification. (doesn't seem to work [probably in the wrong realm]; make own?)
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

Vermilion.DHOStarted = false
local doHookOverride = nil

hook.GetTable()["VPlayerSay"] = {}

doHookOverride = function()
	if(hook.Call != vHookCall) then
		hook.Call = vHookCall
	end
	if(hook.Add != vHookAdd) then
		hook.Add = vHookAdd
	end
	if(hook.Remove != vHookRemove) then
		hook.Remove = vHookRemove
	end
	if(hook.GetTable()["PlayerSay"] != nil) then -- fix for commands from other addons. This was a request, so don't blame me.
		table.Merge(hook.GetTable()["VPlayerSay"], hook.GetTable()["PlayerSay"])
		hook.GetTable()["PlayerSay"] = nil
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
