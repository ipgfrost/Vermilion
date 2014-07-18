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
EXTENSION.Name = "Gravity Gun Limiter"
EXTENSION.ID = "gravgun"
EXTENSION.Description = "Handles gravity gun limits"
EXTENSION.Author = "Ned"
EXTENSION.Permissions = {
	"grav_gun_pickup_all",
	"grav_gun_pickup_own",
	"grav_gun_pickup_others",
	"grav_gun_punt_all",
	"grav_gun_punt_own",
	"grav_gun_punt_others"
}
EXTENSION.RankPermissions = {
	{ "admin", {
			"grav_gun_pickup_all",
			"grav_gun_punt_all"
		}
	},
	{ "player", {
			"grav_gun_pickup_own",
			"grav_gun_punt_own"
		}
	}
}

function EXTENSION:InitServer()
	self:AddHook("GravGunPickupAllowed", "Vermilion_GravGunPickup", function(vplayer, ent)
		if(not Vermilion:HasPermission(vplayer, "grav_gun_pickup_all")) then
			if(ent.Vermilion_Owner == vplayer:SteamID() and not Vermilion:HasPermission(vplayer, "grav_gun_pickup_own")) then
				return false
			end
			if(ent.Vermilion_Owner != vplayer:SteamID() and not Vermilion:HasPermission(vplayer, "grav_gun_pickup_others")) then
				return false
			end
		end
	end)
	
	self:AddHook("GravGunPunt", "Vermilion_GravGunPunt", function(vplayer, ent)
		if(not Vermilion:HasPermission(vplayer, "grav_gun_punt_all")) then
			if(ent.Vermilion_Owner == vplayer:SteamID() and not Vermilion:HasPermission(vplayer, "grav_gun_punt_own")) then
				return false
			end
			if(ent.Vermilion_Owner != vplayer:SteamID() and not Vermilion:HasPermission(vplayer, "grav_gun_punt_others")) then
				return false
			end
		end
	end)
end

Vermilion:RegisterExtension(EXTENSION)


