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

local EXTENSION = Vermilion:MakeExtensionBase()
EXTENSION.Name = "Zones"
EXTENSION.ID = "zones"
EXTENSION.Description = "Creates zones that can limit certain activities in the area."
EXTENSION.Author = "Ned"
EXTENSION.Permissions = {
	"zone_manager",
	"create_zone",
	"remove_zone",
	"ignore_zones"
}
EXTENSION.PermissionDefintions = {
	["zone_manager"] = "This player is able to see the Zones tab on the Vermilion Menu and modify the settings within.",
	["create_zone"] = "This player is able to create new zones.",
	["remove_zone"] = "This player is able to remove zones.",
	["ignore_zones"] = "This player is not affected by any zones."
}
EXTENSION.NetworkStrings ={
	"VUpdateBlocks",
	"VDrawCreateBlocks"
}

EXTENSION.Zones = {}
EXTENSION.DrawEffect = Material("models/effects/comball_tape") -- what happens if the client/server doesn't have HL2?
EXTENSION.DrawEffect2 = Material("models/props_lab/Tank_Glass001")
EXTENSION.DrawEffect3 = Material("models/props_combine/stasisfield_beam")

EXTENSION.Point1 = {}
EXTENSION.DrawingFrom = nil

EXTENSION.EffectDefinitions = {}

function EXTENSION:RegisterEffect(name, func, events)
	EXTENSION.EffectDefinitions[name] = { Handler = func, Events = events }
end

function EXTENSION:NewZone(c1, c2, name, owner)
	self.Zones[name] = { Bound = Crimson.CBound(c1, c2), Effects = { }, Owner = owner, ActivePlayers = {}, ActiveObjects = {}, Map = game.GetMap() }
	self:UpdateClients()
end

function EXTENSION:GetZonesWithEffect(effect)
	return Crimson.FindInTable(self.Zones, function(k) return table.HasValue(k.Effects, effect) and k.Map == game.GetMap() end)
end

function EXTENSION:UpdateClients(client)
	net.Start("VUpdateBlocks")
	local stab = {}
	for i,k in pairs(EXTENSION.Zones) do
		if(k.Map == game.GetMap()) then
			table.insert(stab, {k.Bound.p1, k.Bound.p2})
		end
	end
	net.WriteTable(stab)
	if(not client) then 
		net.Broadcast()
	else
		net.Send(client)
	end
end

function EXTENSION:LoadSettings()
	local stab = self:GetData("zones", {})
	if(table.Count(stab) == 0) then 
		self:ResetSettings()
		self:SaveSettings()
	end
	for i,k in pairs(stab) do
		local v1 = Vector(k[1][1], k[1][2], k[1][3])
		local v2 = Vector(k[2][1], k[2][2], k[2][3])
		self.Zones[i] = { Bound = Crimson.CBound(v1, v2), Effects = k[3], Owner = k[4], ActivePlayers = {}, ActiveObjects = {}, Map = k[5] }
	end
end

function EXTENSION:SaveSettings()
	local stab = {}
	for i,k in pairs(self.Zones) do
		stab[i] = { { k.Bound.p1.x, k.Bound.p1.y, k.Bound.p1.z }, { k.Bound.p2.x, k.Bound.p2.y, k.Bound.p2.z }, k.Effects, k.Owner, k.Map }
	end
	self:SetData("zones", stab)
end

function EXTENSION:ResetSettings()
	self.Zones = {}
end

function EXTENSION:DistributeEvent(eventName, ...)
	for i,k in pairs(Crimson.FindInTable(EXTENSION.EffectDefinitions, function(tentry) return tentry.Events[eventName] != nil end)) do
		local result = k.Events[eventName](...)
		if(result != nil) then
			return result
		end
	end
end

