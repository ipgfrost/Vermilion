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
			{ "no_fall_damage" }
		}
	},
	{ "player", {
			{ "reduced_fall_damage" }
		}
	}
}

function EXTENSION:init()
	self:addHook("GetFallDamage", "Vermilion_FallDamage", function(vplayer, speed)
		if(Vermilion:getSetting("global_no_fall_damage", false)) then
			return 0
		end
		if(Vermilion:hasPermission(vplayer, "no_fall_damage")) then
			return 0
		end
		if(Vermilion:hasPermission(vplayer, "reduced_fall_damage")) then
			return speed / 50
		end
	end)
end

Vermilion:registerExtension(EXTENSION)
