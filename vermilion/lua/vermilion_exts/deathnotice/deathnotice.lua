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
EXTENSION.Name = "Death Notice"
EXTENSION.ID = "deathnotice"
EXTENSION.Description = "Broadcasts a notification when someone dies."
EXTENSION.Author = "Ned"
EXTENSION.Permissions = {
	
}
EXTENSION.NetworkStrings = {
	"VDeathNotice"
}

function EXTENSION:InitServer()

	self:AddHook("PhysgunDrop", function(vplayer, ent)
		if(IsValid(ent)) then
			ent:SetPhysicsAttacker(vplayer, 5)
		end
	end)
	
	self:AddHook("DoPlayerDeath", "DeathNotice", function(victim, attacker, dmg)
		if(not EXTENSION:GetData("enabled", true)) then return end
		local inflictor = dmg:GetInflictor()
		
		if(attacker == nil or victim == nil) then return end
		
		local typ = dmg:GetDamageType()
		
		local suicide = false
		
		if(victim == attacker) then
			suicide = true
		end
		
		local distance = nil
		if(not suicide) then
			distance = math.Round(victim:GetPos():Distance(attacker:GetPos()) * 0.01905)
		end
		
		local weapon_types = {
			8194,
			4098,
			536875010
		}
		
		if(typ == DMG_CRUSH) then
			local dropper = attacker
			if(inflictor:GetPhysicsAttacker(5) != nil) then
				dropper = inflictor:GetPhysicsAttacker(5)
			end
			EXTENSION:HandlePhysics(victim, dropper, inflictor, dmg, suicide)
		elseif(typ == DMG_BULLET or typ == DMG_CLUB or typ == DMG_BUCKSHOT or table.HasValue(weapon_types, typ)) then
			EXTENSION:HandleWeapon(victim, attacker, inflictor, dmg, suicide, distance)
		elseif(typ == DMG_BURN or typ == 268435464 or typ == DMG_FALL or typ == DMG_SHOCK or typ == DMG_DROWN or typ == DMG_ACID or typ == DMG_NERVEGAS or typ == DMG_POISON or typ == DMG_RADIATION) then
			EXTENSION:HandleEnvironmental(victim, attacker, inflictor, dmg, suicide)
		elseif(typ == DMG_BLAST or typ == DMG_BLAST_SURFACE or typ == 134217792) then
			EXTENSION:HandleExplosive(victim, attacker, inflictor, dmg, suicide, distance)
		elseif(typ == DMG_VEHICLE or typ == 17) then
			local driver = attacker
			if(attacker:IsVehicle() and attacker:GetDriver() != nil) then
				driver = attacker:GetDriver()
			end
			EXTENSION:HandleVehicle(victim, driver, inflictor, dmg)
		else
			EXTENSION:HandleGeneric(victim, attacker, inflictor, dmg, suicide, distance)
		end
	end)
	
	function EXTENSION:HandleGeneric(victim, attacker, inflictor, dmg, suicide, distance)
		Msg("[GENERIC]\n", "Victim: ", victim, "\n", "Attacker: ", attacker, "\n", "Inflictor: ", inflictor, "\n", "Type: ", dmg:GetDamageType(), "\n")
		if(dmg:GetDamageType() == DMG_DISSOLVE or dmg:GetDamageType() == 67108865) then
			if(attacker:IsPlayer()) then
				net.Start("VDeathNotice")
				net.WriteString(victim:GetName() .. " was fizzled by " .. attacker:GetName())
				net.Broadcast()
			else
				net.Start("VDeathNotice")
				net.WriteString(victim:GetName() .. " was fizzled.")
				net.Broadcast()
			end
		end
	end
	
	function EXTENSION:HandlePhysics(victim, attacker, inflictor, dmg, suicide)
		Msg("[PHYSICS]\n", "Victim: ", victim, "\n", "Attacker: ", attacker, "\n", "Inflictor: ", inflictor, "\n", "Type: ", dmg:GetDamageType(), "\n")
		if(attacker:IsPlayer()) then
			net.Start("VDeathNotice")
			net.WriteString(victim:GetName() .. " was crushed by " .. attacker:GetName())
			net.Broadcast()
		else
			if(suicide or not IsValid(attacker)) then
				net.Start("VDeathNotice")
				net.WriteString(victim:GetName() .. " crushed him/herself.")
				net.Broadcast()
			else
				net.Start("VDeathNotice")
				net.WriteString(victim:GetName() .. " was crushed.")
				net.Broadcast()
			end
		end
	end
	
	function EXTENSION:HandleWeapon(victim, attacker, inflictor, dmg, suicide, distance)
		Msg("[WEAPON]\n", "Victim: ", victim, "\n", "Attacker: ", attacker, "\n", "Inflictor: ", inflictor, "\n", "Type: ", dmg:GetDamageType(), "\n")
		if(IsValid(attacker) and attacker:IsPlayer()) then
			local weapon = nil
			if(IsValid(attacker:GetActiveWeapon())) then
				weapon = string.lower(Vermilion.Utility.GetWeaponName(attacker:GetActiveWeapon():GetClass()))
			end
			if(weapon != nil) then
				if(suicide) then
					net.Start("VDeathNotice")
					net.WriteString(victim:GetName() .. " killed him/herself with a " .. weapon)
					net.Broadcast()
				else
					local server_best = self:GetData("longest_shot", 0, true)
					local server_best_owner = self:GetData("longest_shot_holder", "", true)
					if(distance > server_best) then
						net.Start("VDeathNotice")
						local recordtext = ""
						if(server_best_owner != "") then
							recordtext = " (NEW RECORD! Old: " .. tostring(server_best) .. "m - " .. server_best_owner .. ")" 
						end
						net.WriteString(victim:GetName() .. " was killed by " .. attacker:GetName() .. " with a " .. weapon .. " from " .. tostring(distance) .. "m away." .. recordtext)
						net.Broadcast()
						self:SetData("longest_shot", distance)
						self:SetData("longest_shot_holder", attacker:GetName())
					else
						net.Start("VDeathNotice")
						net.WriteString(victim:GetName() .. " was killed by " .. attacker:GetName() .. " with a " .. weapon .. " from " .. tostring(distance) .. "m away.")
						net.Broadcast()
					end
				end
			else
				net.Start("VDeathNotice")
				net.WriteString(victim:GetName() .. " was killed by " .. attacker:GetName() .. " from " .. tostring(distance) .. "m away.")
				net.Broadcast()
			end
		end
	end
	
	function EXTENSION:HandleEnvironmental(victim, attacker, inflictor, dmg, suicide)
		Msg("[ENV]\n", "Victim: ", victim, "\n", "Attacker: ", attacker, "\n", "Inflictor: ", inflictor, "\n", "Type: ", dmg:GetDamageType(), "\n")
		if(dmg:GetDamageType() == DMG_FALL) then
			net.Start("VDeathNotice")
			net.WriteString(victim:GetName() .. " was dominated by Isaac Newton!")
			net.Broadcast()
		elseif(dmg:GetDamageType() == DMG_BURN or dmg:GetDamageType() == 268435464) then
			net.Start("VDeathNotice")
			net.WriteString(victim:GetName() .. " burned to death.")
			net.Broadcast()
		end
	end
	
	function EXTENSION:HandleVehicle(victim, attacker, inflictor, dmg)
		Msg("[VEHICLE]\n", "Victim: ", victim, "\n", "Attacker: ", attacker, "\n", "Inflictor: ", inflictor, "\n", "Type: ", dmg:GetDamageType(), "\n")
		if(attacker:IsPlayer()) then
			local vehicleName = nil
			for i,k in pairs(list.Get("Vehicles")) do
				if(k.Class == inflictor:GetClass()) then
					vehicleName = i
					break
				end
			end
			net.Start("VDeathNotice")
			if(vehicleName != nil) then
				net.WriteString(victim:GetName() .. " was run over by " .. attacker:GetName() .. " in a " .. vehicleName)
			else
				net.WriteString(victim:GetName() .. " was run over by " .. attacker:GetName())
			end
			net.Broadcast()
		end
	end
	
	function EXTENSION:HandleExplosive(victim, attacker, inflictor, dmg, suicide, distance)
		Msg("[EXPLOSIVE]\n", "Victim: ", victim, "\n", "Attacker: ", attacker, "\n", "Inflictor: ", inflictor, "\n", "Type: ", dmg:GetDamageType(), "\n")
		if(IsValid(attacker) and attacker:IsPlayer()) then
			local weapon = nil
			if(IsValid(attacker:GetActiveWeapon())) then
				weapon = string.lower(Vermilion.Utility.GetWeaponName(attacker:GetActiveWeapon():GetClass()))
			end
			if(weapon != nil and inflictor:GetClass() != "prop_physics") then
				if(suicide) then
					net.Start("VDeathNotice")
					net.WriteString(victim:GetName() .. " has blown him/herself up with a " .. weapon)
					net.Broadcast()
				else
					local server_best = self:GetData("longest_shot", 0, true)
					local server_best_owner = self:GetData("longest_shot_holder", "", true)
					if(distance > server_best) then
						net.Start("VDeathNotice")
						local recordtext = ""
						if(server_best_owner != "") then
							recordtext = " (NEW RECORD! Old: " .. tostring(server_best) .. "m - " .. server_best_owner .. ")" 
						end
						net.WriteString(victim:GetName() .. " was blown up by " .. attacker:GetName() .. " with a " .. weapon .. " from " .. tostring(distance) .. "m away." .. recordtext)
						net.Broadcast()
						self:SetData("longest_shot", distance)
						self:SetData("longest_shot_holder", attacker:GetName())
					else
						net.Start("VDeathNotice")
						net.WriteString(victim:GetName() .. " was blown up by " .. attacker:GetName() .. " with a " .. weapon .. " from " .. tostring(distance) .. "m away.")
						net.Broadcast()
					end
				end
			else
				if(suicide) then
					net.Start("VDeathNotice")
					net.WriteString(victim:GetName() .. " has blown him/herself up.")
					net.Broadcast()
				else
					net.Start("VDeathNotice")
					net.WriteString(victim:GetName() .. " was blown up by " .. attacker:GetName() .. " from " .. tostring(distance) .. "m away.")
					net.Broadcast()
				end
			end
		end
	end
end

function EXTENSION:InitClient()
	function EXTENSION:DisplayNotice(str)
		if(Vermilion:GetExtension("notifications") != nil) then
			table.insert(Vermilion:GetExtension("notifications").Notifications, {Text = str, Type = 0, Time = os.time() + 10})
		else
			notification.AddLegacy( "[Vermilion] " .. str, NOTIFY_GENERIC, 10 )
		end
		sound.PlayFile("sound/buttons/lever5.wav", "noplay", function(station, errorID)
			if(IsValid(station)) then
				station:SetVolume(0.1)
				station:Play()
			else
				print(errorID)
			end
		end)
	end
	
	self:NetHook("VDeathNotice", function()
		EXTENSION:DisplayNotice(net.ReadString())
	end)
end

Vermilion:RegisterExtension(EXTENSION)