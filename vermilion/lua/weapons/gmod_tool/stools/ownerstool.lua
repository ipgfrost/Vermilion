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

-- This tool needs a rethink...

TOOL.Category = "Vermilion"
TOOL.Name = "Owner"
TOOL.Tab = "Vermilion"
TOOL.Command = nil
TOOL.ConfigName = ""

if(CLIENT) then
	language.Add("tool.ownerstool.name", "Owner Tool")
	language.Add("tool.ownerstool.desc", "Figure out who owns what")
	language.Add("tool.ownerstool.0", "Left Click to print the owner")
end



function TOOL:LeftClick( trace )
	if(trace.Entity) then
		if(SERVER) then
			Vermilion:sendNotify(self:GetOwner(), "Owner: " .. tostring(trace.Entity.Vermilion_Owner), 5, NOTIFY_GENERIC)
		end
	end
	return false
end