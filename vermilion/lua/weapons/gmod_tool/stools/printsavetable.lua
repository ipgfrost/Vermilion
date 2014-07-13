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

-- This tool needs a rethink...

TOOL.Category = "Vermilion"
TOOL.Name = "Save Table"
TOOL.Tab = "Vermilion"
TOOL.Command = nil
TOOL.ConfigName = ""

if(CLIENT) then
	language.Add("tool.printsavetable.name", "Save Table Tool")
	language.Add("tool.printsavetable.desc", "Print an entity save table")
	language.Add("tool.printsavetable.0", "Left Click to print the save table")
end



function TOOL:LeftClick( trace )
	if(trace.Entity and not trace.Entity:IsWorld()) then
		if(SERVER) then
			for k,v in pairs(trace.Entity:GetSaveTable()) do
				print(k .. " => " .. tostring(v))
			end
		end
	end
	return true
end