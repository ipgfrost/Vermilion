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

-- Merge this file into sbox_limits

local EXTENSION = Vermilion:MakeExtensionBase()
EXTENSION.Name = "Fall Damage Limiter"
EXTENSION.ID = "falldamage"
EXTENSION.Description = "Handles fall damage limits"
EXTENSION.Author = "Ned"
EXTENSION.Permissions = {
	"no_fall_damage",
	"reduced_fall_damage"
}
EXTENSION.RankPermissions = {
	{ "admin", {
			"no_fall_damage"
		}
	},
	{ "player", {
			"reduced_fall_damage"
		}
	}
}

function EXTENSION:InitServer()
	self:AddHook("GetFallDamage", "Vermilion_FallDamage", function(vplayer, speed)
		if(Vermilion:GetSetting("global_no_fall_damage", false)) then
			return 0
		end
		if(Vermilion:HasPermission(vplayer, "no_fall_damage")) then
			return 0
		end
		if(Vermilion:HasPermission(vplayer, "reduced_fall_damage")) then
			return 5
		end
	end)
end

Vermilion:RegisterExtension(EXTENSION)
