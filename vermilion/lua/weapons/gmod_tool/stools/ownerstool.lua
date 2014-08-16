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

TOOL.Category = "Vermilion Dev Toolkit"
TOOL.Name = "Owner"
TOOL.Tab = "Vermilion"
TOOL.Command = nil
TOOL.ConfigName = ""

if(CLIENT) then
	language.Add("tool.ownerstool.name", "Owner Tool (Vermilion Dev Toolkit)")
	language.Add("tool.ownerstool.desc", "Figure out who owns what")
	language.Add("tool.ownerstool.0", "Left Click to print the owner")
end



function TOOL:LeftClick( trace )
	if(trace.Entity and not trace.Entity:IsWorld()) then
		if(SERVER) then
			local tplayer = Vermilion:GetPlayerBySteamID(trace.Entity.Vermilion_Owner)
			if(tplayer == nil) then
				Vermilion:SendNotify(self:GetOwner(), "This prop doesn't have an owner.", VERMILION_NOTIFY_HINT)
				return
			end
			Vermilion:SendNotify(self:GetOwner(), "Owner: " .. tplayer.name, 5, VERMILION_NOTIFY_HINT)
		end
	end
	return true
end