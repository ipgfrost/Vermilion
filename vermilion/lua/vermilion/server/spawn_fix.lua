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


local setOwnerFunc = function(vplayer, model, entity)
	local tEnt = entity
	if(tEnt == nil) then -- some of the hooks only have 2 parameters.
		tEnt = model
	end
	if(tEnt) then
		tEnt.Vermilion_Owner = vplayer:SteamID()
		--[[ if(not tEnt:IsPlayer()) then
			tEnt:SetCustomCollisionCheck(true)
		end ]]
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
	local notLimitHit = vplayer:CheckLimit(vtype)
	if(notLimitHit == true) then
		return true
	end
end

Vermilion:RegisterHook("PlayerSpawnProp", "Vermilion_GMFixProp", function(vplayer, model)
	if(not Vermilion:HasPermission(vplayer, "spawn_all")) then
		if(not Vermilion:HasPermission(vplayer, "spawn_prop")) then
			return false
		end
	end
	return SpawnLimitHitFunc(vplayer, "props")
end)

Vermilion:RegisterHook("PlayerSpawnRagdoll", "Vermilion_GMFixRagdoll", function(vplayer, model)
	if(not Vermilion:HasPermission(vplayer, "spawn_all")) then
		if(not Vermilion:HasPermission(vplayer, "spawn_ragdoll")) then
			return false
		end
	end
	return SpawnLimitHitFunc(vplayer, "ragdolls")
end)

Vermilion:RegisterHook("PlayerSpawnEffect", "Vermilion_GMFixEffect", function(vplayer, model)
	if(not Vermilion:HasPermission(vplayer, "spawn_all")) then
		if(not Vermilion:HasPermission(vplayer, "spawn_effect")) then
			return false
		end
	end
	return SpawnLimitHitFunc(vplayer, "effects")
end)

Vermilion:RegisterHook("PlayerSpawnVehicle", "Vermilion_GMFixVehicle", function(vplayer, model, vehicle, tab)
	if(not Vermilion:HasPermission(vplayer, "spawn_all")) then
		if(not Vermilion:HasPermission(vplayer, "spawn_vehicle")) then
			return false
		end
	end
	return SpawnLimitHitFunc(vplayer, "vehicles")
end)

Vermilion:RegisterHook("PlayerSpawnSWEP", "Vermilion_GMFixSWEP", function(vplayer, swepName, swepTab)
	if(not Vermilion:HasPermission(vplayer, "spawn_all")) then
		if(not Vermilion:HasPermission(vplayer, "spawn_weapon")) then
			return false
		end
	end
	return SpawnLimitHitFunc(vplayer, "sents")
end)

Vermilion:RegisterHook("PlayerSpawnSENT", "Vermilion_GMFixSENT", function(vplayer, name)
	if(not Vermilion:HasPermission(vplayer, "spawn_all")) then
		if(not Vermilion:HasPermission(vplayer, "spawn_entity")) then
			return false
		end
	end
	return SpawnLimitHitFunc(vplayer, "sents")
end)

Vermilion:RegisterHook("PlayerSpawnNPC", "Vermilion_GMFixNPC", function(vplayer, npc_typ, equipment)
	if(not Vermilion:HasPermission(vplayer, "spawn_all")) then
		if(not Vermilion:HasPermission(vplayer, "spawn_npc")) then
			return false
		end
	end
	return SpawnLimitHitFunc(vplayer, "npcs")
end)
