--[[
 Copyright 2014 Ned Hyett, 

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

local EXTENSION = Vermilion:MakeExtensionBase()
EXTENSION.Name = "Gamemode Customiser"
EXTENSION.ID = "gm_customiser"
EXTENSION.Description = "Automatically modifies Vermilion Settings to suit the currently active gamemode."
EXTENSION.Author = "Ned"
EXTENSION.Permissions = {
	
}

local types = {}

function EXTENSION:AddGamemodeType(tester, activator, applies)
	table.insert(types, { Tester = tester, Activator = activator, SettingApplies = applies })
end

local cproperties = {
	{ Module = nil, Name = "unlimited_ammo" },
	{ Module = nil, Name = "enable_limit_remover" },
	{ Module = nil, Name = "enable_no_damage" },
	{ Module = nil, Name = "flashlight_control" },
	{ Module = nil, Name = "noclip_control" },
	{ Module = nil, Name = "spray_control" },
	{ Module = nil, Name = "voip_control" },
	{ Module = nil, Name = "enable_kick_immunity" },
	{ Module = nil, Name = "enable_kill_immunity" },
	{ Module = nil, Name = "enable_lock_immunity" },
	{ Module = nil, Name = "disable_fall_damage" },
	{ Module = nil, Name = "force_noclip_permissions" },
	{ Module = "deathnotice", Name = "enabled" },
	{ Module = "scoreboard", Name = "scoreboard_enabled" }
}

function EXTENSION:InitServer()
	
	--[[EXTENSION:AddGamemodeType(function(name, sandbox, toolgunEnabled)
		local knownRPGamemodes = {
			"darkrp"
		}
		return false
	end, function(name)
		
	end)]]
	
	--[[
		This basically resets the settings back to the stored user-defined settings if the gamemode is changed back to sandbox.
	]]--
	EXTENSION:AddGamemodeType(function(name, sandbox, toolgunEnabled)
		return name == "sandbox" and sandbox
	end, function(name, svManager)
		if(EXTENSION:GetData("sandbox_configed", false, true)) then
			local sbData = EXTENSION:GetData("sandbox", {}, true)
			for i,k in pairs(cproperties) do
				local mod = k.Module or "server_manager"
				if(sbData[mod .. k.Name] == nil) then continue end
				Vermilion:SetModuleData(mod, k.Name, sbData[k.Name])
			end
		end
		EXTENSION:SetData("sandbox_configed", true)
	end, function(setting)
		return true
	end)
	
	--[[
		Allow Cops and Runners to be played fairly.
	]]--
	EXTENSION:AddGamemodeType(function(name, sandbox, toolgunEnabled)
		return name == "copsandrunners"
	end, function(name, svManager)
		if(EXTENSION:GetData("copsandrunners_configed", false, true)) then
			local carData = EXTENSION:GetData("copsandrunners", {}, true)
			for i,k in pairs(cproperties) do
				local mod = k.Module or "server_manager"
				if(carData[mod .. k.Name] == nil) then continue end
				Vermilion:SetModuleData(mod, k.Name, carData[k.Name])
			end
			return
		end
		svManager:SetData("unlimited_ammo", 1)
		svManager:SetData("enable_limit_remover", 1)
		svManager:SetData("enable_no_damage", 1)
		svManager:SetData("flashlight_control", 1)
		svManager:SetData("noclip_control", 1)
		svManager:SetData("enable_lock_immunity", 1)
		svManager:SetData("enable_kill_immunity", 1)
		svManager:SetData("enable_kick_immunity", 1)
		svManager:SetData("disable_fall_damage", 1)
		Vermilion:SetModuleData("scoreboard", "scoreboard_enabled", false)
		
		EXTENSION:SetData("copsandrunners_configed", true)
	end, function(mod, setting)
		mod = mod or "server_manager"
		return table.HasValue({"server_manager" .. "unlimited_ammo", "server_manager" .. "enable_limit_remover", "server_manager" .. "enable_no_damage", "server_manager" .. "noclip_control", "server_manager" .. "enable_kick_immunity", "server_manager" .. "enable_kill_immunity", "server_manager" .. "enable_lock_immunity", "server_manager" .. "disable_fall_damage", "scoreboard" .. "scoreboard_enabled"}, mod .. setting)
	end)
	
	EXTENSION:AddGamemodeType(function(name, sandbox, toolgunEnabled)
		return name == "murder"
	end, function(name, svManager)
		if(EXTENSION:GetData("murder_configed", false, true)) then
			local mData = EXTENSION:GetData("murder", {}, true)
			for i,k in pairs(cproperties) do
				local mod = k.Module or "server_manager"
				if(mData[mod .. k.Name] == nil) then continue end
				Vermilion:SetModuleData(mod, k.Name, mData[k.Name])
			end
			return
		end
		svManager:SetData("unlimited_ammo", 1)
		svManager:SetData("enable_limit_remover", 1)
		svManager:SetData("enable_no_damage", 1)
		svManager:SetData("flashlight_control", 1)
		svManager:SetData("noclip_control", 1)
		svManager:SetData("enable_lock_immunity", 1)
		svManager:SetData("enable_kill_immunity", 1)
		svManager:SetData("enable_kick_immunity", 1)
		svManager:SetData("disable_fall_damage", 1)
		Vermilion:SetModuleData("deathnotice", "enabled", false)
		Vermilion:SetModuleData("scoreboard", "scoreboard_enabled", false)
		
		EXTENSION:SetData("murder_configed", true)
	end, function(mod, setting)
		mod = mod or "server_manager"
		return table.HasValue({"server_manager" .. "unlimited_ammo", "server_manager" .. "enable_limit_remover", "server_manager" .. "enable_no_damage", "server_manager" .. "noclip_control", "server_manager" .. "enable_kick_immunity", "server_manager" .. "enable_kill_immunity", "server_manager" .. "enable_lock_immunity", "server_manager" .. "disable_fall_damage", "scoreboard" .. "scoreboard_enabled", "deathnotice" .. "enabled"}, mod .. setting)
	end)
	
	self:AddHook("OnGamemodeLoaded", function()
		if(not EXTENSION:GetData("enabled", true, true)) then return end
		for i,k in pairs(types) do
			if(k.Tester(engine.ActiveGamemode(), GAMEMODE.IsSandboxDerived, weapons.Get("gmod_tool") != nil)) then
				Vermilion.Log("Loading gamemode settings: " .. engine.ActiveGamemode())
				k.Activator(engine.ActiveGamemode(), Vermilion:GetExtension("server_manager"))
			end
		end
	end)
	
	--[[
		Save the data for the active gamemode.
	]]--
	self:AddHook("Vermilion-Pre-Shutdown", function()
		for i,k in pairs(cproperties) do
			for i1,k1 in pairs(types) do
				if(k1.Tester(engine.ActiveGamemode(), GAMEMODE.IsSandboxDerived, weapons.Get("gmod_tool") != nil) and k1.SettingApplies(k.Module, k.Name)) then
					local mod = k.Module or "server_manager"
					EXTENSION:GetData(engine.ActiveGamemode(), {}, true)[mod .. k.Name] = Vermilion:GetModuleData(mod, k.Name)
				end
			end
		end
	end)
	
end

function EXTENSION:InitClient()

end

Vermilion:RegisterExtension(EXTENSION)