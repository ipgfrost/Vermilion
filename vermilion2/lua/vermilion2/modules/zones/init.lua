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

local MODULE = MODULE
MODULE.Name = "Zones"
MODULE.ID = "zones"
MODULE.Description = "Add zones" // <-- add a better description
MODULE.Author = "Ned"
MODULE.Tabs = {
	"zones"
}
MODULE.Permissions = {
	"zone_manager",
	"create_zone",
	"remove_zone",
	"ignore_zones",

	"jail"
}
MODULE.PermissionDefintions = {
	["zone_manager"] = "This player is able to see the Zones tab on the Vermilion Menu and modify the settings within.",
	["create_zone"] = "This player is able to create new zones.",
	["remove_zone"] = "This player is able to remove zones.",
	["ignore_zones"] = "This player is not affected by any zones."
}
MODULE.NetworkStrings = {
	"VUpdateBlocks",
	"VDrawCreateBlocks",
	"VGetZones",
	"VGetZoneModes",
	"VAddZoneMode",
	"VAddZoneModeAdv",
	"VDelZoneMode",
	"VRenameZone",
	"VDelZone"
}

MODULE.Zones = {}
MODULE.DrawEffect = Material("models/effects/comball_tape") -- what happens if the client/server doesn't have HL2?
--MODULE.DrawEffect = Material("models/props_combine/portalball001_sheet")

MODULE.Point1 = {}
MODULE.DrawingFrom = nil

MODULE.ModeDefinitions = {}

MODULE.BaseZone = {}
function MODULE.BaseZone:HasMode(mode)
	return table.HasValue(table.GetKeys(self.Modes), mode)
end
function MODULE.BaseZone:ValidInMap()
	return self.Map == game.GetMap()
end
function MODULE.BaseZone:AddMode(mode, parameters)
	self.Modes[mode] = parameters or {}
	for i,k in pairs(self.ActiveObjects) do
		hook.Call("Vermilion_Object_Left_Zone", nil, self, ents.GetByIndex(i))
		self.ActiveObjects[i] = nil
	end
	for i,k in pairs(self.ActivePlayers) do
		hook.Call("Vermilion_Player_Left_Zone", nil, self, VToolkit.LookupPlayerBySteamID(i))
		self.ActivePlayers[i] = nil
	end
end
function MODULE.BaseZone:RemoveMode(mode)
	self.Modes[mode] = nil
	for i,k in pairs(self.ActiveObjects) do
		hook.Call("Vermilion_Object_Left_Zone", nil, self, ents.GetByIndex(i))
		self.ActiveObjects[i] = nil
	end
	for i,k in pairs(self.ActivePlayers) do
		hook.Call("Vermilion_Player_Left_Zone", nil, self, VToolkit.LookupPlayerBySteamID(i))
		self.ActivePlayers[i] = nil
	end
end
function MODULE.BaseZone:GetModeProps(mode)
	return self.Modes[mode]
end

function MODULE.BaseZone:GetName()
	return table.KeyFromValue(MODULE.Zones, self)
end

local modeMustHave = { "Name" }
local modeShouldHave = {
	{ "Handler", nil },
	{ "Events", nil },
	{ "Predictor", nil },
	{ "PropValidator", nil },
	{ "GuiBuilder", nil }
}

--[[
	Mode components:

	- Name = unlocalised version of the name
	- Handler = function run on every item in a zone each tick
	- Events = string-indexed table of events that the zone mode should listen to
	- Predictor = function that is used by the chat predictor to determine argument predictions
	- PropValidator = function that validates if the arguments are valid
	- GuiBuilder = function that builds a drawer to determine mode parameters in the GUI (if this is nil, the GUI will assume that no parameters are needed.)
]]--

function MODULE:RegisterMode(data)
	for i,k in pairs(modeMustHave) do
		assert(data[k] != nil)
	end
	for i,k in pairs(modeShouldHave) do
		if(data[k[1]] == nil) then data[k[1]] = k[2] end
	end
	MODULE.ModeDefinitions[data.Name] = data
end

function MODULE:NewZone(c1, c2, name, owner)
	self.Zones[name] = { Bound = VToolkit.CBound(c1, c2), Modes = { }, Owner = owner, ActivePlayers = {}, ActiveObjects = {}, Map = game.GetMap() }
	setmetatable(self.Zones[name], { __index = MODULE.BaseZone })
	self:UpdateClients()
end

function MODULE:GetZonesWithMode(mode)
	return VToolkit.FindInTable(self.Zones, function(k) return table.HasValue(table.GetKeys(k.Modes), mode) and k.Map == game.GetMap() end)
end

function MODULE:GetZonesWithName(name)
	for i,k in pairs(self.Zones) do
		if(i == name) then return k end
	end
end

function MODULE:UpdateClients(client)
	MODULE:NetStart("VUpdateBlocks")
	local stab = {}
	for i,k in pairs(MODULE.Zones) do
		if(k.Map == game.GetMap()) then
			table.insert(stab, {k.Bound.Point1, k.Bound.Point2})
		end
	end
	net.WriteTable(stab)
	if(not client) then
		net.Broadcast()
	else
		net.Send(client)
	end
end

function MODULE:LoadSettings()
	local stab = self:GetData("zones", {})
	if(table.Count(stab) == 0) then
		self:ResetSettings()
		self:SaveSettings()
	end
	for i,k in pairs(stab) do
		local v1 = Vector(k[1][1], k[1][2], k[1][3])
		local v2 = Vector(k[2][1], k[2][2], k[2][3])
		self.Zones[i] = { Bound = VToolkit.CBound(v1, v2), Modes = k[3], Owner = k[4], ActivePlayers = {}, ActiveObjects = {}, Map = k[5] }
		setmetatable(self.Zones[i], { __index = MODULE.BaseZone })
	end
end

function MODULE:SaveSettings()
	local stab = {}
	for i,k in pairs(self.Zones) do
		stab[i] = { { k.Bound.Point1.x, k.Bound.Point1.y, k.Bound.Point1.z }, { k.Bound.Point2.x, k.Bound.Point2.y, k.Bound.Point2.z }, k.Modes, k.Owner, k.Map }
	end
	self:SetData("zones", stab)
