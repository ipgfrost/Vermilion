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

TOOL.Category = "Admin"
TOOL.Name = "Kick Driver"
TOOL.Tab = "Vermilion"
TOOL.Command = nil
TOOL.ConfigName = ""

if(CLIENT) then
	language.Add("tool.kickvehicle.name", "Kick Driver Tool")
	language.Add("tool.kickvehicle.desc", "Kick people from their vehicles.")
	language.Add("tool.kickvehicle.0", "Left click to boot them out!")
end

if(SERVER) then AddCSLuaFile("vermilion/crimson_gmod.lua") end
include("vermilion/crimson_gmod.lua")


function TOOL:LeftClick( trace )
	if(trace.Entity) then
		if(trace.Entity:IsVehicle()) then 
			if(SERVER and trace.Entity:GetDriver() != nil and trace.Entity:GetDriver():IsPlayer()) then 
				local trank = Vermilion:LookupRank(Vermilion:GetPlayer(trace.Entity:GetDriver())['rank'])
				local prank = Vermilion:LookupRank(Vermilion:GetPlayer(self:GetOwner())['rank'])
				if(trank < prank) then
					Vermilion:SendNotify(self:GetOwner(), "This player has a higher rank than you.", 10, VERMILION_NOTIFY_ERROR)
					return
				end
				trace.Entity:GetDriver():ExitVehicle()
			end
			return true
		else
			if(SERVER and not trace.Entity:IsWorld()) then
				Vermilion:SendNotify(self:GetOwner(), "That isn't a vehicle!", 8, VERMILION_NOTIFY_ERROR)
			end
		end
	end
	return false
end

function TOOL.BuildCPanel( panel )

end