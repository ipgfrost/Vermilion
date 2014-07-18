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

TOOL.Category = "Vermilion"
TOOL.Name = "Disposition"
TOOL.Tab = "Vermilion"
TOOL.Command = nil
TOOL.ConfigName = ""

if(CLIENT) then
	language.Add("tool.dispostool.name", "Disposition Tool")
	language.Add("tool.dispostool.desc", "Set NPC dispositions towards you.")
	language.Add("tool.dispostool.0", "Left Click to make the NPC like you, right click to make the NPC hate you!")
end

if(SERVER) then AddCSLuaFile("vermilion/crimson_gmod.lua") end
include("vermilion/crimson_gmod.lua")


function TOOL:LeftClick( trace )
	if(trace.Entity) then
		if(trace.Entity:IsNPC()) then 
			if(SERVER) then
				trace.Entity:AddEntityRelationship(self:GetOwner(), D_LI, 99)
			end
			return true
		end
	end
	return false
end

function TOOL:RightClick( trace )
	if(trace.Entity) then
		if(trace.Entity:IsNPC()) then 
			if(SERVER) then
				trace.Entity:AddEntityRelationship(self:GetOwner(), D_HT, 99)
			end
			return true
		end
	end
	return false
end