function EXTENSION:InitServer()

	-- Effect Definitions --
	
	self:RegisterEffect("anti_pvp", function(zone, ent) end, {
		["PlayerShouldTakeDamage"] = function( vplayer, attacker )
			if(not Crimson.CheckAllValid({vplayer, attacker})) then return end
			if(not attacker:IsPlayer()) then return end
			for i,zone in pairs(EXTENSION:GetZonesWithEffect("anti_pvp")) do
				if(zone.Bound:IsInside(vplayer)) then return false end
			end
		end
	})
	
	self:RegisterEffect("anti_noclip", function(zone, ent) 
		if(ent:IsPlayer()) then
			if(ent:GetMoveType() == MOVETYPE_NOCLIP) then
				ent:SetMoveType(MOVETYPE_WALK)
			end
		end
	end, {
		["PlayerNoClip"] = function(vplayer, state)
			if(not IsValid(vplayer)) then return end
			for i,zone in pairs(EXTENSION:GetZonesWithEffect("anti_noclip")) do
				if(zone.Bound:IsInside(vplayer)) then return false end
			end
		end
	})
	
	self:RegisterEffect("confiscate_weapons", function(zone, ent)
		if(ent:IsPlayer()) then
			for i,weapon in pairs(ent:GetWeapons()) do
				if(not (weapon:GetClass() == "gmod_tool" or weapon:GetClass() == "weapon_physgun" or weapon:GetClass() == "weapon_physcannon" or weapon:GetClass() == "gmod_camera")) then
					if(not table.HasValue(zone.ActivePlayers[ent:SteamID()]["Confiscated_Weapons"], weapon:GetClass())) then
						table.insert(zone.ActivePlayers[ent:SteamID()]["Confiscated_Weapons"], weapon:GetClass())
					end
					ent:StripWeapon(weapon:GetClass())
				end
			end
			
		end
	end, {
		["Vermilion_Player_Entered_Zone"] = function(zone, vplayer)
			if(not table.HasValue(zone.Effects, "confiscate_weapons")) then return end
			local weps = {}
			for i,weapon in pairs(vplayer:GetWeapons()) do
				if(not (weapon:GetClass() == "gmod_tool" or weapon:GetClass() == "weapon_physgun" or weapon:GetClass() == "weapon_physcannon" or weapon:GetClass() == "gmod_camera")) then
					table.insert(weps, weapon:GetClass())
					vplayer:StripWeapon(weapon:GetClass())
				end
			end
			local entry = zone.ActivePlayers[vplayer:SteamID()]
			entry["Confiscated_Weapons"] = weps
		end,
		["Vermilion_Player_Left_Zone"] = function(zone, vplayer)
			if(not table.HasValue(zone.Effects, "confiscate_weapons")) then return end
			local entry = zone.ActivePlayers[vplayer:SteamID()]
			if(entry == nil) then
				return
			end
			for i,k in pairs(entry["Confiscated_Weapons"]) do
				vplayer:Give(k)
			end
			vplayer:SwitchToDefaultWeapon()
		end
	})
	
	self:RegisterEffect("no_gravity", function(zone, ent)
		
	end, {
		["Vermilion_Object_Entered_Zone"] = function(zone, ent)
			if(not table.HasValue(zone.Effects, "no_gravity") or ent:IsPlayer()) then return end
			local phys = ent:GetPhysicsObject()
			if(not IsValid(phys)) then 
				ent:SetGravity(-0.00000001)
				return
			end
			construct.SetPhysProp( ent:GetOwner(), ent, ent:EntIndex(), phys, { GravityToggle = false, Material = ent:GetMaterial() } )
		end,
		["Vermilion_Object_Left_Zone"] = function(zone, ent)
			if(not table.HasValue(zone.Effects, "no_gravity") or ent:IsPlayer()) then return end
			local phys = ent:GetPhysicsObject()
			if(not IsValid(phys)) then 
				ent:SetGravity(0)
				return
			end
			construct.SetPhysProp( ent:GetOwner(), ent, ent:EntIndex(), phys, { GravityToggle = true, Material = ent:GetMaterial() } )
		end,
		["Vermilion_Player_Entered_Zone"] = function(zone, vplayer)
			if(not table.HasValue(zone.Effects, "no_gravity")) then return end
			local phys = vplayer:GetPhysicsObject()
			if(not IsValid(phys)) then 
				vplayer:SetGravity(-0.00000001)
				return
			end
			phys:EnableGravity(false)
			vplayer:SetGravity(-0.00000001)
		end,
		["Vermilion_Player_Left_Zone"] = function(zone, vplayer)
			if(not table.HasValue(zone.Effects, "no_gravity")) then return end
			local phys = vplayer:GetPhysicsObject()
			if(not IsValid(phys)) then 
				vplayer:SetGravity(0)
				return
			end
			phys:EnableGravity(true)
			vplayer:SetGravity(0)
		end
	})
	
	self:RegisterEffect("speed", function(zone, ent)
	
	end, {
		["Vermilion_Player_Entered_Zone"] = function(zone, vplayer)
			if(not table.HasValue(zone.Effects, "speed")) then return end
			local speed = math.abs(750)
			GAMEMODE:SetPlayerSpeed(vplayer, speed, speed * 2)
		end,
		["Vermilion_Player_Left_Zone"] = function(zone, vplayer)
			if(not table.HasValue(zone.Effects, "speed")) then return end
			local speed = math.abs(250)
			GAMEMODE:SetPlayerSpeed(vplayer, speed, speed * 2)
		end
	})
	
	self:RegisterEffect("sudden_death", function(zone, ent)
	
	end, {
		["PlayerShouldTakeDamage"] = function(target, attacker)
			if(not IsValid(target)) then return end
			if(target:IsPlayer() and IsValid(attacker)) then
				if(attacker:IsPlayer()) then
					local zones = EXTENSION:GetZonesWithEffect("sudden_death")
					local targetValid = false
					local attackerValid = false
					for i,zone in pairs(zones) do
						if(zone.Bound:IsInside(target)) then
							targetValid = true
						end
						if(zone.Bound:IsInside(attacker)) then
							attackerValid = true
						end
					end
					if(targetValid and attackerValid) then
						target:SetHealth(0)
						Vermilion:BroadcastNotify(attacker:GetName() .. " killed " .. target:GetName() .. " in a sudden death zone!")
					end
				end
			end
		end
	})
	
	self:RegisterEffect("no_vehicles", function(zone, ent)
		if(ent:IsVehicle()) then
			ent:SetSaveValue("VehicleLocked", true)
		end
	end, {
		["Vermilion_Object_Entered_Zone"] = function(zone, ent)
			if(not table.HasValue(zone.Effects, "no_vehicles")) then return end
			if(ent:IsVehicle()) then
				if(IsValid(ent:GetDriver())) then
					ent:GetDriver():ExitVehicle()
				end
				ent:SetSaveValue("VehicleLocked", true)
			end
		end,
		["Vermilion_Object_Left_Zone"] = function(zone, ent)
			if(not table.HasValue(zone.Effects, "no_vehicles")) then return end
			if(ent:IsVehicle()) then
				ent:SetSaveValue("VehicleLocked", false)
			end
		end
	})
	
	self:RegisterEffect("kill", function(zone, ent)
		if(ent:IsPlayer() and ent:Alive()) then ent:Kill() end
	end, {})
	
	
	
	self:AddHook("Think", function()
		for i,zone in pairs(EXTENSION.Zones) do
			for ipl,ent in pairs(ents.FindInBox(zone.Bound.p1, zone.Bound.p2)) do
				if(ent:IsPlayer()) then
					if(zone.ActivePlayers[ent:SteamID()] == nil) then
						zone.ActivePlayers[ent:SteamID()] = {}
						hook.Call("Vermilion_Player_Entered_Zone", nil, zone, ent)
					end
				end
				if(zone.ActiveObjects[ent:EntIndex()] == nil) then
					zone.ActiveObjects[ent:EntIndex()] = {}
					hook.Call("Vermilion_Object_Entered_Zone", nil, zone, ent)
				end
				for i1,effect in pairs(zone.Effects) do
					EXTENSION.EffectDefinitions[effect].Handler(zone, ent)
				end
			end
			for ipl,ent in pairs(zone.ActivePlayers) do
				local tplayer = Crimson.LookupPlayerBySteamID(ipl)
				if(IsValid(tplayer)) then
					if(not zone.Bound:IsInside(tplayer)) then
						hook.Call("Vermilion_Player_Left_Zone", nil, zone, tplayer)
						zone.ActivePlayers[ipl] = nil
					end
				else
					zone.ActivePlayers[ipl] = nil
				end
			end
			for ipl,ent in pairs(zone.ActiveObjects) do
				local tEnt = ents.GetByIndex(ipl)
				if(IsValid(tEnt)) then
					if(not zone.Bound:IsInside(tEnt)) then
						hook.Call("Vermilion_Object_Left_Zone", nil, zone, tEnt)
						zone.ActiveObjects[ipl] = nil
					end
				else
					zone.ActiveObjects[ipl] = nil
				end
			end
		end
	end)
	
	self:AddHook("PlayerInitialSpawn", function( vplayer )
		timer.Simple(2, function() EXTENSION:UpdateClients(vplayer) end)
	end)
	
	Vermilion:AddChatCommand("setmode", function(sender, text, log)
		if(not Vermilion:HasPermissionError(sender, "zone_manager")) then return end
		if(table.Count(text) < 2) then
			log("Invalid parameters!", VERMILION_NOTIFY_ERROR)
			return
		end
		if(EXTENSION.Zones[text[1]] == nil) then
			log("This zone does not exist!", VERMILION_NOTIFY_ERROR)
			return
		end
		if(EXTENSION.Zones[text[1]].Map != game.GetMap() and EXTENSION.Zones[text[1]].Map != nil) then
			log("This zone is not active in this map.", VERMILION_NOTIFY_ERROR)
			return
		end
		if(table.HasValue(EXTENSION.Zones[text[1]].Effects, text[2])) then
			log("This zone already has this mode enabled!", VERMILION_NOTIFY_ERROR)
			return
		end
		if(EXTENSION.EffectDefinitions[text[2]] == nil) then
			log("This mode does not exist!", VERMILION_NOTIFY_ERROR)
			return
		end
		table.insert(EXTENSION.Zones[text[1]].Effects, text[2])
		log("Zone updated!")
	end, "<zone> <mode>")
	
	Vermilion:AddChatCommand("unsetmode", function(sender, text, log)
		if(not Vermilion:HasPermissionError(sender, "zone_manager")) then return end
		if(table.Count(text) < 2) then
			log("Invalid parameters!", VERMILION_NOTIFY_ERROR)
			return
		end
		if(EXTENSION.Zones[text[1]] == nil) then
			log("This zone does not exist!", VERMILION_NOTIFY_ERROR)
			return
		end
		if(EXTENSION.Zones[text[1]].Map != game.GetMap() and EXTENSION.Zones[text[1]].Map != nil) then
			log("This zone is not active in this map.", VERMILION_NOTIFY_ERROR)
			return
		end
		if(EXTENSION.EffectDefinitions[text[2]] == nil) then
			log("This mode does not exist!", VERMILION_NOTIFY_ERROR)
			return
		end
		if(not table.HasValue(EXTENSION.Zones[text[1]].Effects, text[2])) then
			log("This zone doesn't have this mode enabled!", VERMILION_NOTIFY_ERROR)
			return
		end
		table.RemoveByValue(EXTENSION.Zones[text[1]].Effects, text[2])
		log("Zone updated!")
	end, "<zone> <mode>")
	
	Vermilion:AddChatCommand("listmodes", function(sender, text, log)
		if(not Vermilion:HasPermissionError(sender, "zone_manager")) then return end
		if(table.Count(text) < 1) then
			local str = ""
			local pos = 1
			for i,k in pairs(EXTENSION.EffectDefinitions) do
				if(pos == table.Count(EXTENSION.EffectDefinitions)) then
					str = str .. i
				else
					str = str .. i .. ", "
				end
				pos = pos + 1
			end
			log("Possible modes: " .. str)
			return
		end
		if(EXTENSION.Zones[text[1]] == nil) then
			log("This zone does not exist!", VERMILION_NOTIFY_ERROR)
			return
		end
		if(EXTENSION.Zones[text[1]].Map != game.GetMap() and EXTENSION.Zones[text[1]].Map != nil) then
			log("This zone is not active in this map.", VERMILION_NOTIFY_ERROR)
			return
		end
		log("Active modes on this zone:")
		for i,k in pairs(EXTENSION.Zones[text[1]].Effects) do
			log(k)
		end
	end)
	
	Vermilion:AddChatCommand("clearzone", function(sender, text, log)
		if(not Vermilion:HasPermissionError(sender, "zone_manager")) then return end
		if(table.Count(text) == 0) then log("Invalid argument length!", VERMILION_NOTIFY_ERROR) return end
		if(EXTENSION.Zones[text[1]] == nil) then
			log("Zone does not exist!", VERMILION_NOTIFY_ERROR)
			return
		end
		if(EXTENSION.Zones[text[1]].Map != game.GetMap() and EXTENSION.Zones[text[1]].Map != nil) then
			log("This zone is not active in this map.", VERMILION_NOTIFY_ERROR)
			return
		end
		EXTENSION.Zones[text[1]] = nil
		log("Zone removed!")
		EXTENSION:UpdateClients()
	end, "<zone>")
	
	Vermilion:AddChatCommand("listzones", function(sender, text, log)
		if(not Vermilion:HasPermissionError(sender, "zone_manager")) then return end
		log("Active zones:")
		for i,k in pairs(EXTENSION.Zones) do
			if(k.Map == game.GetMap()) then
				log(i)
			else
				log(i .. " (not active in this map)")
			end
		end
	end)
	
	Vermilion:AddChatCommand("cancelzone", function(sender, text, log)
		if(not Vermilion:HasPermissionError(sender, "zone_manager")) then return end
		if(EXTENSION.Point1[sender:SteamID()] == nil) then
			log("You are not creating a zone.", VERMILION_NOTIFY_ERROR)
			return
		end
		EXTENSION.Point1[sender:SteamID()] = nil
		log("Zone creation cancelled!")
		net.Start("VDrawCreateBlocks")
		net.WriteTable( { nil, nil, nil } )
		net.Send(sender)
	end)
	
	Vermilion:AddChatCommand("addzone", function(sender, text, log)
		if(not Vermilion:HasPermissionError(sender, "zone_manager")) then return end
		if(EXTENSION.Point1[sender:SteamID()] == nil) then
			EXTENSION.Point1[sender:SteamID()] = sender:GetPos()
			if(IsValid(sender)) then sender:ChatPrint("Set point 1. Use !cancelzone to stop drawing the zone and !addzone <name> to define the second point.") end
			net.Start("VDrawCreateBlocks")
			net.WriteTable( { sender:GetPos().x, sender:GetPos().y, sender:GetPos().z } )
			net.Send(sender)
		else
			local p1 = EXTENSION.Point1[sender:SteamID()]
			local p2 = sender:GetPos()
			local p1t = p1
			local p2t = p2
			if(p1.x < p2.x) then
				p1t = Vector(p2.x, p1t.y, p1t.z)
				p2t = Vector(p1.x, p2t.y, p2t.z)
			end
			if(p1.y < p2.y) then
				p1t = Vector(p1t.x, p2.y, p1t.z)
				p2t = Vector(p2t.x, p1.y, p2t.z)
			end
			if(p1.z < p2.z) then
				p1t = Vector(p1t.x, p1t.y, p2.z)
				p2t = Vector(p2t.x, p2t.y, p1.z)
			end
			if(table.Count(text) < 1) then
				log("Must provide a name for this zone.")
				return
			end
			if(EXTENSION.Zones[text[1]] != nil) then
				log("This zone already exists! Enter a different name. (Note: you don't have to select the first point again!)")
				return
			end
			EXTENSION:NewZone(p1t, p2t, text[1], sender:SteamID())
			EXTENSION.Point1[sender:SteamID()] = nil
			log("Created zone!")
			net.Start("VDrawCreateBlocks")
			net.WriteTable( { nil, nil, nil } )
			net.Send(sender)
		end
	end, "[name]")
	
	self:AddHook("Vermilion-Pre-Shutdown", "zone_save", function()
		EXTENSION:SaveSettings()
	end)
	
	EXTENSION:LoadSettings()
	
