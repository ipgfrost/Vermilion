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

local EXTENSION = Vermilion:MakeExtensionBase()
EXTENSION.Name = "Physgun Limiter"
EXTENSION.ID = "physgun"
EXTENSION.Description = "Handles physgun limits"
EXTENSION.Author = "Ned"
EXTENSION.Permissions = {
	"physgun_pickup_all",
	"physgun_pickup_own",
	"physgun_pickup_others",
	"physgun_pickup_players",
	"physgun_persist"
}
EXTENSION.RankPermissions = {
	{ "admin", {
			"physgun_pickup_all",
			"physgun_pickup_players"
		}
	},
	{ "player", {
			"physgun_pickup_own"
		}
	}
}

function EXTENSION:InitServer()
	self:AddHook("OnPhysgunFreeze", "Vermilion_Physgun_Freeze", function( weapon, phys, ent, vplayer )
		if(ent:GetPersistent() and Vermilion:HasPermission(vplayer, "physgun_persist")) then
			return true
		end
	end)
	self:AddHook("PhysgunPickup", "Vermilion_Physgun_Pickup", function(vplayer, ent)
		if(ent:IsPlayer() and Vermilion:HasPermission(vplayer, "physgun_pickup_players")) then
			return true
		end
		if(ent:GetPersistent() and Vermilion:HasPermission(vplayer, "physgun_persist")) then
			return true
		end
		if(not Vermilion:HasPermission(vplayer, "physgun_pickup_all") and ent.Vermilion_Owner != nil) then
			if(ent.Vermilion_Owner == vplayer:SteamID() and not Vermilion:HasPermission(vplayer, "physgun_pickup_own")) then
				return false
			elseif (ent.Vermilion_Owner != vplayer:SteamID() and not Vermilion:HasPermission(vplayer, "physgun_pickup_others")) then
				return false
			end
		end
	end)
end

Vermilion:RegisterExtension(EXTENSION)