--[[
 Copyright 2015-16 Ned Hyett

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

TOOL.Category = "Prop Protection"
TOOL.Name = "Public Domain"
TOOL.Tab = "Vermilion 2"
TOOL.Command = nil
TOOL.ConfigName = ""

if(CLIENT) then
	language.Add("tool.vermilion2_public.name", "Public Domain Tool")
	language.Add("tool.vermilion2_public.desc", "Place a prop into the 'public domain' to allow anyone to use it.")
	language.Add("tool.vermilion2_public.0", "Left Click to clear the owner value (use the undo key to reset it)")
end



function TOOL:LeftClick( trace )
	if(trace.Entity and not trace.Entity:IsWorld()) then
		if(SERVER) then
			local tplayer = Vermilion:GetUserBySteamID(trace.Entity.Vermilion_Owner)
			if(tplayer == nil) then
				Vermilion:AddNotification(self:GetOwner(), "Entity " .. tostring(trace.Entity:EntIndex()) .. " doesn't have an owner!", NOTIFY_ERROR)
				return
			end
      if(not trace.Entity:VDoesOwn(self:GetOwner())) then
        Vermilion:AddNotification(self:GetOwner(), "You don't own this.", NOTIFY_ERROR)
        return
      end
      undo.Create("public_domain")
      undo.AddFunction(function(tab, ent, ownerEnt)
        Vermilion:AddNotification(self:GetOwner(), "Ownership restored.", NOTIFY_HINT)
        ent:VSetOwner(ownerEnt)
      end, trace.Entity, self:GetOwner())
      undo.SetPlayer(self:GetOwner())
      undo.Finish()
      trace.Entity:VSetOwner(nil)
    end
	end
	return true
end
