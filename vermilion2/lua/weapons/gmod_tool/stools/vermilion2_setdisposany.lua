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

TOOL.Category = "Misc"
TOOL.Name = "Disposition"
TOOL.Tab = "Vermilion 2"
TOOL.Command = nil
TOOL.ConfigName = ""

if(CLIENT) then
	language.Add("tool.vermilion2_setdisposany.name", "Disposition Tool")
	language.Add("tool.vermilion2_setdisposany.desc", "Set NPC dispositions towards stuff")
	language.Add("tool.vermilion2_setdisposany.0", "Left click to select an NPC to modify the behaviour of, reload to select all NPCs.")
	language.Add("tool.vermilion2_setdisposany.1", "Left click to select the target NPC, right click to select yourself and reload to select all NPCs.")
	language.Add("tool.vermilion2_setdisposany.2", "Left click to set the disposition to like, right click to set the disposition to hate.")
end


function TOOL:LeftClick( trace )
	if(self:GetStage() == 0 and trace.Entity and trace.Entity:IsNPC()) then
		if(SERVER) then
			self.SelectedNPC = {trace.Entity}
		end
		self:SetStage(1)
		return true
	end
	if(self:GetStage() == 1 and trace.Entity and (trace.Entity:IsNPC() or trace.Entity:IsPlayer())) then
		if(SERVER) then
			self.TargetNPC = {trace.Entity}
		end
		self:SetStage(2)
		return true
	end
	if(self:GetStage() == 2) then
		if(SERVER) then
			for i,k in pairs(self.SelectedNPC) do
				if(IsValid(k)) then 
					for i1,k1 in pairs(self.TargetNPC) do
						if(IsValid(k1)) then 
							k:AddEntityRelationship(k1, D_LI, 99)
						end
					end
				end
			end
		end
		self:SetStage(0)
		self.SelectedNPC = nil
		self.TargetNPC = nil
		return true
	end
	return false
end

function TOOL:Reload()
	if(self:GetStage() == 0) then
		local tab = {}
		for i,ent in pairs(ents.GetAll()) do
			if(ent:IsNPC()) then table.insert(tab, ent) end
		end
		self.SelectedNPC = tab
		self:SetStage(1)
		return
	end
	if(self:GetStage() == 1) then
		local tab = {}
		for i,ent in pairs(ents.GetAll()) do
			if(ent:IsNPC()) then table.insert(tab, ent) end
		end
		self.TargetNPC = tab
		self:SetStage(2)
		return
	end
end

function TOOL:RightClick( trace )
	if(self:GetStage() == 1) then
		if(SERVER) then
			self.TargetNPC = {self:GetOwner()}
		end
		self:SetStage(2)
		return true
	end
	if(self:GetStage() < 2) then return false end
	if(SERVER) then
		for i,k in pairs(self.SelectedNPC) do
			if(IsValid(k)) then 
				for i1,k1 in pairs(self.TargetNPC) do
					if(IsValid(k1)) then 
						k:AddEntityRelationship(k1, D_HT, 99)
					end
				end
			end
		end
	end
	self:SetStage(0)
	self.SelectedNPC = nil
	self.TargetNPC = nil
	return true
end
