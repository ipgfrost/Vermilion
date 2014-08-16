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

TOOL.Category = "Vermilion Dev Toolkit"
TOOL.Name = "What is that?"
TOOL.Tab = "Vermilion"
TOOL.Command = nil
TOOL.ConfigName = ""

if(CLIENT) then
	language.Add("tool.whatisthat.name", "What is that? (Vermilion Dev Toolkit)")
	language.Add("tool.whatisthat.desc", "Figure out what an entity is.")
	language.Add("tool.whatisthat.0", "Guess what left click does?")
end



function TOOL:LeftClick( trace )
	if(CLIENT) then return true end
	if(not trace.Hit) then
		Vermilion:SendNotify(self:GetOwner(), "You didn't click on a valid object.")
	else
		Vermilion:SendNotify(self:GetOwner(), "That's a " .. trace.Entity:GetClass() .. " (" .. tostring(trace.Entity) .. ")")
	end
	return true
end