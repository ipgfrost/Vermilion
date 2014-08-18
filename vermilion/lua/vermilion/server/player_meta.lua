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

--[[
	Place all global modifications to the player metatable here. Functions that should be globally accessible regardless of extensions
	being installed go here.
]]--

local META = FindMetaTable("Player")

function META:Vermilion_GetRank()
	return Vermilion:GetRank(self)
end

function META:Vermilion_IsOwner()
	return Vermilion:IsOwner(self)
end

function META:Ban()
	Vermilion.Log("Warning: standard ban attempted!")
end

function META:HasPermission(permission)
	return Vermilion:HasPermission(self, permission)
end

function META:Vermilion_DoRagdoll()
	if(not self.Vermilion_Ragdoll and self:Alive()) then
		self:DrawViewModel(false)
		self:StripWeapons()
		
		local ragdoll = ents.Create("prop_ragdoll")
		ragdoll:SetModel(self:GetModel())
		ragdoll:SetPos(self:GetPos())
		ragdoll:Spawn()
		ragdoll:Activate()
		
		self:Spectate(OBS_MODE_CHASE)
		self:SpectateEntity(ragdoll)
		self:SetParent(ragdoll)
		self.Vermilion_Ragdoll = ragdoll
	else
		self:SetNoTarget(false)
		self:SetParent()
		self.Vermilion_Ragdoll:Remove()
		self.Vermilion_Ragdoll = nil
		self:Spawn()
	end
end

Vermilion:RegisterHook("CanPlayerSuicide", "RagdollSuicide", function(vplayer)
	if(vplayer.Vermilion_Ragdoll) then return false end
end)

Vermilion:RegisterHook("PlayerDisconnect", "RagdollDisconnect", function(vplayer)
	if(vplayer.Vermilion_Ragdoll and IsValid(vplayer.Vermilion_Ragdoll)) then vplayer.Vermilion_Ragdoll:Remove() end
end)

Vermilion:RegisterHook("PlayerSpawn", "RagdollRespawn", function(vplayer)
	if(vplayer.Vermilion_Ragdoll) then
		vplayer:Vermilion_DoRagdoll() -- remove the old one
		vplayer:Vermilion_DoRagdoll() -- create a new one
	end
end)