end

function MODULE:ResetSettings()
	self.Zones = {}
end

function MODULE:DistributeEvent(eventName, ...)
	if(CLIENT) then return end
	for i,k in pairs(VToolkit.FindInTable(MODULE.ModeDefinitions, function(tentry)
		if(tentry.Events == nil) then return false end
		return tentry.Events[eventName] != nil
	end)) do
		local result = k.Events[eventName](...)
		if(result != nil) then
			return result
		end
	end
end

function MODULE:InitShared()
	self:RegisterMode({
		Name = "anti_pvp",
		Events = {
			["PlayerShouldTakeDamage"] = function( vplayer, attacker )
				if(not IsTableOfEntitiesValid({vplayer, attacker})) then return end
				if(not attacker:IsPlayer()) then return end
				for i,zone in pairs(MODULE:GetZonesWithMode("anti_pvp")) do
					if(not zone:ValidInMap()) then continue end
					if(zone.Bound:IsInside(vplayer)) then return false end
				end
			end
		}
	})

	self:RegisterMode({
		Name = "anti_noclip",
		Handler = function(zone, ent, properties)
			if(ent:IsPlayer()) then
				if(ent:GetMoveType() == MOVETYPE_NOCLIP) then
					ent:SetMoveType(MOVETYPE_WALK)
				end
			end
		end,
		Events = {
			["PlayerNoClip"] = function(vplayer, state)
				if(not IsValid(vplayer)) then return end
				for i,zone in pairs(MODULE:GetZonesWithMode("anti_noclip")) do
					if(not zone:ValidInMap()) then continue end
					if(zone.Bound:IsInside(vplayer)) then return false end
				end
			end
		}
	})

	self:RegisterMode({
		Name = "confiscate_weapons",
		Handler = function(zone, ent, properties)
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
		end,
		Events = {
			["Vermilion_Player_Entered_Zone"] = function(zone, vplayer)
				if(not zone:HasMode("confiscate_weapons")) then return end
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
				if(not zone:HasMode("confiscate_weapons")) then return end
				local entry = zone.ActivePlayers[vplayer:SteamID()]
				if(entry == nil) then
					return
				end
				if(entry["Confiscated_Weapons"] == nil) then return end
				for i,k in pairs(entry["Confiscated_Weapons"]) do
					vplayer:Give(k)
				end
				vplayer:SwitchToDefaultWeapon()
			end
		}
	})

	self:RegisterMode({
		Name = "no_gravity",
		Events = {
			["Vermilion_Object_Entered_Zone"] = function(zone, ent)
				if(not zone:HasMode("no_gravity") or ent:IsPlayer()) then return end
				local phys = ent:GetPhysicsObject()
				if(not IsValid(phys)) then
					ent:SetGravity(-0.00000001)
					return
				end
				construct.SetPhysProp( ent:GetOwner(), ent, ent:EntIndex(), phys, { GravityToggle = false, Material = ent:GetMaterial() } )
			end,
			["Vermilion_Object_Left_Zone"] = function(zone, ent)
				if(not zone:HasMode("no_gravity") or ent:IsPlayer()) then return end
				local phys = ent:GetPhysicsObject()
				if(not IsValid(phys)) then
					ent:SetGravity(0)
					return
				end
				construct.SetPhysProp( ent:GetOwner(), ent, ent:EntIndex(), phys, { GravityToggle = true, Material = ent:GetMaterial() } )
			end,
			["Vermilion_Player_Entered_Zone"] = function(zone, vplayer)
				if(not zone:HasMode("no_gravity")) then return end
				local phys = vplayer:GetPhysicsObject()
				if(not IsValid(phys)) then
					vplayer:SetGravity(-0.00000001)
					return
				end
				phys:EnableGravity(false)
				vplayer:SetGravity(-0.00000001)
			end,
			["Vermilion_Player_Left_Zone"] = function(zone, vplayer)
				if(not zone:HasMode("no_gravity")) then return end
				local phys = vplayer:GetPhysicsObject()
				if(not IsValid(phys)) then
					vplayer:SetGravity(0)
					return
				end
				phys:EnableGravity(true)
				vplayer:SetGravity(0)
			end
		}
	})

	self:RegisterMode({
		Name = "speed",
		Events = {
			["Vermilion_Player_Entered_Zone"] = function(zone, vplayer)
				if(not zone:HasMode("speed")) then return end
				local entry = zone.ActivePlayers[vplayer:SteamID()]
				if(entry == nil) then
					return
				end
				entry["origspeed"] = vplayer:GetWalkSpeed()
				local speed = math.abs(200 * (tonumber(zone:GetModeProps("speed")[1]) or 5))
				GAMEMODE:SetPlayerSpeed(vplayer, speed, speed * 2)
			end,
			["Vermilion_Player_Left_Zone"] = function(zone, vplayer)
				if(not zone:HasMode("speed")) then return end
				local entry = zone.ActivePlayers[vplayer:SteamID()]
				if(entry == nil) then
					return
				end
				local speed = entry["origspeed"]
				GAMEMODE:SetPlayerSpeed(vplayer, speed, speed * 2)
			end
		},
		Predictor = function(pos, current, all, vplayer)
			if(pos == 3) then
				return { { Name = "", Syntax = "Speed multiplier..." } }
			end
		end,
		PropValidator = function(sender, text, log, glog)
			if(table.Count(text) == 2) then
				text[3] = "5"
				return
			end
			if(tonumber(text[3]) == nil) then
				log("not_number", nil, NOTIFY_ERROR)
				return false
			end
		end,
		GuiBuilder = function(zoneName, completeFunction, drawer)

			local speedSlider = VToolkit:CreateSlider("Speed", 0.1, 20, 2)
			speedSlider:SetPos(20, 60)
			speedSlider:SetWide(300)
			speedSlider:SetParent(drawer)
			speedSlider:SetValue(10)

			local complete = VToolkit:CreateButton("Add Mode", function()
				completeFunction( { tostring(speedSlider:GetValue()) } )
			end)
			complete:SetPos(20, 100)
			complete:SetSize(drawer:GetWide() - 40, 25)
			complete:SetParent(drawer)


		end
	})

	self:RegisterMode({
		Name = "sudden_death",
		Events = {
			["PlayerShouldTakeDamage"] = function(target, attacker)
				if(not IsValid(target)) then return end
				if(target:IsPlayer() and IsValid(attacker)) then
					if(attacker:IsPlayer()) then
						local zones = MODULE:GetZonesWithMode("sudden_death")
						local targetValid = false
						local attackerValid = false
						for i,zone in pairs(zones) do
							if(not zone:ValidInMap()) then continue end
							if(zone.Bound:IsInside(target)) then
								targetValid = true
							end
							if(zone.Bound:IsInside(attacker)) then
								attackerValid = true
							end
						end
						if(targetValid and attackerValid) then
							target:SetHealth(0)
							Vermilion:BroadcastNotification(attacker:GetName() .. " killed " .. target:GetName() .. " in a sudden death zone!")
						end
					end
				end
			end
		}
	})

	self:RegisterMode({
		Name = "no_vehicles",
		Handler = function(zone, ent, properties)
			if(ent:IsVehicle()) then
				ent:SetSaveValue("VehicleLocked", true)
			end
		end,
		Events = {
			["Vermilion_Object_Entered_Zone"] = function(zone, ent)
				if(not zone:HasMode("no_vehicles")) then return end
				if(ent:IsVehicle()) then
					if(IsValid(ent:GetDriver())) then
						ent:GetDriver():ExitVehicle()
					end
					ent:SetSaveValue("VehicleLocked", true)
				end
			end,
			["Vermilion_Object_Left_Zone"] = function(zone, ent)
				if(not zone:HasMode("no_vehicles")) then return end
				if(ent:IsVehicle()) then
					ent:SetSaveValue("VehicleLocked", false)
				end
			end
		}
	})

	self:RegisterMode({
		Name = "anti_propspawn",
		Events = {
			["PlayerSpawnedProp"] = function(ply, model, ent)
				local zones = MODULE:GetZonesWithMode("anti_propspawn")
				for i,zone in pairs(zones) do
					if(not zone:ValidInMap()) then continue end
					if(zone.Bound:IsInside(ent)) then
						if(not table.HasValue(zone:GetModeProps("anti_propspawn"), ply:SteamID())) then
							ent:Remove()
						end
					end
				end
			end,
			["PlayerSpawnedRagdoll"] = function(ply, model, ent)
				local zones = MODULE:GetZonesWithMode("anti_propspawn")
				for i,zone in pairs(zones) do
					if(not zone:ValidInMap()) then continue end
					if(zone.Bound:IsInside(ent)) then
						if(not table.HasValue(zone:GetModeProps("anti_propspawn"), ply:SteamID())) then
							ent:Remove()
						end
					end
				end
			end,
			["PlayerSpawnedSENT"] = function(ply, ent)
				local zones = MODULE:GetZonesWithMode("anti_propspawn")
				for i,zone in pairs(zones) do
					if(not zone:ValidInMap()) then continue end
					if(zone.Bound:IsInside(ent)) then
						if(not table.HasValue(zone:GetModeProps("anti_propspawn"), ply:SteamID())) then
							ent:Remove()
						end
					end
				end
			end,
			["PlayerSpawnedSWEP"] = function(ply, ent)
				local zones = MODULE:GetZonesWithMode("anti_propspawn")
				for i,zone in pairs(zones) do
					if(not zone:ValidInMap()) then continue end
					if(zone.Bound:IsInside(ent)) then
						if(not table.HasValue(zone:GetModeProps("anti_propspawn"), ply:SteamID())) then
							ent:Remove()
						end
					end
				end
			end,
			["PlayerSpawnedVehicle"] = function(ply, ent)
				local zones = MODULE:GetZonesWithMode("anti_propspawn")
				for i,zone in pairs(zones) do
					if(not zone:ValidInMap()) then continue end
					if(zone.Bound:IsInside(ent)) then
						if(not table.HasValue(zone:GetModeProps("anti_propspawn"), ply:SteamID())) then
							ent:Remove()
						end
					end
				end
			end,
			["PlayerSpawnedEffect"] = function(ply, model, ent)
				local zones = MODULE:GetZonesWithMode("anti_propspawn")
				for i,zone in pairs(zones) do
					if(not zone:ValidInMap()) then continue end
					if(zone.Bound:IsInside(ent)) then
						if(not table.HasValue(zone:GetModeProps("anti_propspawn"), ply:SteamID())) then
							ent:Remove()
						end
					end
				end
			end
		},
		Predictor = function(pos, current, all, vplayer)
			local tab = { { Name = "", Syntax = "Players that can spawn props inside the zone..." } }
			for i,k in pairs(VToolkit.MatchPlayerPart(current)) do
				table.insert(tab, { Name = k, Syntax = "" })
			end
			return tab
		end,
		PropValidator = function(sender, text, log, glog)
			for i,k in pairs(text) do
				if(i < 3) then continue end
				if(not IsValid(VToolkit.LookupPlayer(k))) then
					log("no_users", nil, NOTIFY_ERROR)
					return false
				end
			end
		end,
		GuiBuilder = function(zoneName, completeFunction, drawer)

		end
	})

	self:RegisterMode({
		Name = "anti_rank",
		Handler = function(zone, ent, properties)
			if(ent:IsPlayer()) then
				if(table.HasValue(properties, Vermilion:GetUser(ent):GetRankName())) then Vermilion:AddNotification(ent, "You cannot enter this zone!", nil, NOTIFY_ERROR) ent:Spawn() end
			end
		end,
		Predictor = function(pos, current, all, vplayer)
			local tab = { { Name = "", Syntax = "Ranks that cannot enter the zone..." } }
			for i,k in pairs(Vermilion.Data.Ranks) do
				if(string.find(string.lower(k.Name), string.lower(current))) then
					table.insert(tab, { Name = k.Name, Syntax = "" })
				end
			end
			return tab
		end,
		PropValidator = function(sender, text, log, glog)
			for i,k in pairs(text) do
				if(i < 3) then continue end
				if(Vermilion:GetRank(k) == nil) then
					log("no_rank", nil, NOTIFY_ERROR)
					return false
				end
			end
		end
	})

	self:RegisterMode({
		Name = "kill",
		Handler = function(zone, ent, properties)
			if(ent:IsPlayer() and ent:Alive()) then ent:Kill() end
		end
	})

	self:RegisterMode({
		Name = "notify_enter",
		Events = {
			["Vermilion_Player_Entered_Zone"] = function(zone, vplayer)
				if(not zone:HasMode("notify_enter")) then return end
				timer.Destroy(vplayer:SteamID() .. "ZoneEnter")
				timer.Destroy(vplayer:SteamID() .. "ZoneLeave")
				timer.Create(vplayer:SteamID() .. "ZoneEnter", 0.1, 1, function()
					Vermilion:AddNotification(vplayer, "You have entered " .. zone:GetName(), nil, NOTIFY_HINT)
				end)
			end
		}
	})

	self:RegisterMode({
		Name = "notify_leave",
		Events = {
			["Vermilion_Player_Left_Zone"] = function(zone, vplayer)
				if(not zone:HasMode("notify_leave")) then return end
				timer.Destroy(vplayer:SteamID() .. "ZoneLeave")
				timer.Destroy(vplayer:SteamID() .. "ZoneEnter")
				timer.Create(vplayer:SteamID() .. "ZoneLeave", 0.1, 1, function()
					Vermilion:AddNotification(vplayer, "You have left " .. zone:GetName(), nil, NOTIFY_HINT)
				end)
			end
		}
	})

	self:RegisterMode({
		Name = "jail",
		Events = {
			["Vermilion_Player_Left_Zone"] = function(zone, vplayer)
				if(not zone:HasMode("jail")) then return end
				local vervplayer = Vermilion:GetUser(vplayer)
				if(vervplayer.Jailed and vervplayer.AssignedJail == zone:GetName()) then
					vplayer:SetPos(zone.Bound:CentreBase())
				end
			end
		}
	})
