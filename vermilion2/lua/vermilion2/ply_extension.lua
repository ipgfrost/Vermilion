--[[
 Copyright 2015 Ned Hyett, 

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

local PLAYER = FindMetaTable("Player")

function PLAYER:VHasPermission(permission)
	return Vermilion:HasPermission(self, permission)
end

function PLAYER:VGetUserData()
	return Vermilion:GetUser(self)
end

function PLAYER:VGetRankData()
	return self:VGetUserData():GetRank()
end

function PLAYER:VGetRankName()
	return self:VGetUserData():GetRankName()
end

function PLAYER:Vermilion2_DoRagdoll()
	if(not self.Vermilion2_Ragdoll and self:Alive()) then
		local ragdoll = ents.Create("prop_ragdoll")
		ragdoll:SetModel(self:GetModel())
		ragdoll:SetPos(self:GetPos())
		ragdoll:SetAngles(self:GetAngles())
		ragdoll:Spawn()
		ragdoll:Activate()
		ragdoll:GetPhysicsObject():ApplyForceCenter(self:GetPhysicsObject():GetVelocity() * 5000)
		self:DrawViewModel(false)
		self:StripWeapons()
		self:Spectate(OBS_MODE_CHASE)
		self:SpectateEntity(ragdoll)
		self:SetParent(ragdoll)
		self.Vermilion2_Ragdoll = ragdoll
		return true
	else
		self:SetNoTarget(false)
		self:SetParent()
		local movepos = self.Vermilion2_Ragdoll:GetPos()
		local facepos = self.Vermilion2_Ragdoll:GetAngles()
		self.Vermilion2_Ragdoll:Remove()
		self.Vermilion2_Ragdoll = nil
		self:Spawn()
		self:SetPos(movepos)
		self:SetAngles(facepos)
		return false
	end
end
