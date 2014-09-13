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

CreateConVar("vermilion_spawn_debug", 0, FCVAR_GAMEDLL, "")

duplicator.RegisterEntityModifier("Vermilion_Owner", function(vplayer, entity, data)
	entity.Vermilion_Owner = data.Owner
end)

local setOwnerFunc = function(vplayer, model, entity)
	local tEnt = entity
	if(tEnt == nil) then -- some of the hooks only have 2 parameters.
		tEnt = model
	end
	if(tEnt) then
		local result = hook.Run("CPPIAssignOwnership", vplayer, tEnt)
		if(result == nil) then
			tEnt.Vermilion_Owner = vplayer:SteamID()
			tEnt:SetNWString("Vermilion_Owner", vplayer:SteamID())
			duplicator.StoreEntityModifier(tEnt, "Vermilion_Owner", { Owner = vplayer:SteamID() })
		else
			Vermilion.Log("Warning: prop was spawned but something blocked the CPPI hook to assign the owner!")
		end
	end
end

local spawnedFuncs = {
	"PlayerSpawnedProp",
	"PlayerSpawnedSENT",
	"PlayerSpawnedNPC",
	"PlayerSpawnedVehicle",
	"PlayerSpawnedEffect",
	"PlayerSpawnedRagdoll",
	"PlayerSpawnedSWEP"
}

local spawnFuncs = { 
	"PlayerSpawnProp",
	"PlayerSpawnSENT",
	"PlayerSpawnNPC",
	"PlayerSpawnVehicle",
	"PlayerSpawnEffect",
	"PlayerSpawnSWEP"
}

-- Entity Creator stuff
for i,spHook in pairs(spawnedFuncs) do
	Vermilion:RegisterHook(spHook, "Vermilion_SpawnCreatorSet" .. i, setOwnerFunc)
end

local function SpawnLimitHitFunc(vplayer, vtype)
	if(not IsValid(vplayer)) then return end
	return vplayer:CheckLimit(vtype)
end

Vermilion:RegisterHook("PlayerSpawnProp", "Vermilion_GMFixProp", function(vplayer, model)
	if(GetConVarNumber("vermilion_spawn_debug") > 0) then
		Vermilion.Log(vplayer:GetName() .. " spawned a " .. model)
		for i,k in pairs(player.GetAll()) do
			k:ChatPrint(vplayer:GetName() .. " spawned a " .. model)
		end
	end
	if(not Vermilion:HasPermission(vplayer, "spawn_all")) then
		if(not Vermilion:HasPermission(vplayer, "spawn_prop")) then
			return false
		end
	end
	local result = hook.Run("VPlayerSpawnProp", vplayer, model)
	if(result == nil) then result = true end
	return SpawnLimitHitFunc(vplayer, "props") and result
end)

Vermilion:RegisterHook("PlayerSpawnRagdoll", "Vermilion_GMFixRagdoll", function(vplayer, model)
	if(GetConVarNumber("vermilion_spawn_debug") > 0) then
		Vermilion.Log(vplayer:GetName() .. " spawned a " .. model)
		for i,k in pairs(player.GetAll()) do
			k:ChatPrint(vplayer:GetName() .. " spawned a " .. model)
		end
	end
	if(not Vermilion:HasPermission(vplayer, "spawn_all")) then
		if(not Vermilion:HasPermission(vplayer, "spawn_ragdoll")) then
			return false
		end
	end
	local result = hook.Run("VPlayerSpawnRagdoll", vplayer, model)
	if(result == nil) then result = true end
	if(not result) then return false end
	return SpawnLimitHitFunc(vplayer, "ragdolls")
end)