end

function MODULE:InitServer()
	self:NetHook("VUpdateBlocks", function(vplayer)
		MODULE:UpdateClients(vplayer)
	end)

	self:AddHook("Think", function()
		for i,zone in pairs(MODULE.Zones) do
			if(not zone:ValidInMap()) then continue end
			for ipl,ent in pairs(ents.FindInBox(zone.Bound.Point1, zone.Bound.Point2)) do
				if(ent:IsPlayer()) then
					if(zone.ActivePlayers[ent:SteamID()] == nil) then
						zone.ActivePlayers[ent:SteamID()] = {}
						hook.Call("Vermilion_Player_Entered_Zone", nil, zone, ent)
					end
				else
					if(zone.ActiveObjects[ent:EntIndex()] == nil) then
						zone.ActiveObjects[ent:EntIndex()] = {}
						hook.Call("Vermilion_Object_Entered_Zone", nil, zone, ent)
					end
				end
				for mode,pars in pairs(zone.Modes) do
					if(isfunction(MODULE.ModeDefinitions[mode].Handler)) then
						MODULE.ModeDefinitions[mode].Handler(zone, ent, pars)
					end
				end
			end
			for ipl,ent in pairs(zone.ActivePlayers) do
				local tplayer = VToolkit.LookupPlayerBySteamID(ipl)
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

	local function sendZones(vplayer)
		MODULE:NetStart("VGetZones")
		local tab = {}
		for i,k in pairs(MODULE.Zones) do
			if(k.Map == game.GetMap()) then
				table.insert(tab, i)
			end
		end
		net.WriteTable(tab)
		net.Send(vplayer)
	end

	local function sendZoneModes(vplayer, name, zone)
		if(zone == nil) then return end
		MODULE:NetStart("VGetZoneModes")
		net.WriteString(name)
		net.WriteTable(table.GetKeys(zone.Modes))
		net.Send(vplayer)
	end

	self:NetHook("VGetZones", sendZones)
	self:NetHook("VGetZoneModes", function(vplayer)
		local name = net.ReadString()
		sendZoneModes(vplayer, name, MODULE.Zones[name])
	end)

	self:NetHook("VAddZoneMode", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "zone_manager")) then
			local name = net.ReadString()
			local mode = net.ReadString()

			if(MODULE.Zones[name] != nil) then
				MODULE.Zones[name]:AddMode(mode)
			end

			sendZoneModes(Vermilion:GetUsersWithPermission("zone_manager"), name, MODULE.Zones[name])
		end
	end)

	self:NetHook("VAddZoneModeAdv", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "zone_manager")) then
			local name = net.ReadString()
			local mode = net.ReadString()

			if(MODULE.Zones[name] != nil) then
				MODULE.Zones[name]:AddMode(mode, net.ReadTable())
			end

			sendZoneModes(Vermilion:GetUsersWithPermission("zone_manager"), name, MODULE.Zones[name])
		end
	end)

	self:NetHook("VDelZoneMode", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "zone_manager")) then
			local name = net.ReadString()
			local mode = net.ReadString()

			if(MODULE.Zones[name] != nil) then
				MODULE.Zones[name]:RemoveMode(mode)
			end

			sendZoneModes(Vermilion:GetUsersWithPermission("zone_manager"), name, MODULE.Zones[name])
		end
	end)

	self:NetHook("VRenameZone", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "zone_manager")) then
			local name = net.ReadString()
			local nname = net.ReadString()

			if(MODULE.Zones[name] != nil) then
				MODULE.Zones[nname] = MODULE.Zones[name]
				MODULE.Zones[name] = nil
			end

			sendZones(Vermilion:GetUsersWithPermission("zone_manager"))
			MODULE:UpdateClients(player.GetHumans())
		end
	end)

	self:NetHook("VDelZone", function(vplayer)
		if(Vermilion:HasPermission(vplayer, "zone_manager")) then
			local name = net.ReadString()

			if(MODULE.Zones[name] != nil) then
				MODULE.Zones[name] = nil
			end

			sendZones(Vermilion:GetUsersWithPermission("zone_manager"))
			MODULE:UpdateClients(player.GetHumans())
		end
	end)

	local hooks = {
		"PlayerSpawnEffect",
		"PlayerSpawnNPC",
		"PlayerSpawnObject",
		"PlayerSpawnProp",
		"PlayerSpawnRagdoll",
		"PlayerSpawnSENT",
		"PlayerSpawnSWEP",
		"PlayerSpawnVehicle",
		"CanDrive",
		"CanTool",
		"CanProperty",
		"PlayerUse",
		"PlayerSpray",
		"PlayerNoClip",
		"PhysgunPickup",
		"CanPlayerSuicide",
		"CanPlayerUnfreeze",
		"CanPlayerEnterVehicle"
	}

	for i,k in pairs(hooks) do
		self:AddHook(k, "jail" .. k, function(vplayer)
			if(not IsValid(vplayer)) then return end
			if(Vermilion:GetUser(vplayer).Jailed) then return false end
		end)
	end

	self:AddHook("PlayerSpawn", function(vplayer)
		if(Vermilion:GetUser(vplayer).Jailed) then
			if(Vermilion:GetUser(vplayer).AssignedJail != nil) then
				if(MODULE:GetZonesWithName(Vermilion:GetUser(vplayer).AssignedJail) != nil and MODULE:GetZonesWithName(Vermilion:GetUser(vplayer).AssignedJail):HasMode("jail") and MODULE:GetZonesWithName(Vermilion:GetUser(vplayer).AssignedJail):ValidInMap()) then
					vplayer:SetPos(MODULE:GetZonesWithName(Vermilion:GetUser(vplayer).AssignedJail).Bound:CentreBase())
				else
					Vermilion.Log("Can't send player to jail; the assigned jail zone doesn't exist!")
					Vermilion:GetUser(vplayer).Jailed = false
					Vermilion:GetUser(vplayer).AssignedJail = nil
				end
			end

		end
	end)

	self:AddHook(Vermilion.Event.ShuttingDown, function()
		MODULE:SaveSettings()
	end)

	MODULE:LoadSettings()
