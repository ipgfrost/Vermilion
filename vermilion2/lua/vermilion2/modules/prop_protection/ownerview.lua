--[[
 Copyright 2015 Ned Hyett,

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

AddCSLuaFile()

local MODULE = Vermilion:GetModule("prop_protect")

function MODULE:OwnerViewInitServer()
	self:NetHook("VQueryPPSteamID", function(vplayer)
		local steamid = net.ReadString()
		if(Vermilion:GetUserBySteamID(steamid) == nil) then
			MODULE:NetStart("VQueryPPSteamID")
			net.WriteString(steamid)
			net.WriteBoolean(false)
			net.Send(vplayer)
			return
		end
		MODULE:NetStart("VQueryPPSteamID")
		net.WriteString(steamid)
		net.WriteBoolean(true)
		net.WriteString(Vermilion:GetUserBySteamID(steamid).Name)
		net.Send(vplayer)
	end)
end

function MODULE:OwnerViewInitClient()
	CreateClientConVar("vermilion_prop_hud", 1, true, false)

	local owidth = 0
	local owidth1 = 0
	local namedata = nil
	local tentity = nil

	self:NetHook("VQueryPPSteamID", function()
		local sid = net.ReadString()
		if(not net.ReadBoolean()) then
			namedata = false
			return
		end
		namedata = {
			SteamID = sid,
			Name = net.ReadString()
		}
		//Vermilion.Log("Got owner data for " .. namedata.SteamID .. "!")
	end)

	self:AddHook("HUDPaint", function()
		if(GetConVarNumber("vermilion_prop_hud") != 1) then return end
		local trace = LocalPlayer():GetEyeTrace()
		if(IsValid(trace.Entity) and trace.Entity:GetGlobalValue("Vermilion_Owner") != nil and not trace.Entity:IsPlayer()) then
			local steamid = trace.Entity:GetGlobalValue("Vermilion_Owner")
			if(namedata == false && tentity == trace.Entity:EntIndex()) then return end
			if(namedata == true && tentity == trace.Entity:EntIndex()) then
				surface.SetFont('DermaDefaultBold')
				local ttext = "Querying owner name..."
				local tw,th = surface.GetTextSize(ttext)
				VToolkit:DrawGenericBackground("BLUE", ScrW() - (tw + 25) - 10, ScrH() - 35, tw + 25, 25)
				surface.SetTextPos(ScrW() - (tw + 25), 15)
				surface.DrawText(ttext)
				//owidth = draw.WordBox(8, ScrW() - 10 - owidth, ScrH() - 35, , "Default", Vermilion.Colours.Black, Vermilion.Colours.White)
				return
			end
			if(namedata == nil or tentity != trace.Entity:EntIndex()) then
				namedata = true
				tentity = trace.Entity:EntIndex()
				MODULE:NetStart("VQueryPPSteamID")
				net.WriteString(steamid)
				net.SendToServer()
				return
			end
			local tboxoff = 0
			if(LocalPlayer():SteamID() == steamid) then
				surface.SetFont('DermaDefaultBold')
				local ttext = "You can interact with this prop!"
				local tw,th = surface.GetTextSize(ttext)
				VToolkit:DrawGenericBackground("BLUE", ScrW() - (tw + 25) - 10, ScrH() - 35, tw + 25, 25)
				surface.SetTextPos(ScrW() - (tw + 25), ScrH() - 30)
				surface.DrawText(ttext)
				//owidth1 = draw.WordBox(8, ScrW() - 10 - owidth1, ScrH() - 35, "You can interact with this prop!", "Default", Vermilion.Colours.Black, Vermilion.Colours.White)
				tboxoff = 35
			else
				tboxoff = 0
			end
			surface.SetFont('DermaDefaultBold')
			local ttext = "Owner: " .. namedata.Name
			local tw,th = surface.GetTextSize(ttext)
			VToolkit:DrawGenericBackground("BLUE", ScrW() - (tw + 25) - 10, ScrH() - 35 - tboxoff, tw + 25, 25)
			surface.SetTextPos(ScrW() - (tw + 25), ScrH() - 30 - tboxoff)
			surface.DrawText(ttext)
			//owidth = draw.WordBox(8, ScrW() - 10 - owidth, ScrH() - 35 - tboxoff, "Owner: " .. namedata.Name, "Default", Vermilion.Colours.Black, Vermilion.Colours.White)
		end
	end)

	self:AddHook(Vermilion.Event.MOD_LOADED, function()
		local clopt = Vermilion:GetModule("client_settings")
		clopt:AddOption({
			GuiText = "Prop Owner HUD",
			ConVar = "vermilion_prop_hud",
			Type = "Checkbox",
			Category = "Features"
		})
	end)
end
