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
		
		function base:DistributeEvent(event, parameters) end

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

		
		function base:AddMenuPage(data)
			Vermilion.Menu:AddPage(data)
			if(self.Tabs == nil) then
				self.Tabs = {}
			end
			table.insert(self.Tabs, data.ID)
		end
		

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