end

function MODULE:RegisterChatCommands()
	Vermilion:AddChatCommand({
		Name = "addzone",
		Description = "Creates a new zone",
		Syntax = "[name] (only valid on second execution)",
		Permissions = { "zone_manager" },
		CanMute = true,
		CanRunOnDS = false,
		Function = function(sender, text, log, glog)
			if(MODULE.Point1[sender:SteamID()] == nil) then
				MODULE.Point1[sender:SteamID()] = sender:GetPos()
				if(IsValid(sender)) then log("Set point 1. Use !cancelzone to stop drawing the zone and !addzone <name> to define the second point.") end
				MODULE:NetStart("VDrawCreateBlocks")
				net.WriteTable( { sender:GetPos().x, sender:GetPos().y, sender:GetPos().z } )
				net.Send(sender)
			else
				local p1 = MODULE.Point1[sender:SteamID()]
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
				if(MODULE.Zones[text[1]] != nil) then
					log("This zone already exists! Enter a different name. (Note: you don't have to select the first point again!)")
					return
				end
				MODULE:NewZone(p1t, p2t, text[1], sender:SteamID())
				MODULE.Point1[sender:SteamID()] = nil
				glog(sender:GetName() .. " created a new zone called '" .. text[1] .. "'!")
				MODULE:NetStart("VDrawCreateBlocks")
				net.WriteTable( { nil, nil, nil } )
				net.Send(sender)
			end
		end
	})

	Vermilion:AddChatCommand({
		Name = "cancelzone",
		Description = "Stops the zone definition process",
		CanRunOnDS = false,
		Function = function(sender, text, log, glog)
			if(MODULE.Point1[sender:SteamID()] == nil) then
				log("You are not creating a zone.", nil, NOTIFY_ERROR)
				return
			end
			MODULE.Point1[sender:SteamID()] = nil
			log("Zone creation cancelled!")
			MODULE:NetStart("VDrawCreateBlocks")
			net.WriteTable({ nil, nil, nil })
			net.Send(sender)
		end
	})

	Vermilion:AddChatCommand({
		Name = "removezone",
		Description = "Removes a zone.",
		Syntax = "<zone>",
		Permissions = { "zone_manager" },
		CanMute = true,
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchStringPart(table.GetKeys(MODULE.Zones), current)
			end
		end,
		Function = function(sender, text, log, glog)
			if(table.Count(text) < 1) then
				log(Vermilion:TranslateStr("bad_syntax", nil, sender), NOTIFY_ERROR)
				return false
			end
			if(MODULE.Zones[text[1]] == nil) then
				log("Zone does not exist!", nil, NOTIFY_ERROR)
				return false
			end
			MODULE.Zones[text[1]] = nil
			glog(sender:GetName() .. " has removed the zone '" .. text[1] .. "'")
			MODULE:UpdateClients()
		end
	})

	Vermilion:AddChatCommand({
		Name = "listmodes",
		Description = "Lists the modes applied to the zone",
		Syntax = "<zone>",
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchStringPart(table.GetKeys(MODULE.Zones), current)
			end
		end,
		Function = function(sender, text, log, glog)
			if(MODULE.Zones[text[1]] == nil) then
				log("This zone does not exist!", nil, NOTIFY_ERROR)
				return
			end
			local tab = {}
			for i,k in pairs(MODULE.Zones[text[1]].Modes) do
				table.insert(tab, i)
			end
			log("Active modes: " .. table.concat(tab, ", "))
		end
	})

	Vermilion:AddChatCommand({
		Name = "setmode",
		Description = "Sets a mode on a zone",
		Syntax = "<zone> <mode> [parameters]",
		Permissions = { "zone_manager" },
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchStringPart(table.GetKeys(MODULE.Zones), current)
			end
			if(pos == 2) then
				if(MODULE.Zones[all[1]] == nil) then
					return { { Name = "", Syntax = "Parameter 1 is invalid!" } }
				end
				return VToolkit.FilterTable(VToolkit.MatchStringPart(table.GetKeys(MODULE.ModeDefinitions), current), function(k, v) return not MODULE.Zones[all[1]]:HasMode(v) end)
			end
			if(pos >= 3) then
				if(MODULE.ModeDefinitions[all[2]] == nil) then
					return { { Name = "", Syntax = "Parameter 2 is invalid!" } }
				end
				if(MODULE.ModeDefinitions[all[2]].Predictor != nil) then
					return MODULE.ModeDefinitions[all[2]].Predictor(pos, current, all, vplayer)
				end
			end
		end,
		Function = function(sender, text, log, glog)
			if(table.Count(text) < 1) then
				log("bad_syntax", nil, NOTIFY_ERROR)
				return
			end
			if(MODULE.Zones[text[1]] == nil) then
				log("This zone does not exist!", nil, NOTIFY_ERROR)
				return
			end
			if(MODULE.Zones[text[1]]:HasMode(text[2])) then
				log("This zone already has this mode enabled!", nil, NOTIFY_ERROR)
				return
			end
			if(MODULE.ModeDefinitions[text[2]] == nil) then
				log("This mode does not exist!", nil, NOTIFY_ERROR)
				return
			end
			if(MODULE.ModeDefinitions[text[2]].PropValidator != nil) then
				if(MODULE.ModeDefinitions[text[2]].PropValidator(sender, text, log, glog) == false) then return false end
			end
			local props = table.Copy(text)
			table.remove(props, 1)
			table.remove(props, 1)
			MODULE.Zones[text[1]]:AddMode(text[2], props)
			log("Zone updated!")
		end
	})

	Vermilion:AddChatCommand({
		Name = "unsetmode",
		Description = "Removes a mode from a zone",
		Syntax = "<zone> <mode>",
		Permissions = { "zone_manager" },
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchStringPart(table.GetKeys(MODULE.Zones), current)
			end
			if(pos == 2) then
				local tab = {}
				if(MODULE.Zones[all[1]] == nil) then
					table.insert(tab, { Name = "", Syntax = "This zone doesn't exist." })
					return tab
				end
				for i,k in pairs(MODULE.Zones[all[1]].Modes) do
					if(string.find(string.lower(i), string.lower(current))) then
						table.insert(tab, i)
					end
				end
				return tab
			end
		end,
		Function = function(sender, text, log, glog)
			if(table.Count(text) < 2) then
				log("bad_syntax", nil, NOTIFY_ERROR)
				return
			end
			if(MODULE.Zones[text[1]] == nil) then
				log("This zone does not exist!", nil, NOTIFY_ERROR)
				return
			end
			if(MODULE.ModeDefinitions[text[2]] == nil) then
				log("This mode does not exist!", nil, NOTIFY_ERROR)
				return
			end
			if(not MODULE.Zones[text[1]]:HasMode(text[2])) then
				log("This zone doesn't have this mode enabled!", nil, NOTIFY_ERROR)
				return
			end
			MODULE.Zones[text[1]]:RemoveMode(text[2])
			log("Zone updated!")
		end
	})

	Vermilion:AddChatCommand({
		Name = "listzones",
		Description = "Lists all zones",
		Function = function(sender, text, log, glog)
			local tab = {}
			for i,k in pairs(MODULE.Zones) do
				if(k.Map == game.GetMap()) then
					table.insert(tab, i)
				else
					table.insert(tab, i .. " (not active in this map)")
				end
			end
			log("Active zones: " .. table.concat(tab, ", "))
		end
	})

	Vermilion:AddChatCommand({
		Name = "jail",
		Description = "Send a player to jail.",
		Syntax = function(vplayer) return MODULE:TranslateStr("cmd:jail:syntax", nil, vplayer) end,
		BasicParameters = {
			{ Type = Vermilion.ChatCommandConst.MultiPlayerArg },
			{ Type = Vermilion.ChatCommandConst.StringArg }
		},
		Category = "Utils",
		CommandFormat = "\"%s\" \"%s\"",
		Permissions = { "jail" },
		AllValid = {
			{ Size = nil, Indexes = { 1 } }
		},
		CanMute = true,
		Predictor = function(pos, current, all, vplayer)
			if(pos == 1) then
				return VToolkit.MatchPlayerPart(current)
			end
			if(pos == 2) then
				if(VToolkit.LookupPlayer(all[1]) == nil) then return end
				if(not Vermilion:GetUser(VToolkit.LookupPlayer(all[1])).Jailed) then
					local tab = {}
					for i,k in pairs(MODULE.Zones) do
						if(k:HasMode("jail") and k:ValidInMap()) then table.insert(tab, i) end
					end
					return tab
				end
			end
		end,
		Function = function(sender, text, log, glog)
			if(table.Count(text) < 1) then
				log("bad_syntax", nil, NOTIFY_ERROR)
				return false
			end

			local tplayer = VToolkit.LookupPlayer(text[1])
			if(not IsValid(tplayer)) then
				log("no_users", nil, NOTIFY_ERROR)
				return false
			end
			if(Vermilion:GetUser(tplayer).Jailed) then
				Vermilion:GetUser(tplayer).Jailed = false
				tplayer:Spawn()
				glog("zones:jail:release", { sender:GetName(), tplayer:GetName() })
				return
			end
			if(table.Count(text) < 2) then
				log("bad_syntax", nil, NOTIFY_ERROR)
				return false
			end
			if(MODULE:GetZonesWithName(text[2]) == nil or not MODULE:GetZonesWithName(text[2]):HasMode("jail")) then
				log("zones:jail:nojail", nil, NOTIFY_ERROR)
				return false
			end
			Vermilion:GetUser(tplayer).Jailed = true
			Vermilion:GetUser(tplayer).AssignedJail = text[2]
			glog("zones:jail:jail", { sender:GetName(), tplayer:GetName() })
			local vervplayer = Vermilion:GetUser(tplayer)
			local tzone = MODULE:GetZonesWithName(text[2])
			if(vervplayer.Jailed and vervplayer.AssignedJail == tzone:GetName()) then
				tplayer:SetPos(tzone.Bound:CentreBase())
			end
		end
	})


