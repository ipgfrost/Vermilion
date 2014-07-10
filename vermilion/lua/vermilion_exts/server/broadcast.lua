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
EXTENSION.Name = "Broadcast Message Chat Command"
EXTENSION.ID = "broadcast"
EXTENSION.Description = "Broadcasts a hint"
EXTENSION.Author = "Ned"
EXTENSION.Permissions = {
	"broadcast_hint"
}
EXTENSION.RankPermissions = {
	{ "admin", {
			{ "broadcast_hint" }
		}
	}
}

function EXTENSION:init()
	Vermilion:addChatCommand("broadcast", function(sender, text)
		if(Vermilion:hasPermissionVerboseChat(sender, "broadcast_hint")) then
			Vermilion:broadcastNotify(table.concat(text, " ", 1, table.Count(text)), 10, NOTIFY_HINT)
		end
	end)
end

Vermilion:registerExtension(EXTENSION)