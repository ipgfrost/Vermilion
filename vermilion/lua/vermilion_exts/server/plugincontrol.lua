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
EXTENSION.Name = "Extension Controls"
EXTENSION.ID = "extensioncontrol"
EXTENSION.Description = "Allows for extensions to be controlled"
EXTENSION.Author = "Ned"
EXTENSION.Permissions = {
	"enable_extension",
	"disable_extension",
	"reload_extension",
	"reload_all_extensions"
}

function EXTENSION:init()
	Vermilion:addChatCommand("reloadext", function(sender, text)
		if(Crimson.tableLen(text) == 0) then
			Vermilion:sendNotify(sender, "Invalid syntax!", 5, NOTIFY_ERROR)
			return
		end
		if(text[1] == "*") then
			if(Vermilion:hasPermissionVerboseChat(sender, "reload_all_extensions")) then
				for i,extension in pairs(Vermilion.extensions) do
					Vermilion.log("De-initialising extension: " .. i)
					Vermilion:sendNotify(sender, "De-initialising extension: " .. i, 5, NOTIFY_HINT)
					extension:destroy()
				end
				Vermilion.extensions = {}
				local expr = nil

				if(SERVER) then
					expr = "vermilion_exts/server/"
				elseif(CLIENT) then
					expr = "vermilion_exts/client/"
				end

				for _,ext in ipairs( file.Find(expr .. "*.lua", "LUA") ) do
					include(expr .. ext)
				end
				for _,ext in ipairs( file.Find("vermilion_exts/shared/*.lua", "LUA") ) do
					include("vermilion_exts/shared/" .. ext)
				end

				for i,extension in pairs(Vermilion.extensions) do
					Vermilion.log("Initialising extension: " .. i)
					Vermilion:sendNotify(sender, "Initialising extension: " .. i, 5, NOTIFY_HINT)
					extension:init()
				end
			end
		end
	end)
end

Vermilion:registerExtension(EXTENSION)