end

function EXTENSION:InitClient()
	
	CreateClientConVar("vermilion_render_zones", 1, true, false)
	
	self:NetHook("VUpdateBlocks", function()
		local stab = {}
		for i,k in pairs(net.ReadTable()) do
			table.insert(stab, Crimson.CBound(k[1], k[2]))
		end
		EXTENSION.Zones = stab
	end)
	
	self:NetHook("VDrawCreateBlocks", function()
		local vec = net.ReadTable()
		if(vec[1] == nil and vec[2] == nil and vec[3] == nil) then
			EXTENSION.DrawingFrom = nil
		else
			EXTENSION.DrawingFrom = Vector(vec[1], vec[2], vec[3])
		end
	end)
	
	self:AddHook(Vermilion.EVENT_EXT_LOADED, function()
		if(Vermilion:GetExtension("dermainterface") != nil) then
			Vermilion:AddClientOption("Render Zones in the world", "vermilion_render_zones")
		end
	end)
	
	self:AddHook("PostDrawOpaqueRenderables", function(bDrawingDepth, bDrawingSkybox)
		if(bDrawingSkybox or bDrawingDepth or GetConVarNumber("vermilion_render_zones") == 0) then return end
		for i,k in pairs(EXTENSION.Zones) do
			cam.Start3D2D(k.p1, Angle(0, 0, 0), 1)
				render.SetMaterial(EXTENSION.DrawEffect)
				render.DrawBox(Vector(0, 0, 0), Angle(0, 0, 0), Vector(0, 0, 0), (k.p2 - k.p1) * Vector(1, -1, 1), Color(0, 0, 0, 255), false)
			cam.End3D2D()
		end
		if(EXTENSION.DrawingFrom != nil) then
			cam.Start3D2D(EXTENSION.DrawingFrom, Angle(0, 0, 0), 1)
				local colour = Color(0, 0, 0, 255)
				local p1 = EXTENSION.DrawingFrom
				local p2 = LocalPlayer():GetPos()
				--if(p2.x > p1.x or p2.y > p1.y or p2.z > p1.z) then colour = Color(255, 0, 0, 255) end
				render.DrawWireframeBox(Vector(0, 0, 0), Angle(0, 0, 0), Vector(0, 0, 0), (p2 - p1) * Vector(1, -1, 1), colour, false)
			cam.End3D2D()
		end
	end)
	
end

Vermilion:RegisterExtension(EXTENSION)