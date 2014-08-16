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

TOOL.Category = "Misc"
TOOL.Name = "Teleport"
TOOL.Tab = "Vermilion"
TOOL.Command = nil
TOOL.ConfigName = ""

if(CLIENT) then
	language.Add("tool.teleporttool.name", "Teleport Tool")
	language.Add("tool.teleporttool.desc", "Teleport yourself somewhere")
	language.Add("tool.teleporttool.0", "Left Click: teleport. Right Click: teleport through a wall.")
end

function TOOL:LeftClick( trace )
	if(SERVER and trace.Hit) then
		local tpos = trace.HitPos
		local radius1 = util.IsInWorld(tpos + Vector(20, 0, 0))
		local radius2 = util.IsInWorld(tpos + Vector(0, 20, 0))
		local radius3 = util.IsInWorld(tpos - Vector(20, 0, 0))
		local radius4 = util.IsInWorld(tpos - Vector(0, 20, 0))
		if(not (radius1 and radius2 and radius3 and radius4)) then
			tpos:Sub(trace.HitNormal * 20)
		end
		if(not util.IsInWorld(tpos + Vector(0, 0, 80))) then
			tpos:Sub(Vector(0, 0, 85))
		end
		self:GetOwner():SetPos(tpos)
	end
	return true
end

function TOOL:RightClick( trace )
	if(SERVER and trace.Hit) then
		local tpos = trace.HitPos
		local minmdl, maxmdl = self:GetOwner():GetModelBounds()
		for var=1,2000,1 do
			tpos:Sub(trace.HitNormal)
			minmdl:Sub(trace.HitNormal)
			maxmdl:Sub(trace.HitNormal)
			local radius1 = util.IsInWorld(tpos + Vector(30, 0, 0))
			local radius2 = util.IsInWorld(tpos + Vector(0, 30, 0))
			local radius3 = util.IsInWorld(tpos - Vector(30, 0, 0))
			local radius4 = util.IsInWorld(tpos - Vector(0, 30, 0))
			local tradius = radius1 and radius2 and radius3 and radius4 and (table.Count(ents.FindInBox(maxmdl, minmdl)) == 0)
			if(util.IsInWorld(tpos) and util.IsInWorld(tpos + Vector(0, 0, 80)) and tradius) then
				self:GetOwner():SetPos(tpos)
				break
			end
		end
	end
	return true
end