Vermilion:RegisterHook("PlayerSpawnEffect", "Vermilion_GMFixEffect", function(vplayer, model)
	if(GetConVarNumber("vermilion_spawn_debug") > 0) then
		Vermilion.Log(vplayer:GetName() .. " spawned a " .. model)
		for i,k in pairs(player.GetAll()) do
			k:ChatPrint(vplayer:GetName() .. " spawned a " .. model)
		end
	end
	if(not Vermilion:HasPermission(vplayer, "spawn_all")) then
		if(not Vermilion:HasPermission(vplayer, "spawn_effect")) then
			return false
		end
	end
	local result = hook.Run("VPlayerSpawnEffect", vplayer, model)
	if(result == nil) then result = true end
	if(not result) then return false end
	return SpawnLimitHitFunc(vplayer, "effects")
end)

Vermilion:RegisterHook("PlayerSpawnVehicle", "Vermilion_GMFixVehicle", function(vplayer, model, vehicle, tab)
	if(GetConVarNumber("vermilion_spawn_debug") > 0) then
		PrintTable(tab)
		Vermilion.Log(vplayer:GetName() .. " spawned a " .. tab.Name .. " (" .. tab.Class .. ")")
		for i,k in pairs(player.GetAll()) do
			k:ChatPrint(vplayer:GetName() .. " spawned a " .. tab.Name .. " (" .. tab.Class .. ")")
		end
	end
	if(not Vermilion:HasPermission(vplayer, "spawn_all")) then
		if(not Vermilion:HasPermission(vplayer, "spawn_vehicle")) then
			return false
		end
	end
	local result = hook.Run("VPlayerSpawnVehicle", vplayer, model, vehicle, tab)
	if(result == nil) then result = true end
	if(not result) then return false end
	return SpawnLimitHitFunc(vplayer, "vehicles")
end)

Vermilion:RegisterHook("PlayerSpawnSWEP", "Vermilion_GMFixSWEP", function(vplayer, swepName, swepTab)
	if(GetConVarNumber("vermilion_spawn_debug") > 0) then
		Vermilion.Log(vplayer:GetName() .. " spawned a " .. swepName)
		for i,k in pairs(player.GetAll()) do
			k:ChatPrint(vplayer:GetName() .. " spawned a " .. swepName)
		end
	end
	if(not Vermilion:HasPermission(vplayer, "spawn_all")) then
		if(not Vermilion:HasPermission(vplayer, "spawn_weapon")) then
			return false
		end
	end
	local result = hook.Run("VPlayerSpawnSWEP", vplayer, swepName, swepTab)
	if(result == nil) then result = true end
	if(not result) then return false end
	return SpawnLimitHitFunc(vplayer, "sents")
end)

Vermilion:RegisterHook("PlayerSpawnSENT", "Vermilion_GMFixSENT", function(vplayer, name)
	if(GetConVarNumber("vermilion_spawn_debug") > 0) then
		Vermilion.Log(vplayer:GetName() .. " spawned a " .. name)
		for i,k in pairs(player.GetAll()) do
			k:ChatPrint(vplayer:GetName() .. " spawned a " .. name)
		end
	end
	if(not Vermilion:HasPermission(vplayer, "spawn_all")) then
		if(not Vermilion:HasPermission(vplayer, "spawn_entity")) then
			return false
		end
	end
	local result = hook.Run("VPlayerSpawnSENT", vplayer, name)
	if(result == nil) then result = true end
	if(not result) then return false end
	return SpawnLimitHitFunc(vplayer, "sents")
end)

Vermilion:RegisterHook("PlayerSpawnNPC", "Vermilion_GMFixNPC", function(vplayer, npc_typ, equipment)
	if(GetConVarNumber("vermilion_spawn_debug") > 0) then
		Vermilion.Log(vplayer:GetName() .. " spawned a " .. npc_typ)
		for i,k in pairs(player.GetAll()) do
			k:ChatPrint(vplayer:GetName() .. " spawned a " .. npc_typ)
		end
	end
	if(not Vermilion:HasPermission(vplayer, "spawn_all")) then
		if(not Vermilion:HasPermission(vplayer, "spawn_npc")) then
			return false
		end
	end
	local result = hook.Run("VPlayerSpawnNPC", vplayer, npc_typ, equipment)
	if(result == nil) then result = true end
	if(not result) then return false end
	return SpawnLimitHitFunc(vplayer, "npcs")
end)
