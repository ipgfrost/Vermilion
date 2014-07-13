--[[
 The MIT License

 Copyright 2014 Ned Hyett.

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
]]

local EXTENSION = Vermilion:MakeExtensionBase()
EXTENSION.Name = "Sound Controls"
EXTENSION.ID = "sound"
EXTENSION.Description = "Plays sounds and stuff"
EXTENSION.Author = "Ned"
EXTENSION.Permissions = {
	"playsound",
	"stopsound"
}

function EXTENSION:InitServer()
	Vermilion:AddChatCommand("playsound", function(sender, text)
		if(text[1] == "-targetplayer") then
			local targetPlayer = Crimson.LookupPlayerByName(text[2])
			if(targetPlayer != nil) then
				Vermilion:SendNotify(sender, "Playing " .. table.concat(text, " ", 3, table.Count(text)) .. " to " .. text[2], 10, NOTIFY_GENERIC)
				Vermilion:PlaySound(targetPlayer, table.concat(text, " ", 3, table.Count(text)))
			else
				Vermilion:SendNotify(sender, "Invalid target!", 10, NOTIFY_ERROR)
				return
			end
		end
		Vermilion:BroadcastSound(table.concat(text, " ", 1, table.Count(text)))
	end)
end

Vermilion:RegisterExtension(EXTENSION)