end

function MODULE:InitClient()
	CreateClientConVar("vermilion_render_zones", 1, true, false)

	self:NetHook("VUpdateBlocks", function()
		local stab = {}
		for i,k in pairs(net.ReadTable()) do
			table.insert(stab, VToolkit.CBound(k[1], k[2]))
		end
		MODULE.Zones = stab
	end)

	self:NetHook("VDrawCreateBlocks", function()
		local vec = net.ReadTable()
		if(vec[1] == nil and vec[2] == nil and vec[3] == nil) then
			MODULE.DrawingFrom = nil
		else
			MODULE.DrawingFrom = Vector(vec[1], vec[2], vec[3])
		end
	end)

	self:AddHook(Vermilion.Event.MOD_LOADED, function()
		if(Vermilion:GetModule("client_settings") != nil) then
			Vermilion:GetModule("client_settings"):AddOption({
				GuiText = "Render zones in the world",
				ConVar = "vermilion_render_zones",
				Type = "Checkbox",
				Category = "Features"
			})
		end
	end)

	self:AddHook("PostDrawOpaqueRenderables", function(bDrawingDepth, bDrawingSkybox)
		if(bDrawingSkybox or bDrawingDepth or GetConVarNumber("vermilion_render_zones") == 0) then return end
		for i,k in pairs(MODULE.Zones) do
			cam.Start3D2D(k.Point1, Angle(0, 0, 0), 1)
				render.SetMaterial(MODULE.DrawEffect)
				render.DrawBox(Vector(0, 0, 0), Angle(0, 0, 0), Vector(0, 0, 0), (k.Point2 - k.Point1) * Vector(1, -1, 1), Color(0, 0, 0, 255), false)
			cam.End3D2D()
		end
		if(MODULE.DrawingFrom != nil) then
			cam.Start3D2D(MODULE.DrawingFrom, Angle(0, 0, 0), 1)
				local colour = Color(0, 0, 0, 255)
				local p1 = MODULE.DrawingFrom
				local p2 = LocalPlayer():GetPos()
				render.DrawWireframeBox(Vector(0, 0, 0), Angle(0, 0, 0), Vector(0, 0, 0), (p2 - p1) * Vector(1, -1, 1), colour, false)
			cam.End3D2D()
		end
	end)

	self:NetHook("VGetZones", function()
		local paneldata = Vermilion.Menu.Pages["zones"]
		local data = net.ReadTable()
		paneldata.ZoneList:Clear()
		for i,k in pairs(data) do
			paneldata.ZoneList:AddLine(k)
		end
	end)

	self:NetHook("VGetZoneModes", function()
		local paneldata = Vermilion.Menu.Pages["zones"]
		if(paneldata.ZoneList:GetSelected()[1] == nil or paneldata.ZoneList:GetSelected()[1]:GetValue(1) != net.ReadString()) then return end
		local data = net.ReadTable()
		paneldata.ZoneModes:Clear()
		for i,k in pairs(data) do
			paneldata.ZoneModes:AddLine(MODULE:TranslateStr("mode:" .. k)).ClassName = k
		end
	end)

	Vermilion.Menu:AddCategory("server", 2)

	Vermilion.Menu:AddPage({
		ID = "zones",
		Name = "Zones",
		Order = 10,
		Category = "server",
		Size = { 900, 560 },
		Conditional = function(vplayer)
			return Vermilion:HasPermission("zone_manager")
		end,
		Builder = function(panel, paneldata)
			local delZone = nil
			local renZone = nil
			local giveWeapon = nil
			local takeWeapon = nil
			local zoneList = nil
			local allPermissions = nil
			local zoneModes = nil

			zoneList = VToolkit:CreateList({
				cols = {
					"Name"
				},
				multiselect = false,
				centre = true
			})
			zoneList:SetPos(10, 30)
			zoneList:SetSize(200, panel:GetTall() - 75)
			zoneList:SetParent(panel)
			paneldata.ZoneList = zoneList

			VToolkit:CreateSearchBox(zoneList)

			local zoneHeader = VToolkit:CreateHeaderLabel(zoneList, "Zones")
			zoneHeader:SetParent(panel)

			function zoneList:OnRowSelected(index, line)
				giveWeapon:SetDisabled(not (self:GetSelected()[1] != nil and allPermissions:GetSelected()[1] != nil))
				takeWeapon:SetDisabled(not (self:GetSelected()[1] != nil and zoneModes:GetSelected()[1] != nil))
				renZone:SetDisabled(self:GetSelected()[1] == nil)
				delZone:SetDisabled(self:GetSelected()[1] == nil)
				MODULE:NetStart("VGetZoneModes")
				net.WriteString(self:GetSelected()[1]:GetValue(1))
				net.SendToServer()
			end

			local renZonePanel = VToolkit:CreateLeftDrawer(panel)
			paneldata.RenZonePanel = renZonePanel

			local newZoneName = VToolkit:CreateTextbox()
			newZoneName:SetPos(10, 40)
			newZoneName:SetSize(renZonePanel:GetWide() - 25, 25)
			newZoneName:SetParent(renZonePanel)

			local renZoneFinalButton = VToolkit:CreateButton("Rename Zone", function()
				local fZoneName = newZoneName:GetValue()
				if(fZoneName == nil or fZoneName == "") then
					VToolkit:CreateErrorDialog("Invalid zone name!")
					return
				end
				for i,k in pairs(zoneList:GetLines()) do
					if(k:GetValue(1) == fZoneName) then
						VToolkit:CreateErrorDialog("Zone already exists!")
						return
					end
				end
				local oldZoneName = zoneList:GetSelected()[1]:GetValue(1)
				zoneList:GetSelected()[1]:SetValue(1, fZoneName)
				MODULE:NetStart("VRenameZone")
				net.WriteString(oldZoneName)
				net.WriteString(fZoneName)
				net.SendToServer()
				renZonePanel:Close()
				newZoneName:SetValue("")
			end)
			renZoneFinalButton:SetPos(10, 75)
			renZoneFinalButton:SetSize(renZonePanel:GetWide() - 25, 25)
			renZoneFinalButton:SetParent(renZonePanel)

			renZone = VToolkit:CreateButton("Rename Zone", function()
				newZoneName:SetValue(zoneList:GetSelected()[1]:GetValue(1))
				renZonePanel:Open()
			end)
			renZone:SetPos(10, panel:GetTall() - 35)
			renZone:SetSize(98, 25)
			renZone:SetDisabled(true)
			renZone:SetParent(panel)
			paneldata.RenZone = renZone


			delZone = VToolkit:CreateButton("Delete Zone", function()
				VToolkit:CreateConfirmDialog("Really delete zone?", function()
					MODULE:NetStart("VDelZone")
					net.WriteString(zoneList:GetSelected()[1]:GetValue(1))
					net.SendToServer()
					delZone:SetDisabled(true)
					renZone:SetDisabled(true)
					zoneList:RemoveLine(zoneList:GetSelected()[1]:GetID())
				end, { Confirm = "Yes", Deny = "No", Default = false })
			end)
			delZone:SetPos(210 - 98, panel:GetTall() - 35)
			delZone:SetSize(98, 25)
			delZone:SetParent(panel)
			delZone:SetDisabled(true)
			paneldata.DelZone = delZone



			zoneModes = VToolkit:CreateList({
				cols = {
					"Name"
				}
			})
			zoneModes:SetPos(220, 30)
			zoneModes:SetSize(240, panel:GetTall() - 40)
			zoneModes:SetParent(panel)
			paneldata.ZoneModes = zoneModes

			local zoneModesHeader = VToolkit:CreateHeaderLabel(zoneModes, "Zone Modes")
			zoneModesHeader:SetParent(panel)

			function zoneModes:OnRowSelected(index, line)
				takeWeapon:SetDisabled(not (self:GetSelected()[1] != nil and zoneList:GetSelected()[1] != nil))
			end

			VToolkit:CreateSearchBox(zoneModes)


			allPermissions = VToolkit:CreateList({
				cols = {
					"Name"
				},
				multiselect = false
			})
			allPermissions:SetPos(panel:GetWide() - 250, 30)
			allPermissions:SetSize(240, panel:GetTall() - 40)
			allPermissions:SetParent(panel)
			paneldata.AllPermissions = allPermissions

			local allPermissionsHeader = VToolkit:CreateHeaderLabel(allPermissions, "All Modes")
			allPermissionsHeader:SetParent(panel)

			function allPermissions:OnRowSelected(index, line)
				giveWeapon:SetDisabled(not (self:GetSelected()[1] != nil and zoneList:GetSelected()[1] != nil))
			end

			VToolkit:CreateSearchBox(allPermissions)



			giveWeapon = VToolkit:CreateButton("Add Mode", function()
				for i,k in pairs(allPermissions:GetSelected()) do
					local has = false
					for i1,k1 in pairs(zoneModes:GetLines()) do
						if(k.ClassName == k1.ClassName) then has = true break end
					end
					if(has) then continue end
					if(MODULE.ModeDefinitions[k.ClassName].GuiBuilder != nil) then
						local drawer = VToolkit:CreateRightDrawer(panel)
						local title = VToolkit:CreateLabel(MODULE:TranslateStr("mode_params") .. " - " .. MODULE:TranslateStr("mode:" .. k.ClassName))
						title:SetPos((drawer:GetWide() - title:GetWide()) / 2, 15)
						title:SetParent(drawer)

						drawer.OClose = drawer.Close
						function drawer:Close()
							timer.Simple(0.5, function()
								drawer:Remove()
								paneldata.ModeDrawer = nil
							end)
							self:OClose()
						end
						MODULE.ModeDefinitions[k.ClassName].GuiBuilder(zoneList:GetSelected()[1]:GetValue(1), function(values)
							MODULE:NetStart("VAddZoneModeAdv")
							net.WriteString(zoneList:GetSelected()[1]:GetValue(1))
							net.WriteString(k.ClassName)
							net.WriteTable(values)
							net.SendToServer()
							drawer:Close()
						end, drawer)
						drawer:Open()
						paneldata.ModeDrawer = drawer
						return
					end

					zoneModes:AddLine(k:GetValue(1)).ClassName = k.ClassName

					MODULE:NetStart("VAddZoneMode")
					net.WriteString(zoneList:GetSelected()[1]:GetValue(1))
					net.WriteString(k.ClassName)
					net.SendToServer()
				end
			end)
			giveWeapon:SetPos(select(1, zoneModes:GetPos()) + zoneModes:GetWide() + 10, 100)
			giveWeapon:SetWide(panel:GetWide() - 20 - select(1, allPermissions:GetWide()) - select(1, giveWeapon:GetPos()))
			giveWeapon:SetParent(panel)
			giveWeapon:SetDisabled(true)

			takeWeapon = VToolkit:CreateButton("Remove Mode", function()
				for i,k in pairs(zoneModes:GetSelected()) do
					MODULE:NetStart("VDelZoneMode")
					net.WriteString(zoneList:GetSelected()[1]:GetValue(1))
					net.WriteString(k.ClassName)
					net.SendToServer()

					zoneModes:RemoveLine(k:GetID())
				end
			end)
			takeWeapon:SetPos(select(1, zoneModes:GetPos()) + zoneModes:GetWide() + 10, 130)
			takeWeapon:SetWide(panel:GetWide() - 20 - select(1, allPermissions:GetWide()) - select(1, takeWeapon:GetPos()))
			takeWeapon:SetParent(panel)
			takeWeapon:SetDisabled(true)

			renZonePanel:MoveToFront()

			paneldata.GiveWeapon = giveWeapon
			paneldata.TakeWeapon = takeWeapon
		end,
		OnOpen = function(panel, paneldata)
			MODULE:NetCommand("VGetZones")
			paneldata.AllPermissions:Clear()
			for i,k in pairs(MODULE.ModeDefinitions) do
				paneldata.AllPermissions:AddLine(MODULE:TranslateStr("mode:" .. i)).ClassName = i
			end
			if(paneldata.ModeDrawer != nil) then
				paneldata.ModeDrawer:Close()
			end
			paneldata.ZoneModes:Clear()
		end
	})
	self:NetCommand("VUpdateBlocks")
end
