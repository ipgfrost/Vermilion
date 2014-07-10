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
EXTENSION.Name = "Physgun Limiter"
EXTENSION.ID = "physgun"
EXTENSION.Description = "Handles physgun limits"
EXTENSION.Author = "Ned"
EXTENSION.Permissions = {
	"physgun_pickup_all",
	"physgun_pickup_own",
	"physgun_pickup_others"
}
EXTENSION.RankPermissions = {
	{ "admin", {
			{ "physgun_pickup_all" }
		}
	},
	{ "player", {
			{ "physgun_pickup_own" }
		}
	}
}

function EXTENSION:init()
	self:addHook("PhysgunPickup", "Vermilion_Physgun_Pickup", function(vplayer, ent)
		if(not Vermilion:hasPermission(vplayer, "physgun_pickup_all")) then
			if(ent.Vermilion_Owner == vplayer:SteamID() and not Vermilion:hasPermission(vplayer, "physgun_pickup_own")) then
				return false
			elseif (ent.Vermilion_Owner != vplayer:SteamID() and not Vermilion:hasPermission(vplayer, "physgun_pickup_others")) then
				return false
			end
		end
	end)
end

Vermilion:registerExtension(EXTENSION)