-- The MIT License
--
-- Copyright 2014 Ned Hyett.
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.

local EXTENSION = Vermilion:makeExtensionBase()
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
			{ "grav_gun_pickup_all" },
			{ "grav_gun_punt_all" }
		}
	},
	{ "player", {
			{ "grav_gun_pickup_own" },
			{ "grav_gun_punt_own" }
		}
	}
}

function EXTENSION:init()
	self:addHook("GravGunPickupAllowed", "Vermilion_GravGunPickup", function(vplayer, ent)
		if(not Vermilion:hasPermission(vplayer, "grav_gun_pickup_all")) then
			if(ent.Vermilion_Owner == vplayer:SteamID() and not Vermilion:hasPermission(vplayer, "grav_gun_pickup_own")) then
				return false
			end
			if(ent.Vermilion_Owner != vplayer:SteamID() and not Vermilion:hasPermission(vplayer, "grav_gun_pickup_others")) then
				return false
			end
		end
	end)
	
	self:addHook("GravGunPunt", "Vermilion_GravGunPunt", function(vplayer, ent)
		if(not Vermilion:hasPermission(vplayer, "grav_gun_punt_all")) then
			if(ent.Vermilion_Owner == vplayer:SteamID() and not Vermilion:hasPermission(vplayer, "grav_gun_punt_own")) then
				return false
			end
			if(ent.Vermilion_Owner != vplayer:SteamID() and not Vermilion:hasPermission(vplayer, "grav_gun_punt_others")) then
				return false
			end
		end
	end)
end

Vermilion:registerExtension(EXTENSION)


