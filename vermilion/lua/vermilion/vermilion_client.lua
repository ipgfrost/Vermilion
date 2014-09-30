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

Vermilion.Activated = false

-- Convars
CreateClientConVar("vermilion_alert_sounds", 1, true, false)


net.Receive("Vermilion_Client_Activate", function(len)
	if(Vermilion.Activated) then
		Vermilion.Log(Vermilion.Lang.DualActivation)
		return
	end
	Vermilion.Activated = true
	Vermilion.InfoStores = net.ReadTable() -- probably a bad idea?
	Vermilion:LoadExtensions()
	if(input.LookupBinding("vermilion_menu") == nil and Vermilion:GetExtension("notifications") != nil) then
		Vermilion:GetExtension("notifications"):AddNotify("Please bind a key to \"vermlion_menu\"!\n\nYou can do this by opening the console and typing \"bind <key> vermilion_menu\"", 15, NOTIFY_GENERIC)
	end
end)


net.Receive("Vermilion_ErrorMsg", function(len)
	Crimson:CreateErrorDialog(net.ReadString())
end)

net.Receive("VActivePlayers", function(len)
	hook.Call("VActivePlayers", nil, net.ReadTable())
end)

local oldRanks = nil

function Vermilion:RequestRanksList()
	net.Start("VRanksList")
	net.WriteBoolean(oldRanks != nil)
	if(oldRanks != nil) then
		net.WriteString(util.CRC(table.ToString(oldRanks)))
	end
	net.SendToServer()
end

net.Receive("VRanksList", function(len)
	if(net.ReadBoolean()) then
		oldRanks = net.ReadTable()
	end
	hook.Call("VRanksList", nil, oldRanks)
end)

local oldWeapons = nil

function Vermilion:RequestWeaponsList()
	net.Start("VWeaponsList")
	net.WriteBoolean(oldWeapons != nil)
	if(oldWeapons != nil) then
		net.WriteString(util.CRC(table.ToString(oldWeapons)))
	end
	net.SendToServer()
end

net.Receive("VWeaponsList", function(len)
	if(net.ReadBoolean()) then
		oldWeapons = net.ReadTable()
	end
	hook.Call("VWeaponsList", nil, oldWeapons)
end)

local oldEnts = nil

function Vermilion:RequestEntsList()
	net.Start("VEntsList")
	net.WriteBoolean(oldEnts != nil)
	if(oldEnts != nil) then
		net.WriteString(util.CRC(table.ToString(oldEnts)))
	end
	net.SendToServer()
end

net.Receive("VEntsList", function(len)
	if(net.ReadBoolean()) then
		oldEnts = net.ReadTable()
	end
	hook.Call("VEntsList", nil, oldEnts)
end)

Vermilion:RegisterHook("ChatText", "HideJoin", function(index, name, text, typ)
	if(typ == "joinleave") then return true end
end)

net.Receive("VHTMLMOTD", function()
	local isurl = net.ReadBoolean()
	local html = net.ReadString()
	local frame = Crimson.CreateFrame({
		size = { 800, 600 },
		pos  = { (ScrW() - 800) / 2, (ScrH() - 600) / 2 },
		closeBtn = true,
		draggable = true,
		title = "MOTD",
		bgBlur = true
	})
	
	frame:MakePopup()
	frame:DoModal()
	frame:SetAutoDelete(true)
	
	local dhtml = vgui.Create("DHTML")
	dhtml:SetPos(0, 20)
	dhtml:SetSize(800, 580)
	dhtml:SetParent(frame)
	
	if(isurl) then
		dhtml:OpenURL(html)
	else
		dhtml:SetHTML(html)
	end
end)