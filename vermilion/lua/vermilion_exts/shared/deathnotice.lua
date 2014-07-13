--[[
 The MIT License

 Copyright 2014 Ned Hyett.

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
]]

local EXTENSION = Vermilion:MakeExtensionBase()
EXTENSION.Name = "Death Notice"
EXTENSION.ID = "deathnotice"
EXTENSION.Description = "Broadcasts a notification when someone dies."
EXTENSION.Author = "Ned"
EXTENSION.Permissions = {
	
}

function EXTENSION:InitServer()
	util.AddNetworkString("VDeathNotice")
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
		notification.AddLegacy( str, NOTIFY_GENERIC, 10 )
		sound.PlayFile("sound/buttons/lever5.wav", "noplay", function(station, errorID)
			if(IsValid(station)) then
				station:SetVolume(0.1)
				station:Play()
			else
				print(errorID)
			end
		end)
	end

	net.Receive("VDeathNotice", function(len)
		local victim = ents.GetByIndex(tonumber(net.ReadString()))
		local attacker = ents.GetByIndex(tonumber(net.ReadString()))
		local dist = net.ReadString()
		local damageType = tonumber(net.ReadString())
		
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
			if(IsValid(attacker)) then
				if(IsValid(attacker:GetActiveWeapon()) ) then
					local usinga = " with a "
					if(string.EndsWith(Vermilion:GetWeaponName(attacker:GetActiveWeapon():GetClass()), "s")) then
						usinga = " with "
					end
					EXTENSION:DisplayNotice(victim:GetName() .. " was blown up by " .. attacker:GetName() .. usinga .. string.lower(Vermilion:GetWeaponName(attacker:GetActiveWeapon():GetClass())) .. " at a distance of " .. dist .. " metres")
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
				attackerName = Vermilion:GetNPCName(attacker:GetClass())
			else
				attackerName = attacker:GetName()
			end
			local weapon1 = attacker:GetActiveWeapon()
			if(not IsValid(weapon1)) then
				EXTENSION:DisplayNotice(victim:GetName() .. " was killed by " .. attackerName .. " at a distance of " .. dist .. " metres")
				return
			end
			local usinga = " with a "
			if(string.EndsWith(Vermilion:GetWeaponName(attacker:GetActiveWeapon():GetClass()), "s")) then
				usinga = " with "
			end
			EXTENSION:DisplayNotice(victim:GetName() .. " was killed by " .. attackerName .. usinga .. string.lower(Vermilion:GetWeaponName(weapon1:GetClass())) .. " at a distance of " .. dist .. " metres")
		end
	end)
end

Vermilion:RegisterExtension(EXTENSION)