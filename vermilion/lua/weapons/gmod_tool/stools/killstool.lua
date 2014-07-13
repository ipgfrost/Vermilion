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

TOOL.Category = "Vermilion"
TOOL.Name = "Kill"
TOOL.Tab = "Vermilion"
TOOL.Command = nil
TOOL.ConfigName = ""

if(CLIENT) then
	language.Add("tool.killstool.name", "Kill Tool")
	language.Add("tool.killstool.desc", "Go and KILL them!")
	language.Add("tool.killstool.0", "Left Click for murder!")
end

if(SERVER) then AddCSLuaFile("vermilion/crimson_gmod.lua") end
include("vermilion/crimson_gmod.lua")


function TOOL:LeftClick( trace )
	if(trace.Entity) then
		if(trace.Entity:IsPlayer()) then 
			if(SERVER) then 
				trace.Entity:Kill()
				Vermilion:broadcastNotify(trace.Entity:GetName() .. " was killed by " .. self:GetOwner():GetName() .. "!", 10, NOTIFY_UNDO)
			end
			return true
		else
			if(SERVER and not trace.Entity:IsWorld()) then
				Vermilion:SendNotify(self:GetOwner(), "That isn't a player!", 8, NOTIFY_ERROR)
			end
		end
	end
	return false
end

function TOOL.BuildCPanel( panel )

end