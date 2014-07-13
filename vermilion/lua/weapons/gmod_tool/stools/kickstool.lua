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
TOOL.Name = "Kick"
TOOL.Tab = "Vermilion"
TOOL.Command = nil
TOOL.ConfigName = ""
TOOL.ReasonConVar = CreateConVar("vermilion_kickreason", "Because of reasons", FCVAR_NONE, "Nope")

if(CLIENT) then
	language.Add("tool.kickstool.name", "Kick Tool")
	language.Add("tool.kickstool.desc", "Kick those troublemakers efficiently!")
	language.Add("tool.kickstool.0", "Left Click to give them what for!")
end

if(SERVER) then AddCSLuaFile("vermilion/crimson_gmod.lua") end
include("vermilion/crimson_gmod.lua")


function TOOL:LeftClick( trace )
	if(trace.Entity) then
		if(trace.Entity:IsPlayer()) then 
			if(SERVER) then
				if(Vermilion:HasPermissionVerboseChat(self:GetOwner(), "kick")) then
					trace.Entity:Kick("Kicked by " .. self:GetOwner():GetName() .. " with reason: " .. self.ReasonConVar:GetString())
				end
			end
			return true
		end
	end
	return false
end

function TOOL.BuildCPanel( panel )
	local reasonLabel = Crimson.CreateLabel("Kick reason: ")
	panel:AddItem(reasonLabel)
	local reasonBox = Crimson.CreateTextbox("Because of reasons", panel, "vermilion_kickreason")
	panel:AddItem(reasonBox)
end