--[[
 Copyright 2015 Ned Hyett

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
TOOL.Category = "Admin"
TOOL.Name = "Kick"
TOOL.Tab = "Vermilion 2"
TOOL.Command = nil
TOOL.ConfigName = ""

if(CLIENT) then
	language.Add("tool.vermilion2_kick.name", "Kick Tool")
	language.Add("tool.vermilion2_kick.desc", "Kick troublemakers efficiently! (requires kick permission)")
	language.Add("tool.vermilion2_kick.0", "Left Click to kick the target.")
end


function TOOL:LeftClick( trace )
	if(trace.Entity) then
		if(trace.Entity:IsPlayer()) then 
			if(SERVER) then
				if(Vermilion:HasPermission(self:GetOwner(), "kick")) then
					if(trace.Entity:IsPlayer()) then
						if(Vermilion:GetUser(trace.Entity):IsImmune(self:GetOwner())) then
							Vermilion:AddNotification(self:GetOwner(), "This player has a higher rank than you.", nil, NOTIFY_ERROR)
							return
						end
					end
					Vermilion:BroadcastNotification(trace.Entity:GetName() .. " was kicked by " .. self:GetOwner():GetName() .. "!")
					trace.Entity:Kick("Kicked by " .. self:GetOwner():GetName())
				else
					Vermilion:AddNotification(self:GetOwner(), "access_denied", nil, NOTIFY_ERROR)
				end
			end
			return true
		end
	end
	return false
end