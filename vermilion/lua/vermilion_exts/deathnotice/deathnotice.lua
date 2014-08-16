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
-- move this back to being a server only extension.
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
	self:AddHook("DoPlayerDeath", "DeathNotice", function(vplayer, vplayerAttacker, dmgInfo)
		net.Start("VDeathNotice")
		net.WriteString(tostring(vplayer:EntIndex()))
		local damageType = dmgInfo:GetDamageType()
		if(damageType == DMG_VEHICLE or damageType == 17) then
			net.WriteString(vplayerAttacker:GetDriver():EntIndex())
		else
			net.WriteString(tostring(vplayerAttacker:EntIndex()))
		end
		net.WriteString(tostring(math.Round(vplayer:GetPos():Distance(vplayerAttacker:GetPos()) * 0.01905)))
		net.WriteString(tostring(dmgInfo:GetDamageType()))
		net.Broadcast()
	end)
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
		local victim = ents.GetByIndex(tonumber(net.ReadString()))
		local attacker = ents.GetByIndex(tonumber(net.ReadString()))
		local dist = net.ReadString()
		local damageType = tonumber(net.ReadString())
		if(not IsValid(attacker) or not IsValid(victim)) then return end
		if(victim == attacker) then
			EXTENSION:DisplayNotice(victim:GetName() .. " committed suicide!")
			return
		end
		if(damageType == DMG_CRUSH) then
			EXTENSION:DisplayNotice(victim:GetName() .. " was flattened!")
		elseif(damageType == DMG_BURN) then
			EXTENSION:DisplayNotice(victim:GetName() .. " just discovered fire!")
		elseif(damageType == DMG_VEHICLE or damageType == 17) then
			EXTENSION:DisplayNotice(victim:GetName() .. " was run over by " .. attacker:GetName() .. "!")
		elseif(damageType == DMG_FALL) then
			EXTENSION:DisplayNotice(victim:GetName() .. " just understood f=ma!")
		elseif(damageType == DMG_BLAST or damageType == DMG_BLAST_SURFACE or damageType == 134217792) then
			if(IsValid(attacker) and (attacker:IsPlayer() or attacker:IsNPC())) then
				if(IsValid(attacker:GetActiveWeapon()) ) then
					local usinga = " with a "
					if(string.EndsWith(Vermilion.Utility.GetWeaponName(attacker:GetActiveWeapon():GetClass()), "s")) then
						usinga = " with "
					end
					EXTENSION:DisplayNotice(victim:GetName() .. " was blown up by " .. attacker:GetName() .. usinga .. string.lower(Vermilion.Utility.GetWeaponName(attacker:GetActiveWeapon():GetClass())) .. " at a distance of " .. dist .. " metres")
					return
				end
				EXTENSION:DisplayNotice(victim:GetName() .. " was blown up by " .. attacker:GetName() .. " at a distance of " .. dist .. " metres")
				return
			end
			EXTENSION:DisplayNotice(victim:GetName() .. " was playing with explosives!")
		elseif(damageType == DMG_SHOCK) then
			EXTENSION:DisplayNotice(victim:GetName() .. " was playing with electricity!")
		elseif(damageType == DMG_ENERGYBEAM) then
			EXTENSION:DisplayNotice(victim:GetName() .. " was playing with lasers!")
		elseif(damageType == DMG_DROWN) then
			EXTENSION:DisplayNotice(victim:GetName() .. " tried to breathe underwater!")
		elseif(damageType == DMG_NERVEGAS) then
			EXTENSION:DisplayNotice(victim:GetName() .. " took a bath in the 'deadly' neurotoxin!")
		elseif(damageType == DMG_ACID) then
			EXTENSION:DisplayNotice(victim:GetName() .. " drank some acid!")
		elseif(damageType == DMG_DISSOLVE) then
			EXTENSION:DisplayNotice(victim:GetName() .. " was vaporised!")
		elseif(damageType == DMG_RADIATION) then
			EXTENSION:DisplayNotice(victim:GetName() .. " failed to get into the fridge in time!")
		else
			local attackerName = nil
			if(attacker:IsNPC()) then
				attackerName = Vermilion.Utility.GetNPCName(attacker:GetClass())
			else
				if(attacker.GetName == nil) then attackerName = "ERROR" else
				attackerName = attacker:GetName()
				end
			end
			local weapon1 = attacker:GetActiveWeapon()
			if(not IsValid(weapon1)) then
				EXTENSION:DisplayNotice(victim:GetName() .. " was killed by " .. attackerName .. " at a distance of " .. dist .. " metres")
				return
			end
			local usinga = " with a "
			if(string.EndsWith(Vermilion.Utility.GetWeaponName(attacker:GetActiveWeapon():GetClass()), "s")) then
				usinga = " with "
			end
			EXTENSION:DisplayNotice(victim:GetName() .. " was killed by " .. attackerName .. usinga .. string.lower(Vermilion.Utility.GetWeaponName(weapon1:GetClass())) .. " at a distance of " .. dist .. " metres")
		end
	end)
end

Vermilion:RegisterExtension(EXTENSION)