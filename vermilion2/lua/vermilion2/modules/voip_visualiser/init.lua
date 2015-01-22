--[[
 Copyright 2014 Ned Hyett, 

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

local MODULE = MODULE
MODULE.Name = "VoIP Visualisers"
MODULE.ID = "voip_visualiser"
MODULE.Description = "Displays a 3D graph of the recent VoIP volume."
MODULE.Author = "Ned"
MODULE.NetworkStrings = {
	"VUpdateClientColour"
}
MODULE.ConVars = {
	Client = {
		{
			Name = "vermilion_render_voip",
			Value = 1,
			Keep = true,
			Userdata = false
		},
		{
			Name = "vermilion_voipgraph_r",
			Value = 0,
			Keep = true,
			Userdata = false
		},
		{
			Name = "vermilion_voipgraph_g",
			Value = 0,
			Keep = true,
			Userdata = false
		},
		{
			Name = "vermilion_voipgraph_b",
			Value = 255,
			Keep = true,
			Userdata = false
		}
	}
}

function MODULE:InitServer()
	self:NetHook("VUpdateClientColour", function(vplayer)
		local colour = net.ReadColor()
		vplayer:SetNWInt("VVoIPR", colour.r)
		vplayer:SetNWInt("VVoIPG", colour.g)
		vplayer:SetNWInt("VVoIPB", colour.b)
	end)
end

function MODULE:InitClient()

	local function sendColourToServer()
		MODULE:NetStart("VUpdateClientColour")
		net.WriteColor(Color(GetConVarNumber("vermilion_voipgraph_r"), GetConVarNumber("vermilion_voipgraph_g"), GetConVarNumber("vermilion_voipgraph_b")))
		net.SendToServer()
	end

	self:AddHook(Vermilion.Event.MOD_LOADED, function()
		if(Vermilion:GetModule("client_settings") != nil) then
			Vermilion:GetModule("client_settings"):AddOption({
				GuiText = "Render VoIP Graphs",
				ConVar = "vermilion_render_voip",
				Type = "Checkbox",
				Category = "Features"
			})
			Vermilion:GetModule("client_settings"):AddOption({
				GuiText = "My VoIP graph colour",
				UpdateFunc = function(value)
					RunConsoleCommand("vermilion_voipgraph_r", value.r)
					RunConsoleCommand("vermilion_voipgraph_g", value.g)
					RunConsoleCommand("vermilion_voipgraph_b", value.b)
					sendColourToServer()
				end,
				Type = "Colour",
				Category = "Graphics"
			})
		end
	end)
	
	sendColourToServer()

	self:AddHook("PlayerStartVoice", function(vplayer)
		vplayer.Vermilion_VoIPHistory = {}
	end)
	
	self:AddHook("PlayerEndVoice", function(vplayer)
		vplayer.Vermilion_VoIPHistory = nil
	end)
	

	self:AddHook("PostDrawOpaqueRenderables", function()
		if(GetConVarNumber("vermilion_render_voip") == 0) then return end
		for i,k in pairs(player.GetAll()) do
			if(k.Vermilion_VoIPHistory != nil and k:Alive()) then
				if(table.getn(k.Vermilion_VoIPHistory) == 80) then
					for var = 2, 80, 1 do
						k.Vermilion_VoIPHistory[var - 1] = k.Vermilion_VoIPHistory[var]
					end
					k.Vermilion_VoIPHistory[80] = (k:VoiceVolume() * 100) + 0.01
				else
					k.Vermilion_VoIPHistory[table.getn(k.Vermilion_VoIPHistory) + 1] = (k:VoiceVolume() * 100) + 0.01
				end
			end
		end
		for i,k in pairs(player.GetAll()) do
			surface.SetDrawColor(k:GetNWInt("VVoIPR", 0), k:GetNWInt("VVoIPG", 0), k:GetNWInt("VVoIPB", 255), 255)
			if(k.Vermilion_VoIPHistory != nil and k:Alive()) then
				local sang = k:EyeAngles()
				sang:RotateAroundAxis(Vector(0, 0, 1), -90)
				sang:Set(Angle(0, sang.yaw, -90))
				local spos = k:GetPos()
				spos:Add(Vector(0, 0, 25))
				local sang1 = Angle(90, sang.yaw, 0):Up()
				sang1:Mul(25)
				spos:Add(sang1)
				cam.Start3D2D(spos, sang, 1)
				local xpos = 0
				for i1,voiph in pairs(k.Vermilion_VoIPHistory) do
					for i2 = -0.3, 0.3, 0.1 do
						if(table.Count(k.Vermilion_VoIPHistory) == i1) then
							surface.DrawLine(xpos, voiph + i2, xpos + 1, voiph + i2)
						else
							surface.DrawLine(xpos, voiph + i2, xpos + 1, k.Vermilion_VoIPHistory[i1 + 1] + i2)
						end
					end
					xpos = xpos + 1
				end
				cam.End3D2D()
			end
		end
	end)
end
