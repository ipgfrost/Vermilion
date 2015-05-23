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

TOOL.Category = "Misc"
TOOL.Name = "Print Save Table"
TOOL.Tab = "Vermilion 2"
TOOL.Command = nil
TOOL.ConfigName = ""

if(CLIENT) then
	language.Add("tool.vermilion2_savetable.name", "Print Table Tool (Vermilion 2 Dev Toolkit)")
	language.Add("tool.vermilion2_savetable.desc", "Print an entity save table")
	language.Add("tool.vermilion2_savetable.0", "Left Click to print the save table")
end

function TOOL:LeftClick( trace )
	print(trace.Entity)
	if(trace.Entity and not trace.Entity:IsWorld()) then
		if(SERVER) then
			for k,v in pairs(trace.Entity:GetSaveTable()) do
				print(k .. " => " .. tostring(v))
			end
		end
	end
	return true
end