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
EXTENSION.Name = "Sandbox Limits"
EXTENSION.ID = "sbox_limits"
EXTENSION.Description = "Handles sandbox limits"
EXTENSION.Author = "Ned"
EXTENSION.Permissions = {
	"no_damage"
}

function EXTENSION:init()
	local META = FindMetaTable("Player")
	if(META.Vermilion_CheckLimit == nil) then
		META.Vermilion_CheckLimit = META.CheckLimit
	end
	function META:CheckLimit(str)
		if(not Vermilion:getSetting("enable_limit_remover", true)) then
			return self:Vermilion_CheckLimit(str)
		end
		if(self:Vermilion_GetRank() <= Vermilion:getSetting("limit_remover_min_rank", 2)) then
			return true
		end
		return self:Vermilion_CheckLimit(str)
	end
	
	self:addHook("EntityTakeDamage", "V_PlayerHurt", function(target, dmg)
		if(not target:IsPlayer()) then return end
		if(Vermilion:getSetting("global_no_damage", false)) then
			dmg:ScaleDamage(0)
			return dmg
		end
		if(Vermilion:hasPermission(target, "no_damage")) then
			dmg:ScaleDamage(0)
			return dmg
		end
	end)
end

Vermilion:registerExtension(EXTENSION)