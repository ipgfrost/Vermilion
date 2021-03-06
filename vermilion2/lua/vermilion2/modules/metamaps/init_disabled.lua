--[[
 Copyright 2015-16 Ned Hyett,

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

local MODULE = MODULE
MODULE.Name = "Multiverse"
MODULE.ID = "multiverse"
MODULE.Description = "Welcome to the multiverse! Create multiple dimensions inside the same map to get \"infinite space\"!"
MODULE.Author = "Ned"
MODULE.StartDisabled = true
MODULE.Permissions = {
	"manage_multiverse"
}
MODULE.NetworkStrings = {

}

function MODULE:InitServer()
	self:AddHook(Vermilion.Event.AnythingSpawned, function(vplayer, ent)
		ent:SetNWInt("VActiveDimension", vplayer:GetNWInt("VActiveDimension", 0))
		ent:SetCustomCollisionCheck(true)
	end)

	self:AddHook("PlayerInitialSpawn", function(vplayer)
		vplayer:SetNWInt("VActiveDimension", 0)
		vplayer:SetCustomCollisionCheck(true)
	end)


end

function MODULE:InitClient()
	
end

function MODULE:InitShared()
	self:AddHook("ShouldCollide", function(e1, e2)
		if(e1:GetNWInt("VActiveDimension", 0) != e2:GetNWInt("VActiveDimension", 0)) then return false end
	end)
end
