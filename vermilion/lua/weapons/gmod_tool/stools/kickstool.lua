--[[
 Copyright 2014 Ned Hyett

 Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except
 in compliance with the License. You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under the License
 is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
 or implied. See the License for the specific language governing permissions and limitations under
 the License.
 
 The right to upload this project to the Steam Workshop (which is operated by Valve Corporation) 
 is reserved by the original copyright holder, regardless of any modifications made to the code,
 resources or related content. The original copyright holder is not affiliated with Valve Corporation
 in any way, nor claims to be so. 
]]

-- This tool needs a rethink...

TOOL.Category = "Admin"
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
				if(Vermilion:HasPermissionError(self:GetOwner(), "kick")) then
					if(trace.Entity:IsPlayer()) then
						if(not Vermilion:CalcImmunity(self:GetOwner(), trace.Entity)) then
							Vermilion:SendNotify(self:GetOwner(), "This player has a higher rank than you.", 10, VERMILION_NOTIFY_ERROR)
							return
						end
					end
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