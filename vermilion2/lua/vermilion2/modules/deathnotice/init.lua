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
MODULE.Name = "Death Notice"
MODULE.ID = "deathnotice"
MODULE.Description = "Broadcasts mostly sarcastic and passive-aggressive notifications when someone dies."
MODULE.Author = "Ned"
MODULE.Permissions = {

}

MODULE.HitGroupTranslations = {
	"hitgroup:head",
	"hitgroup:chest",
	"hitgroup:stomach",
	"hitgroup:larm",
	"hitgroup:rarm",
	"hitgroup:lleg",
	"hitgroup:rleg"
}

function MODULE:InitShared()
	self:AddHook(Vermilion.Event.MOD_LOADED, function()
		local mod = Vermilion:GetModule("server_settings")
		if(mod != nil) then
			if(SERVER) then MODULE:GetData("enabled", true, true) end -- create variable if it doesn't exist.
			mod:AddOption({
				Module = "deathnotice",
				Name = "enabled",
				GuiText = MODULE:TranslateStr("opt:enable"),
				Type = "Checkbox",
				Category = "Misc"
				})
			mod:AddOption({
				Module = "deathnotice",
				Name = "debugmode",
				GuiText = MODULE:TranslateStr("opt:debug"),
				Type = "Checkbox",
				Category = "Misc"
				})
		end
	end)
end

