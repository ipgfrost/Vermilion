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
TOOL.Name = "Force Transfer"
TOOL.Tab = "Vermilion 2"
TOOL.Command = nil
TOOL.ConfigName = ""

if(CLIENT) then
	language.Add("tool.vermilion2_setowner.name", "Force Transfer Tool")
	language.Add("tool.vermilion2_setowner.desc", "Force a prop to be reassigned to another player.")
	language.Add("tool.vermilion2_setowner.0", "Left click to set the owner of a prop, right click to select a player or reload to select yourself.")
end



function TOOL:LeftClick(trace)
	if(trace.Entity and not trace.Entity:IsWorld()) then
		local ent = trace.Entity
		if(SERVER) then
			if(self.Target == nil) then
				Vermilion:AddNotification(self:GetOwner(), "You need to select a target player first.", NOTIFY_ERROR)
				return
			end
			local tplayer = Vermilion:GetUserBySteamID(trace.Entity.Vermilion_Owner)
			if(tplayer == nil) then
				if(not trace.Entity:VDoesOwn(self:GetOwner()) and not Vermilion:HasPermission(self:GetOwner(), "allow_force_transfer_override")) then
					Vermilion:AddNotification(self:GetOwner(), "Entity " .. tostring(trace.Entity:EntIndex()) .. " doesn't have an owner!", NOTIFY_ERROR)
					return
				end
				ent:VSetOwner(self.Target)
				Vermilion:AddNotification(self:GetOwner(), "This prop is now the property of " .. self.Target:GetName(), NOTIFY_HINT)
				return
			end
      if(not trace.Entity:VDoesOwn(self:GetOwner()) and not Vermilion:HasPermission(self:GetOwner(), "allow_force_transfer_override")) then
        Vermilion:AddNotification(self:GetOwner(), "You don't own this.", NOTIFY_ERROR)
        return
      end
      trace.Entity:VSetOwner(self.Target)
	  	Vermilion:AddNotification(self:GetOwner(), "This prop is now the property of " .. self.Target:GetName(), NOTIFY_HINT)
    end
	end
	return true
end

function TOOL:RightClick(trace)
	if(trace.Entity and trace.Entity:IsPlayer()) then
		self.Target = trace.Entity
		return true
	end
end

function TOOL:Reload()
	self.Target = self:GetOwner()
end

function TOOL:DrawToolScreen(w, h)
	surface.SetDrawColor(Color(20, 20, 20))
	surface.DrawRect(0, 0, w, h)

	local target = "Nobody"
	if(self.Target != nil) then
		target = self.Target:GetName()
	end

	draw.SimpleText("Selected Player:", "DermaLarge", w / 2, h / 2 - 50, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	draw.SimpleText(target, "DermaLarge", w / 2, h / 2, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end
