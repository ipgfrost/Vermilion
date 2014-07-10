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
EXTENSION.Name = "Ban Manager"
EXTENSION.ID = "bans"
EXTENSION.Description = "Handles bans"
EXTENSION.Author = "Ned"
EXTENSION.Permissions = {
	"ban",
	"unban",
	"kick",
	"bans_alert"
}

function EXTENSION:init()
	self:addHook("CheckPassword", "CheckBanned", function( steamID, ip, svPassword, clPassword, name )
		local playerDat = Vermilion:getPlayerBySteamID(steamID)
		if(playerDat != nil) then
			if(playerDat['rank'] == "banned") then
				Vermilion:sendNotify(Vermilion:getAllPlayersWithPermission("bans_alert"), "Warning: " .. name .. " has attempted to join the server!", 5, NOTIFY_ERROR)
				return false, "You are banned from this server!"
			end
		end
	end)
end

Vermilion:registerExtension(EXTENSION)