function MODULE:InitServer()
	self:AddHook("PhysgunDrop", function(vplayer, ent)
		if(IsValid(ent)) then
			ent:SetPhysicsAttacker(vplayer, 5)
		end
	end)

	self:AddHook("DoPlayerDeath", "DeathNotice", function(victim, attacker, dmg)
		if(not MODULE:GetData("enabled", true, true)) then return end
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
			0,
			8194,
			4098,
			536875010,
			67112960
		}

		if(typ == DMG_CRUSH) then
			local dropper = attacker
			if(inflictor:GetPhysicsAttacker(5) != nil) then
				dropper = inflictor:GetPhysicsAttacker(5)
			end
			MODULE:HandlePhysics(victim, dropper, inflictor, dmg, suicide)
		elseif(typ == DMG_BULLET or typ == DMG_CLUB or typ == DMG_BUCKSHOT or table.HasValue(weapon_types, typ)) then
			MODULE:HandleWeapon(victim, attacker, inflictor, dmg, suicide, distance)
		elseif(typ == DMG_BURN or typ == 268435464 or typ == DMG_FALL or typ == DMG_SHOCK or typ == DMG_DROWN or typ == DMG_ACID or typ == DMG_NERVEGAS or typ == DMG_POISON or typ == DMG_RADIATION) then
			MODULE:HandleEnvironmental(victim, attacker, inflictor, dmg, suicide)
		elseif(typ == DMG_BLAST or typ == DMG_BLAST_SURFACE or typ == 134217792) then
			MODULE:HandleExplosive(victim, attacker, inflictor, dmg, suicide, distance)
		elseif(typ == DMG_VEHICLE or typ == 17) then
			local driver = attacker
			if(attacker:IsVehicle() and attacker:GetDriver() != nil) then
				driver = attacker:GetDriver()
			end
			MODULE:HandleVehicle(victim, driver, inflictor, dmg)
		else
			MODULE:HandleGeneric(victim, attacker, inflictor, dmg, suicide, distance)
		end
	end)

	function MODULE:HandleGeneric(victim, attacker, inflictor, dmg, suicide, distance)
		if(self:GetData("debugmode", false, true)) then Msg("[GENERIC]\n", "Victim: ", victim, "\n", "Attacker: ", attacker, "\n", "Inflictor: ", inflictor, "\n", "Type: ", dmg:GetDamageType(), "\n") end
		if(dmg:GetDamageType() == DMG_DISSOLVE or dmg:GetDamageType() == 67108865) then
			if(attacker:IsPlayer()) then
				Vermilion:BroadcastNotify("deathnotice:die:fizzled", { victim:GetName(), attacker:GetName() })
			else
				Vermilion:BroadcastNotify("deathnotice:die:fizzled:unk", { victim:GetName() })
			end
		end
	end

	function MODULE:HandlePhysics(victim, attacker, inflictor, dmg, suicide)
		if(self:GetData("debugmode", false, true)) then Msg("[PHYSICS]\n", "Victim: ", victim, "\n", "Attacker: ", attacker, "\n", "Inflictor: ", inflictor, "\n", "Type: ", dmg:GetDamageType(), "\n") end
		if(attacker:IsPlayer()) then
			Vermilion:BroadcastNotify("deathnotice:die:crush", { victim:GetName(), attacker:GetName() })
		else
			if(suicide or not IsValid(attacker)) then
				Vermilion:BroadcastNotify("deathnotice:die:crush:self", { victim:GetName() })
			else
				Vermilion:BroadcastNotify("deathnotice:die:crush:unk", { victim:GetName() })
			end
		end
	end

	function MODULE:HandleWeapon(victim, attacker, inflictor, dmg, suicide, distance)
		if(self:GetData("debugmode", false, true)) then Msg("[WEAPON]\n", "Victim: ", victim, "\n", "Attacker: ", attacker, "\n", "Inflictor: ", inflictor, "\n", "Type: ", dmg:GetDamageType(), "\n") end
		if(IsValid(attacker) and attacker:IsPlayer()) then
			local weapon = nil
			if(IsValid(attacker:GetActiveWeapon())) then
				weapon = string.lower(VToolkit.GetWeaponName(attacker:GetActiveWeapon():GetClass()))
			end
			if(weapon != nil) then
				if(suicide) then
					Vermilion:BroadcastNotify("deathnotice:die:weapon:self", { victim:GetName(), weapon })
				else
					local server_best = self:GetData("longest_shot", {}, true)[weapon] or 0
					local server_best_owner = self:GetData("longest_shot_holder", {}, true)[weapon] or ""
					local shotat = MODULE.HitGroupTranslations[victim:LastHitGroup()]
					if(shotat != nil and distance > server_best) then
						for i,k in pairs(VToolkit.GetValidPlayers(true)) do
							Vermilion:AddNotification(k, "deathnotice:die:weapon:recordhitgroup", { victim:GetName(), attacker:GetName(), weapon, tostring(distance), MODULE:TranslateStr(shotat, nil, k), tostring(server_best), server_best_owner })
						end
						self:GetData("longest_shot", {}, true)[weapon] = distance
						self:GetData("longest_shot_holder", {}, true)[weapon] = attacker:GetName()
					elseif(shotat != nil) then
						for i,k in pairs(VToolkit.GetValidPlayers(true)) do
							Vermilion:AddNotification(k, "deathnotice:die:weapon:hitgroup", { victim:GetName(), attacker:GetName(), weapon, tostring(distance), MODULE:TranslateStr(shotat, nil, k) })
						end
					else
						Vermilion:BroadcastNotify("deathnotice:die:weapon:default", { victim:GetName(), attacker:GetName(), weapon, tostring(distance) })
					end
				end
			else
				local shotat = MODULE.HitGroupTranslations[victim:LastHitGroup()]
				if(shotat != nil) then
					for i,k in pairs(VToolkit.GetValidPlayers(true)) do
						Vermilion:AddNotification(k, "deathnotice:die:weapon:unkhitgroup", { victim:GetName(), attacker:GetName(), tostring(distance), MODULE:TranslateStr(shotat, nil, k) })
					end
				else
					shotat = "."
				end
				Vermilion:BroadcastNotify("deathnotice:die:weapon:unk", { victim:GetName(), attacker:GetName(), tostring(distance) })
			end
		end
	end

	function MODULE:HandleEnvironmental(victim, attacker, inflictor, dmg, suicide)
		if(self:GetData("debugmode", false, true)) then Msg("[ENV]\n", "Victim: ", victim, "\n", "Attacker: ", attacker, "\n", "Inflictor: ", inflictor, "\n", "Type: ", dmg:GetDamageType(), "\n") end
		if(dmg:GetDamageType() == DMG_FALL) then
			Vermilion:BroadcastNotify("deathnotice:die:fall", { victim:GetName() })
		elseif(dmg:GetDamageType() == DMG_BURN or dmg:GetDamageType() == 268435464) then
			Vermilion:BroadcastNotify("deathnotice:die:burn", { victim:GetName() })
		end
	end

	function MODULE:HandleVehicle(victim, attacker, inflictor, dmg)
		if(self:GetData("debugmode", false, true)) then Msg("[VEHICLE]\n", "Victim: ", victim, "\n", "Attacker: ", attacker, "\n", "Inflictor: ", inflictor, "\n", "Type: ", dmg:GetDamageType(), "\n") end
		if(attacker:IsPlayer()) then
			local vehicleName = nil
			for i,k in pairs(list.Get("Vehicles")) do
				if(k.Class == inflictor:GetClass()) then
					vehicleName = i
					break
				end
			end
			if(vehicleName != nil) then
				Vermilion:BroadcastNotify("deathnotice:die:vehicle", { victim:GetName(), attacker:GetName(), vehicleName })
			else
				Vermilion:BroadcastNotify("deathnotice:die:vehicle:unk", { victim:GetName(), attacker:GetName() })
			end
		end
	end

	function MODULE:HandleExplosive(victim, attacker, inflictor, dmg, suicide, distance)
		if(self:GetData("debugmode", false, true)) then Msg("[EXPLOSIVE]\n", "Victim: ", victim, "\n", "Attacker: ", attacker, "\n", "Inflictor: ", inflictor, "\n", "Type: ", dmg:GetDamageType(), "\n") end
		if(IsValid(attacker) and attacker:IsPlayer()) then
			local weapon = nil
			if(IsValid(attacker:GetActiveWeapon())) then
				weapon = string.lower(VToolkit.GetWeaponName(attacker:GetActiveWeapon():GetClass()))
			end
			if(weapon != nil and inflictor:GetClass() != "prop_physics") then
				if(suicide) then
					Vermilion:BroadcastNotify("deathnotice:die:expl:self", { victim:GetName(), weapon })
				else
					local server_best = self:GetData("longest_shot", {}, true)[weapon] or 0
					local server_best_owner = self:GetData("longest_shot_holder", {}, true)[weapon] or ""
					if(distance > server_best) then
						Vermilion:BroadcastNotify("deathnotice:die:expl:record", { victim:GetName(), attacker:GetName(), weapon, tostring(distance), tostring(server_best), server_best_owner })
						self:GetData("longest_shot", {}, true)[weapon] = distance
						self:GetData("longest_shot_holder", {}, true)[weapon] = attacker:GetName()
					else
						Vermilion:BroadcastNotify("deathnotice:die:expl:text", { victim:GetName(), attacker:GetName(), weapon, tostring(distance) })
					end
				end
			else
				if(suicide) then
					Vermilion:BroadcastNotify("deathnotice:die:expl:unk:self", { victim:GetName() })
				else
					Vermilion:BroadcastNotify("deathnotice:die:expl:unk", { victim:GetName(), attacker:GetName(), tostring(distance) })
				end
			end
		end
	end
end
